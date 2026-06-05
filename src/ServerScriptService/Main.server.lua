local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

ReplicatedStorage:WaitForChild("Remotes")

-- Load all services
local DataService        = require(script.Parent.Services.DataService)
local GamepassService    = require(script.Parent.Services.GamepassService)
local AchievementService = require(script.Parent.Services.AchievementService)
local RebirthService     = require(script.Parent.Services.RebirthService)
local QuestService       = require(script.Parent.Services.QuestService)
local DailySpinService   = require(script.Parent.Services.DailySpinService)
local PetService         = require(script.Parent.Services.PetService)
local TerritoryService   = require(script.Parent.Services.TerritoryService)
local EconomyService     = require(script.Parent.Services.EconomyService)
local BossService        = require(script.Parent.Services.BossService)
local LeaderboardService = require(script.Parent.Services.LeaderboardService)

local GameConfig = require(ReplicatedStorage.GameConfig)
local remotes    = ReplicatedStorage:WaitForChild("Remotes")

-- Initialise with full dependency injection (order matters)
GamepassService.Init(DataService)
AchievementService.Init(DataService)
RebirthService.Init(DataService)
QuestService.Init(DataService)
DailySpinService.Init(DataService)
PetService.Init(DataService, DailySpinService, QuestService, RebirthService, AchievementService, GamepassService)
TerritoryService.Init(DataService, QuestService, AchievementService)
EconomyService.Init(DataService, QuestService, AchievementService)
BossService.Init(DataService, AchievementService)
LeaderboardService.Init(DataService)

-- ── First-join welcome: give new players a free Basic Egg ─────────────────────
local function welcomeNewPlayer(player)
	task.wait(4)  -- wait for character and data to fully load
	local data = DataService.Get(player)
	if not data then return end

	-- Detect first-ever join (no eggs opened and no pets)
	if data.stats.eggsOpened == 0 and #data.pets == 0 then
		-- Give a free egg via the same mechanism (bypass cost)
		local EggData = require(ReplicatedStorage.Modules.EggData)
		local HttpService = game:GetService("HttpService")
		local PetData     = require(ReplicatedStorage.Modules.PetData)

		local petId = EggData.Roll("basic_egg")
		if petId then
			local entry = { uid = HttpService:GenerateGUID(false), petId = petId, level = 1, xp = 0, shiny = false }
			DataService.AddPet(player, entry)
			data.stats.eggsOpened += 1

			remotes.PetAdded:FireClient(player, entry)

			local petInfo = PetData.GetPet(petId)
			remotes.Notification:FireClient(player, {
				text  = "🎉 Welcome! You got a free " .. (petInfo and petInfo.name or petId) .. "!",
				color = Color3.fromRGB(100, 255, 100),
			})
		end
	end
end

-- ── Push initial state on character spawn ─────────────────────────────────────
local function onPlayerAdded(player)
	task.spawn(welcomeNewPlayer, player)

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
		if data.currentTitle then
			remotes.PlayerTitleUpdate:FireAllClients({
				userId     = player.UserId,
				playerName = player.Name,
				title      = data.currentTitle,
				titleColor = data.currentTitleColor,
			})
		end
		-- Pass benefit info to client
		remotes.PassBenefitsUpdate:FireClient(player, GamepassService.GetBenefits(player))
	end)
end

for _, player in ipairs(Players:GetPlayers()) do onPlayerAdded(player) end
Players.PlayerAdded:Connect(onPlayerAdded)

-- ── Coin generation tick ──────────────────────────────────────────────────────
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

print("[MythicPets] ✅ All systems online.")
