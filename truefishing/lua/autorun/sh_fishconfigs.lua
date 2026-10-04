/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

/*
WARNING: DO NOT MODIFY THIS FILE FOR CONFIGURATION. USE THE IN-GAME CONFIGURATION MENU!
*/

FISH_DAMSELFISH = 1
FISH_GOLDFISH = 2
FISH_SNAPPER = 3
FISH_RAINBOW = 4
FISH_GOLDENFISH = 5
FISH_CATFISH = 6
FISH_BASSFISH = 7
FISH_JUNK = 8

FISH_HIGHNUMBER = 8

local FishModels = {}
FishModels[FISH_DAMSELFISH] = "models/fishing/fish_clownfish.mdl"
FishModels[FISH_GOLDFISH] = "models/fishing/fish_goldfish.mdl"
FishModels[FISH_SNAPPER] = "models/fishing/fish_salmon.mdl"
FishModels[FISH_RAINBOW] = "models/fishing/fish_tuna.mdl"
FishModels[FISH_GOLDENFISH] = "models/fishing/fish_pufferfish.mdl"
FishModels[FISH_CATFISH] = "models/fishing/fish_catfish.mdl"
FishModels[FISH_BASSFISH] = "models/fishing/fish_bass.mdl"
FishModels[FISH_JUNK] = {"models/props_junk/garbage_metalcan001a.mdl",
"models/props_junk/garbage_metalcan002a.mdl",
"models/props_junk/garbage_milkcarton001a.mdl",
"models/props_junk/garbage_milkcarton002a.mdl",
"models/props_junk/garbage_newspaper001a.mdl",
"models/props_junk/garbage_plasticbottle001a.mdl",
"models/props_junk/garbage_plasticbottle002a.mdl",
"models/props_junk/garbage_plasticbottle003a.mdl"}
function TrueFishGetFishModel(int)
	return int == FISH_JUNK and FishModels[int][math.random(#FishModels[int])] or FishModels[int]
end

local FishNames = {}
FishNames[FISH_DAMSELFISH] = "Clownfish"
FishNames[FISH_GOLDFISH] = "Gold Fish"
FishNames[FISH_SNAPPER] = "Salmon"
FishNames[FISH_RAINBOW] = "Tuna"
FishNames[FISH_GOLDENFISH] = "Pufferfish"
FishNames[FISH_CATFISH] = "Cat Fish"
FishNames[FISH_BASSFISH] = "Bass Fish"
FishNames[FISH_JUNK] = "Random Junk"
function TrueFishGetFishName(int)
	return FishNames[int]
end

FISH_GEAR_BAIT = 1
FISH_GEAR_MEDIUMCAGE = 2
FISH_GEAR_LARGECAGE = 3
FISH_GEAR_CONTAINER = 4
FISH_GEAR_ROD = 5
FISH_GEAR_FISHFINDER = 6

FISH_GEAR_HOOK_GADDAN = 7
FISH_GEAR_HOOK_PIRANHA = 8
FISH_GEAR_HOOK_SHARK = 9
FISH_GEAR_HOOK_WHALE = 10
FISH_GEAR_HOOK_MUTATED = 11
FISH_GEAR_HOOK_BLUESHARK = 12
FISH_GEAR_HOOK_TIGERFISH = 13
FISH_GEAR_HOOK_TITAN = 14
FISH_GEAR_HOOK_GAR = 15
FISH_GEAR_HOOK_ANGLER = 16
FISH_GEAR_HOOK_SUNFISH = 17
FISH_GEAR_HOOK_OARFISH = 18
FISH_GEAR_HOOK_SPIDERCRAB = 19
FISH_GEAR_HOOK_PUFFERFISH = 20
FISH_GEAR_HOOK_TUNA = 21
FISH_GEAR_HOOK_BINGBONG = 22
FISH_GEAR_HOOK_ALBATROSS = 23

FISH_GEAR_HIGHNUMBER = 23

TrueFishBosses = {
	[7] = {
		id = 1,
		name = "Gammelgäddan",
		title = "EL LUCIO ANCESTRAL",
		model = "models/fishing/boss_gaddan.mdl",
		hookModel = "models/fishing/hook_homemade.mdl",
		gearName = "Anzuelo de Gammelgäddan",
		price = 300,
		health = 250,
		damage = 20,
		reward = 1200,
		mass = 60,
	},
	[8] = {
		id = 2,
		name = "Piraña Gigante",
		title = "DEPREDADOR DEL RÍO",
		model = "models/fishing/boss_piranha.mdl",
		hookModel = "models/fishing/hook_amateur.mdl",
		gearName = "Anzuelo de Piraña Gigante",
		price = 450,
		health = 320,
		damage = 25,
		reward = 1800,
		mass = 75,
	},
	[9] = {
		id = 3,
		name = "Tiburón Duende",
		title = "TERROR DE LAS PROFUNDIDADES",
		model = "models/fishing/boss_goblinshark.mdl",
		hookModel = "models/fishing/hook_quality.mdl",
		gearName = "Anzuelo de Tiburón Duende",
		price = 650,
		health = 420,
		damage = 30,
		reward = 2500,
		mass = 120,
	},
	[10] = {
		id = 4,
		name = "Ballena Bowhead",
		title = "LEVIATÁN ÁRTICO",
		model = "models/fishing/boss_whale.mdl",
		hookModel = "models/fishing/hook_professional.mdl",
		gearName = "Anzuelo de Ballena Bowhead",
		price = 900,
		health = 550,
		damage = 35,
		reward = 3500,
		mass = 250,
	},
	[11] = {
		id = 5,
		name = "Ballena Mutante",
		title = "LA ABERRACIÓN DEL ABISMO",
		model = "models/fishing/boss_mutatedwhale.mdl",
		hookModel = "models/fishing/hook_scientific.mdl",
		gearName = "Anzuelo de Ballena Mutante",
		price = 1200,
		health = 700,
		damage = 45,
		reward = 5000,
		mass = 350,
	},
	[12] = {
		id = 6,
		name = "Tiburón Azul",
		title = "DEPREDADOR DEL OCÉANO",
		model = "models/fishing/fish_blueshark.mdl",
		hookModel = "models/fishing/hook.mdl",
		gearName = "Anzuelo de Tiburón Azul",
		price = 550,
		health = 380,
		damage = 28,
		reward = 2200,
		mass = 95,
	},
	[13] = {
		id = 7,
		name = "Pez Tigre Goliat",
		title = "TERROR DE AGUA DULCE",
		model = "models/fishing/fish_tigerfish.mdl",
		hookModel = "models/fishing/hook_amateur.mdl",
		gearName = "Anzuelo de Pez Tigre Goliat",
		price = 400,
		health = 300,
		damage = 22,
		reward = 1600,
		mass = 70,
	},
	[14] = {
		id = 8,
		name = "Pez Ballesta Titán",
		title = "BESTIA TERRITORIAL",
		model = "models/fishing/fish_titantriggerfish.mdl",
		hookModel = "models/fishing/hook_quality.mdl",
		gearName = "Anzuelo de Pez Ballesta Titán",
		price = 500,
		health = 360,
		damage = 26,
		reward = 2000,
		mass = 85,
	},
	[15] = {
		id = 9,
		name = "Pez Cocodrilo Gar",
		title = "FÓSIL VIVIENTE DEL PANTANO",
		model = "models/fishing/fish_gar.mdl",
		hookModel = "models/fishing/hook_quality.mdl",
		gearName = "Anzuelo de Pez Cocodrilo",
		price = 600,
		health = 400,
		damage = 30,
		reward = 2400,
		mass = 110,
	},
	[16] = {
		id = 10,
		name = "Pez Rape Abisal",
		title = "SEDUCTOR DE LA OSCURIDAD",
		model = "models/fishing/fish_anglerfish.mdl",
		hookModel = "models/fishing/hook_scientific.mdl",
		gearName = "Anzuelo de Pez Rape Abisal",
		price = 750,
		health = 480,
		damage = 32,
		reward = 2900,
		mass = 130,
	},
	[17] = {
		id = 11,
		name = "Pez Luna Gigante",
		title = "TITÁN COLOSAL DE LOS MARES",
		model = "models/fishing/fish_sunfish.mdl",
		hookModel = "models/fishing/hook_professional.mdl",
		gearName = "Anzuelo de Pez Luna Gigante",
		price = 850,
		health = 600,
		damage = 25,
		reward = 3300,
		mass = 280,
	},
	[18] = {
		id = 12,
		name = "Pez Remo Gigante",
		title = "SERPIENTE MÍTICA DEL OCÉANO",
		model = "models/fishing/fish_oarfish.mdl",
		hookModel = "models/fishing/hook_scientific.mdl",
		gearName = "Anzuelo de Pez Remo Gigante",
		price = 1050,
		health = 650,
		damage = 40,
		reward = 4200,
		mass = 200,
	},
	[19] = {
		id = 13,
		name = "Cangrejo Araña",
		title = "TERROR DEL FONDO MARINO",
		model = "models/fishing/fish_spidercrab.mdl",
		hookModel = "models/fishing/hook_homemade.mdl",
		gearName = "Anzuelo de Cangrejo Araña",
		price = 350,
		health = 280,
		damage = 22,
		reward = 1500,
		mass = 50,
	},
	[20] = {
		id = 14,
		name = "Pez Globo Gigante",
		title = "COLOSO ESPINOSO",
		model = "models/fishing/fish_pufferfish.mdl",
		hookModel = "models/fishing/hook_amateur.mdl",
		gearName = "Anzuelo de Pez Globo",
		price = 480,
		health = 340,
		damage = 24,
		reward = 1900,
		mass = 65,
	},
	[21] = {
		id = 15,
		name = "Atún Colosal",
		title = "TORPEDO DE ALTA MAR",
		model = "models/fishing/fish_tuna.mdl",
		hookModel = "models/fishing/hook_quality.mdl",
		gearName = "Anzuelo de Atún Colosal",
		price = 520,
		health = 370,
		damage = 27,
		reward = 2100,
		mass = 90,
	},
	[22] = {
		id = 16,
		name = "Bing Bong",
		title = "ENTIDAD ANOMALÍA SECRETA",
		model = "models/fishing/fish_bingbong.mdl",
		hookModel = "models/fishing/hook_scientific.mdl",
		gearName = "Anzuelo de Bing Bong",
		price = 1100,
		health = 600,
		damage = 38,
		reward = 4500,
		mass = 150,
	},
	[23] = {
		id = 17,
		name = "Albatros Gigante",
		title = "SEÑOR DE LAS TORMENTAS",
		model = "models/fishing/boss_albatross.mdl",
		hookModel = "models/fishing/hook_professional.mdl",
		gearName = "Anzuelo de Albatros",
		price = 950,
		health = 520,
		damage = 36,
		reward = 3800,
		mass = 45,
	},
}

local GearModels = {}
GearModels[FISH_GEAR_BAIT] = "models/props_junk/garbage_bag001a.mdl"
GearModels[FISH_GEAR_MEDIUMCAGE] = "models/props_junk/wood_crate002a.mdl"
GearModels[FISH_GEAR_LARGECAGE] = "models/hunter/blocks/cube075x2x1.mdl"
GearModels[FISH_GEAR_CONTAINER] = "models/truefishing/caja_pescados.mdl"
GearModels[FISH_GEAR_ROD] = "models/fishing/pole.mdl"
GearModels[FISH_GEAR_FISHFINDER] = "models/props_lab/monitor01b.mdl"
for id, boss in pairs(TrueFishBosses) do
	GearModels[id] = boss.hookModel
end

function TrueFishGetGearModel(int)
	return GearModels[int]
end

if CLIENT then
	local GearMaterials = {}
	GearMaterials[FISH_GEAR_BAIT] = "models/flesh"
	GearMaterials[FISH_GEAR_MEDIUMCAGE] = "!CagePotMaterial"
	GearMaterials[FISH_GEAR_LARGECAGE] = "!CagePotMaterial"

	function TrueFishGetGearMaterial(int)
		return GearMaterials[int]
	end
end

local GearNames = {}
GearNames[FISH_GEAR_BAIT] = "Fish Bait"
GearNames[FISH_GEAR_MEDIUMCAGE] = "Medium Fish Cage"
GearNames[FISH_GEAR_LARGECAGE] = "Large Fish Cage"
GearNames[FISH_GEAR_CONTAINER] = "Fish Container"
GearNames[FISH_GEAR_ROD] = "Fishing Rod"
GearNames[FISH_GEAR_FISHFINDER] = "Fish Finder"
for id, boss in pairs(TrueFishBosses) do
	GearNames[id] = boss.gearName
end

function TrueFishGetGearName(int)
	return GearNames[int]
end

local GearEntity = {}
GearEntity[FISH_GEAR_BAIT] = "fish_bait"
GearEntity[FISH_GEAR_MEDIUMCAGE] = "fishing_pot_medium"
GearEntity[FISH_GEAR_LARGECAGE] = "fishing_pot_large"
GearEntity[FISH_GEAR_CONTAINER] = "fish_container"
function TrueFishGetGearEntityName(int)
	return GearEntity[int]
end

FISH_MAX_DEPTH = 999

TrueFish = TrueFish or {

OPTIMIZED_FISHING = true,
CAGE_NO_FISH_MODEL = false,
CAGE_BUOY_SPLASHING = true,
MEDIUM_CAGE_FISH_LIMIT = 10,
LARGE_CAGE_FISH_LIMIT = 15,
FISH_CONTAINER_LIMIT = 5,
CONTAINERS_DISABLED = false,
MEDIUM_CAGE_LIMIT = 2,
LARGE_CAGE_LIMIT = 2,
CONTAINER_LIMIT = 2,
CAGE_SHARED_LIMIT = true,
MEDIUM_JUNK_CHANCE = 11,
LARGE_JUNK_CHANCE = 10,
ROD_NO_CONTAINER = false,
FISH_CARRY_LIMIT = 20,
ROD_PHYSICS_FISHING = true,
ROD_SEPERATE_CATCH_TIME_ENABLED = false,
ROD_SEPERATE_CATCH_TIME = 5,
ROD_CATCH_WINDOW = 0.33,
ROD_FISH_BAIT_AMOUNT = 5,
ROD_JUNK_CHANCE = 5,
ROD_MONEYBAG_CHANCE = 1,
ROD_MONEYBAG_MONEY = 500,
CAN_PHYSGUN_GEAR = false,
FISH_CONTAINER_OWNER_DISCARD = false, //imp
FISH_BAIT_AUTOREMOVE = 0, //imp

LOCALISATION_LANGUAGE = "German",

FISH_CATCH_TIME = {
[FISH_DAMSELFISH] = {6 ,10},
[FISH_GOLDFISH] = {5 ,11},
[FISH_SNAPPER] = {7 ,17},
[FISH_RAINBOW] = {8 ,16},
[FISH_GOLDENFISH] = {10 ,19},
[FISH_CATFISH] = {13 ,22},
[FISH_BASSFISH] = {10 ,30}
},

FISH_DEPTH = {
[FISH_DAMSELFISH] = {0 ,224},
[FISH_GOLDFISH] = {0 ,525},
[FISH_SNAPPER] = {30 ,525},
[FISH_RAINBOW] = {500 ,672},
[FISH_GOLDENFISH] = {670 ,780},
[FISH_CATFISH] = {600 ,800},
[FISH_BASSFISH] = {666 ,999}
},

FISH_ENABLED = {
[FISH_DAMSELFISH] = true,
[FISH_GOLDFISH] = true,
[FISH_SNAPPER] = true,
[FISH_RAINBOW] = true,
[FISH_GOLDENFISH] = true,
[FISH_CATFISH] = true,
[FISH_BASSFISH] = true,
[FISH_JUNK] = true
},

FISH_PRICE = {
[FISH_DAMSELFISH] = 50,
[FISH_GOLDFISH] = 50,
[FISH_SNAPPER] = 65,
[FISH_RAINBOW] = 80,
[FISH_GOLDENFISH] = 85,
[FISH_CATFISH] = 95,
[FISH_BASSFISH] = 110,
[FISH_JUNK] = 10,
},

GEAR_PRICE = {
[FISH_GEAR_BAIT] = 50,
[FISH_GEAR_MEDIUMCAGE] = 750,
[FISH_GEAR_LARGECAGE] = 1500,
[FISH_GEAR_CONTAINER] = 200,
[FISH_GEAR_ROD] = 250,
[FISH_GEAR_FISHFINDER] = 150,
[FISH_GEAR_HOOK_GADDAN] = 300,
[FISH_GEAR_HOOK_PIRANHA] = 450,
[FISH_GEAR_HOOK_SHARK] = 650,
[FISH_GEAR_HOOK_WHALE] = 900,
[FISH_GEAR_HOOK_MUTATED] = 1200,
[FISH_GEAR_HOOK_BLUESHARK] = 550,
[FISH_GEAR_HOOK_TIGERFISH] = 400,
[FISH_GEAR_HOOK_TITAN] = 500,
[FISH_GEAR_HOOK_GAR] = 600,
[FISH_GEAR_HOOK_ANGLER] = 750,
[FISH_GEAR_HOOK_SUNFISH] = 850,
[FISH_GEAR_HOOK_OARFISH] = 1050,
[FISH_GEAR_HOOK_SPIDERCRAB] = 350,
[FISH_GEAR_HOOK_PUFFERFISH] = 480,
[FISH_GEAR_HOOK_TUNA] = 520,
[FISH_GEAR_HOOK_BINGBONG] = 1100,
[FISH_GEAR_HOOK_ALBATROSS] = 950,
},

GEAR_ENABLED = {
[FISH_GEAR_BAIT] = true,
[FISH_GEAR_MEDIUMCAGE] = true,
[FISH_GEAR_LARGECAGE] = true,
[FISH_GEAR_CONTAINER] = true,
[FISH_GEAR_ROD] = true,
[FISH_GEAR_FISHFINDER] = true,
[FISH_GEAR_HOOK_GADDAN] = true,
[FISH_GEAR_HOOK_PIRANHA] = true,
[FISH_GEAR_HOOK_SHARK] = true,
[FISH_GEAR_HOOK_WHALE] = true,
[FISH_GEAR_HOOK_MUTATED] = true,
[FISH_GEAR_HOOK_BLUESHARK] = true,
[FISH_GEAR_HOOK_TIGERFISH] = true,
[FISH_GEAR_HOOK_TITAN] = true,
[FISH_GEAR_HOOK_GAR] = true,
[FISH_GEAR_HOOK_ANGLER] = true,
[FISH_GEAR_HOOK_SUNFISH] = true,
[FISH_GEAR_HOOK_OARFISH] = true,
[FISH_GEAR_HOOK_SPIDERCRAB] = true,
[FISH_GEAR_HOOK_PUFFERFISH] = true,
[FISH_GEAR_HOOK_TUNA] = true,
[FISH_GEAR_HOOK_BINGBONG] = true,
[FISH_GEAR_HOOK_ALBATROSS] = true,
},

}

// example: TrueFishAddFish("GOLDFISH2", "Gold Fish", "models/props/de_inferno/GoldFish.mdl", {10, 20}, {100, 150}, 50)
function TrueFishAddFish(variableName, name, model, catchTime, depth, price, notDisabled)
	FISH_HIGHNUMBER = FISH_HIGHNUMBER + 1
	_G["FISH_"..variableName] = FISH_HIGHNUMBER
	FishNames[FISH_HIGHNUMBER] = name
	FishModels[FISH_HIGHNUMBER] = model
	TrueFish.FISH_CATCH_TIME[FISH_HIGHNUMBER] = catchTime
	TrueFish.FISH_DEPTH[FISH_HIGHNUMBER] = depth
	TrueFish.FISH_PRICE[FISH_HIGHNUMBER] = price
	TrueFish.FISH_ENABLED[FISH_HIGHNUMBER] = !notDisabled
end

function TrueFishCalculateFish(depth, fullTable)
	local tbl = {}
	for i=1, FISH_HIGHNUMBER do
		if i != FISH_JUNK and TrueFish.FISH_ENABLED[i] and depth > TrueFish.FISH_DEPTH[i][1] and depth < TrueFish.FISH_DEPTH[i][2] then
			tbl[#tbl+1] = i 
		end
	end

	return fullTable and tbl or tbl[math.random(#tbl)]
end

/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

-- TABLA GLOBAL DE OFFSETS DE BOCA DE PECES (Para alineación exacta en el anzuelo)
TrueFishMouthOffsets = TrueFishMouthOffsets or {
	[1] = 4.65,  -- clownfish
	[2] = 4.88,  -- goldfish
	[3] = 9.11,  -- salmon
	[4] = 19.23, -- tuna
	[5] = 8.67,  -- pufferfish
	[6] = 10.61, -- catfish
	[7] = 11.07, -- bass
	[8] = 5.0,   -- junk
}

function TrueFishGetMouthOffset(fishID)
	return (TrueFishMouthOffsets[fishID] or 10.0) * 1.5
end

-- ==========================================================================
-- ==========================================================================
-- NORMALIZACION AUTOMATICA DE ESCALA POR MODELO (pez colgando del anzuelo)
-- Cada pez importado traia un tamano compilado muy distinto (alevin ~3u, atun ~58u).
-- Esta tabla escala cada modelo para que su dimension dominante mida ~FISH_HANG_LENGTH
-- unidades, de modo que TODOS los peces queden parejos colgando del anzuelo.
-- La escala se aplica con SetModelScale; el offset de boca se multiplica por la escala.
-- ==========================================================================
TrueFish.FISH_HANG_LENGTH = TrueFish.FISH_HANG_LENGTH or 28

TrueFishHangScales = TrueFishHangScales or {
    ["models/fishing/fish_angelfish.mdl"] = 1.232,
    ["models/fishing/fish_anglerfish.mdl"] = 1.044,
    ["models/fishing/fish_bass.mdl"] = 0.843,
    ["models/fishing/fish_bingbong.mdl"] = 0.932,
    ["models/fishing/fish_blobfish.mdl"] = 0.951,
    ["models/fishing/fish_bluegill.mdl"] = 1.203,
    ["models/fishing/fish_blueshark.mdl"] = 0.55,
    ["models/fishing/fish_bowlfish.mdl"] = 1.237,
    ["models/fishing/fish_browncrab.mdl"] = 1.358,
    ["models/fishing/fish_catfish.mdl"] = 0.88,
    ["models/fishing/fish_clam.mdl"] = 1.593,
    ["models/fishing/fish_clownfish.mdl"] = 1.8,
    ["models/fishing/fish_cod.mdl"] = 1.01,
    ["models/fishing/fish_dripfish.mdl"] = 0.931,
    ["models/fishing/fish_eel.mdl"] = 0.856,
    ["models/fishing/fish_flyingfish.mdl"] = 0.973,
    ["models/fishing/fish_footsnail.mdl"] = 1.8,
    ["models/fishing/fish_fry.mdl"] = 0.798,
    ["models/fishing/fish_gar.mdl"] = 0.862,
    ["models/fishing/fish_goby.mdl"] = 1.541,
    ["models/fishing/fish_goldfish.mdl"] = 1.8,
    ["models/fishing/fish_halibut.mdl"] = 0.813,
    ["models/fishing/fish_leech.mdl"] = 1.548,
    ["models/fishing/fish_lobster.mdl"] = 1.117,
    ["models/fishing/fish_mackerel.mdl"] = 0.984,
    ["models/fishing/fish_mackerelshiny.mdl"] = 0.984,
    ["models/fishing/fish_needlefish.mdl"] = 1.013,
    ["models/fishing/fish_oarfish.mdl"] = 0.649,
    ["models/fishing/fish_parrotfish.mdl"] = 0.839,
    ["models/fishing/fish_perch.mdl"] = 0.924,
    ["models/fishing/fish_pike.mdl"] = 0.834,
    ["models/fishing/fish_piranha.mdl"] = 1.114,
    ["models/fishing/fish_pufferfish.mdl"] = 1.076,
    ["models/fishing/fish_redsnapper.mdl"] = 1.036,
    ["models/fishing/fish_rockcrab.mdl"] = 1.358,
    ["models/fishing/fish_salmon.mdl"] = 1.025,
    ["models/fishing/fish_seahorse.mdl"] = 0.74,
    ["models/fishing/fish_seaurchin.mdl"] = 1.456,
    ["models/fishing/fish_sengarat.mdl"] = 0.804,
    ["models/fishing/fish_shrimp.mdl"] = 1.8,
    ["models/fishing/fish_spidercrab.mdl"] = 0.55,
    ["models/fishing/fish_stonefish.mdl"] = 0.979,
    ["models/fishing/fish_sunfish.mdl"] = 0.63,
    ["models/fishing/fish_superdwarffish.mdl"] = 1.8,
    ["models/fishing/fish_tigerfish.mdl"] = 0.816,
    ["models/fishing/fish_titantriggerfish.mdl"] = 0.989,
    ["models/fishing/fish_tuna.mdl"] = 0.55,
    ["models/fishing/fish_voxelfish.mdl"] = 1.1,
    ["models/fishing/fish_yellowboxfish.mdl"] = 1.182,
}

function TrueFishGetHangScale(modelPath)
    return (modelPath and TrueFishHangScales[modelPath]) or 1.0
end


-- PECES RESTANTES DE 'HOW TO FISH' IMPORTADOS AL ADDON (42 PECES)
-- ==========================================================================
TrueFishAddFish("ANGELFISH", "Pez Ángel", "models/fishing/fish_angelfish.mdl", {6, 12}, {40, 300}, 75)
TrueFishMouthOffsets[FISH_ANGELFISH] = 7.58
TrueFishAddFish("ANGLERFISH", "Rape Abisal", "models/fishing/fish_anglerfish.mdl", {12, 24}, {650, 999}, 160)
TrueFishMouthOffsets[FISH_ANGLERFISH] = 8.94
TrueFishAddFish("BINGBONG", "Bing Bong", "models/fishing/fish_bingbong.mdl", {10, 20}, {100, 600}, 150)
TrueFishMouthOffsets[FISH_BINGBONG] = 9.91
TrueFishAddFish("BLOBFISH", "Pez Gota", "models/fishing/fish_blobfish.mdl", {10, 18}, {700, 999}, 140)
TrueFishMouthOffsets[FISH_BLOBFISH] = 9.82
TrueFishAddFish("BLUEGILL", "Agalla Azul", "models/fishing/fish_bluegill.mdl", {5, 10}, {10, 250}, 55)
TrueFishMouthOffsets[FISH_BLUEGILL] = 7.76
TrueFishAddFish("BLUESHARK", "Tiburón Azul", "models/fishing/fish_blueshark.mdl", {18, 35}, {400, 999}, 350)
TrueFishMouthOffsets[FISH_BLUESHARK] = 19.29
TrueFishAddFish("BOWLFISH", "Pez Pecera", "models/fishing/fish_bowlfish.mdl", {6, 11}, {20, 350}, 70)
TrueFishMouthOffsets[FISH_BOWLFISH] = 7.55
TrueFishAddFish("COD", "Bacalao", "models/fishing/fish_cod.mdl", {8, 15}, {50, 450}, 75)
TrueFishMouthOffsets[FISH_COD] = 9.24
TrueFishAddFish("BROWNCRAB", "Cangrejo Marrón", "models/fishing/fish_browncrab.mdl", {6, 12}, {0, 250}, 60)
TrueFishMouthOffsets[FISH_BROWNCRAB] = 6.87
TrueFishAddFish("ROCKCRAB", "Cangrejo de Roca", "models/fishing/fish_rockcrab.mdl", {7, 13}, {50, 350}, 70)
TrueFishMouthOffsets[FISH_ROCKCRAB] = 6.87
TrueFishAddFish("SPIDERCRAB", "Cangrejo Araña", "models/fishing/fish_spidercrab.mdl", {15, 28}, {500, 950}, 240)
TrueFishMouthOffsets[FISH_SPIDERCRAB] = 17.62
TrueFishAddFish("DRIPFISH", "Pez Drip", "models/fishing/fish_dripfish.mdl", {9, 17}, {200, 700}, 130)
TrueFishMouthOffsets[FISH_DRIPFISH] = 10.03
TrueFishAddFish("EEL", "Anguila", "models/fishing/fish_eel.mdl", {8, 16}, {150, 600}, 85)
TrueFishMouthOffsets[FISH_EEL] = 10.91
TrueFishAddFish("FLYINGFISH", "Pez Volador", "models/fishing/fish_flyingfish.mdl", {6, 11}, {0, 200}, 90)
TrueFishMouthOffsets[FISH_FLYINGFISH] = 9.59
TrueFishAddFish("FOOTSNAIL", "Caracol Marino", "models/fishing/fish_footsnail.mdl", {5, 9}, {0, 200}, 45)
TrueFishMouthOffsets[FISH_FOOTSNAIL] = 4.31
TrueFishAddFish("FRY", "Alevín", "models/fishing/fish_fry.mdl", {4, 7}, {0, 150}, 35)
TrueFishMouthOffsets[FISH_FRY] = 1.75
TrueFishAddFish("GAR", "Pez Cocodrilo (Gar)", "models/fishing/fish_gar.mdl", {10, 20}, {100, 500}, 115)
TrueFishMouthOffsets[FISH_GAR] = 10.82
TrueFishAddFish("GOBY", "Gobio", "models/fishing/fish_goby.mdl", {5, 9}, {0, 250}, 40)
TrueFishMouthOffsets[FISH_GOBY] = 6.06
TrueFishAddFish("HALIBUT", "Fletán", "models/fishing/fish_halibut.mdl", {12, 22}, {350, 800}, 160)
TrueFishMouthOffsets[FISH_HALIBUT] = 11.48
TrueFishAddFish("SEAHORSE", "Caballito de Mar", "models/fishing/fish_seahorse.mdl", {5, 10}, {10, 300}, 75)
TrueFishMouthOffsets[FISH_SEAHORSE] = 12.61
TrueFishAddFish("LEECH", "Sanguijuela", "models/fishing/fish_leech.mdl", {4, 8}, {0, 150}, 30)
TrueFishMouthOffsets[FISH_LEECH] = 1.02
TrueFishAddFish("LOBSTER", "Langosta", "models/fishing/fish_lobster.mdl", {9, 16}, {100, 500}, 125)
TrueFishMouthOffsets[FISH_LOBSTER] = 4.91
TrueFishAddFish("MACKEREL", "Caballa", "models/fishing/fish_mackerel.mdl", {7, 14}, {50, 400}, 65)
TrueFishMouthOffsets[FISH_MACKEREL] = 9.48
TrueFishAddFish("MACKERELSHINY", "Caballa Brillante", "models/fishing/fish_mackerelshiny.mdl", {8, 16}, {150, 600}, 135)
TrueFishMouthOffsets[FISH_MACKERELSHINY] = 9.48
TrueFishAddFish("NEEDLEFISH", "Pez Aguja", "models/fishing/fish_needlefish.mdl", {6, 12}, {10, 300}, 75)
TrueFishMouthOffsets[FISH_NEEDLEFISH] = 9.21
TrueFishAddFish("OARFISH", "Pez Remo Gigante", "models/fishing/fish_oarfish.mdl", {16, 32}, {600, 999}, 320)
TrueFishMouthOffsets[FISH_OARFISH] = 14.39
TrueFishAddFish("PARROTFISH", "Pez Loro", "models/fishing/fish_parrotfish.mdl", {8, 15}, {50, 450}, 95)
TrueFishMouthOffsets[FISH_PARROTFISH] = 11.12
TrueFishAddFish("PERCH", "Perca", "models/fishing/fish_perch.mdl", {7, 13}, {20, 350}, 60)
TrueFishMouthOffsets[FISH_PERCH] = 10.1
TrueFishAddFish("PIKE", "Lucio", "models/fishing/fish_pike.mdl", {10, 18}, {100, 550}, 90)
TrueFishMouthOffsets[FISH_PIKE] = 11.19
TrueFishAddFish("PIRANHA", "Piraña", "models/fishing/fish_piranha.mdl", {6, 12}, {50, 400}, 55)
TrueFishMouthOffsets[FISH_PIRANHA] = 8.38
TrueFishAddFish("REDSNAPPER", "Huachinango (Pargo)", "models/fishing/fish_redsnapper.mdl", {8, 16}, {80, 500}, 85)
TrueFishMouthOffsets[FISH_REDSNAPPER] = 9.01
TrueFishAddFish("SEAURCHIN", "Erizo de Mar", "models/fishing/fish_seaurchin.mdl", {5, 10}, {0, 300}, 50)
TrueFishMouthOffsets[FISH_SEAURCHIN] = 6.41
TrueFishAddFish("SENGARAT", "Belodontichthys (Sengarat)", "models/fishing/fish_sengarat.mdl", {9, 18}, {150, 600}, 110)
TrueFishMouthOffsets[FISH_SENGARAT] = 11.61
TrueFishAddFish("SHRIMP", "Camarón", "models/fishing/fish_shrimp.mdl", {4, 8}, {0, 200}, 40)
TrueFishMouthOffsets[FISH_SHRIMP] = 4.76
TrueFishAddFish("STONEFISH", "Pez Piedra", "models/fishing/fish_stonefish.mdl", {11, 20}, {250, 750}, 130)
TrueFishMouthOffsets[FISH_STONEFISH] = 9.54
TrueFishAddFish("SUNFISH", "Pez Luna (Mola Mola)", "models/fishing/fish_sunfish.mdl", {18, 35}, {400, 950}, 300)
TrueFishMouthOffsets[FISH_SUNFISH] = 11.4
TrueFishAddFish("SUPERDWARFFISH", "Pez Súper Enano", "models/fishing/fish_superdwarffish.mdl", {4, 7}, {0, 150}, 45)
TrueFishMouthOffsets[FISH_SUPERDWARFFISH] = 3.94
TrueFishAddFish("TIGERFISH", "Pez Tigre Goliat", "models/fishing/fish_tigerfish.mdl", {12, 24}, {300, 800}, 170)
TrueFishMouthOffsets[FISH_TIGERFISH] = 11.44
TrueFishAddFish("TITANTRIGGERFISH", "Pez Ballesta Titán", "models/fishing/fish_titantriggerfish.mdl", {10, 20}, {150, 650}, 130)
TrueFishMouthOffsets[FISH_TITANTRIGGERFISH] = 9.44
TrueFishAddFish("VOXELFISH", "Pez Vóxel", "models/fishing/fish_voxelfish.mdl", {10, 20}, {100, 700}, 160)
TrueFishMouthOffsets[FISH_VOXELFISH] = 8.49
TrueFishAddFish("YELLOWBOXFISH", "Pez Cofre Amarillo", "models/fishing/fish_yellowboxfish.mdl", {7, 13}, {50, 400}, 80)
TrueFishMouthOffsets[FISH_YELLOWBOXFISH] = 7.9
TrueFishAddFish("CLAM", "Almeja Gigante", "models/fishing/fish_clam.mdl", {5, 11}, {0, 300}, 70)
TrueFishMouthOffsets[FISH_CLAM] = 5.86

-- ==========================================================================
-- INTERACCIÓN CON GRAVITY GUN PARA PECES MUERTOS (SHARED: CLIENTE + SERVIDOR)
-- ==========================================================================
hook.Add("GravGunPickupAllowed", "TrueFishing_GravGunPickupAllowed", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "ent_angry_fish" then
		if ent.IsDead or ent:GetNW2Bool("IsDead", false) then
			return true
		else
			return false
		end
	end
end)

hook.Add("GravGunPunt", "TrueFishing_GravGunPunt", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "ent_angry_fish" then
		if ent.IsDead or ent:GetNW2Bool("IsDead", false) then
			return true
		else
			return false
		end
	end
end)

