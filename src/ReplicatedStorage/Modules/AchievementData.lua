-- Achievement definitions — unlock titles and gem rewards at stat milestones
-- condition.stat maps to fields inside player data.stats OR data.rebirth
local AchievementData = {}

-- title = string shown above player's head (nil = no title change)
-- titleColor = Color3 for title text
AchievementData.List = {
	-- ── Egg opening ───────────────────────────────────────────────────────────
	{
		id = "first_egg", name = "Egg Cracker",
		desc = "Open your first egg.",
		condition = { stat = "eggsOpened", target = 1 },
		reward = { gems = 5 },
		title = "🥚 Egg Cracker", titleColor = Color3.fromRGB(200,200,200),
	},
	{
		id = "eggs_50", name = "Egg Addict",
		desc = "Open 50 eggs.",
		condition = { stat = "eggsOpened", target = 50 },
		reward = { gems = 15 },
		title = "🥚 Egg Addict", titleColor = Color3.fromRGB(100,200,100),
	},
	{
		id = "eggs_250", name = "Egg Machine",
		desc = "Open 250 eggs.",
		condition = { stat = "eggsOpened", target = 250 },
		reward = { gems = 40 },
		title = "🥚 Egg Machine", titleColor = Color3.fromRGB(60,120,220),
	},
	{
		id = "eggs_1000", name = "Hatchery Lord",
		desc = "Open 1,000 eggs.",
		condition = { stat = "eggsOpened", target = 1000 },
		reward = { gems = 120 },
		title = "👑 Hatchery Lord", titleColor = Color3.fromRGB(255,165,0),
	},

	-- ── Fusion ────────────────────────────────────────────────────────────────
	{
		id = "first_fuse", name = "Alchemist",
		desc = "Fuse your first pet.",
		condition = { stat = "fusionsDone", target = 1 },
		reward = { gems = 8 },
		title = "⚗ Alchemist", titleColor = Color3.fromRGB(160,80,220),
	},
	{
		id = "fusions_25", name = "Grand Alchemist",
		desc = "Fuse 25 pets.",
		condition = { stat = "fusionsDone", target = 25 },
		reward = { gems = 30 },
		title = "⚗ Grand Alchemist", titleColor = Color3.fromRGB(180,60,255),
	},
	{
		id = "fusions_100", name = "Fusion Master",
		desc = "Fuse 100 pets.",
		condition = { stat = "fusionsDone", target = 100 },
		reward = { gems = 100 },
		title = "⚗ Fusion Master", titleColor = Color3.fromRGB(255,60,200),
	},

	-- ── Shiny ─────────────────────────────────────────────────────────────────
	{
		id = "first_shiny", name = "Lucky One",
		desc = "Obtain your first Shiny pet.",
		condition = { stat = "shiniesFound", target = 1 },
		reward = { gems = 15 },
		title = "✨ Lucky One", titleColor = Color3.fromRGB(255,215,0),
	},
	{
		id = "shinies_10", name = "Shiny Hunter",
		desc = "Collect 10 Shiny pets.",
		condition = { stat = "shiniesFound", target = 10 },
		reward = { gems = 60 },
		title = "✨ Shiny Hunter", titleColor = Color3.fromRGB(255,200,0),
	},
	{
		id = "shinies_50", name = "Rainbow Lord",
		desc = "Collect 50 Shiny pets.",
		condition = { stat = "shiniesFound", target = 50 },
		reward = { gems = 200 },
		title = "🌈 Rainbow Lord", titleColor = Color3.fromRGB(255,100,180),
	},

	-- ── Rebirth ───────────────────────────────────────────────────────────────
	{
		id = "rebirth_1", name = "Prestige I",
		desc = "Rebirth for the first time.",
		condition = { stat = "rebirth", target = 1 },
		reward = { gems = 50 },
		title = "⭐ Prestige I", titleColor = Color3.fromRGB(255,215,0),
	},
	{
		id = "rebirth_5", name = "Prestige V",
		desc = "Rebirth 5 times.",
		condition = { stat = "rebirth", target = 5 },
		reward = { gems = 150 },
		title = "⭐⭐ Prestige V", titleColor = Color3.fromRGB(255,180,0),
	},
	{
		id = "rebirth_10", name = "Transcendent",
		desc = "Rebirth 10 times.",
		condition = { stat = "rebirth", target = 10 },
		reward = { gems = 400 },
		title = "🌟 Transcendent", titleColor = Color3.fromRGB(255,120,0),
	},
	{
		id = "rebirth_25", name = "Eternal",
		desc = "Rebirth 25 times. The true endgame.",
		condition = { stat = "rebirth", target = 25 },
		reward = { gems = 1000 },
		title = "♾ Eternal", titleColor = Color3.fromRGB(255,60,60),
	},

	-- ── Territory ─────────────────────────────────────────────────────────────
	{
		id = "first_capture", name = "Conqueror",
		desc = "Capture your first territory.",
		condition = { stat = "territoriesCaptured", target = 1 },
		reward = { gems = 10 },
		title = "⚔ Conqueror", titleColor = Color3.fromRGB(80,160,255),
	},
	{
		id = "captures_20", name = "Territory King",
		desc = "Capture territories 20 times.",
		condition = { stat = "territoriesCaptured", target = 20 },
		reward = { gems = 50 },
		title = "👑 Territory King", titleColor = Color3.fromRGB(255,165,0),
	},

	-- ── Boss ──────────────────────────────────────────────────────────────────
	{
		id = "boss_first", name = "Boss Slayer",
		desc = "Help defeat your first World Boss.",
		condition = { stat = "bossKills", target = 1 },
		reward = { gems = 20 },
		title = "⚔ Boss Slayer", titleColor = Color3.fromRGB(220,60,60),
	},
	{
		id = "boss_10", name = "Boss Hunter",
		desc = "Help defeat 10 World Bosses.",
		condition = { stat = "bossKills", target = 10 },
		reward = { gems = 80 },
		title = "💀 Boss Hunter", titleColor = Color3.fromRGB(180,40,40),
	},
	{
		id = "boss_50", name = "World Destroyer",
		desc = "Help defeat 50 World Bosses.",
		condition = { stat = "bossKills", target = 50 },
		reward = { gems = 300 },
		title = "☠ World Destroyer", titleColor = Color3.fromRGB(140,20,20),
	},

	-- ── Wealth ────────────────────────────────────────────────────────────────
	{
		id = "coins_100k", name = "Rich",
		desc = "Earn 100,000 total coins.",
		condition = { stat = "totalCoinsEarned", target = 100_000 },
		reward = { gems = 25 },
		title = "💰 Rich", titleColor = Color3.fromRGB(255,220,60),
	},
	{
		id = "coins_1M", name = "Millionaire",
		desc = "Earn 1,000,000 total coins.",
		condition = { stat = "totalCoinsEarned", target = 1_000_000 },
		reward = { gems = 100 },
		title = "💎 Millionaire", titleColor = Color3.fromRGB(100,220,255),
	},
	{
		id = "coins_10M", name = "Coin Emperor",
		desc = "Earn 10,000,000 total coins.",
		condition = { stat = "totalCoinsEarned", target = 10_000_000 },
		reward = { gems = 500 },
		title = "👑 Coin Emperor", titleColor = Color3.fromRGB(255,165,0),
	},

	-- ── Mythic collector ──────────────────────────────────────────────────────
	{
		id = "mythic_first", name = "Mythic Collector",
		desc = "Own your first Mythic pet.",
		condition = { stat = "mythicsOwned", target = 1 },
		reward = { gems = 100 },
		title = "🐉 Mythic Collector", titleColor = Color3.fromRGB(255,60,200),
	},
	{
		id = "mythic_all", name = "God of Pets",
		desc = "Own all 3 Mythic pets simultaneously.",
		condition = { stat = "allMythicsOwned", target = 1 },
		reward = { gems = 500 },
		title = "🌌 God of Pets", titleColor = Color3.fromRGB(255,30,180),
	},
}

-- Build a lookup table by id
AchievementData.ById = {}
for _, a in ipairs(AchievementData.List) do
	AchievementData.ById[a.id] = a
end

return AchievementData
