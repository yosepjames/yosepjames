-- Creates all Remote instances so other scripts can safely wait for them
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function makeEvent(name)
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = remotesFolder
end

local function makeFunction(name)
	local f = Instance.new("RemoteFunction")
	f.Name = name
	f.Parent = remotesFolder
end

makeEvent("StateChanged")
makeEvent("TimerUpdate")
makeEvent("PlayerDataUpdate")
makeEvent("NotifyPlayer")
makeFunction("RequestPlayerData")
