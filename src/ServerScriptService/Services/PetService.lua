-- Egg opening (with shiny rolls), fusion, equip, sell
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PetData    = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local EggData    = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EggData"))

local remotes    = ReplicatedStorage:WaitForChild("Remotes")
local DataService        -- injected
local DailySpinService   -- injected
local QuestService       -- injected
local RebirthService     -- injected
local AchievementService -- injected
local GamepassService    -- injected

local PetService = {}

local function newUID()
	return HttpService:GenerateGUID(false)
end

local function makeEntry(petId, shiny)
	return { uid = newUID(), petId = petId, level = 1, xp = 0, shiny = shiny or false }
end

local function notify(player, text, color)
	remotes.Notification:FireClient(player, { text = text, color = color or Color3.new(1,1,1) })
end

local function rollShiny(player)
	local chance = GameConfig.SHINY_BASE_CHANCE
	if DailySpinService and DailySpinService.HasActiveLuck(player) then
		chance = GameConfig.SHINY_LUCK_CHANCE
	end
	-- Gamepass: permanent 2× luck
	if GamepassService and GamepassService.HasLuckBoost(player) then
		chance = chance * 2
	end
	return math.random(1, 100) <= math.min(chance, 100)
end

-- XP needed to reach level N+1 (lvl 1→2 = 100, 2→3 = 283, ...)
local function xpForLevel(level)
	return math.floor(100 * (level ^ 1.5))
end

local function tryLevelUp(entry, petInfo)
	if entry.level >= 10 then return false end
	local needed = xpForLevel(entry.level)
	if entry.xp >= needed then
		entry.xp    = entry.xp - needed
		entry.level = entry.level + 1
		return true
	end
	return false
end

-- ── Egg Opening ───────────────────────────────────────────────────────────────

local function handleOpenEgg(player, eggId)
	local egg = EggData.Eggs[eggId]
	if not egg then return false end

	local data = DataService.Get(player)
	if not data then return false end

	if egg.costType == "coins" then
		if data.coins < egg.cost then
			notify(player, "Not enough coins!", Color3.fromRGB(255,80,80))
			return false
		end
		DataService.AdjustCoins(player, -egg.cost)
	elseif egg.costType == "gems" then
		if data.gems < egg.cost then
			notify(player, "Not enough gems!", Color3.fromRGB(255,80,80))
			return false
		end
		DataService.AdjustGems(player, -egg.cost)
	end

	local petId = EggData.Roll(eggId)
	if not petId then return false end

	local shiny = rollShiny(player)
	local entry = makeEntry(petId, shiny)

	local added = DataService.AddPet(player, entry)
	if not added then
		notify(player, "Inventory full! Sell some pets first.", Color3.fromRGB(255,160,0))
		if egg.costType == "coins" then DataService.AdjustCoins(player, egg.cost)
		else DataService.AdjustGems(player, egg.cost) end
		return false
	end

	data.stats.eggsOpened += 1
	if shiny then
		data.stats.shiniesFound = (data.stats.shiniesFound or 0) + 1
	end
	local petInfo = PetData.GetPet(petId)
	if petInfo and petInfo.rarity == "Mythic" then
		data.stats.mythicsOwned = (data.stats.mythicsOwned or 0) + 1
	end
	data.stats.totalCoinsEarned = data.stats.totalCoinsEarned or 0

	if QuestService       then QuestService.Advance(player, "eggsOpened", 1) end
	if AchievementService then AchievementService.Check(player) end
	local prefix  = shiny and "✨ SHINY " or ""
	notify(player,
		"You got a " .. prefix .. petInfo.rarity .. " " .. petInfo.name .. "!" .. (shiny and " (3× coins!)" or ""),
		shiny and Color3.fromRGB(255, 215, 0) or PetData.GetRarityColor(petInfo.rarity))

	remotes.PetAdded:FireClient(player, entry)
	return entry
end

-- ── Fusion ────────────────────────────────────────────────────────────────────

local function handleFusePets(player, uid1, uid2, uid3)
	local data = DataService.Get(player)
	if not data then return false end

	local uids    = { uid1, uid2, uid3 }
	local entries = {}
	for _, uid in ipairs(uids) do
		local e = DataService.FindPet(player, uid)
		if not e then notify(player, "Pet not found.", Color3.fromRGB(255,80,80)) return false end
		table.insert(entries, e)
	end

	local basePetId = entries[1].petId
	for _, e in ipairs(entries) do
		if e.petId ~= basePetId then
			notify(player, "All 3 pets must be the same type!", Color3.fromRGB(255,80,80))
			return false
		end
	end

	local basePet = PetData.GetPet(basePetId)
	if not basePet or not basePet.fusionResult then
		notify(player, "This pet can't fuse further.", Color3.fromRGB(255,160,0))
		return false
	end

	-- Shiny: if any input is shiny, result has 50% chance of being shiny
	local anyShiny = false
	for _, e in ipairs(entries) do if e.shiny then anyShiny = true break end end
	local resultShiny = anyShiny and math.random(1,2) == 1

	for _, uid in ipairs(uids) do
		DataService.RemovePet(player, uid)
		remotes.PetRemoved:FireClient(player, uid)
	end

	local resultId    = basePet.fusionResult
	local resultPet   = PetData.GetPet(resultId)
	local resultEntry = makeEntry(resultId, resultShiny)

	DataService.AddPet(player, resultEntry)
	data.stats.fusionsDone += 1
	if QuestService       then QuestService.Advance(player, "fusionsDone", 1) end
	if AchievementService then AchievementService.Check(player) end

	local prefix = resultShiny and "✨ SHINY " or ""
	notify(player,
		"Fusion! You got a " .. prefix .. resultPet.rarity .. " " .. resultPet.name .. "!",
		resultShiny and Color3.fromRGB(255,215,0) or PetData.GetRarityColor(resultPet.rarity))

	remotes.PetAdded:FireClient(player, resultEntry)
	remotes.EquippedUpdated:FireClient(player, data.equipped)
	return resultEntry
