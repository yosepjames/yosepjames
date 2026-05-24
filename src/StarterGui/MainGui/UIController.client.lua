-- Manages all HUD elements: timer, state banner, coin counter, notifications
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local GameState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameState"))
local remotes   = ReplicatedStorage:WaitForChild("Remotes")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Build UI ──────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "MainHUD"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = playerGui

-- State banner (top center)
local stateBanner = Instance.new("TextLabel")
stateBanner.Name            = "StateBanner"
stateBanner.Size            = UDim2.new(0, 400, 0, 50)
stateBanner.Position        = UDim2.new(0.5, -200, 0, 20)
stateBanner.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
stateBanner.BackgroundTransparency = 0.4
stateBanner.TextColor3      = Color3.new(1, 1, 1)
stateBanner.Font            = Enum.Font.GothamBold
stateBanner.TextScaled      = true
stateBanner.Text            = "Waiting for players…"
stateBanner.Parent          = screenGui

Instance.new("UICorner", stateBanner).CornerRadius = UDim.new(0, 8)

-- Timer label (below banner)
local timerLabel = Instance.new("TextLabel")
timerLabel.Name             = "Timer"
timerLabel.Size             = UDim2.new(0, 200, 0, 40)
timerLabel.Position         = UDim2.new(0.5, -100, 0, 80)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3       = Color3.new(1, 1, 1)
timerLabel.Font             = Enum.Font.Gotham
timerLabel.TextScaled       = true
timerLabel.Text             = ""
timerLabel.Parent           = screenGui

-- Coin counter (top left)
local coinLabel = Instance.new("TextLabel")
coinLabel.Name              = "Coins"
coinLabel.Size              = UDim2.new(0, 160, 0, 40)
coinLabel.Position          = UDim2.new(0, 16, 0, 16)
coinLabel.BackgroundColor3  = Color3.fromRGB(255, 200, 0)
coinLabel.BackgroundTransparency = 0.2
coinLabel.TextColor3        = Color3.fromRGB(50, 30, 0)
coinLabel.Font              = Enum.Font.GothamBold
coinLabel.TextScaled        = true
coinLabel.Text              = "Coins: 0"
coinLabel.Parent            = screenGui

Instance.new("UICorner", coinLabel).CornerRadius = UDim.new(0, 8)

-- Notification area (bottom center)
local notifLabel = Instance.new("TextLabel")
notifLabel.Name             = "Notification"
notifLabel.Size             = UDim2.new(0, 500, 0, 44)
notifLabel.Position         = UDim2.new(0.5, -250, 1, -80)
notifLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
notifLabel.BackgroundTransparency = 0.5
notifLabel.TextColor3       = Color3.new(1, 1, 1)
notifLabel.Font             = Enum.Font.Gotham
notifLabel.TextScaled       = true
notifLabel.Text             = ""
notifLabel.TextTransparency = 1
notifLabel.Parent           = screenGui

Instance.new("UICorner", notifLabel).CornerRadius = UDim.new(0, 8)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function formatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

local notifTween
local function showNotification(message)
	if notifTween then notifTween:Cancel() end
	notifLabel.Text = message
	notifLabel.TextTransparency = 0

	notifTween = TweenService:Create(
		notifLabel,
		TweenInfo.new(3, Enum.EasingStyle.Linear),
		{ TextTransparency = 1 }
	)
	notifTween:Play()
end

local STATE_LABELS = {
	[GameState.LOBBY]        = "Waiting for players…",
	[GameState.STARTING]     = "Round starting!",
	[GameState.IN_ROUND]     = "Round in progress",
	[GameState.INTERMISSION] = "Intermission",
}

-- ── Wire remotes ──────────────────────────────────────────────────────────────

remotes.StateChanged.OnClientEvent:Connect(function(state)
	stateBanner.Text = STATE_LABELS[state] or state
end)

remotes.TimerUpdate.OnClientEvent:Connect(function(secondsLeft)
	timerLabel.Text = secondsLeft > 0 and formatTime(secondsLeft) or ""
end)

remotes.PlayerDataUpdate.OnClientEvent:Connect(function(data)
	if data.coins ~= nil then
		coinLabel.Text = "Coins: " .. tostring(data.coins)
	end
end)

remotes.NotifyPlayer.OnClientEvent:Connect(function(message)
	showNotification(message)
end)
