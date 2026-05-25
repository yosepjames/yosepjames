-- Entry point: waits for Remotes, then initialises all services and starts ticks
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- Wait for RemoteSetup to finish
ReplicatedStorage:WaitForChild("Remotes")

local DataService      = require(script.Parent.Services.DataService)
local PetService       = require(script.Parent.Services.PetService)
local TerritoryService = require(script.Parent.Services.TerritoryService)
local EconomyService   = require(script.Parent.Services.EconomyService)
local GameConfig       = require(ReplicatedStorage.GameConfig)

-- Inject DataService dependency into other services
PetService.Init(DataService)
TerritoryService.Init(DataService)
EconomyService.Init(DataService)

-- Send initial state to each player when they fully load
local function onPlayerAdded(player)
	-- DataService already loaded their data via Players.PlayerAdded
	-- Wait for character then push initial values
	player.CharacterAdded:Connect(function()
		task.wait(1) -- let client scripts initialise
		local data = DataService.Get(player)
		if not data then return end

		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		remotes.CoinUpdate:FireClient(player, data.coins)
		remotes.GemUpdate:FireClient(player, data.gems)
		remotes.EquippedUpdated:FireClient(player, data.equipped)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- ── Coin tick (every COIN_TICK_INTERVAL seconds) ──────────────────────────────
task.spawn(function()
	while true do
		task.wait(GameConfig.COIN_TICK_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			PetService.TickCoins(player)
		end
	end
end)

-- ── Territory bonus tick ──────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(GameConfig.TERRITORY_TICK_INTERVAL)
		TerritoryService.BonusTick()
	end
end)

print("[MythicPets] Server initialised successfully.")
