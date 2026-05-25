-- Applies character stats and sends territory zone events to server
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local TerritoryData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TerritoryData"))

local remotes     = ReplicatedStorage:WaitForChild("Remotes")
local localPlayer = Players.LocalPlayer

local currentZone = nil  -- territory id the player is currently inside

local function applyStats(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = GameConfig.WALK_SPEED
	humanoid.JumpPower = GameConfig.JUMP_POWER
end

localPlayer.CharacterAdded:Connect(applyStats)
if localPlayer.Character then applyStats(localPlayer.Character) end

-- ── Territory proximity check (every 0.5 s) ──────────────────────────────────
RunService.Heartbeat:Connect(function()
	local character = localPlayer.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local pos    = root.Position
	local inZone = nil

	for id, tdata in pairs(TerritoryData.Territories) do
		local center = tdata.position
		local dist   = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
		if dist <= tdata.radius then
			inZone = id
			break
		end
	end

	if inZone ~= currentZone then
		if currentZone then
			remotes.LeaveZone:FireServer(currentZone)
		end
		currentZone = inZone
		if currentZone then
			remotes.EnterZone:FireServer(currentZone)
		end
	end
end)
