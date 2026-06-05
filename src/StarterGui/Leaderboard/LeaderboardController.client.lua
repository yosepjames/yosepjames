-- Global leaderboard panel: top players by Rebirth, Coins, and Pets
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local lbCache = {}

-- ── Build UI ──────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "LeaderboardGui"
screen.ResetOnSpawn   = false
screen.Enabled        = false
screen.Parent         = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size             = UDim2.new(1,0,1,0)
backdrop.BackgroundColor3 = Color3.new(0,0,0)
backdrop.BackgroundTransparency = 0.5
backdrop.Parent           = screen

local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0,720,0,520)
panel.Position         = UDim2.new(0.5,-360,0.5,-260)
panel.BackgroundColor3 = Color3.fromRGB(12,14,22)
panel.Parent           = screen
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,14)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60,120,220) ; stroke.Thickness = 2 ; stroke.Parent = panel

local titleL = Instance.new("TextLabel")
titleL.Size             = UDim2.new(1,0,0,52)
titleL.BackgroundTransparency = 1
titleL.TextColor3       = Color3.fromRGB(100,180,255)
titleL.Font             = Enum.Font.GothamBold
titleL.TextScaled       = true
titleL.Text             = "🌍 Global Leaderboard"
titleL.Parent           = panel

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

-- Three columns
local CATEGORIES = {
	{ key = "rebirth", label = "⭐ Most Rebirths",   color = Color3.fromRGB(255,215,0)  },
	{ key = "coins",   label = "💰 Most Coins Earned", color = Color3.fromRGB(255,180,0)  },
	{ key = "pets",    label = "🐾 Most Pets Owned",   color = Color3.fromRGB(100,220,100) },
}

local columns = {}

for i, cat in ipairs(CATEGORIES) do
	local col = Instance.new("Frame")
	col.Size             = UDim2.new(0.32,0,1,-62)
	col.Position         = UDim2.new((i-1) * 0.34, i==1 and 6 or 0, 0, 58)
	col.BackgroundColor3 = Color3.fromRGB(16,18,28)
	col.Parent           = panel
	Instance.new("UICorner", col).CornerRadius = UDim.new(0,8)

	local header = Instance.new("TextLabel")
	header.Size             = UDim2.new(1,0,0,34)
	header.BackgroundTransparency = 1
	header.TextColor3       = cat.color
	header.Font             = Enum.Font.GothamBold
	header.TextScaled       = true
	header.Text             = cat.label
	header.Parent           = col

	local list = Instance.new("Frame")
	list.Size             = UDim2.new(1,-8,1,-40)
	list.Position         = UDim2.new(0,4,0,36)
	list.BackgroundTransparency = 1
	list.Parent           = col

	local layout = Instance.new("UIListLayout")
	layout.Padding   = UDim.new(0,4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent    = list

	columns[cat.key] = { list = list, color = cat.color }
end

local RANK_COLORS = {
	Color3.fromRGB(255,215,0),
	Color3.fromRGB(200,200,200),
	Color3.fromRGB(200,120,50),
}

local function buildColumn(key, entries)
	local col = columns[key]
	if not col then return end

	for _, child in ipairs(col.list:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if not entries or #entries == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size             = UDim2.new(1,0,0,30)
		empty.BackgroundTransparency = 1
		empty.TextColor3       = Color3.new(0.4,0.4,0.4)
		empty.Font             = Enum.Font.Gotham
		empty.TextScaled       = true
		empty.Text             = "No data yet"
		empty.Parent           = col.list
		return
	end

	for i, entry in ipairs(entries) do
		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1,0,0,34)
		row.BackgroundColor3 = i <= 3
			and Color3.fromRGB(25,22,35) or Color3.fromRGB(18,18,24)
		row.LayoutOrder      = i
		row.Parent           = col.list
		Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

		local rankL = Instance.new("TextLabel")
		rankL.Size             = UDim2.new(0,28,1,0)
		rankL.BackgroundTransparency = 1
		rankL.TextColor3       = RANK_COLORS[i] or Color3.new(0.6,0.6,0.6)
		rankL.Font             = Enum.Font.GothamBold
		rankL.TextScaled       = true
		rankL.Text             = "#" .. i
		rankL.Parent           = row

		local nameL = Instance.new("TextLabel")
		nameL.Size             = UDim2.new(0.55,0,1,0)
		nameL.Position         = UDim2.new(0,30,0,0)
		nameL.BackgroundTransparency = 1
		nameL.TextColor3       = Color3.new(1,1,1)
		nameL.Font             = Enum.Font.Gotham
		nameL.TextScaled       = true
		nameL.TextXAlignment   = Enum.TextXAlignment.Left
		nameL.Text             = entry.name or "?"
		nameL.Parent           = row

		local valL = Instance.new("TextLabel")
		valL.Size             = UDim2.new(0.38,0,1,0)
		valL.Position         = UDim2.new(0.62,0,0,0)
		valL.BackgroundTransparency = 1
		valL.TextColor3       = col.color
		valL.Font             = Enum.Font.GothamBold
		valL.TextScaled       = true
		valL.TextXAlignment   = Enum.TextXAlignment.Right
		valL.Text             = tostring(entry.value or 0)
		valL.Parent           = row
	end
end

local function refreshAll(data)
	lbCache = data or {}
	for _, cat in ipairs(CATEGORIES) do
		buildColumn(cat.key, lbCache[cat.key])
	end
end

-- ── Remotes ───────────────────────────────────────────────────────────────────

remotes.LeaderboardUpdate.OnClientEvent:Connect(function(data)
	lbCache = data
	if screen.Enabled then refreshAll(data) end
end)

screen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screen.Enabled then return end
	task.spawn(function()
		local ok, data = pcall(function() return remotes.GetLeaderboard:InvokeServer() end)
		if ok and data then refreshAll(data) end
	end)
end)

-- ── Toggle ────────────────────────────────────────────────────────────────────
local masterGui = Instance.new("ScreenGui")
masterGui.Name           = "LeaderboardToggle"
masterGui.ResetOnSpawn   = false
masterGui.Parent         = playerGui

local lbBtn = Instance.new("TextButton")
lbBtn.Size             = UDim2.new(0,120,0,46)
lbBtn.Position         = UDim2.new(0,12,0.5,86)
lbBtn.BackgroundColor3 = Color3.fromRGB(15,30,60)
lbBtn.TextColor3       = Color3.fromRGB(80,180,255)
lbBtn.Font             = Enum.Font.GothamBold
lbBtn.TextScaled       = true
lbBtn.Text             = "🌍 Rankings"
lbBtn.Parent           = masterGui
Instance.new("UICorner", lbBtn).CornerRadius = UDim.new(0,10)
lbBtn.MouseButton1Click:Connect(function()
	screen.Enabled = not screen.Enabled
end)
