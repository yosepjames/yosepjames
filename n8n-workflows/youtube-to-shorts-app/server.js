require('dotenv').config();
const express = require('express');
const axios = require('axios');
const path = require('path');
const fs = require('fs');
const { google } = require('googleapis');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const PORT = process.env.PORT || 3000;
const TOKEN_PATH = path.join(__dirname, '.youtube-token.json');

// ── OAuth2 client ──────────────────────────────────────────────────────────────
const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  `http://localhost:${PORT}/auth/callback`
);

if (fs.existsSync(TOKEN_PATH)) {
  oauth2Client.setCredentials(JSON.parse(fs.readFileSync(TOKEN_PATH)));
}

// ── In-memory job store & SSE clients ─────────────────────────────────────────
const jobs = new Map();
const sseClients = new Map();

function emit(jobId, data) {
  const clients = sseClients.get(jobId) || [];
  const payload = `data: ${JSON.stringify(data)}\n\n`;
  clients.forEach(res => res.write(payload));
}

// ── Auth routes ────────────────────────────────────────────────────────────────
app.get('/auth', (_req, res) => {
  const url = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    prompt: 'consent',
    scope: ['https://www.googleapis.com/auth/youtube.upload']
  });
  res.redirect(url);
});

app.get('/auth/callback', async (req, res) => {
  try {
    const { tokens } = await oauth2Client.getToken(req.query.code);
    oauth2Client.setCredentials(tokens);
    fs.writeFileSync(TOKEN_PATH, JSON.stringify(tokens));
    res.redirect('/?auth=success');
  } catch (err) {
    res.redirect('/?auth=error&msg=' + encodeURIComponent(err.message));
  }
});

app.get('/api/auth-status', (_req, res) => {
  res.json({ authenticated: fs.existsSync(TOKEN_PATH) });
});

// ── SSE progress stream ────────────────────────────────────────────────────────
app.get('/api/events/:jobId', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  const { jobId } = req.params;
  if (!sseClients.has(jobId)) sseClients.set(jobId, []);
  sseClients.get(jobId).push(res);

  req.on('close', () => {
    sseClients.set(jobId, (sseClients.get(jobId) || []).filter(c => c !== res));
  });
});

// ── Start workflow ─────────────────────────────────────────────────────────────
app.post('/api/start', (req, res) => {
  if (!fs.existsSync(TOKEN_PATH)) {
    return res.status(401).json({ error: 'Not authenticated with YouTube. Visit /auth first.' });
  }

  const { videoId, firstPublicationAt, intervalHours, captionStyling } = req.body;
  if (!videoId || !firstPublicationAt || !intervalHours) {
    return res.status(400).json({ error: 'videoId, firstPublicationAt and intervalHours are required.' });
  }

  const jobId = `job_${Date.now()}`;
  jobs.set(jobId, { status: 'running', results: [], logs: [] });
  res.json({ jobId });

  runWorkflow(jobId, {
    videoId,
    firstPublicationAt,
    intervalHours: Number(intervalHours),
    captionStyling
  }).catch(err => {
    console.error('[workflow error]', err.message);
    emit(jobId, { type: 'error', message: err.message });
    const job = jobs.get(jobId);
    if (job) { job.status = 'error'; job.error = err.message; }
  });
});

// ── Job status ─────────────────────────────────────────────────────────────────
app.get('/api/status/:jobId', (req, res) => {
  const job = jobs.get(req.params.jobId);
  if (!job) return res.status(404).json({ error: 'Job not found' });
  res.json(job);
});

// ── Workflow helpers ───────────────────────────────────────────────────────────
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function poll(fn, done, intervalMs = 30_000, maxTries = 60) {
  for (let i = 0; i < maxTries; i++) {
    const result = await fn();
    if (done(result)) return result;
    await sleep(intervalMs);
  }
  throw new Error('Polling timed out');
}

function parseStyling(raw) {
  if (!raw || typeof raw !== 'string' || !raw.trim()) return null;
  try {
    const p = JSON.parse(raw);
    if (p.options !== undefined) return p.options;
    if (p.preset !== undefined) return p.preset;
  } catch { /* ignore */ }
  return null;
}

