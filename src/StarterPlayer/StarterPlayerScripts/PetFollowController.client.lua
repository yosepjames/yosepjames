-- Renders equipped pets as orbiting glowing spheres
-- Shiny pets pulse rainbow colors; luck aura wraps the player in gold light
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local PetData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local localPlayer = Players.LocalPlayer
local petModels   = {}     -- [uid] = { part, light }
local equippedUids = {}
local petIdCache   = {}    -- [uid] = { petId, shiny }
local luckAuraPart = nil   -- golden aura around player when luck is active

-- ── Luck Aura ─────────────────────────────────────────────────────────────────

local RAINBOW = {
	Color3.fromRGB(255,80,200),
	Color3.fromRGB(255,180,0),
	Color3.fromRGB(80,255,80),
	Color3.fromRGB(60,180,255),
}
local rainbowIdx = 1

local function setLuckAura(active)
	if active then
		if luckAuraPart then return end
		luckAuraPart = Instance.new("Part")
		luckAuraPart.Name        = "LuckAura"
		luckAuraPart.Size        = Vector3.new(6,6,6)
		luckAuraPart.Shape       = Enum.PartType.Ball
		luckAuraPart.Material    = Enum.Material.ForceField
		luckAuraPart.BrickColor  = BrickColor.new(Color3.fromRGB(255,215,0))
		luckAuraPart.CanCollide  = false
		luckAuraPart.Anchored    = true
		luckAuraPart.Transparency = 0.7
		luckAuraPart.CastShadow  = false
		luckAuraPart.Parent      = workspace

		local glow = Instance.new("PointLight")
		glow.Color      = Color3.fromRGB(255, 215, 0)
		glow.Range      = 16
		glow.Brightness = 4
		glow.Parent     = luckAuraPart
	else
		if luckAuraPart then
			luckAuraPart:Destroy()
			luckAuraPart = nil
		end
	end
end

-- ── Pet visual builder ────────────────────────────────────────────────────────

local function buildPetVisual(uid, petId, shiny)
	if petModels[uid] then petModels[uid].part:Destroy() end

	local petInfo = PetData.GetPet(petId)
	if not petInfo then return end

	local color = shiny and PetData.SHINY_COLOR or petInfo.bodyColor

	local part = Instance.new("Part")
	part.Name        = "Pet_" .. uid
	part.Size        = Vector3.new(1.5, 1.5, 1.5)
	part.Shape       = Enum.PartType.Ball
	part.BrickColor  = BrickColor.new(color)
	part.Material    = shiny and Enum.Material.Neon or Enum.Material.SmoothPlastic
	part.CanCollide  = false
	part.Anchored    = true
	part.CastShadow  = false
	part.Parent      = workspace

	local light = Instance.new("PointLight")
	light.Color      = shiny and Color3.fromRGB(255, 215, 0) or petInfo.bodyColor
	light.Range      = shiny and 12 or 8
	light.Brightness = shiny and 4 or 2
	light.Parent     = part

	-- BillboardGui label
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 90, 0, 28)
	bb.StudsOffset = Vector3.new(0, 1.6, 0)
	bb.Parent      = part

	local lbl = Instance.new("TextLabel")
	lbl.Size             = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Font             = Enum.Font.GothamBold
	lbl.TextScaled       = true
	lbl.TextStrokeTransparency = 0.4
	lbl.TextColor3       = shiny and Color3.fromRGB(255,215,0) or PetData.GetRarityColor(petInfo.rarity)
	lbl.Text             = (shiny and "✨ " or "") .. petInfo.name
	lbl.Parent           = bb

	petModels[uid] = { part = part, light = light, shiny = shiny }
end

local function removePetVisual(uid)
	local m = petModels[uid]
	if m then m.part:Destroy() ; petModels[uid] = nil end
end

-- ── Orbit update ──────────────────────────────────────────────────────────────
local t = 0

RunService.Heartbeat:Connect(function(dt)
	t += dt

	-- Rainbow cycle for shiny pets
	rainbowIdx = ((math.floor(t * 3)) % #RAINBOW) + 1

	local character = localPlayer.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local pos = root.Position

	-- Move luck aura with player
	if luckAuraPart then
		luckAuraPart.CFrame = CFrame.new(pos.X, pos.Y + 1, pos.Z)
	end

	local count  = 0
	local total  = 0
	for _ in pairs(petModels) do total += 1 end

	for uid, m in pairs(petModels) do
		local angle  = t * 1.5 + count * (2 * math.pi / math.max(total, 1))
		local radius = 4 + total * 0.4
		local x      = pos.X + math.cos(angle) * radius
		local z      = pos.Z + math.sin(angle) * radius
		local y      = pos.Y + 2 + math.sin(t * 2 + count) * 0.6

		m.part.CFrame = CFrame.new(x, y, z)

		-- Shiny rainbow color pulse
		if m.shiny then
			m.part.BrickColor = BrickColor.new(RAINBOW[rainbowIdx])
			m.light.Color     = RAINBOW[rainbowIdx]
		end

		count += 1
	end
end)

-- ── Remote listeners ──────────────────────────────────────────────────────────

remotes.PetAdded.OnClientEvent:Connect(function(entry)
	petIdCache[entry.uid] = { petId = entry.petId, shiny = entry.shiny }
end)

remotes.PetRemoved.OnClientEvent:Connect(function(uid)
	petIdCache[uid] = nil
	removePetVisual(uid)
end)

remotes.EquippedUpdated.OnClientEvent:Connect(function(uids)
	equippedUids = uids
	-- Remove unequipped
	for uid in pairs(petModels) do
		local found = false
		for _, eu in ipairs(uids) do if eu == uid then found = true break end end
		if not found then removePetVisual(uid) end
	end
	-- Add newly equipped
	for _, uid in ipairs(uids) do
		if not petModels[uid] then
			local cache = petIdCache[uid]
			if cache then buildPetVisual(uid, cache.petId, cache.shiny) end
		end
	end
end)

remotes.LuckAuraUpdate.OnClientEvent:Connect(function(payload)
	setLuckAura(payload.active and payload.expiresAt > os.time())
	-- Auto-remove when expired
	if payload.active then
		local remaining = payload.expiresAt - os.time()
		task.delay(remaining, function() setLuckAura(false) end)
	end
end)

localPlayer.CharacterRemoving:Connect(function()
	for uid in pairs(petModels) do removePetVisual(uid) end
end)
