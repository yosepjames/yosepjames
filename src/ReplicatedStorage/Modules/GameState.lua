-- Shared game state enum, safe to require from both sides
local GameState = {
	LOBBY        = "Lobby",
	STARTING     = "Starting",
	IN_ROUND     = "InRound",
	INTERMISSION = "Intermission",
}

return GameState