async function generateMetadata(videoTitle, transcript, reason) {
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-lite' });

  const prompt = `You are a YouTube Shorts content strategist. Generate metadata for a Short.

Original video title: ${videoTitle}
Transcript: ${transcript || '(none)'}
Why this clip: ${reason || '(none)'}

Return ONLY a raw JSON object (no markdown fences) with:
- short_title: string, max 70 chars, hook-driven
- short_description: string, max 500 chars, must contain #shorts
- short_tags: string[], 5-15 items, must include "shorts" and "youtubeshorts"
- youtube_category_id: integer (e.g. 22=People&Blogs, 24=Entertainment, 27=Education, 28=Science&Technology, 20=Gaming)`;

  const result = await model.generateContent(prompt);
  const raw = result.response.text().replace(/```(?:json)?\n?/g, '').trim();
  return JSON.parse(raw);
}

async function getAccessToken() {
  const { credentials } = await oauth2Client.refreshAccessToken();
  oauth2Client.setCredentials(credentials);
  fs.writeFileSync(TOKEN_PATH, JSON.stringify(credentials));
  return credentials.access_token;
}

async function uploadToYouTube(videoBuffer, metadata, publicationDate) {
  const token = await getAccessToken();

  const initRes = await axios.post(
    'https://www.googleapis.com/upload/youtube/v3/videos?part=snippet,status&uploadType=resumable',
    {
      snippet: {
        title: metadata.short_title,
        description: metadata.short_description,
        tags: metadata.short_tags.slice(0, 6),
        categoryId: String(metadata.youtube_category_id),
        defaultLanguage: 'en_US',
        defaultAudioLanguage: 'en_US'
      },
      status: {
        privacyStatus: 'private',
        publishAt: publicationDate,
        license: 'youtube',
        embeddable: true,
        publicStatsViewable: true,
        madeForKids: false,
        selfDeclaredMadeForKids: false
      }
    },
    {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'X-Upload-Content-Type': 'video/mp4'
      }
    }
  );

  const uploadUrl = initRes.headers.location;

  const uploadRes = await axios.put(uploadUrl, videoBuffer, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'video/mp4'
    },
    maxContentLength: Infinity,
    maxBodyLength: Infinity
  });

  return uploadRes.data?.id || null;
}

// ── Main workflow ──────────────────────────────────────────────────────────────
async function runWorkflow(jobId, { videoId, firstPublicationAt, intervalHours, captionStyling }) {
  const log = (type, message, extra = {}) => {
    console.log(`[${jobId}] ${message}`);
    emit(jobId, { type, message, ...extra });
    const job = jobs.get(jobId);
    if (job) job.logs.push({ type, message, ts: Date.now() });
  };

  const swiftia = axios.create({
    baseURL: 'https://app.swiftia.io',
    headers: { Authorization: `Bearer ${process.env.SWIFTIA_API_KEY}` }
  });

  const styling = parseStyling(captionStyling);

  // ── 1. Start analysis ──
  log('step', `Mengirim video ${videoId} ke Swiftia untuk analisis...`, { step: 1, totalSteps: 4 });

  const { data: analysisJob } = await swiftia.post('/api/jobs', {
    functionName: 'VideoShorts',
    options: { youtubeVideoId: videoId },
    webhook: ''
  });

  // ── 2. Wait for analysis ──
  log('step', 'Menunggu hasil analisis video...', { step: 2, totalSteps: 4 });

  const analysis = await poll(
    () => swiftia.get(`/api/jobs/${analysisJob.id}`).then(r => r.data),
    d => d.status === 'COMPLETED' || d.status === 'FAILED',
    30_000, 60
  );

  if (analysis.status === 'FAILED') throw new Error('Video analysis failed on Swiftia');

  const shorts = (analysis.data?.shorts || []).slice(0, 10);
  if (!shorts.length) throw new Error('No shorts found in video');

  log('step', `Ditemukan ${shorts.length} klip. Memproses...`, { step: 3, totalSteps: 4 });

  const startDate = new Date(firstPublicationAt);
  const results = [];
  const job = jobs.get(jobId);

  // ── 3. Loop over each short ──
  for (let i = 0; i < shorts.length; i++) {
    const short = shorts[i];
    const publicationDate = new Date(startDate.getTime() + i * intervalHours * 3_600_000).toISOString();

    log('progress', `Short ${i + 1}/${shorts.length}: Rendering...`, { current: i + 1, total: shorts.length });

    // Render
    const renderPayload = { shortId: short.id };
    if (styling) renderPayload.renderOptions = styling;

    const { data: renderJob } = await swiftia.post('/api/render/', renderPayload);

    const rendered = await poll(
      () => swiftia.get(`/api/render/${renderJob.renderId}`).then(r => r.data),
      d => d.status === 'COMPLETED' || d.status === 'FAILED',
      30_000, 60
    );

    if (rendered.status === 'FAILED') {
      log('warning', `Short ${i + 1} gagal dirender, dilewati.`);
      continue;
    }

    // Generate metadata
    log('substep', `Short ${i + 1}: Membuat metadata dengan Gemini...`);
    const metadata = await generateMetadata(
      analysis.title || videoId,
      short.text || '',
      short.reason || ''
    );

    // Download rendered video
    log('substep', `Short ${i + 1}: Mengunduh video...`);
    const { data: videoData } = await axios.get(rendered.url, { responseType: 'arraybuffer' });
    const videoBuffer = Buffer.from(videoData);

    // Upload to YouTube
    log('substep', `Short ${i + 1}: Mengupload ke YouTube...`);
    const youtubeId = await uploadToYouTube(videoBuffer, metadata, publicationDate);

    const result = {
      index: i + 1,
      shortId: short.id,
      youtubeId,
      title: metadata.short_title,
      publicationDate,
      youtubeUrl: youtubeId ? `https://youtube.com/watch?v=${youtubeId}` : null
    };

    results.push(result);
    if (job) job.results = [...results];
    log('result', `Short ${i + 1} berhasil dijadwalkan: ${metadata.short_title}`, { result });
  }

  // ── 4. Done ──
  log('step', 'Semua selesai!', { step: 4, totalSteps: 4 });
  log('complete', `${results.length} shorts berhasil dijadwalkan.`, { results });
  if (job) job.status = 'complete';
}

app.listen(PORT, () => {
  console.log(`YouTube to Shorts app berjalan di http://localhost:${PORT}`);
});
