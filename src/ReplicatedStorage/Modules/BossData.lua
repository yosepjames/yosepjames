-- World Boss definitions for server-wide events
local BossData = {}

BossData.Bosses = {
	{
		id          = "shadow_titan",
		name        = "Shadow Titan",
		description = "A colossal dark giant born from void energy.",
		baseHp      = 50_000,
		color       = Color3.fromRGB(60,  20, 100),
		glowColor   = Color3.fromRGB(160, 60, 255),
		rewardCoins = 5_000,
		rewardGems  = 10,
		luckyEggChance = 0.15,  -- 15% chance of Lucky Egg bonus per contributor
	},
	{
		id          = "crystal_golem",
		name        = "Crystal Golem",
		description = "Ancient guardian of the Crystal Caverns.",
		baseHp      = 80_000,
		color       = Color3.fromRGB(80, 180, 255),
		glowColor   = Color3.fromRGB(150, 220, 255),
		rewardCoins = 9_000,
		rewardGems  = 18,
		luckyEggChance = 0.20,
	},
	{
		id          = "inferno_dragon",
		name        = "Inferno Dragon",
		description = "The volcanic overlord of Volcano Peak.",
		baseHp      = 130_000,
		color       = Color3.fromRGB(220, 50, 20),
		glowColor   = Color3.fromRGB(255, 140, 20),
		rewardCoins = 15_000,
		rewardGems  = 30,
		luckyEggChance = 0.30,
	},
	{
		id          = "cosmic_leviathan",
		name        = "Cosmic Leviathan",
		description = "A mythic sea serpent from between galaxies.",
		baseHp      = 250_000,
		color       = Color3.fromRGB(30, 10, 80),
		glowColor   = Color3.fromRGB(255, 60, 200),
		rewardCoins = 30_000,
		rewardGems  = 60,
		luckyEggChance = 0.50,
	},
}

BossData.SPAWN_INTERVAL    = 30 * 60  -- every 30 minutes
BossData.DURATION          = 5  * 60  -- 5 minutes to defeat
BossData.HP_PER_PLAYER     = 5_000    -- extra HP added per player in server

function BossData.Random()
	return BossData.Bosses[math.random(1, #BossData.Bosses)]
end

return BossData
