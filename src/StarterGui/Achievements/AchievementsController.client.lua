-- Achievement panel + title display above OTHER players' heads
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Track titles for all players ──────────────────────────────────────────────
-- (own title shown by PetFollowController above head; here we wire ALL players)
local playerTitles = {}  -- [userId] = { title, titleColor }

local function applyTitleBillboard(targetPlayer, title, titleColor)
	local character = targetPlayer.Character
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	local existing = head:FindFirstChild("TitleBillboard")
	if existing then existing:Destroy() end
	if not title then return end

	local bb = Instance.new("BillboardGui")
	bb.Name        = "TitleBillboard"
	bb.Size        = UDim2.new(0, 160, 0, 28)
	bb.StudsOffset = Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = head

	local lbl = Instance.new("TextLabel")
	lbl.Size             = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font             = Enum.Font.GothamBold
	lbl.TextScaled       = true
	lbl.TextColor3       = titleColor or Color3.fromRGB(255, 215, 0)
	lbl.TextStrokeTransparency = 0.4
	lbl.Text             = title
	lbl.Parent           = bb
end

remotes.PlayerTitleUpdate.OnClientEvent:Connect(function(payload)
	if not payload.userId then return end
	local titleColor = payload.titleColor

	playerTitles[payload.userId] = payload.title and {
		title      = payload.title,
		titleColor = titleColor,
	} or nil

	local targetPlayer = Players:GetPlayerByUserId(payload.userId)
	if targetPlayer then
		applyTitleBillboard(targetPlayer, payload.title, titleColor)
	end
end)

-- Reapply when character respawns
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(1)
		local info = playerTitles[p.UserId]
		if info then applyTitleBillboard(p, info.title, info.titleColor) end
	end)
end)

-- ── Achievement Panel ─────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "AchievementsGui"
screen.ResetOnSpawn   = false
screen.Enabled        = false
screen.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1,0,1,0)
backdrop.BackgroundColor3 = Color3.new(0,0,0)
backdrop.BackgroundTransparency = 0.5
backdrop.Parent           = screen

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0,640,0,540)
panel.Position         = UDim2.new(0.5,-320,0.5,-270)
panel.BackgroundColor3 = Color3.fromRGB(14,18,14)
panel.Parent           = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,14)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255,215,0) ; stroke.Thickness = 2 ; stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1,0,0,52)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(255,215,0)
title.Font             = Enum.Font.GothamBold
title.TextScaled       = true
title.Text             = "🏆 Achievements"
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

