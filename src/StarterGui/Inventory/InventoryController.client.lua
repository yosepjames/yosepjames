-- Inventory GUI: view pets, equip/unequip, sell, fuse
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetData   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local remotes   = ReplicatedStorage:WaitForChild("Remotes")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local inventoryCache  = {}   -- uid → entry
local selectedForFuse = {}   -- up to 3 uids
local equippedCache   = {}
local searchText      = ""

-- ── Build ScreenGui ───────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "InventoryGui"
screen.ResetOnSpawn   = false
screen.Enabled        = false
screen.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.Parent           = screen

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 760, 0, 520)
panel.Position         = UDim2.new(0.5, -380, 0.5, -260)
panel.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
panel.Parent           = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(200, 180, 255)
title.Font             = Enum.Font.GothamBold
title.TextScaled       = true
title.Text             = "🎒 Inventory"
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

-- Search / filter input
local searchBox = Instance.new("TextBox")
searchBox.Size             = UDim2.new(1, -20, 0, 36)
searchBox.Position         = UDim2.new(0, 10, 0, 54)
searchBox.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
searchBox.TextColor3       = Color3.new(1, 1, 1)
searchBox.Font             = Enum.Font.Gotham
searchBox.TextScaled       = true
searchBox.PlaceholderText  = "🔍 Search by name or rarity…"
searchBox.Text             = ""
searchBox.ClearTextOnFocus = false
searchBox.Parent           = panel
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
local searchStroke = Instance.new("UIStroke")
searchStroke.Color     = Color3.fromRGB(100, 80, 160)
searchStroke.Thickness = 1
searchStroke.Parent    = searchBox

-- Fusion status bar
local fuseBar = Instance.new("Frame")
fuseBar.Size             = UDim2.new(1, -20, 0, 44)
fuseBar.Position         = UDim2.new(0, 10, 1, -54)
fuseBar.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
fuseBar.Parent           = panel
Instance.new("UICorner", fuseBar).CornerRadius = UDim.new(0, 8)

local fuseLabel = Instance.new("TextLabel")
fuseLabel.Size             = UDim2.new(0.6, 0, 1, 0)
fuseLabel.BackgroundTransparency = 1
fuseLabel.TextColor3       = Color3.new(1, 1, 1)
fuseLabel.Font             = Enum.Font.Gotham
fuseLabel.TextScaled       = true
fuseLabel.Text             = "Select 3 identical pets to fuse"
fuseLabel.Parent           = fuseBar

local fuseBtn = Instance.new("TextButton")
fuseBtn.Size             = UDim2.new(0.38, 0, 0.8, 0)
fuseBtn.Position         = UDim2.new(0.61, 0, 0.1, 0)
fuseBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 220)
fuseBtn.TextColor3       = Color3.new(1, 1, 1)
fuseBtn.Font             = Enum.Font.GothamBold
fuseBtn.TextScaled       = true
fuseBtn.Text             = "⚗ Fuse (0/3)"
fuseBtn.Active           = false
fuseBtn.Parent           = fuseBar
Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 6)

-- Pet grid
local petScroll = Instance.new("ScrollingFrame")
petScroll.Size             = UDim2.new(1, -20, 1, -152)
petScroll.Position         = UDim2.new(0, 10, 0, 98)
petScroll.BackgroundTransparency = 1
petScroll.ScrollBarThickness = 6
petScroll.Parent           = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize    = UDim2.new(0, 110, 0, 140)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.SortOrder   = Enum.SortOrder.LayoutOrder
grid.Parent      = petScroll

-- ── Pet card builder ──────────────────────────────────────────────────────────
local petCards = {}  -- uid → frame

local function updateFuseBar()
	fuseBtn.Text = "⚗ Fuse (" .. #selectedForFuse .. "/3)"
	if #selectedForFuse == 3 then
		fuseBtn.Active           = true
		fuseBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 255)
	else
		fuseBtn.Active           = false
		fuseBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 220)
	end
end

local function isEquipped(uid)
	for _, eu in ipairs(equippedCache) do
		if eu == uid then return true end
	end
	return false
end

local function isSelectedForFuse(uid)
	for _, su in ipairs(selectedForFuse) do
		if su == uid then return true end
	end
	return false
end

