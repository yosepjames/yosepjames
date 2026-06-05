-- Trading Post: players list pets for coins, others can browse and buy
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PetData    = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))

local remotes    = ReplicatedStorage:WaitForChild("Remotes")

local DataService  -- injected
local QuestService -- injected

-- listings[listingId] = { id, sellerId, uid, petId, petEntry, price, sellerName }
local listings = {}

local EconomyService = {}

local function broadcast()
	remotes.ListingUpdated:FireAllClients(listings)
end

local function notify(player, text, color)
	remotes.Notification:FireClient(player, { text = text, color = color or Color3.new(1,1,1) })
end

local function countListings(userId)
	local n = 0
	for _, l in pairs(listings) do
		if l.sellerId == userId then n += 1 end
	end
	return n
end

-- ── Create listing ────────────────────────────────────────────────────────────

local function handleCreateListing(player, payload)
	if type(payload) ~= "table" then return end
	local uid   = payload.uid
	local price = tonumber(payload.price)
	if not uid or not price or price < 1 then return end
	price = math.floor(price)

	if countListings(player.UserId) >= GameConfig.MAX_ACTIVE_LISTINGS then
		notify(player, "Max " .. GameConfig.MAX_ACTIVE_LISTINGS .. " active listings!", Color3.fromRGB(255,160,0))
		return
	end

	local entry = DataService.FindPet(player, uid)
	if not entry then
		notify(player, "Pet not found in your inventory.", Color3.fromRGB(255,80,80))
		return
	end

	-- Remove from inventory while listed
	DataService.RemovePet(player, uid)
	remotes.PetRemoved:FireClient(player, uid)

	local id = HttpService:GenerateGUID(false)
	listings[id] = {
		id         = id,
		sellerId   = player.UserId,
		sellerName = player.Name,
		uid        = uid,
		petId      = entry.petId,
		petEntry   = entry,
		price      = price,
	}

	notify(player, "Listed " .. (PetData.GetPet(entry.petId) or {}).name .. " for " .. price .. " coins!")
	broadcast()
end

-- ── Cancel listing ────────────────────────────────────────────────────────────

local function handleCancelListing(player, listingId)
	local l = listings[listingId]
	if not l or l.sellerId ~= player.UserId then return end

	listings[listingId] = nil
	-- Return pet to seller
	DataService.AddPet(player, l.petEntry)
	remotes.PetAdded:FireClient(player, l.petEntry)
	notify(player, "Listing cancelled.")
	broadcast()
end

-- ── Buy listing ───────────────────────────────────────────────────────────────

local function handleBuyListing(player, listingId)
	local l = listings[listingId]
	if not l then
		notify(player, "Listing no longer available.", Color3.fromRGB(255,80,80))
		return
	end
	if l.sellerId == player.UserId then
		notify(player, "You can't buy your own listing.", Color3.fromRGB(255,160,0))
		return
	end

	local data = DataService.Get(player)
	if not data or data.coins < l.price then
		notify(player, "Not enough coins!", Color3.fromRGB(255,80,80))
		return
	end

	local tax     = math.floor(l.price * GameConfig.TRADE_TAX_PERCENT / 100)
	local payout  = l.price - tax

	-- Deduct from buyer
	DataService.AdjustCoins(player, -l.price)

	-- Pay seller (if still in game)
	local seller = Players:GetPlayerByUserId(l.sellerId)
	if seller then
		DataService.AdjustCoins(seller, payout)
		notify(seller, player.Name .. " bought your " .. (PetData.GetPet(l.petId) or {}).name .. " for " .. payout .. " coins!")
	end
	-- If seller offline, coins are just earned when they next login — omitted for simplicity

	-- Transfer pet to buyer
	listings[listingId] = nil
	local petInfo = PetData.GetPet(l.petId)
	DataService.AddPet(player, l.petEntry)
	remotes.PetAdded:FireClient(player, l.petEntry)
	notify(player, "You bought " .. (petInfo and petInfo.name or l.petId) .. " for " .. l.price .. " coins!")

	local buyerData = DataService.Get(player)
	if buyerData then buyerData.stats.tradeBuys += 1 end
	if QuestService then QuestService.Advance(player, "tradeBuys", 1) end

	broadcast()
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function EconomyService.Init(ds, qs)
	DataService  = ds
	QuestService = qs

	remotes.GetListings.OnServerInvoke = function()
		return listings
	end

	remotes.CreateListing.OnServerEvent:Connect(handleCreateListing)
	remotes.CancelListing.OnServerEvent:Connect(handleCancelListing)
	remotes.BuyListing.OnServerEvent:Connect(handleBuyListing)

	-- Return listed pets on seller disconnect
	Players.PlayerRemoving:Connect(function(player)
		for id, l in pairs(listings) do
			if l.sellerId == player.UserId then
				listings[id] = nil
			end
		end
		broadcast()
	end)
end

return EconomyService
