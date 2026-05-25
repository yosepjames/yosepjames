-- Main HUD: coins, gems, equipped pet slots, notifications, territory banner
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local PetData       = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local TerritoryData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TerritoryData"))
local remotes       = ReplicatedStorage:WaitForChild("Remotes")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Build ScreenGui ───────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "MainHUD"
screen.ResetOnSpawn   = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent         = playerGui

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent       = parent
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	for k, v in pairs(props) do l[k] = v end
	l.Parent = parent
	return l
end

-- ── Coin bar (top-left) ───────────────────────────────────────────────────────
local coinFrame = Instance.new("Frame")
coinFrame.Size            = UDim2.new(0, 170, 0, 44)
coinFrame.Position        = UDim2.new(0, 12, 0, 12)
coinFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 10)
coinFrame.BackgroundTransparency = 0.2
coinFrame.Parent          = screen
corner(coinFrame)

local coinLabel = label(coinFrame, {
	Size     = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 8, 0, 0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 220, 60),
	Font       = Enum.Font.GothamBold,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text       = "🪙 100",
})

-- ── Gem bar (below coins) ─────────────────────────────────────────────────────
local gemFrame = Instance.new("Frame")
gemFrame.Size             = UDim2.new(0, 170, 0, 44)
gemFrame.Position         = UDim2.new(0, 12, 0, 62)
gemFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 40)
gemFrame.BackgroundTransparency = 0.2
gemFrame.Parent           = screen
corner(gemFrame)

local gemLabel = label(gemFrame, {
	Size     = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 8, 0, 0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(140, 180, 255),
	Font       = Enum.Font.GothamBold,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text       = "💎 5",
})

-- ── Equipped pet slots (top-right) ────────────────────────────────────────────
local slotContainer = Instance.new("Frame")
slotContainer.Size             = UDim2.new(0, 170, 0, 60)
slotContainer.Position         = UDim2.new(1, -182, 0, 12)
slotContainer.BackgroundTransparency = 1
slotContainer.Parent           = screen

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding       = UDim.new(0, 6)
layout.Parent        = slotContainer

local petSlots = {}
for i = 1, 3 do
	local slot = Instance.new("Frame")
	slot.Size             = UDim2.new(0, 52, 0, 52)
	slot.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	slot.BackgroundTransparency = 0.3
	slot.Parent           = slotContainer
	corner(slot, 6)

	local slotLabel = label(slot, {
		Size     = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(0.5, 0.5, 0.5),
		Font       = Enum.Font.Gotham,
		TextScaled = true,
		Text       = tostring(i),
	})
	petSlots[i] = { frame = slot, label = slotLabel }
end

-- ── Notification toast (bottom-center) ───────────────────────────────────────
local toast = Instance.new("TextLabel")
toast.Size             = UDim2.new(0, 500, 0, 46)
toast.Position         = UDim2.new(0.5, -250, 1, -80)
toast.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
toast.BackgroundTransparency = 0.35
toast.TextColor3       = Color3.new(1, 1, 1)
toast.Font             = Enum.Font.Gotham
toast.TextScaled       = true
toast.Text             = ""
toast.TextTransparency = 1
toast.Parent           = screen
corner(toast)

local toastTween
local function showToast(text, color)
	if toastTween then toastTween:Cancel() end
	toast.Text             = text
	toast.TextColor3       = color or Color3.new(1, 1, 1)
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.35
	toastTween = TweenService:Create(toast, TweenInfo.new(3, Enum.EasingStyle.Linear), {
		TextTransparency       = 1,
		BackgroundTransparency = 1,
	})
	toastTween:Play()
end

-- ── Territory banner (top-center) ─────────────────────────────────────────────
local terrBanner = Instance.new("TextLabel")
terrBanner.Size             = UDim2.new(0, 340, 0, 40)
terrBanner.Position         = UDim2.new(0.5, -170, 0, 12)
terrBanner.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
terrBanner.BackgroundTransparency = 0.4
terrBanner.TextColor3       = Color3.new(1, 1, 1)
terrBanner.Font             = Enum.Font.GothamBold
terrBanner.TextScaled       = true
terrBanner.Text             = "Mythic Pets Empire"
terrBanner.Parent           = screen
corner(terrBanner)

-- ── Remote listeners ──────────────────────────────────────────────────────────

remotes.CoinUpdate.OnClientEvent:Connect(function(coins)
	coinLabel.Text = "🪙 " .. tostring(coins)
end)

remotes.GemUpdate.OnClientEvent:Connect(function(gems)
	gemLabel.Text = "💎 " .. tostring(gems)
end)

remotes.Notification.OnClientEvent:Connect(function(payload)
	showToast(payload.text, payload.color)
end)

remotes.EquippedUpdated.OnClientEvent:Connect(function(uids)
	-- Update slot display (we need petIdCache from PetFollowController)
	-- For now show uid count
	for i = 1, 3 do
		local uid = uids[i]
		if uid then
			petSlots[i].frame.BackgroundColor3 = Color3.fromRGB(60, 40, 10)
			petSlots[i].label.Text             = "✦"
			petSlots[i].label.TextColor3       = Color3.fromRGB(255, 220, 60)
		else
			petSlots[i].frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			petSlots[i].label.Text             = tostring(i)
			petSlots[i].label.TextColor3       = Color3.new(0.5, 0.5, 0.5)
		end
	end
end)

remotes.TerritoryUpdated.OnClientEvent:Connect(function(state)
	-- Show which territories player owns
	local ownedNames = {}
	for id, info in pairs(state) do
		if info.owner == player.UserId then
			local tdata = TerritoryData.Get(id)
			if tdata then table.insert(ownedNames, tdata.name) end
		end
	end
	if #ownedNames > 0 then
		terrBanner.Text      = "Owning: " .. table.concat(ownedNames, ", ")
		terrBanner.TextColor3 = Color3.fromRGB(255, 220, 60)
	else
		terrBanner.Text       = "Mythic Pets Empire"
		terrBanner.TextColor3 = Color3.new(1, 1, 1)
	end
end)

-- Fetch initial data
task.spawn(function()
	task.wait(2)
	local ok, data = pcall(function() return remotes.GetPlayerData:InvokeServer() end)
	if ok and data then
		coinLabel.Text = "🪙 " .. tostring(data.coins or 0)
		gemLabel.Text  = "💎 " .. tostring(data.gems or 0)
	end
end)
