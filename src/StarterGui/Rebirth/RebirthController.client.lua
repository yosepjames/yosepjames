-- Rebirth/Prestige UI: shows multiplier, cost, and big REBIRTH button
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rebirthInfo = { rebirth = 0, multiplier = 1, nextCost = 50000 }
local currentCoins = 0

-- ── Build UI ──────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "RebirthGui"
screen.ResetOnSpawn   = false
screen.Enabled        = false
screen.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1,0,1,0)
backdrop.BackgroundColor3 = Color3.new(0,0,0)
backdrop.BackgroundTransparency = 0.6
backdrop.Parent           = screen

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0,480,0,400)
panel.Position         = UDim2.new(0.5,-240,0.5,-200)
panel.BackgroundColor3 = Color3.fromRGB(10, 8, 20)
panel.Parent           = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,16)

local stroke = Instance.new("UIStroke")
stroke.Color     = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 3
stroke.Parent    = panel

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1,0,0,56)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(255, 215, 0)
title.Font             = Enum.Font.GothamBold
title.TextScaled       = true
title.Text             = "⭐ REBIRTH"
title.Parent           = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0,36,0,36)
closeBtn.Position         = UDim2.new(1,-44,0,10)
closeBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
closeBtn.TextColor3       = Color3.new(1,1,1)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.Text             = "✕"
closeBtn.TextScaled       = true
closeBtn.Parent           = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)
closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

-- Star icons row
local starsLabel = Instance.new("TextLabel")
starsLabel.Size             = UDim2.new(1,-20,0,50)
starsLabel.Position         = UDim2.new(0,10,0,62)
starsLabel.BackgroundTransparency = 1
starsLabel.TextColor3       = Color3.fromRGB(255,215,0)
starsLabel.Font             = Enum.Font.GothamBold
starsLabel.TextScaled       = true
starsLabel.Text             = "No rebirths yet"
starsLabel.Parent           = panel

-- Multiplier display
local multLabel = Instance.new("TextLabel")
multLabel.Size             = UDim2.new(1,-20,0,44)
multLabel.Position         = UDim2.new(0,10,0,118)
multLabel.BackgroundColor3 = Color3.fromRGB(20,18,40)
multLabel.TextColor3       = Color3.fromRGB(100,255,200)
multLabel.Font             = Enum.Font.GothamBold
multLabel.TextScaled       = true
multLabel.Text             = "Coin Multiplier: 1.00×"
multLabel.Parent           = panel
Instance.new("UICorner", multLabel).CornerRadius = UDim.new(0,8)

-- Cost bar
local costLabel = Instance.new("TextLabel")
costLabel.Size             = UDim2.new(1,-20,0,40)
costLabel.Position         = UDim2.new(0,10,0,170)
costLabel.BackgroundTransparency = 1
costLabel.TextColor3       = Color3.new(0.85,0.85,0.85)
costLabel.Font             = Enum.Font.Gotham
costLabel.TextScaled       = true
costLabel.Text             = "Cost: 50,000 coins"
costLabel.Parent           = panel

-- Progress bar bg
local progBg = Instance.new("Frame")
progBg.Size             = UDim2.new(1,-20,0,18)
progBg.Position         = UDim2.new(0,10,0,214)
progBg.BackgroundColor3 = Color3.fromRGB(30,28,50)
progBg.Parent           = panel
Instance.new("UICorner", progBg).CornerRadius = UDim.new(0,8)

local progFill = Instance.new("Frame")
progFill.Size             = UDim2.new(0,0,1,0)
progFill.BackgroundColor3 = Color3.fromRGB(255,215,0)
progFill.Parent           = progBg
Instance.new("UICorner", progFill).CornerRadius = UDim.new(0,8)

-- Warning text
local warnLabel = Instance.new("TextLabel")
warnLabel.Size             = UDim2.new(1,-20,0,44)
warnLabel.Position         = UDim2.new(0,10,0,238)
warnLabel.BackgroundTransparency = 1
warnLabel.TextColor3       = Color3.fromRGB(255,120,40)
warnLabel.Font             = Enum.Font.Gotham
warnLabel.TextScaled       = true
warnLabel.Text             = "⚠ Rebirth resets your coins!\nYou keep all pets and get a permanent bonus."
warnLabel.TextWrapped      = true
warnLabel.Parent           = panel

