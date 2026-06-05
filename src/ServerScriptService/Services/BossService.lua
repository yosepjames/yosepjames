-- World Boss: spawns every 30 min, all players attack together, shared reward
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossData   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("BossData"))
local PetData    = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local remotes    = ReplicatedStorage:WaitForChild("Remotes")
local DataService  -- injected
local QuestService -- injected

-- Runtime boss state
local bossState = {
	active        = false,
	boss          = nil,
	hp            = 0,
	maxHp         = 0,
	endsAt        = 0,
	contributions = {},  -- [userId] = totalDamage
}

local BossService = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function broadcastBossState()
	local snapshot = {
		active  = bossState.active,
		bossId  = bossState.boss and bossState.boss.id,
		name    = bossState.boss and bossState.boss.name,
		hp      = bossState.hp,
		maxHp   = bossState.maxHp,
		endsAt  = bossState.endsAt,
		color   = bossState.boss and bossState.boss.color,
		glowColor = bossState.boss and bossState.boss.glowColor,
	}
	remotes.BossUpdate:FireAllClients(snapshot)
end

local function getPlayerPower(player)
	local data = DataService.Get(player)
	if not data then return 0 end
	local total = 0
	for _, uid in ipairs(data.equipped) do
		for _, entry in ipairs(data.pets) do
			if entry.uid == uid then
				local pet = PetData.GetPet(entry.petId)
				if pet then
					local mult = entry.shiny and 2 or 1
					total += pet.power * entry.level * mult
				end
				break
			end
		end
	end
	return total
end

local function distributeRewards()
	local boss = bossState.boss
	if not boss then return end

	for userId, damage in pairs(bossState.contributions) do
		local player = Players:GetPlayerByUserId(userId)
		if not player then continue end

		local share = damage / math.max(bossState.maxHp, 1)
		local coins = math.floor(boss.rewardCoins * (0.5 + share * 0.5))  -- min 50% of reward
		local gems  = math.floor(boss.rewardGems  * (0.3 + share * 0.7))

		DataService.AdjustCoins(player, coins)
		DataService.AdjustGems(player, gems)

		-- Lucky egg bonus: roll per contributor based on their damage share
		local luckRoll = math.random()
		local data = DataService.Get(player)
		if data then
			data.stats.bossKills += 1
			if QuestService then QuestService.Advance(player, "bossKills", 1) end
		end
		if data and luckRoll < boss.luckyEggChance then
			data.luckTokens = (data.luckTokens or 0) + 1
			remotes.LuckTokenUpdate:FireClient(player, data.luckTokens)
			remotes.Notification:FireClient(player, {
				text  = "Boss reward: " .. coins .. " coins, " .. gems .. " 💎 + Lucky Token!",
				color = Color3.fromRGB(255, 215, 0),
			})
		else
			remotes.Notification:FireClient(player, {
				text  = "Boss reward: +" .. coins .. " coins, +" .. gems .. " 💎!",
				color = boss.glowColor,
			})
		end
	end
end

-- ── Spawn / despawn ───────────────────────────────────────────────────────────

local function spawnBoss()
	local boss   = BossData.Random()
	local players = Players:GetPlayers()
	local baseHp  = boss.baseHp + #players * BossData.HP_PER_PLAYER

	bossState = {
		active        = true,
		boss          = boss,
		hp            = baseHp,
		maxHp         = baseHp,
		endsAt        = os.time() + BossData.DURATION,
		contributions = {},
	}

	broadcastBossState()

	remotes.Notification:FireAllClients({
		text  = "⚔ World Boss appeared: " .. boss.name .. "! Attack now!",
		color = boss.glowColor,
	})

	-- Auto-expire after DURATION
	task.delay(BossData.DURATION, function()
		if bossState.active and bossState.hp > 0 then
			-- Boss survived
			remotes.Notification:FireAllClients({
				text  = boss.name .. " escaped! Not enough damage.",
				color = Color3.fromRGB(200, 60, 60),
			})
			bossState.active = false
			broadcastBossState()
		end
	end)
end

-- ── Attack handler ────────────────────────────────────────────────────────────

local attackCooldowns = {}  -- [userId] = lastAttackTime

local function handleAttackBoss(player)
	if not bossState.active then return end

	local now    = os.time()
	local lastAt = attackCooldowns[player.UserId] or 0
	if now - lastAt < GameConfig.BOSS_DAMAGE_TICK then return end
	attackCooldowns[player.UserId] = now

	local dmg = getPlayerPower(player)
	if dmg <= 0 then
		remotes.Notification:FireClient(player, {
			text = "Equip pets to deal damage!", color = Color3.fromRGB(255, 160, 0)
		})
		return
	end

	bossState.hp -= dmg
	bossState.contributions[player.UserId] = (bossState.contributions[player.UserId] or 0) + dmg

	broadcastBossState()

	if bossState.hp <= 0 then
		bossState.active = false
		broadcastBossState()

		remotes.Notification:FireAllClients({
			text  = "💥 " .. bossState.boss.name .. " defeated! Distributing rewards…",
			color = bossState.boss.glowColor,
		})

		distributeRewards()
	end
end

-- ── Main loop ─────────────────────────────────────────────────────────────────

function BossService.Init(ds, qs)
	DataService  = ds
	QuestService = qs

	remotes.AttackBoss.OnServerEvent:Connect(handleAttackBoss)

	remotes.GetBossState.OnServerInvoke = function()
		return {
			active  = bossState.active,
			bossId  = bossState.boss and bossState.boss.id,
			name    = bossState.boss and bossState.boss.name,
			hp      = bossState.hp,
			maxHp   = bossState.maxHp,
			endsAt  = bossState.endsAt,
			color   = bossState.boss and bossState.boss.color,
			glowColor = bossState.boss and bossState.boss.glowColor,
		}
	end

	-- Boss spawn loop
	task.spawn(function()
		task.wait(60)  -- short warm-up after server start
		while true do
			spawnBoss()
			task.wait(BossData.SPAWN_INTERVAL)
		end
	end)
end

return BossService
