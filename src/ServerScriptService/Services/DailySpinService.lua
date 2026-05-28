-- Daily Spin Wheel: one free spin per 24 hours with weighted prizes
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local remotes    = ReplicatedStorage:WaitForChild("Remotes")
local DataService -- injected

local DailySpinService = {}

-- Prize table
local PRIZES = {
	{ weight = 28, type = "coins",  value = 500,        label = "500 🪙",         color = Color3.fromRGB(255, 220, 60)  },
	{ weight = 18, type = "coins",  value = 2_000,      label = "2,000 🪙",       color = Color3.fromRGB(255, 180, 0)   },
	{ weight = 10, type = "coins",  value = 10_000,     label = "10,000 🪙",      color = Color3.fromRGB(255, 140, 0)   },
	{ weight = 16, type = "gems",   value = 5,           label = "5 💎",            color = Color3.fromRGB(80, 160, 255)  },
	{ weight = 8,  type = "gems",   value = 20,          label = "20 💎",           color = Color3.fromRGB(60, 220, 255)  },
	{ weight = 5,  type = "gems",   value = 80,          label = "80 💎",           color = Color3.fromRGB(30, 255, 200)  },
	{ weight = 10, type = "luck",   value = 1,           label = "Lucky Token ✨",  color = Color3.fromRGB(255, 80, 200)  },
	{ weight = 4,  type = "luck",   value = 3,           label = "3 Lucky Tokens!", color = Color3.fromRGB(255, 30, 150)  },
	{ weight = 1,  type = "shinyEgg", value = "magic_egg", label = "✨ Shiny Egg!", color = Color3.fromRGB(255, 215, 0) },
}

local TOTAL_WEIGHT = (function()
	local s = 0
	for _, p in ipairs(PRIZES) do s += p.weight end
	return s
end)()

local function rollPrize()
	local r = math.random(1, TOTAL_WEIGHT)
	local c = 0
	for i, p in ipairs(PRIZES) do
		c += p.weight
		if r <= c then return p, i end
	end
	return PRIZES[1], 1
end

local function handleSpin(player)
	local data = DataService.Get(player)
	if not data then return false end

	local now      = os.time()
	local lastSpin = data.lastDailySpin or 0

	if now - lastSpin < GameConfig.DAILY_SPIN_COOLDOWN then
		local remaining = GameConfig.DAILY_SPIN_COOLDOWN - (now - lastSpin)
		return { error = true, remaining = remaining }
	end

	data.lastDailySpin = now

	local prize, prizeIndex = rollPrize()

	if prize.type == "coins" then
		DataService.AdjustCoins(player, prize.value)
	elseif prize.type == "gems" then
		DataService.AdjustGems(player, prize.value)
	elseif prize.type == "luck" then
		data.luckTokens = (data.luckTokens or 0) + prize.value
		remotes.LuckTokenUpdate:FireClient(player, data.luckTokens)
	elseif prize.type == "shinyEgg" then
		-- Grant lucky tokens as proxy (egg opening handled normally but with boosted luck)
		data.luckTokens = (data.luckTokens or 0) + 5
		remotes.LuckTokenUpdate:FireClient(player, data.luckTokens)
	end

	remotes.Notification:FireClient(player, {
		text  = "Daily Spin: You won " .. prize.label .. "!",
		color = prize.color,
	})

	return {
		prize      = prize,
		prizeIndex = prizeIndex,
		prizes     = PRIZES,
		nextSpin   = now + GameConfig.DAILY_SPIN_COOLDOWN,
	}
end

local function handleActivateLuck(player)
	local data = DataService.Get(player)
	if not data or (data.luckTokens or 0) < 1 then
		remotes.Notification:FireClient(player, { text = "No Lucky Tokens!", color = Color3.fromRGB(255,80,80) })
		return false
	end

	data.luckTokens     -= 1
	data.activeLuckUntil = os.time() + GameConfig.LUCK_TOKEN_DURATION
	remotes.LuckTokenUpdate:FireClient(player, data.luckTokens)
	remotes.LuckAuraUpdate:FireClient(player, { active = true, expiresAt = data.activeLuckUntil })
	remotes.Notification:FireClient(player, {
		text  = "✨ Lucky Aura active for " .. (GameConfig.LUCK_TOKEN_DURATION/60) .. " minutes!",
		color = Color3.fromRGB(255, 215, 0),
	})
	return true
end

function DailySpinService.HasActiveLuck(player)
	local data = DataService.Get(player)
	return data and (data.activeLuckUntil or 0) > os.time()
end

function DailySpinService.Init(ds)
	DataService = ds

	remotes.ClaimDailySpin.OnServerInvoke  = handleSpin
	remotes.ActivateLuckToken.OnServerEvent:Connect(handleActivateLuck)

	remotes.GetSpinInfo.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then return {} end
		local now      = os.time()
		local lastSpin = data.lastDailySpin or 0
		return {
			luckTokens   = data.luckTokens or 0,
			nextSpin     = lastSpin + GameConfig.DAILY_SPIN_COOLDOWN,
			prizes       = PRIZES,
			activeLuckUntil = data.activeLuckUntil or 0,
		}
	end
end

return DailySpinService
