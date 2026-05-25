-- Creates every Remote BEFORE any other script runs so WaitForChild never deadlocks
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = Instance.new("Folder")
folder.Name   = "Remotes"
folder.Parent = ReplicatedStorage

local function event(name)
	local e = Instance.new("RemoteEvent")
	e.Name   = name
	e.Parent = folder
end

local function fn(name)
	local f = Instance.new("RemoteFunction")
	f.Name   = name
	f.Parent = folder
end

-- Economy
event("CoinUpdate")      -- server → client: number
event("GemUpdate")       -- server → client: number

-- Pets
fn   ("OpenEgg")         -- client → server: eggId  → { petId, uid, ... } | false
fn   ("FusePets")        -- client → server: uid1,uid2,uid3 → resultPet | false
event("SellPet")         -- client → server: uid
event("EquipPet")        -- client → server: uid
event("UnequipPet")      -- client → server: uid
fn   ("GetInventory")    -- client → server: () → pets table
event("PetAdded")        -- server → client: petEntry table
event("PetRemoved")      -- server → client: uid
event("EquippedUpdated") -- server → client: equippedUids table

-- Territories
fn   ("GetTerritoryState") -- → { [id] = { owner, captureProgress } }
event("TerritoryUpdated")  -- server → client: updated territory table
event("EnterZone")         -- client → server: territoryId
event("LeaveZone")         -- client → server: territoryId

-- Trading Post
fn   ("GetListings")     -- → listings table
event("CreateListing")   -- client → server: { uid, price }
event("CancelListing")   -- client → server: listingId
event("BuyListing")      -- client → server: listingId
event("ListingUpdated")  -- server → client: full listings table

-- General
event("Notification")    -- server → client: { text, color }
fn   ("GetPlayerData")   -- → { coins, gems, stats }
