-- Drives the core game loop: Lobby → Starting → InRound → Intermission → repeat
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local GameState   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameState"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))

local remotes     = ReplicatedStorage:WaitForChild("Remotes")

-- Tracks which players are still alive this round
local alivePlayers = {}
local currentState = GameState.LOBBY

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function setState(state)
	currentState = state
	remotes.StateChanged:FireAllClients(state)
end

local function countdown(seconds, label)
	for t = seconds, 0, -1 do
		remotes.TimerUpdate:FireAllClients(t)
		if t > 0 then task.wait(1) end
	end
end

local function teleportToLobby(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		-- Replace with your actual lobby spawn CFrame
		root.CFrame = CFrame.new(0, 5, 0)
	end
end

local function teleportToMap(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Replace with real spawn points from the map
	local angle = math.random() * 2 * math.pi
	local radius = 20
	root.CFrame = CFrame.new(
		math.cos(angle) * radius,
		5,
		math.sin(angle) * radius
	)
end

local function resetCharacter(player)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
end

-- ── Round phases ─────────────────────────────────────────────────────────────

local function doLobby()
	setState(GameState.LOBBY)

	-- Wait until enough players join
	while #Players:GetPlayers() < GameConfig.MIN_PLAYERS do
		task.wait(1)
	end

	setState(GameState.STARTING)
	countdown(GameConfig.LOBBY_DURATION, "Starting in")
end

local function startRound()
	setState(GameState.IN_ROUND)
	alivePlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		resetCharacter(player)
		teleportToMap(player)
		table.insert(alivePlayers, player)
	end

	-- Monitor eliminations
	local roundOver = false
	local connections = {}

	for _, player in ipairs(alivePlayers) do
		local char = player.Character
		if not char then continue end
		local humanoid = char:FindFirstChild("Humanoid")
		if not humanoid then continue end

		local conn = humanoid.Died:Connect(function()
			-- Remove from alive list
			for i, p in ipairs(alivePlayers) do
				if p == player then
					table.remove(alivePlayers, i)
					break
				end
			end
			remotes.NotifyPlayer:FireAllClients(player.Name .. " was eliminated!")
		end)
		table.insert(connections, conn)
	end

	-- Run the timer
	for t = GameConfig.ROUND_DURATION, 0, -1 do
		remotes.TimerUpdate:FireAllClients(t)

		-- Check win condition: only one player standing
		if #alivePlayers == 1 and not roundOver then
			roundOver = true
			local winner = alivePlayers[1]
			remotes.NotifyPlayer:FireAllClients(winner.Name .. " wins the round!")
			DataManager.AdjustCoins(winner, GameConfig.COINS_FOR_WIN)
			break
		end

		if #alivePlayers == 0 then
			remotes.NotifyPlayer:FireAllClients("No survivors – it's a draw!")
			break
		end

		if t > 0 then task.wait(1) end
	end

	-- Cleanup connections
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
end

local function doIntermission()
	setState(GameState.INTERMISSION)

	for _, player in ipairs(Players:GetPlayers()) do
		teleportToLobby(player)
		resetCharacter(player)
	end

	countdown(GameConfig.INTERMISSION, "Next round in")
end

-- ── Main loop ─────────────────────────────────────────────────────────────────

task.spawn(function()
	while true do
		doLobby()
		startRound()
		doIntermission()
	end
end)

-- Handle new characters during lobby so they spawn correctly
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if currentState == GameState.LOBBY or currentState == GameState.INTERMISSION then
			task.wait(0.1) -- let character load
			teleportToLobby(player)
		end
	end)
end)
