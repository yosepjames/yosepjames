-- Daily Spin Wheel: animated slot-style spin with 24h cooldown
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────────────────────────────────────────────
local spinInfo     = {}
local isSpinning   = false
local luckTokens   = 0
local activeLuckUntil = 0

-- ── Build UI ──────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "DailySpinGui"
screen.ResetOnSpawn   = false
screen.Enabled        = false
screen.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1,0,1,0)
backdrop.BackgroundColor3 = Color3.new(0,0,0)
backdrop.BackgroundTransparency = 0.5
backdrop.Parent           = screen

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, 640, 0, 520)
panel.Position         = UDim2.new(0.5, -320, 0.5, -260)
panel.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
panel.Parent           = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

-- Gold border
local stroke = Instance.new("UIStroke")
stroke.Color     = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 3
stroke.Parent    = panel

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1,0,0,54)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(255, 215, 0)
title.Font             = Enum.Font.GothamBold
title.TextScaled       = true
title.Text             = "🎰 Daily Spin"
title.Parent           = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0,36,0,36)
closeBtn.Position         = UDim2.new(1,-44,0,8)
closeBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
closeBtn.TextColor3       = Color3.new(1,1,1)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.Text             = "✕"
closeBtn.TextScaled       = true
closeBtn.Parent           = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)
closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

-- Slot display (scrolling strip of prize cards)
local slotFrame = Instance.new("Frame")
slotFrame.Size             = UDim2.new(0, 560, 0, 110)
slotFrame.Position         = UDim2.new(0.5,-280, 0, 62)
slotFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
slotFrame.ClipsDescendants = true
slotFrame.Parent           = panel
Instance.new("UICorner", slotFrame).CornerRadius = UDim.new(0, 10)

-- Highlight arrow
local arrow = Instance.new("Frame")
arrow.Size             = UDim2.new(0,4,1,0)
arrow.Position         = UDim2.new(0.5,-2,0,0)
arrow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
arrow.Parent           = slotFrame

local strip = Instance.new("Frame")
strip.Size             = UDim2.new(0, 9999, 1, -8)
strip.Position         = UDim2.new(0,0,0,4)
strip.BackgroundTransparency = 1
strip.Parent           = slotFrame

local stripLayout = Instance.new("UIListLayout")
stripLayout.FillDirection = Enum.FillDirection.Horizontal
stripLayout.Padding       = UDim.new(0, 6)
stripLayout.Parent        = strip

local CARD_W = 130
local stripCards = {}

local function buildStripCards(prizes)
	for _, c in ipairs(stripCards) do c:Destroy() end
	stripCards = {}
	-- Repeat prizes multiple times for scroll length
	for rep = 1, 6 do
		for _, prize in ipairs(prizes) do
			local card = Instance.new("Frame")
			card.Size             = UDim2.new(0, CARD_W, 1, 0)
			card.BackgroundColor3 = Color3.fromRGB(35, 28, 60)
			card.Parent           = strip
			Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)

			local lbl = Instance.new("TextLabel")
			lbl.Size             = UDim2.new(1,0,1,0)
			lbl.BackgroundTransparency = 1
			lbl.TextColor3       = prize.color
			lbl.Font             = Enum.Font.GothamBold
			lbl.TextScaled       = true
			lbl.Text             = prize.label
			lbl.TextWrapped      = true
			lbl.Parent           = card
			table.insert(stripCards, card)
		end
	end
end

-- Countdown / status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size             = UDim2.new(1,-20,0,34)
statusLabel.Position         = UDim2.new(0,10,0,180)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3       = Color3.new(0.8,0.8,0.8)
statusLabel.Font             = Enum.Font.Gotham
statusLabel.TextScaled       = true
statusLabel.Text             = ""
statusLabel.Parent           = panel

-- Luck Token display
local luckFrame = Instance.new("Frame")
luckFrame.Size             = UDim2.new(0,280,0,50)
luckFrame.Position         = UDim2.new(0,10,0,222)
luckFrame.BackgroundColor3 = Color3.fromRGB(25, 15, 50)
luckFrame.Parent           = panel
Instance.new("UICorner", luckFrame).CornerRadius = UDim.new(0,8)

local luckLabel = Instance.new("TextLabel")
luckLabel.Size             = UDim2.new(1,0,1,0)
luckLabel.BackgroundTransparency = 1
luckLabel.TextColor3       = Color3.fromRGB(255,80,200)
luckLabel.Font             = Enum.Font.GothamBold
luckLabel.TextScaled       = true
luckLabel.Text             = "✨ Lucky Tokens: 0"
luckLabel.Parent           = luckFrame

local activateLuckBtn = Instance.new("TextButton")
activateLuckBtn.Size             = UDim2.new(0,280,0,50)
activateLuckBtn.Position         = UDim2.new(0,10,0,280)
activateLuckBtn.BackgroundColor3 = Color3.fromRGB(80,20,140)
activateLuckBtn.TextColor3       = Color3.new(1,1,1)
activateLuckBtn.Font             = Enum.Font.GothamBold
activateLuckBtn.TextScaled       = true
activateLuckBtn.Text             = "✨ Activate Lucky Aura (uses 1 token)"
activateLuckBtn.Parent           = panel
Instance.new("UICorner", activateLuckBtn).CornerRadius = UDim.new(0,10)