-- REBIRTH button
local rebirthBtn = Instance.new("TextButton")
rebirthBtn.Size             = UDim2.new(0,260,0,58)
rebirthBtn.Position         = UDim2.new(0.5,-130,1,-72)
rebirthBtn.BackgroundColor3 = Color3.fromRGB(60,40,120)
rebirthBtn.TextColor3       = Color3.new(1,1,1)
rebirthBtn.Font             = Enum.Font.GothamBold
rebirthBtn.TextScaled       = true
rebirthBtn.Text             = "⭐ REBIRTH (need more coins)"
rebirthBtn.Active           = false
rebirthBtn.Parent           = panel
Instance.new("UICorner", rebirthBtn).CornerRadius = UDim.new(0,12)

-- ── Update display ────────────────────────────────────────────────────────────

local function updateDisplay()
	local r      = rebirthInfo.rebirth or 0
	local mult   = rebirthInfo.multiplier or 1
	local cost   = rebirthInfo.nextCost or 50000
	local stars  = string.rep("⭐", math.min(r, 10)) .. (r > 10 and ("+" .. (r-10)) or "")

	starsLabel.Text = r == 0 and "No rebirths yet" or ("Prestige " .. r .. ":  " .. stars)
	multLabel.Text  = string.format("Coin Multiplier: %.2f×  (+%.0f%% per rebirth)", mult, 25)
	costLabel.Text  = "Cost: " .. string.format("%d", cost) .. " coins  (you have " .. currentCoins .. ")"

	local progress = math.min(1, currentCoins / math.max(cost, 1))
	TweenService:Create(progFill, TweenInfo.new(0.3), { Size = UDim2.new(progress, 0, 1, 0) }):Play()

	if currentCoins >= cost then
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
		rebirthBtn.Text             = "⭐ REBIRTH NOW! (" .. r+1 .. " stars)"
		rebirthBtn.Active           = true
	else
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(60,40,120)
		rebirthBtn.Text             = "⭐ REBIRTH (need " .. math.max(0, cost - currentCoins) .. " more)"
		rebirthBtn.Active           = false
	end
end

rebirthBtn.MouseButton1Click:Connect(function()
	if not rebirthBtn.Active then return end
	rebirthBtn.Text   = "Rebirthing…"
	rebirthBtn.Active = false
	local ok, result = pcall(function() return remotes.Rebirth:InvokeServer() end)
	if ok and result then
		rebirthInfo = result
		currentCoins = 0
		updateDisplay()
	else
		rebirthBtn.Active = true
	end
end)

-- ── Remote listeners ──────────────────────────────────────────────────────────

remotes.CoinUpdate.OnClientEvent:Connect(function(coins)
	currentCoins = coins
	if screen.Enabled then updateDisplay() end
end)

remotes.RebirthUpdate.OnClientEvent:Connect(function(info)
	rebirthInfo = info
	if screen.Enabled then updateDisplay() end
end)

screen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screen.Enabled then return end
	task.spawn(function()
		local ok, info = pcall(function() return remotes.GetRebirthInfo:InvokeServer() end)
		if ok and info then rebirthInfo = info end
		local ok2, data = pcall(function() return remotes.GetPlayerData:InvokeServer() end)
		if ok2 and data then currentCoins = data.coins or 0 end
		updateDisplay()
	end)
end)

-- ── Toggle button ─────────────────────────────────────────────────────────────
local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "RebirthToggle"
masterGui.ResetOnSpawn   = false
masterGui.Parent         = playerGui

local rebirthToggle = Instance.new("TextButton")
rebirthToggle.Size             = UDim2.new(0,120,0,46)
rebirthToggle.Position         = UDim2.new(0,12,0.5,-23)
rebirthToggle.BackgroundColor3 = Color3.fromRGB(100, 70, 0)
rebirthToggle.TextColor3       = Color3.fromRGB(255,215,0)
rebirthToggle.Font             = Enum.Font.GothamBold
rebirthToggle.TextScaled       = true
rebirthToggle.Text             = "⭐ Rebirth"
rebirthToggle.Parent           = masterGui
Instance.new("UICorner", rebirthToggle).CornerRadius = UDim.new(0,10)
rebirthToggle.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)
