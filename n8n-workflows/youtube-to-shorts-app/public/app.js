/* ── DOM refs ──────────────────────────────────────────────────── */
const authBadge         = document.getElementById('auth-badge');
const authBanner        = document.getElementById('auth-banner');
const authSuccessBanner = document.getElementById('auth-success-banner');
const form              = document.getElementById('workflow-form');
const submitBtn         = document.getElementById('submit-btn');
const progressCard      = document.getElementById('progress-card');
const progressBarWrap   = document.getElementById('progress-bar-wrap');
const progressBar       = document.getElementById('progress-bar');
const progressLabelText = document.getElementById('progress-label-text');
const progressCount     = document.getElementById('progress-count');
const logList           = document.getElementById('log-list');
const resultsCard       = document.getElementById('results-card');
const resultsList       = document.getElementById('results-list');

/* ── Auth check ────────────────────────────────────────────────── */
async function checkAuth() {
  try {
    const { authenticated } = await fetch('/api/auth-status').then(r => r.json());
    if (authenticated) {
      authBadge.textContent = '✓ YouTube Terhubung';
      authBadge.className = 'auth-badge ok';
      submitBtn.disabled = false;
    } else {
      authBadge.textContent = '✗ Belum Terhubung';
      authBadge.className = 'auth-badge fail';
      authBanner.classList.remove('hidden');
    }
  } catch {
    authBadge.textContent = 'Gagal cek auth';
    authBadge.className = 'auth-badge fail';
  }
}

/* Show success banner if redirected back from OAuth */
const params = new URLSearchParams(location.search);
if (params.get('auth') === 'success') {
  authSuccessBanner.classList.remove('hidden');
  history.replaceState({}, '', '/');
}

/* ── Set default datetime (now + 1 day) ───────────────────────── */
const defaultDate = new Date(Date.now() + 86_400_000);
defaultDate.setMinutes(defaultDate.getMinutes() - defaultDate.getTimezoneOffset());
document.getElementById('firstPublicationAt').value = defaultDate.toISOString().slice(0, 16);

/* ── Step helpers ──────────────────────────────────────────────── */
const stepEls = [1, 2, 3, 4].map(n => document.getElementById(`step-${n}`));
const stepLines = document.querySelectorAll('.step-line');

function setStep(n) {
  stepEls.forEach((el, i) => {
    el.classList.remove('active', 'done');
    if (i + 1 < n)  el.classList.add('done');
    if (i + 1 === n) el.classList.add('active');
  });
  stepLines.forEach((line, i) => {
    line.classList.toggle('done', i + 1 < n);
  });
}

/* ── Log helper ────────────────────────────────────────────────── */
const ICONS = {
  step: '🔵', substep: '→', progress: '⏳',
  warning: '⚠️', error: '❌', complete: '✅', result: '🎬'
};

function appendLog(type, message) {
  const entry = document.createElement('div');
  entry.className = `log-entry ${type}`;
  entry.innerHTML = `<span class="icon">${ICONS[type] || '•'}</span><span>${message}</span>`;
  logList.appendChild(entry);
  logList.scrollTop = logList.scrollHeight;
}

/* ── Handle SSE events ─────────────────────────────────────────── */
function handleEvent(data) {
  switch (data.type) {

    case 'step':
      appendLog('step', data.message);
      if (data.step) setStep(data.step);
      break;

    case 'substep':
      appendLog('substep', data.message);
      break;

    case 'progress': {
      progressBarWrap.classList.remove('hidden');
      const pct = Math.round((data.current / data.total) * 100);
      progressBar.style.width = pct + '%';
      progressLabelText.textContent = data.message || 'Memproses...';
      progressCount.textContent = `${data.current} / ${data.total}`;
      appendLog('progress', data.message);
      break;
    }

    case 'result':
      appendLog('result', data.message);
      if (data.result) renderResult(data.result);
      break;

    case 'warning':
      appendLog('warning', data.message);
      break;

    case 'error':
      appendLog('error', data.message);
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span class="btn-icon">⚡</span> Coba Lagi';
      break;

    case 'complete':
      setStep(4);
      progressBar.style.width = '100%';
      appendLog('complete', data.message);
      resultsCard.classList.remove('hidden');
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span class="btn-icon">⚡</span> Mulai Proses';
      break;
  }
}

