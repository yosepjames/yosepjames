-- Handles egg opening, pet fusion, equipping, and selling
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PetData       = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local EggData       = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EggData"))

local DataService   -- injected on init to avoid circular require

local remotes       = ReplicatedStorage:WaitForChild("Remotes")

local PetService = {}

local function newUID()
	return HttpService:GenerateGUID(false)
end

local function makeEntry(petId)
	return { uid = newUID(), petId = petId, level = 1, xp = 0 }
end

local function notify(player, text, color)
	remotes.Notification:FireClient(player, {
		text  = text,
		color = color or Color3.new(1, 1, 1),
	})
end

-- ── Egg Opening ───────────────────────────────────────────────────────────────

local function handleOpenEgg(player, eggId)
	local egg = EggData.Eggs[eggId]
	if not egg then return false end

	local data = DataService.Get(player)
	if not data then return false end

	-- Deduct cost
	if egg.costType == "coins" then
		if data.coins < egg.cost then
			notify(player, "Not enough coins!", Color3.fromRGB(255, 80, 80))
			return false
		end
		DataService.AdjustCoins(player, -egg.cost)
	elseif egg.costType == "gems" then
		if data.gems < egg.cost then
			notify(player, "Not enough gems!", Color3.fromRGB(255, 80, 80))
			return false
		end
		DataService.AdjustGems(player, -egg.cost)
	end

	-- Roll for pet
	local petId = EggData.Roll(eggId)
	if not petId then return false end

	local petInfo = PetData.GetPet(petId)
	local entry   = makeEntry(petId)

	local added = DataService.AddPet(player, entry)
	if not added then
		notify(player, "Inventory full! Sell some pets first.", Color3.fromRGB(255, 160, 0))
		-- Refund
		if egg.costType == "coins" then DataService.AdjustCoins(player, egg.cost)
		else DataService.AdjustGems(player, egg.cost) end
		return false
	end

	data.stats.eggsOpened += 1

	remotes.PetAdded:FireClient(player, entry)
	notify(player,
		"You got a " .. petInfo.rarity .. " " .. petInfo.name .. "!",
		PetData.GetRarityColor(petInfo.rarity))

	return entry
end

-- ── Fusion ────────────────────────────────────────────────────────────────────

local function handleFusePets(player, uid1, uid2, uid3)
	local data = DataService.Get(player)
	if not data then return false end

	local uids = { uid1, uid2, uid3 }
	local entries = {}
	for _, uid in ipairs(uids) do
		local e = DataService.FindPet(player, uid)
		if not e then
			notify(player, "One or more pets not found.", Color3.fromRGB(255, 80, 80))
			return false
		end
		table.insert(entries, e)
	end

	-- All three must share the same petId
	local basePetId = entries[1].petId
	for _, e in ipairs(entries) do
		if e.petId ~= basePetId then
			notify(player, "All three pets must be the same type!", Color3.fromRGB(255, 80, 80))
			return false
		end
	end

	local basePet = PetData.GetPet(basePetId)
	if not basePet or not basePet.fusionResult then
		notify(player, "This pet cannot be fused further.", Color3.fromRGB(255, 160, 0))
		return false
	end

	-- Remove the three pets
	for _, uid in ipairs(uids) do
		DataService.RemovePet(player, uid)
		remotes.PetRemoved:FireClient(player, uid)
	end

	-- Create result pet
	local resultId    = basePet.fusionResult
	local resultPet   = PetData.GetPet(resultId)
	local resultEntry = makeEntry(resultId)

	DataService.AddPet(player, resultEntry)
	data.stats.fusionsDone += 1

	remotes.PetAdded:FireClient(player, resultEntry)
	notify(player,
		"Fusion success! You got a " .. resultPet.rarity .. " " .. resultPet.name .. "!",
		PetData.GetRarityColor(resultPet.rarity))

	-- Refresh equipped list (removed pets might have been equipped)
	remotes.EquippedUpdated:FireClient(player, data.equipped)

	return resultEntry
end

-- ── Sell ──────────────────────────────────────────────────────────────────────

local function handleSellPet(player, uid)
	local entry = DataService.FindPet(player, uid)
	if not entry then return end

	local petInfo = PetData.GetPet(entry.petId)
	local value   = GameConfig.RARITY_SELL_VALUES[petInfo.rarity] or 25

	DataService.RemovePet(player, uid)
	DataService.AdjustCoins(player, value)

	remotes.PetRemoved:FireClient(player, uid)
	local data = DataService.Get(player)
	remotes.EquippedUpdated:FireClient(player, data.equipped)
	notify(player, "Sold " .. petInfo.name .. " for " .. value .. " coins!")
end

-- ── Equip / Unequip ───────────────────────────────────────────────────────────

local function handleEquipPet(player, uid)
	local data  = DataService.Get(player)
	local entry = DataService.FindPet(player, uid)
	if not entry or not data then return end

	-- Already equipped?
	for _, eu in ipairs(data.equipped) do
		if eu == uid then return end
	end

	if #data.equipped >= GameConfig.MAX_EQUIPPED_PETS then
		notify(player, "Equip slot full! Unequip a pet first.", Color3.fromRGB(255, 160, 0))
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

-- ── Coin tick: equipped pets generate coins ───────────────────────────────────

function PetService.TickCoins(player)
	local data = DataService.Get(player)
	if not data or #data.equipped == 0 then return end

	local totalPerMin = 0
	for _, uid in ipairs(data.equipped) do
		local entry = DataService.FindPet(player, uid)
		if entry then
			local pet = PetData.GetPet(entry.petId)
			if pet then
				totalPerMin += pet.coinPerMin * entry.level
			end
		end
	end

	-- Scale by tick interval (COIN_TICK_INTERVAL seconds out of 60)
	local GameCfg = require(ReplicatedStorage.GameConfig)
	local coinsThisTick = math.floor(totalPerMin * GameCfg.COIN_TICK_INTERVAL / 60)
	if coinsThisTick > 0 then
		DataService.AdjustCoins(player, coinsThisTick)
	end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function PetService.Init(ds)
	DataService = ds

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
		return { coins = data.coins, gems = data.gems, stats = data.stats, equipped = data.equipped }
	end
end

return PetService
