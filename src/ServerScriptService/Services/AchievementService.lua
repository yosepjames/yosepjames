-- Checks player stats against achievement conditions and awards unlocked ones
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AchievementData"))
local PetData         = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))

local remotes    = ReplicatedStorage:WaitForChild("Remotes")
local DataService -- injected

local AchievementService = {}

local MYTHIC_IDS = { "emperor_cosmic", "sovereign_void", "dragon_mythic" }

local function countMythicsOwned(pets)
	local owned = {}
	for _, entry in ipairs(pets) do
		local pet = PetData.GetPet(entry.petId)
		if pet and pet.rarity == "Mythic" then
			owned[entry.petId] = true
		end
	end
	return owned
end

local function getStatValue(data, stat)
	if stat == "rebirth" then
		return data.rebirth or 0
	elseif stat == "mythicsOwned" then
		local owned = countMythicsOwned(data.pets)
		local n = 0
		for _ in pairs(owned) do n += 1 end
		return n
	elseif stat == "allMythicsOwned" then
		local owned = countMythicsOwned(data.pets)
		for _, id in ipairs(MYTHIC_IDS) do
			if not owned[id] then return 0 end
		end
		return 1
	else
		return data.stats[stat] or 0
	end
end

-- Check and award all newly unlocked achievements for a player
function AchievementService.Check(player)
	local data = DataService.Get(player)
	if not data then return end

	data.achievements = data.achievements or {}
	local newUnlocks  = {}

	for _, achievement in ipairs(AchievementData.List) do
		if not data.achievements[achievement.id] then
			local val = getStatValue(data, achievement.condition.stat)
			if val >= achievement.condition.target then
				data.achievements[achievement.id] = true
				table.insert(newUnlocks, achievement)

				-- Grant reward
				if achievement.reward.gems then
					DataService.AdjustGems(player, achievement.reward.gems)
				end
				if achievement.reward.coins then
					DataService.AdjustCoins(player, achievement.reward.coins)
				end

				-- Award title (store last unlocked title)
				if achievement.title then
					data.currentTitle      = achievement.title
					data.currentTitleColor = achievement.titleColor
				end
			end
		end
	end

	if #newUnlocks > 0 then
		remotes.AchievementsUnlocked:FireClient(player, newUnlocks)

		-- Broadcast title change to all players so they see it above head
		if newUnlocks[#newUnlocks].title then
			remotes.PlayerTitleUpdate:FireAllClients({
				userId     = player.UserId,
				playerName = player.Name,
				title      = data.currentTitle,
				titleColor = data.currentTitleColor,
			})
		end
	end
end

-- Called when a player joins (restore their title)
local function restoreTitle(player)
	task.wait(3)
	local data = DataService.Get(player)
	if not data or not data.currentTitle then return end
	remotes.PlayerTitleUpdate:FireAllClients({
		userId     = player.UserId,
		playerName = player.Name,
		title      = data.currentTitle,
		titleColor = data.currentTitleColor,
	})
end

function AchievementService.Init(ds)
	DataService = ds

	remotes.GetAchievements.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		return {
			unlocked = data and data.achievements or {},
			all      = AchievementData.List,
		}
	end

	Players.PlayerAdded:Connect(restoreTitle)
	Players.PlayerRemoving:Connect(function(player)
		-- Clear title for other clients
		remotes.PlayerTitleUpdate:FireAllClients({
			userId = player.UserId, title = nil,
		})
	end)
end

return AchievementService