end

-- ── Sell ─────────────────────────────────────────────────────────────────────

local function handleSellPet(player, uid)
	local entry = DataService.FindPet(player, uid)
	if not entry then return end

	local petInfo = PetData.GetPet(entry.petId)
	local value   = GameConfig.RARITY_SELL_VALUES[petInfo.rarity] or 25
	if entry.shiny then value = value * 5 end  -- shiny sells for 5× base

	DataService.RemovePet(player, uid)
	DataService.AdjustCoins(player, value)

	local data = DataService.Get(player)
	if data then
		data.stats.petsSold += 1
		if QuestService then QuestService.Advance(player, "petsSold", 1) end
	end

	remotes.PetRemoved:FireClient(player, uid)
	remotes.EquippedUpdated:FireClient(player, data and data.equipped or {})
	notify(player, "Sold " .. (entry.shiny and "✨ " or "") .. petInfo.name .. " for " .. value .. " coins!")
end

-- ── Equip / Unequip ──────────────────────────────────────────────────────────

local function handleEquipPet(player, uid)
	local data  = DataService.Get(player)
	local entry = DataService.FindPet(player, uid)
	if not entry or not data then return end
	for _, eu in ipairs(data.equipped) do if eu == uid then return end end
	if #data.equipped >= GameConfig.MAX_EQUIPPED_PETS then
		notify(player, "Equip slot full!", Color3.fromRGB(255,160,0))
		return
	end
	table.insert(data.equipped, uid)
	remotes.EquippedUpdated:FireClient(player, data.equipped)
end

local function handleUnequipPet(player, uid)
	local data = DataService.Get(player)
	if not data then return end
	for i, eu in ipairs(data.equipped) do
		if eu == uid then
			table.remove(data.equipped, i)
			remotes.EquippedUpdated:FireClient(player, data.equipped)
			return
		end
	end
end

-- ── Coin tick with rebirth multiplier ────────────────────────────────────────

function PetService.TickCoins(player)
	local data = DataService.Get(player)
	if not data or #data.equipped == 0 then return end

	local totalPerMin = 0
	for _, uid in ipairs(data.equipped) do
		for _, entry in ipairs(data.pets) do
			if entry.uid == uid then
				local pet = PetData.GetPet(entry.petId)
				if pet then
					local base = pet.coinPerMin * entry.level
					if entry.shiny then base = base * GameConfig.SHINY_COIN_MULTIPLIER end
					totalPerMin += base
				end
				break
			end
		end
	end

	local raw = math.floor(totalPerMin * GameConfig.COIN_TICK_INTERVAL / 60)
	local final = RebirthService and RebirthService.ApplyMultiplier(player, raw) or raw

	if final > 0 then
		DataService.AdjustCoins(player, final)
		data.stats.coinsFromPets    = (data.stats.coinsFromPets or 0) + final
		data.stats.totalCoinsEarned = (data.stats.totalCoinsEarned or 0) + final
		if QuestService       then QuestService.Advance(player, "coinsFromPets", final) end
		if AchievementService then AchievementService.Check(player) end
	end

	-- Pet XP gain: each equipped pet gains XP equal to coinPerMin per tick
	local xpMult = (GamepassService and GamepassService.HasVIP(player)) and 2 or 1
	local leveledUp = false
	for _, uid in ipairs(data.equipped) do
		for _, entry in ipairs(data.pets) do
			if entry.uid == uid and entry.level < 10 then
				local pet   = PetData.GetPet(entry.petId)
				if pet then
					entry.xp = (entry.xp or 0) + math.floor(pet.coinPerMin * xpMult)
					if tryLevelUp(entry, pet) then
						leveledUp = true
						remotes.Notification:FireClient(player, {
							text  = entry.shiny and "✨ " .. pet.name or pet.name
								.. " reached level " .. entry.level .. "!",
							color = PetData.GetRarityColor(pet.rarity),
						})
					end
				end
				break
			end
		end
	end
	if leveledUp then
		remotes.GetInventory.OnServerInvoke(player)  -- clients re-fetch inventory
	end
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function PetService.Init(ds, dss, qs, rs, as, gps)
	DataService        = ds
	DailySpinService   = dss
	QuestService       = qs
	RebirthService     = rs
	AchievementService = as
	GamepassService    = gps

	remotes.OpenEgg.OnServerInvoke      = handleOpenEgg
	remotes.FusePets.OnServerInvoke     = handleFusePets
	remotes.SellPet.OnServerEvent:Connect(handleSellPet)
	remotes.EquipPet.OnServerEvent:Connect(handleEquipPet)
	remotes.UnequipPet.OnServerEvent:Connect(handleUnequipPet)

	remotes.GetInventory.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		return data and data.pets or {}
	end

	remotes.GetPlayerData.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then return {} end
		return {
			coins       = data.coins,
			gems        = data.gems,
			stats       = data.stats,
			equipped    = data.equipped,
			luckTokens  = data.luckTokens or 0,
			rebirth     = data.rebirth or 0,
		}
	end
end

return PetService
