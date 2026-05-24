-- Handles saving and loading per-player data via DataStoreService
local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local playerStore = DataStoreService:GetDataStore("PlayerData_v1")
local sessionData = {} -- [userId] = { coins = number }

local DEFAULT_DATA = {
	coins = GameConfig.STARTING_COINS,
}

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = type(v) == "table" and deepCopy(v) or v
	end
	return copy
end

local function loadData(player)
	local key = tostring(player.UserId)
	local ok, result = pcall(function()
		return playerStore:GetAsync(key)
	end)

	if ok and result then
		-- Merge saved data with defaults so new keys are always present
		local data = deepCopy(DEFAULT_DATA)
		for k, v in pairs(result) do
			data[k] = v
		end
		sessionData[player.UserId] = data
	else
		sessionData[player.UserId] = deepCopy(DEFAULT_DATA)
	end
end

local function saveData(player)
	local data = sessionData[player.UserId]
	if not data then return end

	local key = tostring(player.UserId)
	local ok, err = pcall(function()
		playerStore:SetAsync(key, data)
	end)

	if not ok then
		warn("[DataManager] Failed to save data for", player.Name, "–", err)
	end
end

-- Public API used by other server scripts
local DataManager = {}

function DataManager.GetData(player)
	return sessionData[player.UserId]
end

function DataManager.AdjustCoins(player, amount)
	local data = sessionData[player.UserId]
	if not data then return end
	data.coins = math.max(0, data.coins + amount)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes.PlayerDataUpdate:FireClient(player, { coins = data.coins })
end

-- Wire up player events
Players.PlayerAdded:Connect(function(player)
	loadData(player)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes.RequestPlayerData.OnServerInvoke = function(requestingPlayer)
		return sessionData[requestingPlayer.UserId] or deepCopy(DEFAULT_DATA)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	sessionData[player.UserId] = nil
end)

-- Save all data if the server shuts down unexpectedly
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

return DataManager
