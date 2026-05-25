-- Handles DataStore persistence and in-memory session data
local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local store        = DataStoreService:GetDataStore("MythicPets_v1")
local sessionData  = {}  -- [userId] = data

local DEFAULT = {
	coins    = GameConfig.STARTING_COINS,
	gems     = GameConfig.STARTING_GEMS,
	pets     = {},   -- array of { uid, petId, level, xp }
	equipped = {},   -- array of uids (max 3)
	stats    = { eggsOpened = 0, fusionsDone = 0, petsOwned = 0 },
}

local function deepCopy(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = type(v) == "table" and deepCopy(v) or v
	end
	return c
end

local function mergeDefaults(data)
	for k, v in pairs(DEFAULT) do
		if data[k] == nil then
			data[k] = type(v) == "table" and deepCopy(v) or v
		end
	end
	return data
end

local DataService = {}

function DataService.Load(player)
	local key = tostring(player.UserId)
	local ok, result = pcall(function() return store:GetAsync(key) end)
	if ok and type(result) == "table" then
		sessionData[player.UserId] = mergeDefaults(result)
	else
		if not ok then warn("[DataService] Load error:", result) end
		sessionData[player.UserId] = deepCopy(DEFAULT)
	end
end

function DataService.Save(player)
	local data = sessionData[player.UserId]
	if not data then return end
	local key = tostring(player.UserId)
	local ok, err = pcall(function() store:SetAsync(key, data) end)
	if not ok then warn("[DataService] Save error:", err) end
end

function DataService.Get(player)
	return sessionData[player.UserId]
end

function DataService.AdjustCoins(player, amount)
	local data = sessionData[player.UserId]
	if not data then return end
	data.coins = math.max(0, data.coins + amount)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes.CoinUpdate:FireClient(player, data.coins)
end

function DataService.AdjustGems(player, amount)
	local data = sessionData[player.UserId]
	if not data then return end
	data.gems = math.max(0, data.gems + amount)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes.GemUpdate:FireClient(player, data.gems)
end

function DataService.AddPet(player, petEntry)
	local data = sessionData[player.UserId]
	if not data then return end
	if #data.pets >= GameConfig.MAX_INVENTORY_SIZE then return false end
	table.insert(data.pets, petEntry)
	data.stats.petsOwned += 1
	return true
end

function DataService.RemovePet(player, uid)
	local data = sessionData[player.UserId]
	if not data then return false end
	for i, entry in ipairs(data.pets) do
		if entry.uid == uid then
			table.remove(data.pets, i)
			-- also unequip if equipped
			for j, eu in ipairs(data.equipped) do
				if eu == uid then table.remove(data.equipped, j) break end
			end
			return true
		end
	end
	return false
end

function DataService.FindPet(player, uid)
	local data = sessionData[player.UserId]
	if not data then return nil end
	for _, entry in ipairs(data.pets) do
		if entry.uid == uid then return entry end
	end
	return nil
end

-- Wire lifecycle
Players.PlayerAdded:Connect(function(player)
	DataService.Load(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.Save(player)
	sessionData[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.Save(player)
	end
end)

return DataService
