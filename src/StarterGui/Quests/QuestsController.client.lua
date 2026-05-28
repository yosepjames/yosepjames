-- Daily Quests panel: shows 3 quests with progress bars and claim buttons
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local questsCache = {}

-- ── Build UI ──────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "QuestsGui"
screen.ResetOnSpawn   = false
screen.Enabled        = false
screen.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1,0,1,0)
backdrop.BackgroundColor3 = Color3.new(0,0,0)
backdrop.BackgroundTransparency = 0.5
backdrop.Parent           = screen

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0,480,0,460)
panel.Position         = UDim2.new(0.5,-240,0.5,-230)
panel.BackgroundColor3 = Color3.fromRGB(18,22,18)
panel.Parent           = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke")
stroke.Color     = Color3.fromRGB(60,200,60)
stroke.Thickness = 2
stroke.Parent    = panel

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1,0,0,54)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(100,255,100)
title.Font             = Enum.Font.GothamBold
title.TextScaled       = true
title.Text             = "📋 Daily Quests"
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

local resetLabel = Instance.new("TextLabel")
resetLabel.Size             = UDim2.new(1,-20,0,26)
resetLabel.Position         = UDim2.new(0,10,0,56)
resetLabel.BackgroundTransparency = 1
resetLabel.TextColor3       = Color3.new(0.5,0.5,0.5)
resetLabel.Font             = Enum.Font.Gotham
resetLabel.TextScaled       = true
resetLabel.Text             = "Resets daily at midnight UTC"
resetLabel.Parent           = panel

local questContainer = Instance.new("Frame")
questContainer.Size             = UDim2.new(1,-20,1,-94)
questContainer.Position         = UDim2.new(0,10,0,88)
questContainer.BackgroundTransparency = 1
questContainer.Parent           = panel

