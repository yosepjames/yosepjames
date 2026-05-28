local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = Instance.new("Folder")
folder.Name   = "Remotes"
folder.Parent = ReplicatedStorage

local function event(name)
	local e = Instance.new("RemoteEvent") ; e.Name = name ; e.Parent = folder
end
local function fn(name)
	local f = Instance.new("RemoteFunction") ; f.Name = name ; f.Parent = folder
end

-- Economy
event("CoinUpdate")
event("GemUpdate")

-- Pets
fn   ("OpenEgg")
fn   ("FusePets")
event("SellPet")
event("EquipPet")
event("UnequipPet")
fn   ("GetInventory")
event("PetAdded")
event("PetRemoved")
event("EquippedUpdated")

-- Territories
fn   ("GetTerritoryState")
event("TerritoryUpdated")
event("EnterZone")
event("LeaveZone")

-- Trading Post
fn   ("GetListings")
event("CreateListing")
event("CancelListing")
event("BuyListing")
event("ListingUpdated")

-- General
event("Notification")
fn   ("GetPlayerData")

-- ── NEW TRENDING FEATURES ─────────────────────────────────────────────────────

-- Rebirth / Prestige
fn   ("Rebirth")
fn   ("GetRebirthInfo")
event("RebirthUpdate")

-- Daily Spin Wheel
fn   ("ClaimDailySpin")
fn   ("GetSpinInfo")
event("LuckTokenUpdate")
event("LuckAuraUpdate")
event("ActivateLuckToken")  -- client→server as event is fine but fn returns bool
-- keep as event and let server fire Notification for result

-- Daily Quests
fn   ("GetQuests")
event("ClaimQuest")
event("QuestUpdate")

-- World Boss
fn   ("GetBossState")
event("AttackBoss")
event("BossUpdate")
