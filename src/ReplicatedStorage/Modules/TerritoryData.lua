-- Territory (island) definitions for Mythic Pets Empire
local TerritoryData = {}

TerritoryData.Territories = {
	meadow_isle = {
		name            = "Meadow Isle",
		description     = "A peaceful island perfect for beginners.",
		coinBonusPercent = 10,
		captureTime     = 20,   -- seconds of standing in zone to capture
		color           = Color3.fromRGB(100, 200, 80),
		-- In Studio: place a Part named "Territory_meadow_isle" at these coords
		position        = Vector3.new(60, 0, 60),
		radius          = 30,
	},

	crystal_caverns = {
		name            = "Crystal Caverns",
		description     = "Glittering caves with mineral-rich deposits.",
		coinBonusPercent = 25,
		captureTime     = 45,
		color           = Color3.fromRGB(80, 160, 255),
		position        = Vector3.new(-80, 0, 40),
		radius          = 25,
	},

	volcano_peak = {
		name            = "Volcano Peak",
		description     = "Dangerous but unbelievably profitable.",
		coinBonusPercent = 50,
		captureTime     = 90,
		color           = Color3.fromRGB(220, 60, 20),
		position        = Vector3.new(10, 0, -110),
		radius          = 20,
	},
}

function TerritoryData.Get(territoryId)
	return TerritoryData.Territories[territoryId]
end

function TerritoryData.GetAll()
	return TerritoryData.Territories
end

return TerritoryData