local luckAuraLabel = Instance.new("TextLabel")
luckAuraLabel.Size             = UDim2.new(0,280,0,34)
luckAuraLabel.Position         = UDim2.new(0,10,0,338)
luckAuraLabel.BackgroundTransparency = 1
luckAuraLabel.TextColor3       = Color3.fromRGB(255,215,0)
luckAuraLabel.Font             = Enum.Font.Gotham
luckAuraLabel.TextScaled       = true
luckAuraLabel.Text             = ""
luckAuraLabel.Parent           = panel

-- Spin button
local spinBtn = Instance.new("TextButton")
spinBtn.Size             = UDim2.new(0,220,0,56)
spinBtn.Position         = UDim2.new(0.5,-110,1,-74)
spinBtn.BackgroundColor3 = Color3.fromRGB(255,170,0)
spinBtn.TextColor3       = Color3.fromRGB(30,20,0)
spinBtn.Font             = Enum.Font.GothamBold
spinBtn.TextScaled       = true
spinBtn.Text             = "🎰 SPIN!"
spinBtn.Parent           = panel
Instance.new("UICorner", spinBtn).CornerRadius = UDim.new(0,12)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function formatCountdown(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function updateCountdown()
	local now       = os.time()
	local nextSpin  = spinInfo.nextSpin or 0
	local remaining = nextSpin - now
	if remaining <= 0 then
		statusLabel.Text      = "Ready to spin!"
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		spinBtn.BackgroundColor3 = Color3.fromRGB(255,170,0)
		spinBtn.Active = true
	else
		statusLabel.Text       = "Next spin in: " .. formatCountdown(remaining)
		statusLabel.TextColor3 = Color3.new(0.6,0.6,0.6)
		spinBtn.BackgroundColor3 = Color3.fromRGB(80,70,60)
		spinBtn.Active = false
	end

	-- Luck aura countdown
	local luckRemaining = (spinInfo.activeLuckUntil or 0) - now
	if luckRemaining > 0 then
		luckAuraLabel.Text = "✨ Lucky Aura active: " .. formatCountdown(luckRemaining)
	else
		luckAuraLabel.Text = ""
	end
end

-- Animate the strip to land on prizeIndex
local function animateSpin(prizeIndex, prizes)
	local stripLen  = #prizes
	local totalCards = stripLen * 6  -- we built 6 repeats

	-- Target card index in strip (land on 5th repeat for smooth stop)
	local targetCard = stripLen * 4 + prizeIndex
	local targetX    = -(CARD_W + 6) * (targetCard - 1) + (slotFrame.AbsoluteSize.X / 2 - CARD_W / 2)

	-- Start from current position
	strip.Position = UDim2.new(0, 0, 0, 4)

	-- Fast then slow tween
	TweenService:Create(strip, TweenInfo.new(2.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, targetX, 0, 4) }):Play()
	task.wait(2.8)
end

-- ── Spin logic ────────────────────────────────────────────────────────────────

spinBtn.MouseButton1Click:Connect(function()
	if isSpinning then return end
	isSpinning = true
	spinBtn.Text   = "Spinning…"
	spinBtn.Active = false

	local ok, result = pcall(function() return remotes.ClaimDailySpin:InvokeServer() end)
	if not ok or not result or result.error then
		isSpinning = false
		spinBtn.Text   = "🎰 SPIN!"
		spinBtn.Active = true
		return
	end

	-- Animate
	if result.prizes then
		buildStripCards(result.prizes)
		animateSpin(result.prizeIndex, result.prizes)
	end

	spinInfo.nextSpin = result.nextSpin
	isSpinning = false
	spinBtn.Text = "🎰 SPIN!"
	updateCountdown()
end)

activateLuckBtn.MouseButton1Click:Connect(function()
	if luckTokens < 1 then return end
	remotes.ActivateLuckToken:FireServer()
end)

-- ── Remote listeners ──────────────────────────────────────────────────────────

remotes.LuckTokenUpdate.OnClientEvent:Connect(function(tokens)
	luckTokens = tokens
	luckLabel.Text = "✨ Lucky Tokens: " .. tokens
end)

remotes.LuckAuraUpdate.OnClientEvent:Connect(function(payload)
	spinInfo.activeLuckUntil = payload.active and payload.expiresAt or 0
end)

-- Refresh countdown every second while open
task.spawn(function()
	while true do
		task.wait(1)
		if screen.Enabled then
			updateCountdown()
		end
	end
end)

screen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screen.Enabled then return end
	task.spawn(function()
		local ok, info = pcall(function() return remotes.GetSpinInfo:InvokeServer() end)
		if ok and info then
			spinInfo = info
			luckTokens = info.luckTokens or 0
			luckLabel.Text = "✨ Lucky Tokens: " .. luckTokens
			if info.prizes then buildStripCards(info.prizes) end
			updateCountdown()
		end
	end)
end)

-- ── Toggle button ─────────────────────────────────────────────────────────────
local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "SpinToggle"
masterGui.ResetOnSpawn   = false
masterGui.Parent         = playerGui

local spinToggle = Instance.new("TextButton")
spinToggle.Size             = UDim2.new(0,120,0,46)
spinToggle.Position         = UDim2.new(0.5,-340, 1,-60)
spinToggle.BackgroundColor3 = Color3.fromRGB(160, 100, 0)
spinToggle.TextColor3       = Color3.new(1,1,1)
spinToggle.Font             = Enum.Font.GothamBold
spinToggle.TextScaled       = true
spinToggle.Text             = "🎰 Spin"
spinToggle.Parent           = masterGui
Instance.new("UICorner", spinToggle).CornerRadius = UDim.new(0,10)
spinToggle.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)
