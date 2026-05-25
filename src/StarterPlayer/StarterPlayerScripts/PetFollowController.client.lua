-- Renders equipped pets as small coloured parts with BillboardGuis that orbit the player
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local PetData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetData"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local localPlayer = Players.LocalPlayer
local petModels   = {}  -- [uid] = { part, billboard, label }
local equippedUids = {}

-- ── Build a pet visual ────────────────────────────────────────────────────────

local function buildPetVisual(uid, petId)
	local petInfo = PetData.GetPet(petId)
	if not petInfo then return end

	local part = Instance.new("Part")
	part.Name        = "Pet_" .. uid
	part.Size        = Vector3.new(1.5, 1.5, 1.5)
	part.Shape       = Enum.PartType.Ball
	part.BrickColor  = BrickColor.new(petInfo.bodyColor)
	part.Material    = Enum.Material.Neon
	part.CanCollide  = false
	part.Anchored    = true
	part.CastShadow  = false
	part.Parent      = workspace

	-- Glow effect
	local light = Instance.new("PointLight")
	light.Color      = petInfo.bodyColor
	light.Range      = 8
	light.Brightness = 2
	light.Parent     = part

	-- Billboard label
	local billboard = Instance.new("BillboardGui")
	billboard.Size          = UDim2.new(0, 80, 0, 30)
	billboard.StudsOffset   = Vector3.new(0, 1.5, 0)
	billboard.AlwaysOnTop   = false
	billboard.Parent        = part

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size            = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3      = PetData.GetRarityColor(petInfo.rarity)
	nameLabel.Font            = Enum.Font.GothamBold
	nameLabel.TextScaled      = true
	nameLabel.Text            = petInfo.name
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent          = billboard

	petModels[uid] = { part = part, billboard = billboard }
end

local function removePetVisual(uid)
	local m = petModels[uid]
	if m then
		m.part:Destroy()
		petModels[uid] = nil
	end
end

local function rebuildVisuals(uids)
	-- Remove pets no longer equipped
	for uid in pairs(petModels) do
		local stillEquipped = false
		for _, eu in ipairs(uids) do
			if eu == uid then stillEquipped = true break end
		end
		if not stillEquipped then removePetVisual(uid) end
	end

	-- Add new pets
	for _, uid in ipairs(uids) do
		if not petModels[uid] then
			-- We need the petId; request inventory
			-- Use a quick approach: request on demand or cache from PetAdded
		end
	end
end

-- ── Orbit update (every frame) ────────────────────────────────────────────────
local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	local character = localPlayer.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local count  = 0
	local total  = 0
	for uid in pairs(petModels) do total += 1 end

	for uid, m in pairs(petModels) do
		local angle  = (t * 1.5) + (count * (2 * math.pi / math.max(total, 1)))
		local radius = 4 + total * 0.5
		local x      = root.Position.X + math.cos(angle) * radius
		local z      = root.Position.Z + math.sin(angle) * radius
		local y      = root.Position.Y + 2 + math.sin(t * 2 + count) * 0.5

		m.part.CFrame = CFrame.new(x, y, z)
		count += 1
	end
end)

-- ── Remote handlers ───────────────────────────────────────────────────────────

-- Cache petId by uid when pets are added
local petIdCache = {}

remotes.PetAdded.OnClientEvent:Connect(function(entry)
	petIdCache[entry.uid] = entry.petId
end)

remotes.PetRemoved.OnClientEvent:Connect(function(uid)
	petIdCache[uid] = nil
	removePetVisual(uid)
	for i, eu in ipairs(equippedUids) do
		if eu == uid then table.remove(equippedUids, i) break end
	end
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
			local petId = petIdCache[uid]
			if petId then buildPetVisual(uid, petId) end
		end
	end
end)

-- Clean up visuals when character is destroyed (respawn)
localPlayer.CharacterRemoving:Connect(function()
	for uid in pairs(petModels) do removePetVisual(uid) end
end)
