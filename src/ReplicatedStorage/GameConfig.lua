local GameConfig = {
	-- Economy
	STARTING_COINS         = 100,
	STARTING_GEMS          = 5,

	-- Pet system
	MAX_EQUIPPED_PETS      = 3,
	MAX_INVENTORY_SIZE     = 100,
	FUSION_REQUIRED        = 3,

	-- Shiny pets (trending: rare jackpot variant)
	SHINY_BASE_CHANCE      = 1,    -- 1 in 100 base
	SHINY_LUCK_CHANCE      = 5,    -- 1 in 20 when luck token active
	SHINY_COIN_MULTIPLIER  = 3,    -- shiny pets earn 3× coins

	-- Coin generation
	COIN_TICK_INTERVAL     = 10,

	-- Rebirth / Prestige
	REBIRTH_BASE_COST      = 50_000,   -- coins needed for first rebirth
	REBIRTH_COST_SCALE     = 1.8,      -- cost × 1.8 per rebirth level
	REBIRTH_COIN_BONUS     = 0.25,     -- +25% coin rate per rebirth level

	-- Daily Spin
	DAILY_SPIN_COOLDOWN    = 86_400,   -- 24 hours in seconds

	-- Lucky Token
	LUCK_TOKEN_DURATION    = 300,      -- 5 minutes of boosted shiny chance

	-- Territory
	TERRITORY_TICK_INTERVAL = 60,

	-- World Boss
	BOSS_DAMAGE_TICK       = 2,        -- seconds between auto-damage ticks when attacking

	-- Trading
	MAX_ACTIVE_LISTINGS    = 5,
	TRADE_TAX_PERCENT      = 5,

	-- Character
	WALK_SPEED             = 16,
	JUMP_POWER             = 50,

	RARITY_SELL_VALUES = {
		Common    = 25,
		Uncommon  = 100,
		Rare      = 400,
		Epic      = 1_500,
		Legendary = 6_000,
		Mythic    = 25_000,
	},

	RARITY_ORDER = {
		Common    = 1,
		Uncommon  = 2,
		Rare      = 3,
		Epic      = 4,
		Legendary = 5,
		Mythic    = 6,
	},
}

return GameConfig
