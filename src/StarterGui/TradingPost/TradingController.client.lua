-- Trading Post GUI: browse listings, list your pets, buy from others
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetData   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local remotes   = ReplicatedStorage:WaitForChild("Remotes")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local listingsCache   = {}   -- listingId → listing
local inventoryCache  = {}   -- uid → entry (populated from PetAdded/PetRemoved)
local listingSearch   = ""

-- ── Build ScreenGui ───────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "TradingGui"
screen.ResetOnSpawn   = false
screen.Enabled        = false
screen.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.Parent           = screen

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 820, 0, 560)
panel.Position         = UDim2.new(0.5, -410, 0.5, -280)
panel.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
panel.Parent           = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(80, 200, 255)
title.Font             = Enum.Font.GothamBold
title.TextScaled       = true
title.Text             = "🏪 Trading Post"
title.Parent           = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 36, 0, 36)
closeBtn.Position         = UDim2.new(1, -44, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.TextColor3       = Color3.new(1, 1, 1)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.Text             = "✕"
closeBtn.TextScaled       = true
closeBtn.Parent           = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

-- Left: listings browser
local leftPane = Instance.new("Frame")
leftPane.Size             = UDim2.new(0.62, -8, 1, -60)
leftPane.Position         = UDim2.new(0, 10, 0, 55)
leftPane.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
leftPane.Parent           = panel
Instance.new("UICorner", leftPane).CornerRadius = UDim.new(0, 8)

local leftTitle = Instance.new("TextLabel")
leftTitle.Size             = UDim2.new(1, 0, 0, 30)
leftTitle.BackgroundTransparency = 1
leftTitle.TextColor3       = Color3.new(1, 1, 1)
leftTitle.Font             = Enum.Font.GothamBold
leftTitle.TextScaled       = true
leftTitle.Text             = "Active Listings"
leftTitle.Parent           = leftPane

-- Listings search box
local listingSearchBox = Instance.new("TextBox")
listingSearchBox.Size             = UDim2.new(1, -8, 0, 32)
listingSearchBox.Position         = UDim2.new(0, 4, 0, 32)
listingSearchBox.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
listingSearchBox.TextColor3       = Color3.new(1, 1, 1)
listingSearchBox.Font             = Enum.Font.Gotham
listingSearchBox.TextScaled       = true
listingSearchBox.PlaceholderText  = "🔍 Search listings…"
listingSearchBox.Text             = ""
listingSearchBox.ClearTextOnFocus = false
listingSearchBox.Parent           = leftPane
Instance.new("UICorner", listingSearchBox).CornerRadius = UDim.new(0, 6)
local listSearchStroke = Instance.new("UIStroke")
listSearchStroke.Color     = Color3.fromRGB(60, 120, 180)
listSearchStroke.Thickness = 1
listSearchStroke.Parent    = listingSearchBox

local listScroll = Instance.new("ScrollingFrame")
listScroll.Size             = UDim2.new(1, -8, 1, -74)
listScroll.Position         = UDim2.new(0, 4, 0, 70)
listScroll.BackgroundTransparency = 1
listScroll.ScrollBarThickness = 5
listScroll.Parent           = leftPane

local listLayout = Instance.new("UIListLayout")
listLayout.Padding   = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent    = listScroll

-- Right: create listing
local rightPane = Instance.new("Frame")
rightPane.Size             = UDim2.new(0.36, -6, 1, -60)
rightPane.Position         = UDim2.new(0.64, 0, 0, 55)
rightPane.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
rightPane.Parent           = panel
Instance.new("UICorner", rightPane).CornerRadius = UDim.new(0, 8)

local rightTitle = Instance.new("TextLabel")
rightTitle.Size             = UDim2.new(1, 0, 0, 30)
rightTitle.BackgroundTransparency = 1
rightTitle.TextColor3       = Color3.new(1, 1, 1)
rightTitle.Font             = Enum.Font.GothamBold
rightTitle.TextScaled       = true
rightTitle.Text             = "List a Pet"
rightTitle.Parent           = rightPane

local petDropdown = Instance.new("TextButton")
petDropdown.Size             = UDim2.new(1, -16, 0, 38)
petDropdown.Position         = UDim2.new(0, 8, 0, 38)
petDropdown.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
petDropdown.TextColor3       = Color3.new(0.7, 0.7, 0.7)
petDropdown.Font             = Enum.Font.Gotham
petDropdown.TextScaled       = true
petDropdown.Text             = "Select a pet…"
petDropdown.Parent           = rightPane
Instance.new("UICorner", petDropdown).CornerRadius = UDim.new(0, 6)

local priceBox = Instance.new("TextBox")
priceBox.Size             = UDim2.new(1, -16, 0, 38)
priceBox.Position         = UDim2.new(0, 8, 0, 84)
priceBox.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
priceBox.TextColor3       = Color3.new(1, 1, 1)
priceBox.Font             = Enum.Font.Gotham
priceBox.TextScaled       = true
priceBox.PlaceholderText  = "Price in coins…"
priceBox.Text             = ""
priceBox.Parent           = rightPane
Instance.new("UICorner", priceBox).CornerRadius = UDim.new(0, 6)

local listBtn = Instance.new("TextButton")
listBtn.Size             = UDim2.new(1, -16, 0, 42)
listBtn.Position         = UDim2.new(0, 8, 0, 130)
listBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
listBtn.TextColor3       = Color3.new(1, 1, 1)
listBtn.Font             = Enum.Font.GothamBold
listBtn.TextScaled       = true
listBtn.Text             = "📤 List for Sale"
listBtn.Parent           = rightPane
Instance.new("UICorner", listBtn).CornerRadius = UDim.new(0, 8)

-- ── Selected pet tracking ─────────────────────────────────────────────────────
local selectedUid = nil

petDropdown.MouseButton1Click:Connect(function()
	-- Cycle through inventory
	local uids = {}
	for uid in pairs(inventoryCache) do table.insert(uids, uid) end
	if #uids == 0 then
		petDropdown.Text = "No pets in inventory"
		return
	end
	-- Find current index
	local currentIdx = 0
	for i, uid in ipairs(uids) do
		if uid == selectedUid then currentIdx = i break end
	end
	local nextIdx = (currentIdx % #uids) + 1
	selectedUid = uids[nextIdx]
	local entry   = inventoryCache[selectedUid]
	local petInfo = entry and PetData.GetPet(entry.petId)
	petDropdown.Text = petInfo and petInfo.name or selectedUid
end)

listBtn.MouseButton1Click:Connect(function()
	if not selectedUid then return end
	local price = tonumber(priceBox.Text)
	if not price or price < 1 then return end
	remotes.CreateListing:FireServer({ uid = selectedUid, price = math.floor(price) })
	selectedUid      = nil
	petDropdown.Text = "Select a pet…"
	priceBox.Text    = ""
end)

-- ── Render listings ───────────────────────────────────────────────────────────
local listingCards = {}  -- listingId → frame

local function buildListingCard(listing)
	if listingCards[listing.id] then listingCards[listing.id]:Destroy() end

	local petInfo = PetData.GetPet(listing.petId)
	local isMine  = listing.sellerId == player.UserId

	local card = Instance.new("Frame")
	card.Size             = UDim2.new(1, -8, 0, 60)
	card.BackgroundColor3 = isMine
		and Color3.fromRGB(30, 35, 55) or Color3.fromRGB(24, 28, 44)
	card.Parent           = listScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

	-- Pet colour dot
	local dot = Instance.new("Frame")
	dot.Size             = UDim2.new(0, 40, 0, 40)
	dot.Position         = UDim2.new(0, 10, 0.5, -20)
	dot.BackgroundColor3 = petInfo and petInfo.bodyColor or Color3.new(1,1,1)
	dot.Parent           = card
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

	local nameL = Instance.new("TextLabel")
	nameL.Size             = UDim2.new(0.45, 0, 0.5, 0)
	nameL.Position         = UDim2.new(0, 58, 0, 4)
	nameL.BackgroundTransparency = 1
	nameL.TextColor3       = Color3.new(1, 1, 1)
	nameL.Font             = Enum.Font.GothamBold
	nameL.TextScaled       = true
	nameL.TextXAlignment   = Enum.TextXAlignment.Left
	nameL.Text             = petInfo and petInfo.name or listing.petId
	nameL.Parent           = card

	local sellerL = Instance.new("TextLabel")
	sellerL.Size             = UDim2.new(0.45, 0, 0.45, 0)
	sellerL.Position         = UDim2.new(0, 58, 0.5, 2)
	sellerL.BackgroundTransparency = 1
	sellerL.TextColor3       = Color3.new(0.6, 0.6, 0.6)
	sellerL.Font             = Enum.Font.Gotham
	sellerL.TextScaled       = true
	sellerL.TextXAlignment   = Enum.TextXAlignment.Left
	sellerL.Text             = "by " .. listing.sellerName
	sellerL.Parent           = card

	local priceL = Instance.new("TextLabel")
	priceL.Size             = UDim2.new(0, 90, 1, 0)
	priceL.Position         = UDim2.new(1, -180, 0, 0)
	priceL.BackgroundTransparency = 1
	priceL.TextColor3       = Color3.fromRGB(255, 220, 60)
	priceL.Font             = Enum.Font.GothamBold
	priceL.TextScaled       = true
	priceL.Text             = "🪙 " .. tostring(listing.price)
	priceL.Parent           = card

	local actionBtn = Instance.new("TextButton")
	actionBtn.Size             = UDim2.new(0, 80, 0, 36)
	actionBtn.Position         = UDim2.new(1, -90, 0.5, -18)
	actionBtn.TextColor3       = Color3.new(1, 1, 1)
	actionBtn.Font             = Enum.Font.GothamBold
	actionBtn.TextScaled       = true
	actionBtn.Parent           = card
	Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 6)

	if isMine then
		actionBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
		actionBtn.Text             = "Cancel"
		actionBtn.MouseButton1Click:Connect(function()
			remotes.CancelListing:FireServer(listing.id)
		end)
	else
		actionBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
		actionBtn.Text             = "Buy"
		actionBtn.MouseButton1Click:Connect(function()
			remotes.BuyListing:FireServer(listing.id)
		end)
	end

	listingCards[listing.id] = card
end

local function filterListings()
	local query = listingSearch:lower()
	for id, card in pairs(listingCards) do
		if query == "" then
			card.Visible = true
		else
			local listing = listingsCache[id]
			local petInfo = listing and PetData.GetPet(listing.petId)
			local name    = petInfo and petInfo.name:lower()     or ""
			local seller  = listing and listing.sellerName:lower() or ""
			card.Visible  = name:find(query, 1, true) ~= nil
				or seller:find(query, 1, true) ~= nil
		end
	end
end

local function refreshListings()
	for _, card in pairs(listingCards) do card:Destroy() end
	listingCards = {}
	for _, listing in pairs(listingsCache) do
		buildListingCard(listing)
	end
	filterListings()
end

listingSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	listingSearch = listingSearchBox.Text
	filterListings()
end)

