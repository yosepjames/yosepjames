-- Server-side leaderboard: top players by rebirth, all-time coins, and pets owned
-- In-server ranking updates every 60 s; global ranking via OrderedDataStore
local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes    = ReplicatedStorage:WaitForChild("Remotes")
local DataService -- injected

-- OrderedDataStores for global persistence
local rebirthLB  = DataStoreService:GetOrderedDataStore("LB_Rebirth_v1")
local coinsLB    = DataStoreService:GetOrderedDataStore("LB_Coins_v1")
local petsLB     = DataStoreService:GetOrderedDataStore("LB_Pets_v1")

local LeaderboardService = {}

-- ── Save player scores to OrderedDataStore ────────────────────────────────────

local function saveScores(player)
	local data = DataService.Get(player)
	if not data then return end

	local uid = tostring(player.UserId)
	pcall(function() rebirthLB:SetAsync(uid, data.rebirth or 0) end)
	pcall(function() coinsLB:SetAsync(uid, data.stats.totalCoinsEarned or 0) end)
	pcall(function() petsLB:SetAsync(uid, data.stats.petsOwned or 0) end)
end

-- ── Fetch global top 10 ───────────────────────────────────────────────────────

local function fetchTop10(store)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 10)
	end)
	if not ok then return {} end

	local ok2, data = pcall(function() return pages:GetCurrentPage() end)
	if not ok2 then return {} end

	local results = {}
	for rank, entry in ipairs(data) do
		local name = "Player"
		-- Try to resolve name from currently online players first
		local onlinePlayer = Players:GetPlayerByUserId(tonumber(entry.key))
		if onlinePlayer then
			name = onlinePlayer.Name
		else
			-- Attempt Players:GetNameFromUserIdAsync (may yield, wrapped in pcall)
			local nameOk, resolved = pcall(function()
				return Players:GetNameFromUserIdAsync(tonumber(entry.key))
			end)
			if nameOk then name = resolved end
		end

		table.insert(results, {
			rank  = rank,
			name  = name,
			value = entry.value,
		})
	end
	return results
end

-- ── Build combined snapshot ───────────────────────────────────────────────────

local cachedSnapshot = {}

local function buildSnapshot()
	cachedSnapshot = {
		rebirth = fetchTop10(rebirthLB),
		coins   = fetchTop10(coinsLB),
		pets    = fetchTop10(petsLB),
	}
	remotes.LeaderboardUpdate:FireAllClients(cachedSnapshot)
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function LeaderboardService.SavePlayer(player)
	saveScores(player)
end

function LeaderboardService.Init(ds)
	DataService = ds

	remotes.GetLeaderboard.OnServerInvoke = function()
		return cachedSnapshot
	end

	-- Save scores periodically and refresh board
	task.spawn(function()
		task.wait(30) -- initial warm-up
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				saveScores(player)
			end
			buildSnapshot()
			task.wait(60)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveScores(player)
	end)
end

return LeaderboardService
