-- All pet definitions for Mythic Pets Empire
local PetData = {}

PetData.RarityColors = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(60,  200, 60),
	Rare      = Color3.fromRGB(60,  120, 220),
	Epic      = Color3.fromRGB(160, 60,  220),
	Legendary = Color3.fromRGB(255, 165, 0),
	Mythic    = Color3.fromRGB(255, 60,  180),
}

-- coinPerMin: coins generated every minute when pet is equipped
-- fusionResult: petId of evolved form when 3 identical pets are fused (nil = max tier)
PetData.Pets = {

	-- ══════════════ COMMON ══════════════
	cat_basic = {
		name = "Tabby Cat", rarity = "Common",
		coinPerMin = 5,  sellValue = 25,
		bodyColor = Color3.fromRGB(200, 170, 130),
		description = "A simple but loyal cat.",
		fusionResult = "cat_silver",
	},
	dog_basic = {
		name = "Puppy", rarity = "Common",
		coinPerMin = 6,  sellValue = 25,
		bodyColor = Color3.fromRGB(220, 200, 160),
		description = "An eager puppy ready to help.",
		fusionResult = "dog_gold",
	},
	bunny_basic = {
		name = "Cotton Bunny", rarity = "Common",
		coinPerMin = 5,  sellValue = 25,
		bodyColor = Color3.fromRGB(245, 245, 245),
		description = "Fluffy and surprisingly fast.",
		fusionResult = "bunny_crystal",
	},
	chick_basic = {
		name = "Yellow Chick", rarity = "Common",
		coinPerMin = 7,  sellValue = 25,
		bodyColor = Color3.fromRGB(255, 230, 80),
		description = "Cheeps coins into your pocket.",
		fusionResult = "chick_neon",
	},
	turtle_basic = {
		name = "Baby Turtle", rarity = "Common",
		coinPerMin = 8,  sellValue = 25,
		bodyColor = Color3.fromRGB(80, 160, 80),
		description = "Slow but very steady income.",
		fusionResult = "turtle_stone",
	},
	fox_basic = {
		name = "Little Fox", rarity = "Common",
		coinPerMin = 9,  sellValue = 25,
		bodyColor = Color3.fromRGB(220, 100, 30),
		description = "Cunning and coin-savvy.",
		fusionResult = "fox_arctic",
	},

	-- ══════════════ UNCOMMON ══════════════
	cat_silver = {
		name = "Silver Cat", rarity = "Uncommon",
		coinPerMin = 15, sellValue = 100,
		bodyColor = Color3.fromRGB(190, 200, 215),
		description = "A cat with a silver sheen.",
		fusionResult = "cat_shadow",
	},
	dog_gold = {
		name = "Golden Pup", rarity = "Uncommon",
		coinPerMin = 18, sellValue = 100,
		bodyColor = Color3.fromRGB(240, 200, 60),
		description = "Worth its weight in gold.",
		fusionResult = "dog_diamond",
	},
	bunny_crystal = {
		name = "Crystal Bunny", rarity = "Uncommon",
		coinPerMin = 14, sellValue = 100,
		bodyColor = Color3.fromRGB(170, 220, 255),
		description = "Its fur sparkles like gemstones.",
		fusionResult = "bunny_rainbow",
	},
	chick_neon = {
		name = "Neon Chick", rarity = "Uncommon",
		coinPerMin = 20, sellValue = 100,
		bodyColor = Color3.fromRGB(90, 255, 90),
		description = "Glows so bright it prints coins.",
		fusionResult = "phoenix_baby",
	},
	turtle_stone = {
		name = "Stone Turtle", rarity = "Uncommon",
		coinPerMin = 22, sellValue = 100,
		bodyColor = Color3.fromRGB(130, 120, 110),
		description = "Hard shell, harder work ethic.",
		fusionResult = "turtle_ancient",
	},
	fox_arctic = {
		name = "Arctic Fox", rarity = "Uncommon",
		coinPerMin = 24, sellValue = 100,
		bodyColor = Color3.fromRGB(220, 240, 255),
		description = "Survives any economy.",
		fusionResult = "fox_thunder",
	},

	-- ══════════════ RARE ══════════════
	cat_shadow = {
		name = "Shadow Cat", rarity = "Rare",
		coinPerMin = 35, sellValue = 400,
		bodyColor = Color3.fromRGB(40, 30, 60),
		description = "Appears from thin air holding coins.",
		fusionResult = "cat_void",
	},
	dog_diamond = {
		name = "Diamond Dog", rarity = "Rare",
		coinPerMin = 40, sellValue = 400,
		bodyColor = Color3.fromRGB(180, 230, 255),
		description = "Crystalline and priceless.",
		fusionResult = "wolf_titan",
	},
	bunny_rainbow = {
		name = "Rainbow Bunny", rarity = "Rare",
		coinPerMin = 38, sellValue = 400,
		bodyColor = Color3.fromRGB(255, 100, 180),
		description = "Leaves a rainbow trail of coins.",
		fusionResult = "rabbit_cosmic",
	},
	phoenix_baby = {
		name = "Baby Phoenix", rarity = "Rare",
		coinPerMin = 50, sellValue = 400,
		bodyColor = Color3.fromRGB(255, 140, 0),
		description = "Reborn with fresh coins every dawn.",
		fusionResult = "phoenix_inferno",
	},
	turtle_ancient = {
		name = "Ancient Turtle", rarity = "Rare",
		coinPerMin = 45, sellValue = 400,
		bodyColor = Color3.fromRGB(100, 140, 60),
		description = "Carries centuries of wealth.",
		fusionResult = "dragon_storm",
	},
	fox_thunder = {
		name = "Thunder Fox", rarity = "Rare",
		coinPerMin = 55, sellValue = 400,
		bodyColor = Color3.fromRGB(200, 200, 30),
		description = "Strikes like lightning, earns like thunder.",
		fusionResult = "wolf_titan",
	},

	-- ══════════════ EPIC ══════════════
	cat_void = {
		name = "Void Cat", rarity = "Epic",
		coinPerMin = 90,  sellValue = 1500,
		bodyColor = Color3.fromRGB(20, 10, 40),
		description = "Exists between dimensions, earning everywhere.",
		fusionResult = "cat_celestial",
	},
	wolf_titan = {
		name = "Titan Wolf", rarity = "Epic",
		coinPerMin = 110, sellValue = 1500,
		bodyColor = Color3.fromRGB(60, 80, 120),
		description = "Alpha of the coin pack.",
		fusionResult = "wolf_nebula",
	},
	dragon_storm = {
		name = "Storm Dragon", rarity = "Epic",
		coinPerMin = 130, sellValue = 1500,
		bodyColor = Color3.fromRGB(100, 120, 200),
		description = "Its roar shakes coins from the sky.",
		fusionResult = "dragon_eternal",
	},
	phoenix_inferno = {
		name = "Inferno Phoenix", rarity = "Epic",
		coinPerMin = 120, sellValue = 1500,
		bodyColor = Color3.fromRGB(255, 60, 20),
		description = "Forged in fire, paid in gold.",
		fusionResult = "phoenix_divine",
	},
	rabbit_cosmic = {
		name = "Cosmic Rabbit", rarity = "Epic",
		coinPerMin = 100, sellValue = 1500,
		bodyColor = Color3.fromRGB(180, 100, 255),
		description = "Hops between galaxies collecting coins.",
		fusionResult = "cat_celestial",
	},

	-- ══════════════ LEGENDARY ══════════════
	cat_celestial = {
		name = "Celestial Cat", rarity = "Legendary",
		coinPerMin = 220, sellValue = 6000,
		bodyColor = Color3.fromRGB(255, 215, 120),
		description = "Blessed by the stars themselves.",
		fusionResult = "emperor_cosmic",
	},
	wolf_nebula = {
		name = "Nebula Wolf", rarity = "Legendary",
		coinPerMin = 280, sellValue = 6000,
		bodyColor = Color3.fromRGB(120, 60, 200),
		description = "Born in the heart of a nebula.",
		fusionResult = "sovereign_void",
	},
	dragon_eternal = {
		name = "Eternal Dragon", rarity = "Legendary",
		coinPerMin = 350, sellValue = 6000,
		bodyColor = Color3.fromRGB(200, 160, 30),
		description = "Has outlived every economy.",
		fusionResult = "dragon_mythic",
	},
	phoenix_divine = {
		name = "Divine Phoenix", rarity = "Legendary",
		coinPerMin = 320, sellValue = 6000,
		bodyColor = Color3.fromRGB(255, 200, 80),
		description = "Its feathers are made of pure gold.",
		fusionResult = "emperor_cosmic",
	},

	-- ══════════════ MYTHIC ══════════════
	emperor_cosmic = {
		name = "Cosmic Emperor", rarity = "Mythic",
		coinPerMin = 700,  sellValue = 25000,
		bodyColor = Color3.fromRGB(255, 80, 200),
		description = "Rules the cosmos and the coin supply.",
		fusionResult = nil,
	},
	sovereign_void = {
		name = "Void Sovereign", rarity = "Mythic",
		coinPerMin = 850,  sellValue = 25000,
		bodyColor = Color3.fromRGB(80, 0, 120),
		description = "Commands the void and endless wealth.",
		fusionResult = nil,
	},
	dragon_mythic = {
		name = "Mythic Dragon", rarity = "Mythic",
		coinPerMin = 1000, sellValue = 25000,
		bodyColor = Color3.fromRGB(255, 30, 30),
		description = "The rarest creature in existence.",
		fusionResult = nil,
	},
}

function PetData.GetPet(petId)
	return PetData.Pets[petId]
end

function PetData.GetRarityColor(rarity)
	return PetData.RarityColors[rarity] or Color3.new(1, 1, 1)
end

return PetData
