-- Daily quest templates. Each day 3 are picked at random with a random tier.
local QuestData = {}

-- Reward types: coins, gems, luckTokens
QuestData.Templates = {
	{
		id      = "open_eggs",
		textFmt = "Open %d Eggs",
		stat    = "eggsOpened",
		tiers   = {
			{ target = 3,  reward = { coins = 500  } },
			{ target = 7,  reward = { coins = 1500, gems = 3 } },
			{ target = 15, reward = { coins = 5000, gems = 8 } },
		},
	},
	{
		id      = "fuse_pets",
		textFmt = "Fuse %d Pets",
		stat    = "fusionsDone",
		tiers   = {
			{ target = 1, reward = { coins = 400  } },
			{ target = 3, reward = { coins = 1200, gems = 5 } },
			{ target = 6, reward = { coins = 3000, gems = 12, luckTokens = 1 } },
		},
	},
	{
		id      = "earn_coins",
		textFmt = "Earn %d coins from pets",
		stat    = "coinsFromPets",
		tiers   = {
			{ target = 500,   reward = { coins = 300  } },
			{ target = 3000,  reward = { coins = 2000 } },
			{ target = 15000, reward = { coins = 8000, gems = 5 } },
		},
	},
	{
		id      = "capture_territory",
		textFmt = "Capture %d territories",
		stat    = "territoriesCaptured",
		tiers   = {
			{ target = 1, reward = { coins = 800 } },
			{ target = 2, reward = { coins = 2500, gems = 3 } },
			{ target = 3, reward = { coins = 6000, gems = 10, luckTokens = 1 } },
		},
	},
	{
		id      = "sell_pets",
		textFmt = "Sell %d pets",
		stat    = "petsSold",
		tiers   = {
			{ target = 3,  reward = { coins = 600  } },
			{ target = 8,  reward = { coins = 2000 } },
			{ target = 20, reward = { coins = 6000, gems = 6 } },
		},
	},
	{
		id      = "trade_items",
		textFmt = "Buy %d items from Trading Post",
		stat    = "tradeBuys",
		tiers   = {
			{ target = 1, reward = { coins = 500, gems = 2 } },
			{ target = 3, reward = { coins = 2000, gems = 6 } },
			{ target = 5, reward = { coins = 5000, gems = 15, luckTokens = 1 } },
		},
	},
	{
		id      = "defeat_bosses",
		textFmt = "Defeat %d World Boss(es)",
		stat    = "bossKills",
		tiers   = {
			{ target = 1, reward = { coins = 1000, gems = 5 } },
			{ target = 3, reward = { coins = 4000, gems = 15 } },
			{ target = 5, reward = { coins = 10000, gems = 30, luckTokens = 2 } },
		},
	},
}

QuestData.DAILY_COUNT  = 3    -- quests per day
QuestData.RESET_HOUR   = 0    -- UTC hour daily quests reset (midnight)

return QuestData
