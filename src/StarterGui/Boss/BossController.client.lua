-- World Boss HUD: HP bar at top, attack button, countdown timer
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local bossState = { active = false }

-- ── Build HUD (always visible when boss active) ───────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "BossHUD"
screen.ResetOnSpawn   = false
screen.Parent         = playerGui

-- Boss panel (top-center, hidden unless active)
local bossPanel = Instance.new("Frame")
bossPanel.Size             = UDim2.new(0,500,0,80)
bossPanel.Position         = UDim2.new(0.5,-250,0,130)
bossPanel.BackgroundColor3 = Color3.fromRGB(15,8,25)
bossPanel.BackgroundTransparency = 0.15
bossPanel.Visible          = false
bossPanel.Parent           = screen
Instance.new("UICorner", bossPanel).CornerRadius = UDim.new(0,10)

local bossNameLabel = Instance.new("TextLabel")
bossNameLabel.Size             = UDim2.new(1,-10,0,28)
bossNameLabel.Position         = UDim2.new(0,5,0,4)
bossNameLabel.BackgroundTransparency = 1
bossNameLabel.TextColor3       = Color3.fromRGB(255,80,80)
bossNameLabel.Font             = Enum.Font.GothamBold
bossNameLabel.TextScaled       = true
bossNameLabel.Text             = "⚔ Boss"
bossNameLabel.Parent           = bossPanel

-- HP bar background
local hpBg = Instance.new("Frame")
hpBg.Size             = UDim2.new(1,-10,0,18)
hpBg.Position         = UDim2.new(0,5,0,34)
hpBg.BackgroundColor3 = Color3.fromRGB(60,10,10)
hpBg.Parent           = bossPanel
Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0,8)

local hpFill = Instance.new("Frame")
hpFill.Size             = UDim2.new(1,0,1,0)
hpFill.BackgroundColor3 = Color3.fromRGB(220,40,40)
hpFill.Parent           = hpBg
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0,8)

local hpLabel = Instance.new("TextLabel")
hpLabel.Size             = UDim2.new(1,0,0,20)
hpLabel.Position         = UDim2.new(0,0,1,2)
hpLabel.BackgroundTransparency = 1
hpLabel.TextColor3       = Color3.new(0.8,0.8,0.8)
hpLabel.Font             = Enum.Font.Gotham
hpLabel.TextScaled       = true
hpLabel.Text             = ""
hpLabel.Parent           = bossPanel

-- Timer
local timerLabel = Instance.new("TextLabel")
timerLabel.Size             = UDim2.new(0,100,0,24)
timerLabel.Position         = UDim2.new(1,-105,0,4)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3       = Color3.fromRGB(255,160,60)
timerLabel.Font             = Enum.Font.GothamBold
timerLabel.TextScaled       = true
timerLabel.Text             = ""
timerLabel.Parent           = bossPanel

-- Attack button (bottom-right when boss active)
local attackBtn = Instance.new("TextButton")
attackBtn.Size             = UDim2.new(0,180,0,60)
attackBtn.Position         = UDim2.new(1,-192,1,-72)
attackBtn.BackgroundColor3 = Color3.fromRGB(200,30,30)
attackBtn.TextColor3       = Color3.new(1,1,1)
attackBtn.Font             = Enum.Font.GothamBold
attackBtn.TextScaled       = true
attackBtn.Text             = "⚔ ATTACK!"
attackBtn.Visible          = false
attackBtn.Parent           = screen
Instance.new("UICorner", attackBtn).CornerRadius = UDim.new(0,12)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function updateHUD(state)
	bossState = state

	if not state.active then
		bossPanel.Visible  = false
		attackBtn.Visible  = false
		return
	end

	bossPanel.Visible  = true
	attackBtn.Visible  = true

	local color = state.color or Color3.fromRGB(200,40,40)
	bossNameLabel.Text      = "⚔ " .. (state.name or "World Boss")
	bossNameLabel.TextColor3 = state.glowColor or color

	local hpPct = math.max(0, (state.hp or 0) / math.max(state.maxHp or 1, 1))
	TweenService:Create(hpFill, TweenInfo.new(0.3),
		{ Size = UDim2.new(hpPct, 0, 1, 0), BackgroundColor3 = color }):Play()
	hpLabel.Text = math.floor(state.hp or 0) .. " / " .. math.floor(state.maxHp or 0) .. " HP"

	local stroke = bossPanel:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", bossPanel)
	stroke.Color     = state.glowColor or color
	stroke.Thickness = 2
end

-- ── Countdown ticker ──────────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(1)
		if bossState.active and bossState.endsAt then
			local rem = math.max(0, bossState.endsAt - os.time())
			local m = math.floor(rem / 60)
			local s = rem % 60
			timerLabel.Text = string.format("%d:%02d", m, s)
			if rem == 0 then
				bossState.active = false
				updateHUD(bossState)
			end
		else
			timerLabel.Text = ""
		end
	end
end)

-- ── Attack ────────────────────────────────────────────────────────────────────
local attackCooldown = false

attackBtn.MouseButton1Click:Connect(function()
	if attackCooldown or not bossState.active then return end
	attackCooldown = true
	remotes.AttackBoss:FireServer()

	-- Visual flash
	local orig = attackBtn.BackgroundColor3
	attackBtn.BackgroundColor3 = Color3.fromRGB(255,200,0)
	task.delay(0.2, function() attackBtn.BackgroundColor3 = orig end)

	task.delay(2, function() attackCooldown = false end)
end)

-- ── Remote listeners ──────────────────────────────────────────────────────────

remotes.BossUpdate.OnClientEvent:Connect(function(state)
	updateHUD(state)
end)

-- Fetch initial state
task.spawn(function()
	task.wait(3)
	local ok, state = pcall(function() return remotes.GetBossState:InvokeServer() end)
	if ok and state then updateHUD(state) end
end)
