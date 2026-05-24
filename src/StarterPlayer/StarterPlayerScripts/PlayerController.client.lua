-- Applies per-player settings and reacts to server state changes on the client
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local GameState  = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameState"))
local remotes    = ReplicatedStorage:WaitForChild("Remotes")

local localPlayer = Players.LocalPlayer

-- Apply consistent character stats whenever the character spawns
local function applyCharacterStats(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = GameConfig.WALK_SPEED
	humanoid.JumpPower = GameConfig.JUMP_POWER
end

localPlayer.CharacterAdded:Connect(applyCharacterStats)
if localPlayer.Character then
	applyCharacterStats(localPlayer.Character)
end

-- React to game-state changes (e.g. hide/show UI elements)
remotes.StateChanged.OnClientEvent:Connect(function(state)
	-- UI controller listens to this too; nothing extra needed here
	-- unless you want character-level effects per state.
	if state == GameState.IN_ROUND then
		-- Example: enable sprint, abilities, etc.
	elseif state == GameState.LOBBY then
		-- Example: disable combat tools
	end
end)

-- Receive and cache the latest player data
local playerData = {}

remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
	for k, v in pairs(data) do
		playerData[k] = v
	end
end)

-- Fetch initial data from server
local ok, data = pcall(function()
	return remotes.RequestPlayerData:InvokeServer()
end)
if ok and data then
	for k, v in pairs(data) do
		playerData[k] = v
	end
end

-- Expose data for UI scripts via a shared value
local dataValue = Instance.new("StringValue")
dataValue.Name  = "PlayerDataCache"
dataValue.Value = game:GetService("HttpService"):JSONEncode(playerData)
dataValue.Parent = localPlayer
