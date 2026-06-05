local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

ReplicatedStorage:WaitForChild("Remotes")

local DataService      = require(script.Parent.Services.DataService)
local PetService       = require(script.Parent.Services.PetService)
local TerritoryService = require(script.Parent.Services.TerritoryService)
local EconomyService   = require(script.Parent.Services.EconomyService)
local RebirthService   = require(script.Parent.Services.RebirthService)
local QuestService     = require(script.Parent.Services.QuestService)
local BossService      = require(script.Parent.Services.BossService)
local DailySpinService = require(script.Parent.Services.DailySpinService)

local GameConfig = require(ReplicatedStorage.GameConfig)

-- Initialise with dependency injection
PetService.Init(DataService, DailySpinService, QuestService, RebirthService)
TerritoryService.Init(DataService, QuestService)
EconomyService.Init(DataService, QuestService)
RebirthService.Init(DataService)
QuestService.Init(DataService)
BossService.Init(DataService, QuestService)
DailySpinService.Init(DataService)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Push initial state to each player
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(1.5)
		local data = DataService.Get(player)
		if not data then return end
		remotes.CoinUpdate:FireClient(player, data.coins)
		remotes.GemUpdate:FireClient(player, data.gems)
		remotes.EquippedUpdated:FireClient(player, data.equipped)
		remotes.LuckTokenUpdate:FireClient(player, data.luckTokens or 0)
		remotes.RebirthUpdate:FireClient(player, {
			rebirth    = data.rebirth or 0,
			multiplier = data.rebirthMultiplier or 1,
			nextCost   = RebirthService.GetCost(player),
		})
		if (data.activeLuckUntil or 0) > os.time() then
			remotes.LuckAuraUpdate:FireClient(player, { active = true, expiresAt = data.activeLuckUntil })
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do onPlayerAdded(player) end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Coin tick
task.spawn(function()
	while true do
		task.wait(GameConfig.COIN_TICK_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			PetService.TickCoins(player)
		end
	end
end)

-- Territory bonus tick
task.spawn(function()
	while true do
		task.wait(GameConfig.TERRITORY_TICK_INTERVAL)
		TerritoryService.BonusTick()
	end
end)

print("[MythicPets] Server fully initialised.")
