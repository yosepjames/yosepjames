-- Shared configuration read by both server and client
local GameConfig = {
	LOBBY_DURATION    = 15,  -- seconds in lobby before round starts
	ROUND_DURATION    = 120, -- seconds per round
	INTERMISSION      = 10,  -- seconds between rounds
	MIN_PLAYERS       = 2,   -- minimum players to start a round
	MAX_PLAYERS       = 10,

	STARTING_COINS    = 0,
	COINS_PER_KILL    = 10,
	COINS_FOR_WIN     = 50,

	RESPAWN_TIME      = 5,   -- seconds before player respawns during lobby
	WALK_SPEED        = 16,
	JUMP_POWER        = 50,
}

return GameConfig
