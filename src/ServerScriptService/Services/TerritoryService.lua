-- Manages territory capture, ownership, and coin bonuses
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TerritoryData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TerritoryData"))
local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataService        -- injected
local QuestService       -- injected
local AchievementService -- injected

-- Runtime state
-- territoryState[id] = { owner = userId | nil, progress = { [userId] = seconds } }
local territoryState = {}

for id in pairs(TerritoryData.Territories) do
	territoryState[id] = { owner = nil, progress = {} }
end

-- Which territory each player is currently inside
local playerZone = {}  -- [userId] = territoryId | nil

local TerritoryService = {}

local function broadcastState()
	-- Build a clean snapshot for clients
	local snapshot = {}
	for id, state in pairs(territoryState) do
		local ownerName = nil
		if state.owner then
			local p = Players:GetPlayerByUserId(state.owner)
			ownerName = p and p.Name or "Unknown"
		end
		snapshot[id] = {
			owner       = state.owner,
			ownerName   = ownerName,
			progress    = state.progress,
		}
	end
	remotes.TerritoryUpdated:FireAllClients(snapshot)
end

-- Capture tick: every second, advance progress for players standing in zones
local function captureTick()
	local changed = false

	for id, tdata in pairs(TerritoryData.Territories) do
		local state = territoryState[id]

		-- Find players in this zone
		local playersInZone = {}
		for userId, zoneId in pairs(playerZone) do
			if zoneId == id then
				table.insert(playersInZone, userId)
			end
		end

		if #playersInZone == 0 then
			-- Decay capture progress for contested zones
			for userId in pairs(state.progress) do
				if userId ~= state.owner then
					state.progress[userId] = nil
					changed = true
				end
			end
			continue
		end

		-- If already owned by the only player here, do nothing
		if #playersInZone == 1 and state.owner == playersInZone[1] then
			continue
		end

		-- Advance progress
		for _, userId in ipairs(playersInZone) do
			if userId ~= state.owner then
				state.progress[userId] = (state.progress[userId] or 0) + 1

				if state.progress[userId] >= tdata.captureTime then
					state.owner    = userId
					state.progress = {}
					changed        = true

					local player = Players:GetPlayerByUserId(userId)
					if player then
						remotes.Notification:FireClient(player, {
							text  = "You captured " .. tdata.name .. "! +" .. tdata.coinBonusPercent .. "% coins!",
							color = tdata.color,
						})
						-- Advance quest + achievement stats
						local data = DataService.Get(player)
						if data then
							data.stats.territoriesCaptured = (data.stats.territoriesCaptured or 0) + 1
						end
						if QuestService       then QuestService.Advance(player, "territoriesCaptured", 1) end
						if AchievementService then AchievementService.Check(player) end
					end
				end
			end
		end

		changed = true
	end

	if changed then broadcastState() end
end

-- Coin bonus tick (every TERRITORY_TICK_INTERVAL seconds)
function TerritoryService.BonusTick()
	for id, state in pairs(territoryState) do
		if not state.owner then continue end
		local player = Players:GetPlayerByUserId(state.owner)
		if not player then
			state.owner = nil -- owner left; unclaim
			broadcastState()
			continue
		end

		local tdata = TerritoryData.Get(id)
		local data  = DataService.Get(player)
		if not data then continue end

		-- Calculate bonus as percent of current coins (floored at 10)
		local bonusCoins = math.max(10, math.floor(data.coins * tdata.coinBonusPercent / 100))
		DataService.AdjustCoins(player, bonusCoins)

		remotes.Notification:FireClient(player, {
			text  = tdata.name .. " bonus: +" .. bonusCoins .. " coins!",
			color = tdata.color,
		})
	end
end

-- ── Remote handlers ───────────────────────────────────────────────────────────

local function handleEnterZone(player, territoryId)
	if not TerritoryData.Get(territoryId) then return end
	playerZone[player.UserId] = territoryId
end

local function handleLeaveZone(player, territoryId)
	if playerZone[player.UserId] == territoryId then
		playerZone[player.UserId] = nil
	end
end

Players.PlayerRemoving:Connect(function(player)
	playerZone[player.UserId] = nil
	-- Unclaim any territory this player owned
	for _, state in pairs(territoryState) do
		if state.owner == player.UserId then
			state.owner = nil
			broadcastState()
		end
	end
end)

-- ── Init ──────────────────────────────────────────────────────────────────────

function TerritoryService.Init(ds, qs, as)
	DataService        = ds
	QuestService       = qs
	AchievementService = as

	remotes.EnterZone.OnServerEvent:Connect(handleEnterZone)
	remotes.LeaveZone.OnServerEvent:Connect(handleLeaveZone)

	remotes.GetTerritoryState.OnServerInvoke = function()
		local snapshot = {}
		for id, state in pairs(territoryState) do
			local ownerName = nil
			if state.owner then
				local p = Players:GetPlayerByUserId(state.owner)
				ownerName = p and p.Name or "Unknown"
			end
			snapshot[id] = { owner = state.owner, ownerName = ownerName, progress = state.progress }
		end
		return snapshot
	end

	-- Capture tick every second
	task.spawn(function()
		while true do
			task.wait(1)
			captureTick()
		end
	end)
end

return TerritoryService