/* ── Render result card ────────────────────────────────────────── */
function renderResult(r) {
  resultsCard.classList.remove('hidden');
  const pubDate = new Date(r.publicationDate).toLocaleString('id-ID', {
    dateStyle: 'medium', timeStyle: 'short'
  });
  const item = document.createElement('div');
  item.className = 'result-item';
  item.innerHTML = `
    <div class="result-num">${r.index}</div>
    <div class="result-info">
      <div class="result-title">${escHtml(r.title)}</div>
      <div class="result-meta">📅 ${pubDate} · ID: ${r.shortId}</div>
    </div>
    ${r.youtubeUrl
      ? `<a href="${r.youtubeUrl}" target="_blank" rel="noopener" class="result-link">Buka ↗</a>`
      : '<span class="result-link" style="opacity:.4">Menunggu</span>'
    }
  `;
  resultsList.appendChild(item);
}

function escHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

/* ── Form submit ───────────────────────────────────────────────── */
form.addEventListener('submit', async e => {
  e.preventDefault();

  const videoId          = document.getElementById('videoId').value.trim();
  const firstPublicationAt = new Date(document.getElementById('firstPublicationAt').value).toISOString();
  const intervalHours    = Number(document.getElementById('intervalHours').value);
  const captionStyling   = document.getElementById('captionStyling').value.trim();

  // Reset UI
  logList.innerHTML = '';
  resultsList.innerHTML = '';
  progressBar.style.width = '0%';
  progressBarWrap.classList.add('hidden');
  progressCard.classList.remove('hidden');
  resultsCard.classList.add('hidden');
  setStep(1);

  submitBtn.disabled = true;
  submitBtn.innerHTML = '<span class="btn-icon">⏳</span> Memproses...';

  try {
    const res = await fetch('/api/start', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ videoId, firstPublicationAt, intervalHours, captionStyling })
    });

    if (!res.ok) {
      const { error } = await res.json();
      appendLog('error', error || 'Gagal memulai workflow');
      submitBtn.disabled = false;
      submitBtn.innerHTML = '<span class="btn-icon">⚡</span> Mulai Proses';
      return;
    }

    const { jobId } = await res.json();

    // Open SSE stream
    const source = new EventSource(`/api/events/${jobId}`);
    source.onmessage = e => {
      try { handleEvent(JSON.parse(e.data)); } catch { /* ignore */ }
    };
    source.onerror = () => {
      source.close();
      // Fallback: poll job status
      pollStatus(jobId);
    };

  } catch (err) {
    appendLog('error', err.message);
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<span class="btn-icon">⚡</span> Mulai Proses';
  }
});

/* ── Fallback status polling (if SSE fails) ────────────────────── */
async function pollStatus(jobId) {
  for (let i = 0; i < 120; i++) {
    await new Promise(r => setTimeout(r, 5000));
    try {
      const job = await fetch(`/api/status/${jobId}`).then(r => r.json());
      if (job.status === 'complete') {
        setStep(4);
        progressBar.style.width = '100%';
        (job.results || []).forEach(renderResult);
        resultsCard.classList.remove('hidden');
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span class="btn-icon">⚡</span> Mulai Proses';
        return;
      }
      if (job.status === 'error') {
        appendLog('error', job.error || 'Terjadi kesalahan');
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<span class="btn-icon">⚡</span> Coba Lagi';
        return;
      }
    } catch { /* continue */ }
  }
}

/* ── Init ──────────────────────────────────────────────────────── */
checkAuth();