-- ── Remote listeners ──────────────────────────────────────────────────────────
remotes.PetAdded.OnClientEvent:Connect(function(entry)
	inventoryCache[entry.uid] = entry
end)

remotes.PetRemoved.OnClientEvent:Connect(function(uid)
	inventoryCache[uid] = nil
	if selectedUid == uid then
		selectedUid      = nil
		petDropdown.Text = "Select a pet…"
	end
end)

remotes.ListingUpdated.OnClientEvent:Connect(function(listings)
	listingsCache = listings
	refreshListings()
end)

-- Fetch listings when panel opens
screen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screen.Enabled then return end
	task.spawn(function()
		local ok, listings = pcall(function() return remotes.GetListings:InvokeServer() end)
		if ok and listings then
			listingsCache = listings
			refreshListings()
		end
		local ok2, pets = pcall(function() return remotes.GetInventory:InvokeServer() end)
		if ok2 and pets then
			for _, entry in ipairs(pets) do
				inventoryCache[entry.uid] = entry
			end
		end
	end)
end)

-- ── Toggle button ─────────────────────────────────────────────────────────────
local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "TradingToggle"
masterGui.ResetOnSpawn   = false
masterGui.Parent         = playerGui

local tradeBtn = Instance.new("TextButton")
tradeBtn.Size             = UDim2.new(0, 120, 0, 46)
tradeBtn.Position         = UDim2.new(0.5, 80, 1, -60)
tradeBtn.BackgroundColor3 = Color3.fromRGB(20, 80, 140)
tradeBtn.TextColor3       = Color3.new(1, 1, 1)
tradeBtn.Font             = Enum.Font.GothamBold
tradeBtn.TextScaled       = true
tradeBtn.Text             = "🏪 Trade"
tradeBtn.Parent           = masterGui
Instance.new("UICorner", tradeBtn).CornerRadius = UDim.new(0, 10)

tradeBtn.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)
