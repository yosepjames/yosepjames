-- Daily quests: 3 random quests per player, reset every 24 h UTC midnight
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestData  = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("QuestData"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local remotes    = ReplicatedStorage:WaitForChild("Remotes")
local DataService -- injected

local QuestService = {}

-- Returns today's UTC day number (days since epoch) for reset comparison
local function todayKey()
	return math.floor(os.time() / 86400)
end

local function pickQuests()
	local templates = QuestData.Templates
	local picks     = {}
	local used      = {}
	while #picks < QuestData.DAILY_COUNT do
		local idx = math.random(1, #templates)
		if not used[idx] then
			used[idx] = true
			local t    = templates[idx]
			local tier = t.tiers[math.random(1, #t.tiers)]
			table.insert(picks, {
				id       = t.id .. "_" .. #picks,
				templateId = t.id,
				stat     = t.stat,
				text     = string.format(t.textFmt, tier.target),
				target   = tier.target,
				reward   = tier.reward,
				progress = 0,
				claimed  = false,
			})
		end
	end
	return picks
end

local function ensureQuests(data)
	local today = todayKey()
	if data.questDay ~= today then
		data.questDay    = today
		data.quests      = pickQuests()
		data.stats.coinsFromPets      = data.stats.coinsFromPets or 0
		data.stats.territoriesCaptured = data.stats.territoriesCaptured or 0
		data.stats.petsSold            = data.stats.petsSold or 0
		data.stats.tradeBuys           = data.stats.tradeBuys or 0
	end
end

local function pushQuests(player)
	local data = DataService.Get(player)
	if not data then return end
	ensureQuests(data)
	remotes.QuestUpdate:FireClient(player, data.quests)
end

-- Advance quest progress for a given stat
function QuestService.Advance(player, stat, amount)
	local data = DataService.Get(player)
	if not data then return end
	ensureQuests(data)

	local changed = false
	for _, quest in ipairs(data.quests) do
		if quest.stat == stat and not quest.claimed and quest.progress < quest.target then
			quest.progress = math.min(quest.target, quest.progress + (amount or 1))
			changed = true
		end
	end

	if changed then
		remotes.QuestUpdate:FireClient(player, data.quests)
	end
end

local function handleClaim(player, questId)
	local data = DataService.Get(player)
	if not data then return end
	ensureQuests(data)

	for _, quest in ipairs(data.quests) do
		if quest.id == questId then
			if quest.claimed then
				remotes.Notification:FireClient(player, {
					text = "Quest already claimed!", color = Color3.fromRGB(255,160,0)
				})
				return
			end
			if quest.progress < quest.target then
				remotes.Notification:FireClient(player, {
					text = "Quest not complete yet!", color = Color3.fromRGB(255,80,80)
				})
				return
			end

			quest.claimed = true
			local r = quest.reward
			if r.coins      then DataService.AdjustCoins(player, r.coins) end
			if r.gems       then DataService.AdjustGems(player, r.gems) end
			if r.luckTokens then
				data.luckTokens = (data.luckTokens or 0) + r.luckTokens
				remotes.LuckTokenUpdate:FireClient(player, data.luckTokens)
			end

			local rewardText = ""
			if r.coins      then rewardText ..= r.coins .. " coins " end
			if r.gems       then rewardText ..= r.gems  .. " 💎 " end
			if r.luckTokens then rewardText ..= r.luckTokens .. " Lucky Token!" end

			remotes.Notification:FireClient(player, {
				text  = "Quest complete! +" .. rewardText,
				color = Color3.fromRGB(100, 255, 100),
			})
			remotes.QuestUpdate:FireClient(player, data.quests)
			return
		end
	end
end

function QuestService.Init(ds)
	DataService = ds

	remotes.ClaimQuest.OnServerEvent:Connect(handleClaim)

	remotes.GetQuests.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then return {} end
		ensureQuests(data)
		return data.quests
	end

	Players.PlayerAdded:Connect(function(player)
		task.wait(3)  -- let data load
		pushQuests(player)
	end)
end

return QuestService