local function buildCard(entry)
	if petCards[entry.uid] then petCards[entry.uid]:Destroy() end

	local petInfo = PetData.GetPet(entry.petId)
	if not petInfo then return end

	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
	card.Parent           = petScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	-- Rarity glow border
	local stroke = Instance.new("UIStroke")
	stroke.Color     = PetData.GetRarityColor(petInfo.rarity)
	stroke.Thickness = 2
	stroke.Parent    = card

	-- Colour icon
	local icon = Instance.new("Frame")
	icon.Size             = UDim2.new(0, 60, 0, 60)
	icon.Position         = UDim2.new(0.5, -30, 0, 8)
	icon.BackgroundColor3 = petInfo.bodyColor
	icon.Parent           = card
	Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)

	local nameL = Instance.new("TextLabel")
	nameL.Size             = UDim2.new(1, 0, 0, 18)
	nameL.Position         = UDim2.new(0, 0, 0, 72)
	nameL.BackgroundTransparency = 1
	nameL.TextColor3       = Color3.new(1, 1, 1)
	nameL.Font             = Enum.Font.GothamBold
	nameL.TextScaled       = true
	nameL.Text             = petInfo.name
	nameL.Parent           = card

	local rarityL = Instance.new("TextLabel")
	rarityL.Size             = UDim2.new(1, 0, 0, 14)
	rarityL.Position         = UDim2.new(0, 0, 0, 92)
	rarityL.BackgroundTransparency = 1
	rarityL.TextColor3       = PetData.GetRarityColor(petInfo.rarity)
	rarityL.Font             = Enum.Font.Gotham
	rarityL.TextScaled       = true
	rarityL.Text             = petInfo.rarity
	rarityL.Parent           = card

	-- Action buttons
	local equipBtn = Instance.new("TextButton")
	equipBtn.Size             = UDim2.new(0.48, 0, 0, 22)
	equipBtn.Position         = UDim2.new(0.01, 0, 1, -26)
	equipBtn.BackgroundColor3 = isEquipped(entry.uid)
		and Color3.fromRGB(60, 160, 60) or Color3.fromRGB(50, 100, 50)
	equipBtn.TextColor3       = Color3.new(1, 1, 1)
	equipBtn.Font             = Enum.Font.GothamBold
	equipBtn.TextScaled       = true
	equipBtn.Text             = isEquipped(entry.uid) and "✓ On" or "Equip"
	equipBtn.Parent           = card
	Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 4)

	local sellBtn = Instance.new("TextButton")
	sellBtn.Size             = UDim2.new(0.48, 0, 0, 22)
	sellBtn.Position         = UDim2.new(0.51, 0, 1, -26)
	sellBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
	sellBtn.TextColor3       = Color3.new(1, 1, 1)
	sellBtn.Font             = Enum.Font.GothamBold
	sellBtn.TextScaled       = true
	sellBtn.Text             = "Sell"
	sellBtn.Parent           = card
	Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 4)

	-- Click card = toggle fuse selection
	card.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		if isSelectedForFuse(entry.uid) then
			for i, su in ipairs(selectedForFuse) do
				if su == entry.uid then table.remove(selectedForFuse, i) break end
			end
			stroke.Thickness = 2
		else
			if #selectedForFuse < 3 then
				table.insert(selectedForFuse, entry.uid)
				stroke.Thickness = 5
			end
		end
		updateFuseBar()
	end)

	equipBtn.MouseButton1Click:Connect(function()
		if isEquipped(entry.uid) then
			remotes.UnequipPet:FireServer(entry.uid)
		else
			remotes.EquipPet:FireServer(entry.uid)
		end
	end)

	sellBtn.MouseButton1Click:Connect(function()
		remotes.SellPet:FireServer(entry.uid)
	end)

	petCards[entry.uid] = card
end

local function filterCards()
	local query = searchText:lower()
	for uid, card in pairs(petCards) do
		if query == "" then
			card.Visible = true
		else
			local entry   = inventoryCache[uid]
			local petInfo = entry and PetData.GetPet(entry.petId)
			local name    = petInfo and petInfo.name:lower()   or ""
			local rarity  = petInfo and petInfo.rarity:lower() or ""
			card.Visible  = name:find(query, 1, true) ~= nil
				or rarity:find(query, 1, true) ~= nil
		end
	end
end

local function refreshGrid()
	for _, card in pairs(petCards) do card:Destroy() end
	petCards = {}
	for _, entry in pairs(inventoryCache) do
		buildCard(entry)
	end
	filterCards()
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchText = searchBox.Text
	filterCards()
end)

-- Fuse button
fuseBtn.MouseButton1Click:Connect(function()
	if #selectedForFuse ~= 3 then return end
	local u1, u2, u3 = selectedForFuse[1], selectedForFuse[2], selectedForFuse[3]
	selectedForFuse = {}
	updateFuseBar()
	pcall(function() remotes.FusePets:InvokeServer(u1, u2, u3) end)
end)

-- ── Remote listeners ──────────────────────────────────────────────────────────
remotes.PetAdded.OnClientEvent:Connect(function(entry)
	inventoryCache[entry.uid] = entry
	buildCard(entry)
end)

remotes.PetRemoved.OnClientEvent:Connect(function(uid)
	inventoryCache[uid] = nil
	if petCards[uid] then
		petCards[uid]:Destroy()
		petCards[uid] = nil
	end
	for i, su in ipairs(selectedForFuse) do
		if su == uid then table.remove(selectedForFuse, i) break end
	end
	updateFuseBar()
end)

remotes.EquippedUpdated.OnClientEvent:Connect(function(uids)
	equippedCache = uids
	refreshGrid()
end)

-- Fetch inventory on open
screen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screen.Enabled then return end
	task.spawn(function()
		local ok, pets = pcall(function() return remotes.GetInventory:InvokeServer() end)
		if ok and pets then
			inventoryCache = {}
			for _, entry in ipairs(pets) do
				inventoryCache[entry.uid] = entry
			end
			refreshGrid()
		end
	end)
end)

-- ── Toggle button ─────────────────────────────────────────────────────────────
local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "InventoryToggle"
masterGui.ResetOnSpawn   = false
masterGui.Parent         = playerGui

local invBtn = Instance.new("TextButton")
invBtn.Size             = UDim2.new(0, 120, 0, 46)
invBtn.Position         = UDim2.new(0.5, -60, 1, -60)
invBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 90)
invBtn.TextColor3       = Color3.new(1, 1, 1)
invBtn.Font             = Enum.Font.GothamBold
invBtn.TextScaled       = true
invBtn.Text             = "🎒 Pets"
invBtn.Parent           = masterGui
Instance.new("UICorner", invBtn).CornerRadius = UDim.new(0, 10)

invBtn.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)
