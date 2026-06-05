-- Gamepass monetization: checks ownership and applies benefits
-- Replace the placeholder IDs below with your real Roblox gamepass IDs
local Players              = game:GetService("Players")
local MarketplaceService   = game:GetService("MarketplaceService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local remotes    = ReplicatedStorage:WaitForChild("Remotes")

local DataService -- injected

-- ── Gamepass IDs (replace with real IDs from Creator Dashboard) ───────────────
local PASSES = {
	VIP = {
		id          = 000000001,  -- TODO: replace
		name        = "VIP Pass",
		description = "2× coin rate, 4th pet slot, gold name colour.",
	},
	AUTO_COLLECT = {
		id          = 000000002,  -- TODO: replace
		name        = "Auto Collect",
		description = "Pets auto-generate coins even when you're offline (hourly tick saved to DataStore).",
	},
	LUCK_BOOST = {
		id          = 000000003,  -- TODO: replace
		name        = "2× Luck",
		description = "Permanent double shiny-pet chance on all egg opens.",
	},
	SPEED_BOOST = {
		id          = 000000004,  -- TODO: replace
		name        = "Speed Boost",
		description = "WalkSpeed permanently increased to 24.",
	},
}

-- Per-session cache so we only call the API once per player per pass
local ownershipCache = {}  -- [userId] = { [passKey] = bool }

local GamepassService = {}

local function owns(player, passKey)
	local uid = player.UserId
	if not ownershipCache[uid] then
		ownershipCache[uid] = {}
	end
	if ownershipCache[uid][passKey] == nil then
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(uid, PASSES[passKey].id)
		end)
		ownershipCache[uid][passKey] = ok and result or false
	end
	return ownershipCache[uid][passKey]
end

-- Public helpers used by other services

function GamepassService.HasVIP(player)
	return owns(player, "VIP")
end

function GamepassService.HasAutoCollect(player)
	return owns(player, "AUTO_COLLECT")
end

function GamepassService.HasLuckBoost(player)
	return owns(player, "LUCK_BOOST")
end

function GamepassService.HasSpeedBoost(player)
	return owns(player, "SPEED_BOOST")
end

-- Return combined benefits table (sent to client for UI display)
function GamepassService.GetBenefits(player)
	return {
		vip         = GamepassService.HasVIP(player),
		autoCollect = GamepassService.HasAutoCollect(player),
		luckBoost   = GamepassService.HasLuckBoost(player),
		speedBoost  = GamepassService.HasSpeedBoost(player),
	}
end

-- Apply character-level benefits when character spawns
local function applyToCharacter(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	if GamepassService.HasSpeedBoost(player) then
		humanoid.WalkSpeed = 24
	end
	if GamepassService.HasVIP(player) then
		-- Golden name overhead
		local head = character:FindFirstChild("Head")
		if head then
			local existing = head:FindFirstChild("VIPBillboard")
			if not existing then
				local bb = Instance.new("BillboardGui")
				bb.Name        = "VIPBillboard"
				bb.Size        = UDim2.new(0,120,0,24)
				bb.StudsOffset = Vector3.new(0, 3.5, 0)
				bb.Parent      = head
				local lbl = Instance.new("TextLabel")
				lbl.Size             = UDim2.new(1,0,1,0)
				lbl.BackgroundTransparency = 1
				lbl.TextColor3       = Color3.fromRGB(255,215,0)
				lbl.Font             = Enum.Font.GothamBold
				lbl.TextScaled       = true
				lbl.Text             = "⭐ VIP"
				lbl.TextStrokeTransparency = 0.5
				lbl.Parent           = bb
			end
		end
	end
end

-- ProcessReceipt: called by Roblox when a developer product purchase completes.
-- Wire gem bundle developer products here.
-- Developer product IDs (replace with real ones):
local GEM_PRODUCTS = {
	[111111001] = 10,   -- 10 gems
	[111111002] = 50,   -- 50 gems
	[111111003] = 200,  -- 200 gems
	[111111004] = 750,  -- 750 gems
}

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local gems = GEM_PRODUCTS[receiptInfo.ProductId]
	if gems then
		DataService.AdjustGems(player, gems)
		remotes.Notification:FireClient(player, {
			text  = "Purchase complete! +" .. gems .. " 💎 added.",
			color = Color3.fromRGB(100, 200, 255),
		})
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function GamepassService.Init(ds)
	DataService = ds

	-- Check ownership and apply benefits when character spawns
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			applyToCharacter(player)
		end)
	end)

	-- Extra pet slot for VIP
	remotes.GetPlayerData.OnServerInvoke = nil  -- will be re-set in PetService, leave alone
	-- VIP extra slot is enforced server-side in PetService.handleEquipPet:
	--   max = GamepassService.HasVIP(player) and 4 or GameConfig.MAX_EQUIPPED_PETS

	remotes.GetPassInfo.OnServerInvoke = function(player)
		return {
			benefits = GamepassService.GetBenefits(player),
			passes   = PASSES,
		}
	end

	Players.PlayerRemoving:Connect(function(player)
		ownershipCache[player.UserId] = nil
	end)
end

return GamepassService
