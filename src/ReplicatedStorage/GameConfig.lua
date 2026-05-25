local GameConfig = {
	-- Economy
	STARTING_COINS         = 100,
	STARTING_GEMS          = 5,

	-- Pet system
	MAX_EQUIPPED_PETS      = 3,
	MAX_INVENTORY_SIZE     = 100,
	FUSION_REQUIRED        = 3,   -- 3 identical pets needed to fuse

	-- Coin generation (server tick every N seconds)
	COIN_TICK_INTERVAL     = 10,

	-- Territory
	TERRITORY_TICK_INTERVAL = 60, -- bonus coins every 60 s
	MAX_CLAN_TERRITORIES   = 2,

	-- Trading
	MAX_ACTIVE_LISTINGS    = 5,
	TRADE_TAX_PERCENT      = 5,   -- 5% marketplace fee

	-- Character
	WALK_SPEED             = 16,
	JUMP_POWER             = 50,

	-- Rarity sell-value multipliers (base × multiplier)
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
