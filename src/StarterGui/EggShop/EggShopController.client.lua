-- Egg Shop GUI: browse eggs, open one, see animated result
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local EggData   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EggData"))
local PetData   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local remotes   = ReplicatedStorage:WaitForChild("Remotes")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Build ScreenGui ───────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "EggShopGui"
screen.ResetOnSpawn   = false
screen.Enabled        = false
screen.Parent         = playerGui

-- Dark backdrop
local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.Parent           = screen

-- Main panel
local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 700, 0, 480)
panel.Position         = UDim2.new(0.5, -350, 0.5, -240)
panel.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
panel.Parent           = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- Title
local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(255, 220, 60)
title.Font             = Enum.Font.GothamBold
title.TextScaled       = true
title.Text             = "🥚 Egg Shop"
title.Parent           = panel

-- Close button
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

closeBtn.MouseButton1Click:Connect(function()
	screen.Enabled = false
end)

-- Egg grid
local eggScroll = Instance.new("ScrollingFrame")
eggScroll.Size             = UDim2.new(1, -20, 1, -60)
eggScroll.Position         = UDim2.new(0, 10, 0, 55)
eggScroll.BackgroundTransparency = 1
eggScroll.ScrollBarThickness = 6
eggScroll.Parent           = panel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize    = UDim2.new(0, 150, 0, 190)
gridLayout.CellPadding = UDim2.new(0, 14, 0, 14)
gridLayout.SortOrder   = Enum.SortOrder.LayoutOrder
gridLayout.Parent      = eggScroll

local eggOrder = { "basic_egg", "magic_egg", "legendary_egg", "mythic_egg" }

for i, eggId in ipairs(eggOrder) do
	local egg = EggData.Eggs[eggId]
	if not egg then continue end

	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
	card.LayoutOrder      = i
	card.Parent           = eggScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	-- Egg icon (coloured circle)
	local icon = Instance.new("Frame")
	icon.Size             = UDim2.new(0, 80, 0, 80)
	icon.Position         = UDim2.new(0.5, -40, 0, 10)
	icon.BackgroundColor3 = egg.bodyColor
	icon.Parent           = card
	Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)

	local eggText = Instance.new("TextLabel")
	eggText.Size             = UDim2.new(1, 0, 0, 20)
	eggText.Position         = UDim2.new(0, 0, 0, 95)
	eggText.BackgroundTransparency = 1
	eggText.TextColor3       = Color3.new(1, 1, 1)
	eggText.Font             = Enum.Font.GothamBold
	eggText.TextScaled       = true
	eggText.Text             = egg.name
	eggText.Parent           = card

	local costLabel = Instance.new("TextLabel")
	costLabel.Size             = UDim2.new(1, 0, 0, 18)
	costLabel.Position         = UDim2.new(0, 0, 0, 118)
	costLabel.BackgroundTransparency = 1
	costLabel.TextColor3       = egg.costType == "gems"
		and Color3.fromRGB(140, 180, 255) or Color3.fromRGB(255, 220, 60)
	costLabel.Font             = Enum.Font.Gotham
	costLabel.TextScaled       = true
	costLabel.Text             = tostring(egg.cost) .. (egg.costType == "gems" and " 💎" or " 🪙")
	costLabel.Parent           = card

	local openBtn = Instance.new("TextButton")
	openBtn.Size             = UDim2.new(1, -16, 0, 34)
	openBtn.Position         = UDim2.new(0, 8, 1, -42)
	openBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 160)
	openBtn.TextColor3       = Color3.new(1, 1, 1)
	openBtn.Font             = Enum.Font.GothamBold
	openBtn.TextScaled       = true
	openBtn.Text             = "Open"
	openBtn.Parent           = card
	Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)

	openBtn.MouseButton1Click:Connect(function()
		openBtn.Text    = "..."
		openBtn.Active  = false
		local ok, result = pcall(function()
			return remotes.OpenEgg:InvokeServer(eggId)
		end)
		openBtn.Text   = "Open"
		openBtn.Active = true
		-- Result notification handled by MainHUD Notification remote
	end)
end

-- ── Shop toggle button (bottom-right of screen) ────────────────────────────────
local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "ShopToggle"
masterGui.ResetOnSpawn   = false
masterGui.Parent         = playerGui

local shopBtn = Instance.new("TextButton")
shopBtn.Size             = UDim2.new(0, 120, 0, 46)
shopBtn.Position         = UDim2.new(0.5, -200, 1, -60)
shopBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 160)
shopBtn.TextColor3       = Color3.new(1, 1, 1)
shopBtn.Font             = Enum.Font.GothamBold
shopBtn.TextScaled       = true
shopBtn.Text             = "🥚 Eggs"
shopBtn.Parent           = masterGui
Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 10)

shopBtn.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)
