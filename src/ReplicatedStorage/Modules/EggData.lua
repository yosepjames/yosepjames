-- Egg definitions: cost, currency type, and weighted pet pool
local EggData = {}

-- Each pool entry: { id = petId, weight = number }
-- Higher weight = more common. Roll = random(1, totalWeight)
EggData.Eggs = {

	basic_egg = {
		name        = "Basic Egg",
		description = "A common egg. Who knows what's inside?",
		cost        = 100,
		costType    = "coins",   -- "coins" | "gems"
		bodyColor   = Color3.fromRGB(210, 210, 210),
		openTime    = 1.5,       -- seconds for open animation
		pool = {
			{ id = "cat_basic",    weight = 28 },
			{ id = "dog_basic",    weight = 28 },
			{ id = "bunny_basic",  weight = 28 },
			{ id = "chick_basic",  weight = 28 },
			{ id = "turtle_basic", weight = 28 },
			{ id = "fox_basic",    weight = 28 },
			{ id = "cat_silver",   weight = 7  },
			{ id = "dog_gold",     weight = 7  },
			{ id = "bunny_crystal",weight = 7  },
			{ id = "chick_neon",   weight = 7  },
			{ id = "cat_shadow",   weight = 1  },
			{ id = "dog_diamond",  weight = 1  },
		},
	},

	magic_egg = {
		name        = "Magic Egg",
		description = "Shimmers with arcane energy. Rarer pets await.",
		cost        = 500,
		costType    = "coins",
		bodyColor   = Color3.fromRGB(100, 180, 255),
		openTime    = 2,
		pool = {
			{ id = "cat_silver",    weight = 20 },
			{ id = "dog_gold",      weight = 20 },
			{ id = "bunny_crystal", weight = 20 },
			{ id = "chick_neon",    weight = 20 },
			{ id = "turtle_stone",  weight = 20 },
			{ id = "fox_arctic",    weight = 20 },
			{ id = "cat_shadow",    weight = 10 },
			{ id = "dog_diamond",   weight = 10 },
			{ id = "bunny_rainbow", weight = 10 },
			{ id = "phoenix_baby",  weight = 10 },
			{ id = "cat_void",      weight = 3  },
			{ id = "wolf_titan",    weight = 3  },
			{ id = "dragon_storm",  weight = 2  },
		},
	},

	legendary_egg = {
		name        = "Legendary Egg",
		description = "Pulsing with legendary power. Epic and beyond guaranteed.",
		cost        = 2000,
		costType    = "coins",
		bodyColor   = Color3.fromRGB(255, 165, 0),
		openTime    = 2.5,
		pool = {
			{ id = "cat_void",       weight = 20 },
			{ id = "wolf_titan",     weight = 20 },
			{ id = "dragon_storm",   weight = 20 },
			{ id = "phoenix_inferno",weight = 20 },
			{ id = "rabbit_cosmic",  weight = 20 },
			{ id = "cat_celestial",  weight = 10 },
			{ id = "wolf_nebula",    weight = 10 },
			{ id = "dragon_eternal", weight = 10 },
			{ id = "phoenix_divine", weight = 10 },
			{ id = "emperor_cosmic", weight = 2  },
			{ id = "sovereign_void", weight = 2  },
			{ id = "dragon_mythic",  weight = 1  },
		},
	},

	mythic_egg = {
		name        = "Mythic Egg",
		description = "Reserved for the wealthiest collectors. Mythic chance guaranteed.",
		cost        = 80,       -- gems (Robux-purchased currency)
		costType    = "gems",
		bodyColor   = Color3.fromRGB(255, 60, 180),
		openTime    = 3,
		pool = {
			{ id = "cat_celestial",  weight = 15 },
			{ id = "wolf_nebula",    weight = 15 },
			{ id = "dragon_eternal", weight = 15 },
			{ id = "phoenix_divine", weight = 15 },
			{ id = "emperor_cosmic", weight = 20 },
			{ id = "sovereign_void", weight = 15 },
			{ id = "dragon_mythic",  weight = 5  },
		},
	},
}

-- Helper: weighted random roll, returns petId
function EggData.Roll(eggId)
	local egg = EggData.Eggs[eggId]
	if not egg then return nil end

	local totalWeight = 0
	for _, entry in ipairs(egg.pool) do
		totalWeight += entry.weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, entry in ipairs(egg.pool) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.id
		end
	end

	-- Fallback (should never reach here)
	return egg.pool[1].id
end

return EggData