local layout = Instance.new("UIListLayout")
layout.Padding   = UDim.new(0,10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent    = questContainer

-- ── Quest card builder ────────────────────────────────────────────────────────

local questCards = {}

local function buildQuestCard(quest, order)
	if questCards[quest.id] then questCards[quest.id]:Destroy() end

	local card = Instance.new("Frame")
	card.Size             = UDim2.new(1,0,0,108)
	card.BackgroundColor3 = Color3.fromRGB(24,30,24)
	card.LayoutOrder      = order
	card.Parent           = questContainer
	Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)

	local questText = Instance.new("TextLabel")
	questText.Size             = UDim2.new(1,-10,0,28)
	questText.Position         = UDim2.new(0,8,0,6)
	questText.BackgroundTransparency = 1
	questText.TextColor3       = Color3.new(1,1,1)
	questText.Font             = Enum.Font.GothamBold
	questText.TextScaled       = true
	questText.TextXAlignment   = Enum.TextXAlignment.Left
	questText.Text             = quest.text
	questText.Parent           = card

	-- Progress bar
	local progBg = Instance.new("Frame")
	progBg.Size             = UDim2.new(1,-16,0,14)
	progBg.Position         = UDim2.new(0,8,0,38)
	progBg.BackgroundColor3 = Color3.fromRGB(40,50,40)
	progBg.Parent           = card
	Instance.new("UICorner", progBg).CornerRadius = UDim.new(0,6)

	local pct = math.min(1, quest.progress / math.max(quest.target, 1))
	local progFill = Instance.new("Frame")
	progFill.Size             = UDim2.new(pct,0,1,0)
	progFill.BackgroundColor3 = quest.claimed
		and Color3.fromRGB(40,120,40) or Color3.fromRGB(80,200,80)
	progFill.Parent           = progBg
	Instance.new("UICorner", progFill).CornerRadius = UDim.new(0,6)

	local progLabel = Instance.new("TextLabel")
	progLabel.Size             = UDim2.new(1,0,0,14)
	progLabel.Position         = UDim2.new(0,0,0,56)
	progLabel.BackgroundTransparency = 1
	progLabel.TextColor3       = Color3.new(0.7,0.7,0.7)
	progLabel.Font             = Enum.Font.Gotham
	progLabel.TextScaled       = true
	progLabel.Text             = quest.progress .. " / " .. quest.target
	progLabel.Parent           = card

	-- Reward text
	local rewardText = ""
	local r = quest.reward or {}
	if r.coins      then rewardText ..= r.coins .. " 🪙 " end
	if r.gems       then rewardText ..= r.gems  .. " 💎 " end
	if r.luckTokens then rewardText ..= r.luckTokens .. " ✨ token " end

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size             = UDim2.new(0.6,0,0,22)
	rewardLabel.Position         = UDim2.new(0,8,1,-28)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.TextColor3       = Color3.fromRGB(255,220,60)
	rewardLabel.Font             = Enum.Font.Gotham
	rewardLabel.TextScaled       = true
	rewardLabel.TextXAlignment   = Enum.TextXAlignment.Left
	rewardLabel.Text             = "Reward: " .. rewardText
	rewardLabel.Parent           = card

	-- Claim button
	local claimBtn = Instance.new("TextButton")
	claimBtn.Size             = UDim2.new(0,110,0,28)
	claimBtn.Position         = UDim2.new(1,-118,1,-32)
	claimBtn.Font             = Enum.Font.GothamBold
	claimBtn.TextScaled       = true
	claimBtn.Parent           = card
	Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0,6)

	if quest.claimed then
		claimBtn.BackgroundColor3 = Color3.fromRGB(40,70,40)
		claimBtn.TextColor3       = Color3.fromRGB(80,180,80)
		claimBtn.Text             = "✓ Claimed"
		claimBtn.Active           = false
	elseif quest.progress >= quest.target then
		claimBtn.BackgroundColor3 = Color3.fromRGB(60,160,60)
		claimBtn.TextColor3       = Color3.new(1,1,1)
		claimBtn.Text             = "Claim!"
		claimBtn.Active           = true
		claimBtn.MouseButton1Click:Connect(function()
			remotes.ClaimQuest:FireServer(quest.id)
		end)
	else
		claimBtn.BackgroundColor3 = Color3.fromRGB(40,50,40)
		claimBtn.TextColor3       = Color3.new(0.5,0.5,0.5)
		claimBtn.Text             = "Incomplete"
		claimBtn.Active           = false
	end

	questCards[quest.id] = card
end

local function refreshQuests()
	for _, c in pairs(questCards) do c:Destroy() end
	questCards = {}
	for i, quest in ipairs(questsCache) do
		buildQuestCard(quest, i)
	end
end

-- ── Remote listeners ──────────────────────────────────────────────────────────

remotes.QuestUpdate.OnClientEvent:Connect(function(quests)
	questsCache = quests
	if screen.Enabled then refreshQuests() end
end)

screen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screen.Enabled then return end
	task.spawn(function()
		local ok, quests = pcall(function() return remotes.GetQuests:InvokeServer() end)
		if ok and quests then
			questsCache = quests
			refreshQuests()
		end
	end)
end)

-- ── Toggle button ─────────────────────────────────────────────────────────────
local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "QuestsToggle"
masterGui.ResetOnSpawn   = false
masterGui.Parent         = playerGui

local questToggle = Instance.new("TextButton")
questToggle.Size             = UDim2.new(0,120,0,46)
questToggle.Position         = UDim2.new(0.5,220,1,-60)
questToggle.BackgroundColor3 = Color3.fromRGB(30,80,30)
questToggle.TextColor3       = Color3.new(1,1,1)
questToggle.Font             = Enum.Font.GothamBold
questToggle.TextScaled       = true
questToggle.Text             = "📋 Quests"
questToggle.Parent           = masterGui
Instance.new("UICorner", questToggle).CornerRadius = UDim.new(0,10)
questToggle.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)
