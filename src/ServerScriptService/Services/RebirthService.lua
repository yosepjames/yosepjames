-- Prestige/Rebirth system: spend coins for a permanent multiplier
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local remotes    = ReplicatedStorage:WaitForChild("Remotes")
local DataService -- injected

local RebirthService = {}

local function rebirthCost(currentRebirth)
	return math.floor(GameConfig.REBIRTH_BASE_COST * (GameConfig.REBIRTH_COST_SCALE ^ currentRebirth))
end

local function notify(player, text, color)
	remotes.Notification:FireClient(player, { text = text, color = color or Color3.new(1, 1, 1) })
end

local function handleRebirth(player)
	local data = DataService.Get(player)
	if not data then return false end

	local needed = rebirthCost(data.rebirth or 0)
	if data.coins < needed then
		notify(player, "Need " .. needed .. " coins to Rebirth!", Color3.fromRGB(255, 80, 80))
		return false
	end

	data.coins   = 0  -- reset coins
	data.rebirth = (data.rebirth or 0) + 1
	data.rebirthMultiplier = 1 + data.rebirth * GameConfig.REBIRTH_COIN_BONUS

	-- Flush coin display to 0
	remotes.CoinUpdate:FireClient(player, 0)

	-- Broadcast rebirth update
	remotes.RebirthUpdate:FireClient(player, {
		rebirth    = data.rebirth,
		multiplier = data.rebirthMultiplier,
		nextCost   = rebirthCost(data.rebirth),
	})

	notify(player,
		"⭐ Rebirth " .. data.rebirth .. "! Coins ×" .. string.format("%.2f", data.rebirthMultiplier),
		Color3.fromRGB(255, 215, 0))

	return {
		rebirth    = data.rebirth,
		multiplier = data.rebirthMultiplier,
		nextCost   = rebirthCost(data.rebirth),
	}
end

function RebirthService.GetCost(player)
	local data = DataService.Get(player)
	return rebirthCost(data and data.rebirth or 0)
end

-- Apply rebirth multiplier to a coin amount
function RebirthService.ApplyMultiplier(player, baseCoins)
	local data = DataService.Get(player)
	local mult = data and (data.rebirthMultiplier or 1) or 1
	return math.floor(baseCoins * mult)
end

function RebirthService.Init(ds)
	DataService = ds

	remotes.Rebirth.OnServerInvoke = handleRebirth

	remotes.GetRebirthInfo.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then return {} end
		return {
			rebirth    = data.rebirth or 0,
			multiplier = data.rebirthMultiplier or 1,
			nextCost   = rebirthCost(data.rebirth or 0),
		}
	end
end

return RebirthService