local scroll = Instance.new("ScrollingFrame")
scroll.Size             = UDim2.new(1,-16,1,-60)
scroll.Position         = UDim2.new(0,8,0,56)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.Parent           = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding   = UDim.new(0,8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent    = scroll

-- ── Build achievement rows ────────────────────────────────────────────────────

local function buildRows(allAchievements, unlocked)
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for i, a in ipairs(allAchievements) do
		local done = unlocked[a.id] == true

		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1,0,0,64)
		row.BackgroundColor3 = done
			and Color3.fromRGB(20,40,20) or Color3.fromRGB(22,22,28)
		row.LayoutOrder      = i
		row.Parent           = scroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

		-- Icon / checkmark
		local icon = Instance.new("TextLabel")
		icon.Size             = UDim2.new(0,44,0,44)
		icon.Position         = UDim2.new(0,10,0.5,-22)
		icon.BackgroundColor3 = done
			and Color3.fromRGB(40,120,40) or Color3.fromRGB(40,40,50)
		icon.TextColor3       = Color3.new(1,1,1)
		icon.Font             = Enum.Font.GothamBold
		icon.TextScaled       = true
		icon.Text             = done and "✓" or "?"
		icon.Parent           = row
		Instance.new("UICorner", icon).CornerRadius = UDim.new(0,8)

		local nameL = Instance.new("TextLabel")
		nameL.Size             = UDim2.new(0.6,0,0,24)
		nameL.Position         = UDim2.new(0,62,0,8)
		nameL.BackgroundTransparency = 1
		nameL.TextColor3       = done and Color3.fromRGB(100,255,100) or Color3.new(0.7,0.7,0.7)
		nameL.Font             = Enum.Font.GothamBold
		nameL.TextScaled       = true
		nameL.TextXAlignment   = Enum.TextXAlignment.Left
		nameL.Text             = a.name
		nameL.Parent           = row

		local descL = Instance.new("TextLabel")
		descL.Size             = UDim2.new(0.6,0,0,20)
		descL.Position         = UDim2.new(0,62,0,32)
		descL.BackgroundTransparency = 1
		descL.TextColor3       = Color3.new(0.5,0.5,0.5)
		descL.Font             = Enum.Font.Gotham
		descL.TextScaled       = true
		descL.TextXAlignment   = Enum.TextXAlignment.Left
		descL.Text             = a.desc
		descL.Parent           = row

		-- Reward label
		local rewardText = a.reward.gems and ("+" .. a.reward.gems .. " 💎") or ""
		local rewardL = Instance.new("TextLabel")
		rewardL.Size             = UDim2.new(0.32,0,1,0)
		rewardL.Position         = UDim2.new(0.68,0,0,0)
		rewardL.BackgroundTransparency = 1
		rewardL.TextColor3       = Color3.fromRGB(140,180,255)
		rewardL.Font             = Enum.Font.Gotham
		rewardL.TextScaled       = true
		rewardL.Text             = rewardText .. (a.title and "\n" .. a.title or "")
		rewardL.TextWrapped      = true
		rewardL.Parent           = row
	end

	-- Adjust canvas size
	scroll.CanvasSize = UDim2.new(0, 0, 0, #allAchievements * 72)
end

-- ── Achievement unlock toast ──────────────────────────────────────────────────

local toastGui = Instance.new("ScreenGui")
toastGui.Name           = "AchievementToast"
toastGui.ResetOnSpawn   = false
toastGui.Parent         = playerGui

local toastFrame = Instance.new("Frame")
toastFrame.Size             = UDim2.new(0,380,0,70)
toastFrame.Position         = UDim2.new(0.5,-190,-0.02,0)
toastFrame.BackgroundColor3 = Color3.fromRGB(20,16,40)
toastFrame.BackgroundTransparency = 0.1
toastFrame.Parent           = toastGui
Instance.new("UICorner", toastFrame).CornerRadius = UDim.new(0,10)
local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(255,215,0) ; toastStroke.Thickness = 2 ; toastStroke.Parent = toastFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Size             = UDim2.new(1,-10,1,0)
toastLabel.Position         = UDim2.new(0,5,0,0)
toastLabel.BackgroundTransparency = 1
toastLabel.TextColor3       = Color3.fromRGB(255,215,0)
toastLabel.Font             = Enum.Font.GothamBold
toastLabel.TextScaled       = true
toastLabel.Text             = ""
toastLabel.Parent           = toastFrame

local toastQueue = {}
local toastShowing = false

local function showNextToast()
	if #toastQueue == 0 or toastShowing then return end
	toastShowing = true

	local achievement = table.remove(toastQueue, 1)
	toastLabel.Text = "🏆 " .. achievement.name .. "!\n" .. (achievement.title or "")

	-- Slide in
	TweenService:Create(toastFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back),
		{ Position = UDim2.new(0.5,-190,0.02,0) }):Play()
	task.wait(3)
	-- Slide out
	TweenService:Create(toastFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5,-190,-0.12,0) }):Play()
	task.wait(0.5)
	toastShowing = false
	showNextToast()
end

remotes.AchievementsUnlocked.OnClientEvent:Connect(function(newAchievements)
	for _, a in ipairs(newAchievements) do
		table.insert(toastQueue, a)
	end
	showNextToast()
end)

-- ── Fetch data when panel opens ───────────────────────────────────────────────

screen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screen.Enabled then return end
	task.spawn(function()
		local ok, result = pcall(function() return remotes.GetAchievements:InvokeServer() end)
		if ok and result then
			buildRows(result.all, result.unlocked)
		end
	end)
end)

-- ── Toggle button ─────────────────────────────────────────────────────────────
local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "AchievementsToggle"
masterGui.ResetOnSpawn   = false
masterGui.Parent         = playerGui

local achieveBtn = Instance.new("TextButton")
achieveBtn.Size             = UDim2.new(0,120,0,46)
achieveBtn.Position         = UDim2.new(0,12,0.5,30)
achieveBtn.BackgroundColor3 = Color3.fromRGB(60,50,10)
achieveBtn.TextColor3       = Color3.fromRGB(255,215,0)
achieveBtn.Font             = Enum.Font.GothamBold
achieveBtn.TextScaled       = true
achieveBtn.Text             = "🏆 Trophies"
achieveBtn.Parent           = masterGui
Instance.new("UICorner", achieveBtn).CornerRadius = UDim.new(0,10)
achieveBtn.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)
