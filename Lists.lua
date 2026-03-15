local _, MakuluFramework  = ...
MakuluFramework           = MakuluFramework or _G.MakuluFramework

local lists               = {}

local function arrayToLuT(array)
    local newLuT = {}
    for _, item in ipairs(array) do
        newLuT[item] = true
    end
    
    return newLuT
end

lists.purgeableBuffs      = {
    --[10060] = true,  -- Power Infusion
    [1022] = true,   -- Blessing of Protection
    --[79206] = true,  -- Spiritwalkers Grace
    --[12042] = true,  -- Arcane Power
    [12472] = true,  -- Icy Veins
    --[467] = true,    -- Thorns
    --[29166] = true,  -- Innervate
    --[358267] = true, -- Hover
    --[378464] = true, -- Nullifying Shroud
    [108978] = true, -- Alter Time
    [342246] = true,  -- alterTime
    [212295] = true, -- netherward
    [204361] = true, -- bloodlust (arena version)
    [466904] = true, -- Harrier's Cry (MM Bloodlust)
    [213610] = true, -- Holy Ward
}

--WIP
lists.purgeableBuffsLowHP = {}

lists.shatteringBuffs = {
    [642] = true, -- Bubble
    [45438] = true, -- Ice Block
    
}

lists.feared              = {
    -- Warlock Fears
    [5782] = true,   -- Fear
    [118699] = true, -- Fear (Horrify)
    [130616] = true, -- Fear (variant)
    [5484] = true,   -- Howl of Terror
    -- Priest Fears
    [8122] = true,   -- Psychic Scream
    [64044] = true,  -- Psychic Horror
    -- Warrior Fears
    [5246] = true,   -- Intimidating Shout
    [316593] = true, -- Intimidating Shout (variant)
    [316595] = true, -- Intimidating Shout (variant)
    -- Demon Hunter Fear
    [207684] = true, -- Sigil of Misery
    -- Evoker Fear
    [360806] = true, -- Sleep Walk
}

-- Berserker Rage breaks Fear and Incapacitate (not Sap)
lists.berserkerRageBreaks = {
    -- Fears
    [5782] = true,    -- Fear (Warlock)
    [118699] = true,  -- Fear Horrify (Warlock)
    [130616] = true,  -- Fear variant (Warlock)
    [5484] = true,    -- Howl of Terror (Warlock)
    [8122] = true,    -- Psychic Scream (Priest)
    [64044] = true,   -- Psychic Horror (Priest)
    [5246] = true,    -- Intimidating Shout (Warrior)
    [316593] = true,  -- Intimidating Shout variant (Warrior)
    [316595] = true,  -- Intimidating Shout variant (Warrior)
    [207684] = true,  -- Sigil of Misery (Demon Hunter)
    [360806] = true,  -- Sleep Walk (Evoker)
    
    -- Incapacitates
    [99] = true,      -- Incapacitating Roar (Druid)
    [3355] = true,    -- Freezing Trap (Hunter)
    [203337] = true,  -- Freezing Trap variant (Hunter)
    [19386] = true,   -- Wyvern Sting (Hunter)
    [217832] = true,  -- Imprison (Demon Hunter)
    [20066] = true,   -- Repentance (Paladin)
    [115078] = true,  -- Paralysis (Monk)
    [107079] = true,  -- Quaking Palm (Pandaren)
    [2637] = true,    -- Hibernate (Druid)
    [9484] = true,    -- Shackle Undead (Priest)
    [6358] = true,    -- Seduction (Warlock Succubus)
    [261589] = true,  -- Seduction Grimoire (Warlock)
}

lists.arenaDispelDebuffs  = {
    -- Disorients
    [605] = true,    -- mind control
    [8122] = true,   -- psychic scream
    [205369] = true, -- mind bomb
    [115750] = true, -- blinding light
    [5782] = true,   -- fear
    [118699] = true, -- fear 2
    [130616] = true, -- fear 3
    [5484] = true,   -- howl of terror
    [6358] = true,   -- seduction
    [198898] = true, -- song of chi-ji
    
    -- Incapacitates
    [2637] = true,   -- hibernate
    [217832] = true, -- imprison
    [118] = true,    -- Polymorph - normal
    [28271] = true,  -- Polymorph - Turtle
    [28272] = true,  -- Polymorph - Pig
    [28285] = true,  -- Polymorph - Pig 2
    [61305] = true,  -- Polymorph - Black Cat
    [61721] = true,  -- Polymorph - Rabbit
    [61025] = true,  -- Polymorph - Serpent
    [61780] = true,  -- Polymorph - Turkey
    [161372] = true, -- Polymorph - Peacock
    [161355] = true, -- Polymorph - Penguin
    [161353] = true, -- Polymorph - Polar Bear Cub
    [161354] = true, -- Polymorph - Monkey
    [126819] = true, -- Polymorph - Porcupine
    [277787] = true, -- Polymorph - Direhorn
    [277792] = true, -- Polymorph - Bumblebee
    [391622] = true, -- Polymorph - Duck
    [321395] = true, -- Polymorph - Mawrat
    [113724] = true, -- ring of frost
    [187650] = true, -- freezing trap
    [20066] = true,  -- repentance
    
    -- Silences
    --[47476] = true,  -- strangulate
    [410201] = true, -- searing glare
    
    -- Roots
    [339] = true,    -- entangling roots
    [122] = true,    -- frost nova
    [102359] = true, -- mass entanglement
    [33395] = true,  -- freeze
    [109248] = true, -- binding shot
    [51485] = true,  -- earthgrab totem 1
    [64695] = true,  -- earthgrab totem 2
    
    -- Stuns
    [853] = true,    -- hammer of justice
    [179057] = true, -- chaos Nova
    [64044] = true,  -- psychic horror
    [200199] = true, -- censure
    
    --[375901] = true, -- mindgames new 2
    [80240] = true,  -- havoc
    [325640] = true,  -- soul rot
    [390612] = true, -- frost bomb
}

lists.arenaKicks          = {
    [118] = true,    -- Polymorph
    [5782] = true,   -- Fear
    [20066] = true,  -- Repentence
    [51514] = true,  -- Hex
    [254412] = true, -- Hex 2
    [33786] = true,  -- Cyclone
    [323673] = true, -- Mindgames
    [323701] = true, -- Mindgames
    [605] = true,    -- Mind Control
    [205367] = true, -- Dominate Mind
    [323764] = true, -- Convoke
    [360806] = true, -- Sleep Walk
    [47540] = true,  -- Penance
    [47757] = true, -- Penance
    [186723] = true, -- Penance
    [2060] = true,   -- Heal
    [2061] = true,   -- Flash Heal
    [289666] = true, -- Greater Heal
    [64843] = true,  -- Divine Hymn
    [265202] = true, -- Holy Word: Salvation
    -- [8936] = true,   -- Regrowth
    [289022] = true, -- Nourish
    [48438] = true,  -- Wild Growth
    [202771] = true, -- Full Moon
    [77472] = true,  -- Healing Wave
    [8004] = true,   -- Healing Surge
    [1064] = true,   -- Chain Heal
    [73920] = true,  -- Healing Rain
    [197995] = true, -- Wellspring
    [207778] = true, -- Downpour
    [204437] = true, -- Lightning Lasso
    [19750] = true,  -- Flash of Light
    [82326] = true,  -- Holy Light
    [410126] = true, -- Searing Glare
    [115175] = true, -- Soothing Mist
    [116670] = true, -- Vivify
    [124682] = true, -- Enveloping Mist
    [191837] = true, -- Essence Font
    [227344] = true, -- Surging Mist
    [376788] = true, -- Dream Breath
    [367226] = true, -- Spiritbloom
    [361469] = true, -- Living Flame
    [982] = true,    -- Revive pet
    [454009] = true, -- tempest
    -- [198013] = true, -- Eye Beam
    [113724] = true, -- Ring of Frost
    [199786] = true, -- Glacial Spike
    [365350] = true, -- Arcane Surge
    [234153] = true, -- Drain Life
    [116858] = true, -- Chaos Bolt
    [421453] = true, -- Ultimate Penitence
    [391109] = true, -- Dark Ascension
    [8092] = true, -- Mind Blast
    [357208] = true, -- Fire Breath
    [686] = true, -- Shadow Bolt
    [48181] = true, -- Haunt
    [191634] = true, -- Stormkeeper
    [352278] = true, -- Ice Wall
    [28271] = true,  -- polymorphTurtle
    [28272] = true,  -- polymorphPig
    [61025] = true,  -- polymorphSnake
    [61305] = true,  -- polymorphBlackCat
    [61780] = true,  -- polymorphTurkey
    [61721] = true,  -- polymorphRabbit
    [126819] = true, -- polymorphPorcupine
    [161353] = true, -- polymorphPolarBearCub
    [161354] = true, -- polymorphMonkey
    [161355] = true, -- polymorphPenguin
    [161372] = true, -- polymorphPeacock
    [277787] = true, -- polymorphBabyDirehorn
    [277792] = true, -- polymorphBumblebee
    [321395] = true, -- polymorphMawrat
    [391622] = true, -- polymorphDuck
    [196942] = true, -- hexVoodooTotem
    [210873] = true, -- hexRaptor
    [211004] = true, -- hexSpider
    [211010] = true, -- hexSnake
    [211015] = true, -- hexCockroach
    [269352] = true, -- hexSkeletalHatchling
    [309328] = true, -- hexLivingHoney
    [277778] = true, -- hexZandalariTendonripper
    [277784] = true, -- hexWickerMongrel
    [198898] = true, -- songOfChiji
    [2637] = true,   -- hibernate
    [710] = true,    -- banish
    [10326] = true,  -- turnEvil
    [691] = true,    -- summonFelhunter
    [688] = true,    -- summonImp
    [712] = true,    -- summonSuccubus
    [32375] = true,  -- massDispel
    [203286] = true, -- greaterPyro
    [6353] = true,   -- soulFire
    [265187] = true, -- summonTyrant
    [263165] = true, -- voidTorrent
    --[378464] = true, -- nullifyingShroud
    --[356995] = true, -- disintegrate
    [30283] = true,  -- shadowFury
    [205021] = true, -- rayOfFrost
    [30146] = true,  -- summonfelguard
    [390612] = true, -- frostBomb
    [396286] = true, -- upheavel
    [410201] = true, -- searingGlare
    --[30108] = true,  -- Unstable Affliction
    --[316099] = true, -- Unstable affliction
    [47536] = true, -- Rapture
    [386997] = true, -- soul rot
    [171788] = true, -- haunt
    [200652] = true, --Tyr's Deliverance
    [414273] = true, -- Hand of Divinity
    [395152] = true, -- Ebon Might
    [395160] =true, -- Eruption
    [473909] = true, -- Ancient of Lore (Restoration Druid PvP talent)
    [8092] = true, -- Mind Blast 
    [360806] = true, -- Sleep Walk
}

lists.arenaKicksHeals     = {
    [47540] = true,  -- Penance
    [186723] = true, -- Penance
    [2060] = true,   -- Heal
    [2061] = true,   -- Flash Heal
    [289666] = true, -- Greater Heal
    [64843] = true,  -- Divine Hymn
    [265202] = true, -- Holy Word: Salvation
    -- [8936] = true,   -- Regrowth
    [289022] = true, -- Nourish
    [48438] = true,  -- Wild Growth
    [77472] = true,  -- Healing Wave
    [8004] = true,   -- Healing Surge
    [1064] = true,   -- Chain Heal
    [73920] = true,  -- Healing Rain
    [197995] = true, -- Wellspring
    [207778] = true, -- Downpour
    [19750] = true,  -- Flash of Light
    [82326] = true,  -- Holy Light
    [115175] = true, -- Soothing Mist
    [116670] = true, -- Vivify
    [124682] = true, -- Enveloping Mist
    [191837] = true, -- Essence Font
    [227344] = true, -- Surging Mist
    [376788] = true, -- Dream Breath
    [367226] = true, -- Spiritbloom
    [361469] = true, -- Living Flame
    [421453] = true, -- Ultimate Penitence
}

lists.arenaKicksCCs       = {
    [118] = true,    -- Polymorph
    [5782] = true,   -- Fear
    [20066] = true,  -- Repentence
    [51514] = true,  -- Hex
    [33786] = true,  -- Cyclone
    [605] = true,    -- Mind Control
    [360806] = true, -- Sleep Walk
    [28271] = true,  -- polymorphTurtle
    [28272] = true,  -- polymorphPig
    [61025] = true,  -- polymorphSnake
    [61305] = true,  -- polymorphBlackCat
    [61780] = true,  -- polymorphTurkey
    [61721] = true,  -- polymorphRabbit
    [126819] = true, -- polymorphPorcupine
    [161353] = true, -- polymorphPolarBearCub
    [161354] = true, -- polymorphMonkey
    [161355] = true, -- polymorphPenguin
    [161372] = true, -- polymorphPeacock
    [277787] = true, -- polymorphBabyDirehorn
    [277792] = true, -- polymorphBumblebee
    [321395] = true, -- polymorphMawrat
    [391622] = true, -- polymorphDuck
    [196942] = true, -- hexVoodooTotem
    [210873] = true, -- hexRaptor
    [211004] = true, -- hexSpider
    [211010] = true, -- hexSnake
    [211015] = true, -- hexCockroach
    [269352] = true, -- hexSkeletalHatchling
    [309328] = true, -- hexLivingHoney
    [277778] = true, -- hexZandalariTendonripper
    [277784] = true, -- hexWickerMongrel
    [198898] = true, -- songOfChiji
    [2637] = true,   -- hibernate
    [710] = true,    -- banish
    [10326] = true,  -- turnEvil
}

lists.arenaSpellReflect = {
    [118] = true,    -- Polymorph
    [5782] = true,   -- Fear
    [20066] = true,  -- Repentence
    [51514] = true,  -- Hex
    [33786] = true,  -- Cyclone
    [605] = true,    -- Mind Control
    [360806] = true, -- Sleep Walk
    [28271] = true,  -- polymorphTurtle
    [28272] = true,  -- polymorphPig
    [61025] = true,  -- polymorphSnake
    [61305] = true,  -- polymorphBlackCat
    [61780] = true,  -- polymorphTurkey
    [61721] = true,  -- polymorphRabbit
    [126819] = true, -- polymorphPorcupine
    [161353] = true, -- polymorphPolarBearCub
    [161354] = true, -- polymorphMonkey
    [161355] = true, -- polymorphPenguin
    [161372] = true, -- polymorphPeacock
    [277787] = true, -- polymorphBabyDirehorn
    [277792] = true, -- polymorphBumblebee
    [321395] = true, -- polymorphMawrat
    [391622] = true, -- polymorphDuck
    [196942] = true, -- hexVoodooTotem
    [210873] = true, -- hexRaptor
    [211004] = true, -- hexSpider
    [211010] = true, -- hexSnake
    [211015] = true, -- hexCockroach
    [269352] = true, -- hexSkeletalHatchling
    [309328] = true, -- hexLivingHoney
    [277778] = true, -- hexZandalariTendonripper
    [277784] = true, -- hexWickerMongrel
    [390612] = true, -- frostBomb
}

lists.AMSDispell          = arrayToLuT({
        390612,   -- Frost Bomb
        44457,    -- Living Bomb
})

lists.arenaGrounding      = {
    [118] = true,    -- Poly
    [605] = true,    -- Mind control
    [5782] = true,   -- Fear
    [20066] = true,  -- Repentance
    [33786] = true,  -- Cyclone
    [51514] = true,  -- Hex
    [116858] = true, -- Chaos bolt
    [199786] = true, -- Glacial spike
    [269352] = true, -- Other hex
    [360806] = true, -- Sleep walk
    [390612] = true, -- frost bomb
    [44457] = true,  -- living bomb
    [104316] = true, -- call dreadstalkers
    [386997] = true, -- soul rot
    [359073] = true, -- eternity surge
    [323673] = true, -- mindgames
    [61305] = true,  -- poly x
    [365350] = true, -- arcane surge
}

lists.arenaTremor         = {
    [5782] = true,   -- Fear
    [360806] = true, -- Sleep walk
    [5246] = true,   -- Intimidating Shout
    [8122] = true,   -- Psychic Scream
    [207684] = true, -- Sigil of Misery
}

lists.arenaHealerGround = {
    [190925] = true, -- Harpoon
    [213691] = true, -- Scatter
    [24394] = true, -- Intim
}

lists.arenaFadeList = {
    [118] = true,    -- Polymorph - normal
    [28271] = true,  -- Polymorph - Turtle
    [28272] = true,  -- Polymorph - Pig
    [28285] = true,  -- Polymorph - Pig 2
    [61305] = true,  -- Polymorph - Black Cat
    [61721] = true,  -- Polymorph - Rabbit
    [61025] = true,  -- Polymorph - Serpent
    [61780] = true,  -- Polymorph - Turkey
    [161372] = true, -- Polymorph - Peacock
    [161355] = true, -- Polymorph - Penguin
    [161353] = true, -- Polymorph - Polar Bear Cub
    [161354] = true, -- Polymorph - Monkey
    [126819] = true, -- Polymorph - Porcupine
    [277787] = true, -- Polymorph - Direhorn
    [277792] = true, -- Polymorph - Bumblebee
    [391622] = true, -- Polymorph - Duck
    [321395] = true, -- polymorphMawrat
    [51514] = true, -- OG Hex
    [219216] = true, -- Hex?
    [219217] = true, -- Another Hex?
    [219218] = true, -- Another Hex??
    [219219] = true, -- Another Hex???
    [254412] = true, -- Hex
    [196942] = true, -- Hex (Voodoo Totem)
    [210873] = true, -- Hex (Raptor)
    [211004] = true, -- Hex (Spider)
    [211010] = true, -- Hex (Snake)
    [269352] = true, -- Hex (Skeletal Hatchling)
    [269355] = true, -- Hex Again
    [309328] = true, -- Hex (Living Honey)
    [277778] = true, -- Hex (Zandalari Tendonripper)
    [277780] = true, -- Hex Something
    [277785] = true, -- Another fucking Hex
    [277784] = true, -- Hex (Wicker Mongrel)
    [33786] = true, -- Cyclone
    [20066] = true, -- Repentance
    [5782] = true, -- Fear
    [360806] = true, --Sleep Walk
    
}

lists.swdList = {
    [118] = true,    -- Polymorph - normal
    [28271] = true,  -- Polymorph - Turtle
    [28272] = true,  -- Polymorph - Pig
    [28285] = true,  -- Polymorph - Pig 2
    [61305] = true,  -- Polymorph - Black Cat
    [61721] = true,  -- Polymorph - Rabbit
    [61025] = true,  -- Polymorph - Serpent
    [61780] = true,  -- Polymorph - Turkey
    [161372] = true, -- Polymorph - Peacock
    [161355] = true, -- Polymorph - Penguin
    [161353] = true, -- Polymorph - Polar Bear Cub
    [161354] = true, -- Polymorph - Monkey
    [126819] = true, -- Polymorph - Porcupine
    [277787] = true, -- Polymorph - Direhorn
    [277792] = true, -- Polymorph - Bumblebee
    [391622] = true, -- Polymorph - Duck
    [219216] = true, -- Hex?
    [219217] = true, -- Another Hex?
    [219218] = true, -- Another Hex??
    [219219] = true, -- Another Hex???
    [51514] = true, -- OG Hex
    [254412] = true, -- Hex
    [196942] = true, -- Hex (Voodoo Totem)
    [210873] = true, -- Hex (Raptor)
    [211004] = true, -- Hex (Spider)
    [211010] = true, -- Hex (Snake)
    [269352] = true, -- Hex (Skeletal Hatchling)
    [269355] = true, -- Hex Again
    [309328] = true, -- Hex (Living Honey)
    [277778] = true, -- Hex (Zandalari Tendonripper)
    [277780] = true, -- Hex Something
    [277785] = true, -- Another fucking Hex
    [277784] = true, -- Hex (Wicker Mongrel)
    [20066] = true, -- Repentance
    [5782] = true, -- Fear
    [360806] = true, --Sleep Walk
}

lists.dontGrip            = arrayToLuT({
        206959,     -- Rain from Above
        206804,     -- Rain from Above
        73325,      -- Leap of Faith
        113942,     -- Demonic Gateway?
        376079,     -- Spear of Bastion
        357210,     -- Deep Breath
        444347,     -- Death Charge
        23920,      -- Spell Reflection
        444347,     -- Spell Reflection
        212295,     -- Nether Ward
})

lists.zerkRoot            = arrayToLuT({
        204085,   -- Deathchill (Chains of Ice)
        233395,   -- Deathchill (Remorseless Winter)
        339,      -- Entangling Roots
        235963,   -- Entangling Roots (Earthen Grasp)
        170855,   -- Entangling Roots (Nature's Grasp)
        102359,   -- Mass Entanglement
        355689,   -- Landslide
        393456,   -- Entrapment (Tar Trap)
        162480,   -- Steel Trap
        273909,   -- Steelclaw Trap
        212638,   -- Tracker's Net
        201158,   -- Super Sticky Tar
        122,      -- Frost Nova
        33395,    -- Freeze
        386770,   -- Freezing Cold
        198121,   -- Frostbite
        114404,   -- Void Tendril's Grasp
        342375,   -- Tormenting Backlash (Torghast PvE)
        233582,   -- Entrenched in Flame
        116706,   -- Disable
        324382,   -- Clash
        64695,    -- Earthgrab (Totem effect)
        285515,   -- Surge of Power
        199042,   -- Thunderstruck (Protection PvP Talent)
        39965,    -- Frost Grenade (Item)
        75148,    -- Embersilk Net (Item)
        55536,    -- Frostweave Net (Item)
        268966,   -- Hooked Deep Sea Net (Item)
        91802,    -- Shambling Rush
        454787,   -- Ice Prison
        454786,   -- Ice Prison2
        316595,   -- Intimidating Shout
        316593,   -- Intimidating Shout
        5246,     -- Intimidating Shou
})

lists.freedom = arrayToLuT({
        339, --entangling roots
        122, --frost nova
        102359, --mass entanglement
        51485, --earthgrab totem
        162488, --steel trap
        212638, --tracker's net
        64695, -- earthgrab totem
        358385, --Landslide
        114404, -- void tendrils
        3409, -- crippling poison
        5116, -- concussive shot (testing)
        450505, -- enfebling spirit
})

lists.sanc = {
    [5782] = true, -- Fear
    [118699] = true, -- fear 2
    [130616] = true, -- fear 3
    [5484] = true, -- Howl of Terror
    [8122] = true, -- Psychic Scream
    [5246] = true, -- Intimidating Shout
    [82691] = true, -- Ring of Frost
    [221562] = true, -- Asphyxiate
    [108194] = true, --Aspyhxiate
    [211881] = true, --Fel Eruption
    [179057] = true, --Chaos Nova
    [22570] = true, --Maim
    [5211] = true, --Mighty Bash
    [19577] = true, --Intimidation
    [119381] = true, --Leg Sweep
    [853] = true, --Hammer of Justice
    [200199] = true, --Censure
    [64044] = true, --Psychic Horror
    [1833] = true, --Cheap Shot
    [408] = true, --Kidney Shot
    [204437] = true, --Lightning Lasso
    [132169] = true, --Storm Bolt
    [47476] = true, --Strangulate
    [205630] = true, --Illidan's Grasp
    [202137] = true, --Sigil of Silence
    [15478] = true, --Silence
    [118905] = true, -- capacitor totem
    [24394] = true, -- Intimidation
}

lists.TotalImmune = arrayToLuT({
        642,    --Divine Shield
        45438,  --Ice Block
        186265, --Aspect of Turtle
        215769, --Spirit of Redemption
        33786,  --Cyclone
        196555, --Netherwalk
        408557, --Phase Shift
        421453, --Ultimate Penitence
        740,    --Tranquility
        409293, --Burrow
        378441, --Time stop
        3355,   -- Freezing Trap
        217832, --Imprison
        221527,  --Imprison Pvp Talent
        362486, --Tranquility (preserve nature)
        408558, -- Phase Shift
        203337, --Diamond Trap
        1221107, -- Overpowered Barrier
})

lists.Passive = arrayToLuT({
        45438,  --Ice Block
        186265, --Aspect of Turtle
        378441, --Time stop
        409293, --Burrow
        196555, --Netherwalk
})

lists.TotalImmuneDebuff = arrayToLuT({
        33786,  --Cyclone
        217832, --Imprison
        203337, --Diamond Trap
        221527, --Imprison Pvp Talent
        3355,   -- Freezing Trap
})

lists.PhysicalImmune = arrayToLuT({
        1022,  --Blessing of Protection
        5277,  --Evasion
        118038, --Die by the Sword
        408558, -- Phase Shift
})

lists.MagicImmune = arrayToLuT({
        31224,  -- Cloak of Shadows
        204018, -- Blessing of Spellwarding
        8178,   --Grounding Totem
        212295, --Nether Ward
        115310, --Revival
        69901,  --Spell Reflect
        23920,  --Spell Reflection
        388615, -- Restoral
        353313, --Peaveweaver 1
        353319, --Peaveweaver 2
        408558, -- Phase Shift
})

lists.HealImmuneBuff = arrayToLuT({
        378441, --Time stop
})

lists.HealImmuneDebuff = arrayToLuT({
        33786,  --Cyclone
        221527, --Imprison Pvp Talent
})

lists.KickImmune = arrayToLuT({
        377362, --Precognition
        104773, --Unending Resolve
        377360, --Precognition
        131557, --Spiritwalker’s Aegis
        209584, --Zen Focus Tea
        378444,  --Obsidian Mettle
        642, -- Divine Shield
        408558, -- Phase Shift
        378078, -- Spiritwalker's Aegis
})

lists.CCImmune = arrayToLuT({
        104773, --Unending Resolve
        115310, --Revival
        378464, --Nullifying Shroud
        377360, --Precognition
        377362, -- precognition 2
        227847, --Bladestorm
        446035, --Bladestorm 2
        213610, --Holy Ward
        357210, --Deep Breath
        354489, --Glimpse
        8178,   --Grounding Totem - Not a immunity but want to avoid CCs while Totem is up
        317929,  --Aura Mastery
        421453, -- ultimate pen
        215769, -- Spirit of Redemption
        382486, -- Tranquility (preserve nature)
        408558, -- Phase Shift
        473909, -- Ancient of Lore
        455945, -- Absolute Serenity
        456499, -- Absolute Serenity
        
})

lists.hexImmune = arrayToLuT({
        642,    -- divineShield
        45438,  -- iceBlock
        186265, -- deterrence
        31224,  -- cloakOfShadows
        235450, -- prismatic
        33891, -- Incarn Tree
        117679, -- Incarn Two
        5487, -- Bear Form
        783, -- Travel Form
        768, -- Cat Form
        186265, -- Turtle
        408558, -- Phase Shift
        473909, -- Ancient of Lore
})

lists.Rooted = arrayToLuT({
        204085, -- Deathchill (Chains of Ice)
        233395, -- Deathchill (Remorseless Winter)
        454787, -- Ice Prison
        339,    -- Entangling Roots
        343238, -- Entangling Roots (Soulshape)
        235963, -- Entangling Roots (Earthen Grasp)
        170855, -- Entangling Roots (Nature's Grasp)
        102359, -- Mass Entanglement
        355689, -- Landslide
        393456, -- Entrapment (Tar Trap)
        162480, -- Steel Trap
        273909, -- Steelclaw Trap
        212638, -- Tracker's Net
        201158, -- Super Sticky Tar
        122,    -- Frost Nova
        33395,  -- Freeze
        386770, -- Freezing Cold
        198121, -- Frostbite
        114404, -- Void Tendril's Grasp
        342375, -- Tormenting Backlash (Torghast PvE)
        233582, -- Entrenched in Flame
        116706, -- Disable
        324382, -- Clash
        64695,  -- Earthgrab (Totem effect)
        285515, -- Surge of Power
        199042, -- Thunderstruck (Protection PvP Talent)
        39965,  -- Frost Grenade (Item)
        75148,  -- Embersilk Net (Item)
        55536,  -- Frostweave Net (Item)
        268966,  -- Hooked Deep Sea Net (Item)
        
        290366,  -- Commandant's Frigid Winds           (Daelin Proudmoore's Saber+Lord Admiral's Signet 2-set, from Battle of Dazar'alor raid)
        204085, -- Deathchill (Chains of Ice)
        233395, -- Deathchill (Remorseless Winter)
        454787, -- Ice Prison
        339, -- Entangling Roots
        235963, -- Entangling Roots (Earthen Grasp)
        170855, -- Entangling Roots (Nature's Grasp)
        16979, -- Wild Charge (has no DR)
        102359, -- Mass Entanglement
        355689, -- Landslide
        393456, -- Entrapment (Tar Trap)
        162480, -- Steel Trap
        190927, -- Harpoon (has no DR)
        212638, -- Tracker's Net
        201158, -- Super Sticky Tar
        122, -- Frost Nova
        33395, -- Freeze
        386770, -- Freezing Cold
        378760, -- Frostbite
        199786, -- Glacial Spike (has no DR)
        114404, -- Void Tendril's Grasp
        342375, -- Tormenting Backlash (Torghast PvE)
        116706, -- Disable
        324382, -- Clash
        64695, -- Earthgrab (Totem effect)
        356738, -- Earth Unleashed
        285515, -- Surge of Power
        199042, -- Thunderstruck (Protection PvP Talent)
        356356, -- Warbringer
        39965, -- Frost Grenade (Item)
        75148, -- Embersilk Net (Item)
        55536, -- Frostweave Net (Item)
        268966, -- Hooked Deep Sea Net (Item)
})

lists.Slowed = arrayToLuT({
        116,    -- Frostbolt                           (mage, frost)
        1715,   -- Hamstring                           (warrior, arms)
        2120,   -- Flamestrike                         (mage, fire)
        3409,   -- Crippling Poison                    (rogue, assassination)
        3600,   -- Earthbind                           (shaman, general)
        5116,   -- Concussive Shot                     (hunter, beast mastery/marksman)
        6343,   -- Thunder Clap                        (warrior, protection)
        7992,   -- Slowing Poison                      (NPC ability)
        12323,  -- Piercing Howl                       (warrior, fury)
        12486,  -- Blizzard                            (mage, frost)
        12544,  -- Frost Armor                         (NPC ability only now?)
        15407,  -- Mind Flay                           (priest, shadow)
        31589,  -- Slow                                (mage, arcane)
        35346,  -- Warp Time                           (NPC ability)
        44614,  -- Flurry                              (mage, frost)
        45524,  -- Chains of Ice                       (death knight)
        50259,  -- Dazed                               (druid, PVE talent, general)
        50433,  -- Ankle Crack                         (hunter pet)
        51490,  -- Thunderstorm                        (shaman, elemental)
        58180,  -- Infected Wounds                     (druid, feral)
        61391,  -- Typhoon                             (druid, general)
        116095, -- Disable                             (monk, windwalker)
        118000, -- Dragon Roar                         (warrior, PVE talent, fury)
        121253, -- Keg Smash                           (monk, brewmaster)
        196733, -- Special Delivery                    (monk, brewmaster)
        123586, -- Flying Serpent Kick                 (monk, windwalker)
        127797, -- Ursol's Vortex                      (druid, restoration)
        135299, -- Tar Trap                            (hunter, survival)
        147732, -- Frostbrand Attack                   (shaman, enhancement)
        157981, -- Blast Wave                          (mage, fire)
        160065, -- Tendon Rip                          (hunter pet)
        160067, -- Web Spray                           (pet ability)
        183218, -- Hand of Hindrance                   (paladin, retribution)
        185763, -- Pistol Shot                         (rogue, outlaw)
        186387, -- Bursting Shot                       (hunter, marks)
        195645, -- Wing Clip                           (hunter, survival)
        196840, -- Frost Shock                         (shaman, elemental)
        198222, -- System Shock                        (rogue, assassination)
        198813, -- Vengeful Retreat                    (demon hunter, havoc)
        201787, -- Heavy-Handed Strikes                (monk, windwalker)
        204263, -- Shining Force                       (priest, disc/holy)
        204843, -- Sigil of Chains                     (demon hunter, veng)
        205021, -- Ray of Frost                        (mage, frost)
        205708, -- Chilled                             (mage, frost)
        206930, -- Heart Strike                        (death knight, blood)
        208278, -- Debilitating Infestation            (DK unholy talent)
        211793, -- Remorseless Winter                  (death knight, frost)
        212792, -- Cone of Cold                        (mage, frost)
        213405, -- Master of the Glaive                (demon hunter, PVE talent, havoc)
        228354, -- Flurry                              (mage, frost)
        255937, -- Wake of Ashes                       (paladin, PVE talent, retribution)
        257478, -- Crippling Bite                      (Freehold dungeon)
        257777, -- Crippling Shiv                      (Tol Dagor dungeon)
        258313, -- Handcuff                            (Tol Dagor dungeon)
        267899, -- Hindering Cleave                    (Shrine of the Storms dungeon)
        268896, -- Mind Rend                           (Shrine of the Storms dungeon)
        270499, -- Frost Shock                         (King's Rest dungeon)
        271564, -- Embalming Fluid                     (King's Rest dungeon)
        272834, -- Viscous Slobber                     (Siege of Boralus dungeon)
        273977, -- Grip of the Dead                    (death knight, unholy)
        277953, -- Night Terrors                       (rogue, subtlety)
        279303, -- Frostwyrm's Fury                    (death knight, PVE talent, frost)
        280184, -- Sweep the Leg                       (monk, azerite trait)
        280583, -- Cauterized                          (engineering goggles azerite trait)
        280604, -- Iced Spritzer                       (Motherload dungeon)
        288962, -- Blood Bolt                          (hunter pet)
        289308, -- Frozen Orb                          (mage, frost)
        289526, -- Everchill                           (Everchill Anchor, from Battle of Dazar'alor raid)
        290366  -- Commandant's Frigid Winds           (Daelin Proudmoore's Saber+Lord Admiral's Signet 2-set, from Battle of Dazar'alor raid)
})

lists.SlowImmune = {
    [642] = true,    -- Divine Shield
    [45438] = true,  -- Ice Block
    [186265] = true, -- Aspect of Turtle
    [215769] = true, -- Spirit of Redemption
    [33786] = true,  -- Cyclone
    [227847] = true, -- Bladestorm
    [768] = true,    -- Cat Form
    [5487] = true,   -- Bear Form
    [783] = true,    -- Travel Form
    [31224] = true,  -- Cloak of Shadows
    [204018] = true, -- Blessing of Spellwarding
    [48707] = true,  -- Anti Magic Shell
    [23920] = true,  -- Spell Reflection
    [213915] = true, -- Mass reflect
    [212295] = true, -- Nether Ward (Warlock)
    [1022] = true,   -- Blessing of Protection
    [188499] = true, -- Blade Dance
    [1044] = true,   -- Blessing of Freedom
    [48265] = true,  -- Death's Advance
    [287081] = true, -- Lichborne
    [212552] = true, -- Wraith Walk
    [53271] = true,  -- Master's Call
    [116841] = true, -- Tiger's Lust
    [216113] = true, -- Way of the Crane (Monk TT PvP)
}

lists.DPSCooldownList = arrayToLuT({
        --Death Knight
        207289, -- Unholy Assault
        51271,  -- Pillar of Frost
        440861, -- Feat of souls
        279302, -- Frostwyrm's Fury
        305392, -- Chill Streak
        315443, -- Abomination Limb
        383269, -- BDK LIMB
        49206,  -- Summon Gargoyle
        288853, -- Raise Abomination
        275699, -- Apocalypse
        63560,  -- Dark Transformation
        
        --Demon Hunter
        191427, -- Metamorphosis
        258860, -- Essence Break
        320338, -- Essence Break
        323639, -- The Hunt
        
        --Druid
        102560, -- Incarnation: Chosen of Elune
        102543, -- Incarnation: Avatar of Ashamane
        274837, -- Feral Frenzy
        194223, -- Celestial Alignment
        106951, -- Berserk
        50334, -- Berserk
        
        --Evoker
        375087, -- Dragonrage
        
        --Hunter
        360952, -- Coordinated Assault
        288613, -- Trueshot
        19574,  -- Bestial Wrath
        392060, -- Wailing Arrow
        375891, -- Death Chakram
        260402, -- Double Tap
        359844, -- Call of the Wild
        
        --Mage
        190319, -- Combustion
        12472,  -- Icy Veins
        365350, -- Arcane SurgeVeins
        365362, -- Arcane Surge
        321507, -- Touch of the Magi
        205025, -- Presence of Mind
        
        --Monk
        137639, -- Storm, Earth, and Fire
        386276, -- Bonedust Brew
        152173, -- Serenity
        392983, -- Strike of the Windlord
        123904, -- Invoke Xuen, the White Tiger
        392991, -- Skyreach
        
        --Paladin
        31884,  -- Avenging Wrath
        454351,  -- Avenging Wrath
        231895,  -- Crusade
        454373,  -- Crusade
        152262, -- Seraphim
        343721, -- Final Reckoning
        375576, -- Divine Toll
        343527, -- Execution Sentence
        
        --Priest
        228260, -- Void Eruption
        391109, -- Dark Ascension
        197871, -- Dark Archangel
        
        --Rogue
        360194, -- Deathmark
        13750,  -- Adrenaline Rush
        121471, -- Shadow Blades
        185422, -- Shadow Dance
        343142, -- Dreadblades
        
        --Shaman
        114050, -- Ascendance
        114051, -- Ascendance
        1219480, -- Ascendance
        191634, -- Stormkeeper
        51533,  -- Feral Spirit
        333957,  -- Feral Spirit
        384352, -- Doom Winds
        466772, -- Doom Winds
        
        --Warlock
        267217, -- Nether Portal
        1122,   -- Summon Infernal
        386997, -- Soul Rot
        265187, -- Summon Demonic Tyrant
        267171, -- Demonic Strength
        104316, -- Call Dreadstalkers
        196586, -- Dimensional Rift
        80240,  -- Havoc
        
        --Warrior
        107574, -- Avatar
        401150, -- Avatar
        1719,   -- Recklessness
        262161, -- Warbreaker
        208086, -- Warbreaker
        384318, -- Thunderous Roar
        385059, -- Odyn's Fury
})

lists.MagicCds = arrayToLuT({
        --Death Knight
        279302, -- Frostwyrm's Fury (Frost)
        305392, -- Chill Streak (Frost)
        207289, -- Unholy Assault (Shadow)
        315443, -- Abomination Limb (Shadow)
        49206,  -- Summon Gargoyle (Shadow)
        275699, -- Apocalypse (Shadow)
        63560,  -- Dark Transformation (Shadow)
        
        --Demon Hunter
        258860, -- Essence Break (Fire, Nature, Frost, Shadow, Arcane)
        323639, -- The Hunt (Nature)
        
        --Druid
        194223, -- Celestial Alignment (Nature, Arcane)
        
        --Evoker
        357210, -- Deep Breath (Fire, Nature)
        370553, -- Tip the Scales (Arcane)
        
        --Hunter
        360952, -- Coordinated Assault (Nature)
        392060, -- Wailing Arrow (Shadow)
        
        --Mage
        190319, -- Combustion (Fire)
        12472,  -- Icy Veins (Frost)
        365350, -- Arcane Surge (Arcane)
        321507, -- Touch of the Magi (Arcane)
        205025, -- Presence of Mind (Arcane)
        84714,  -- Frozen Orb (Frost)
        389794, -- Snowdrift (Frost)
        
        --Monk
        137639, -- Storm, Earth, and Fire (Nature)
        386276, -- Bonedust Brew (Shadow)
        123904, -- Invoke Xuen, the White Tiger (Nature)
        
        --Paladin
        31884,  -- Avenging Wrath (Holy)
        152262, -- Seraphim (Holy)
        343721, -- Final Reckoning (Holy)
        375576, -- Divine Toll (Arcane)
        343527, -- Execution Sentence (Holy)
        
        --Priest
        10060,  -- Power Infusion (Holy)
        228260, -- Void Eruption (Shadow)
        391109, -- Dark Ascension (Shadow)
        211522, -- Psyfiend (Shadow)
        375901, -- Mindgames (Shadow)
        197871, -- Dark Archangel (Shadow)
        
        --Rogue
        385616, -- Echoing Reprimand (Arcane)
        
        --Shaman
        198067, -- Fire Elemental (Fire)
        2825,   -- Bloodlust (Nature)
        114051, -- Ascendance (Nature)
        191634, -- Stormkeeper (Nature)
        204330, -- Skyfury Totem (Fire)
        51533,  -- Feral Spirit (Nature)
        355580, -- Static Field Totem (Nature)
        
        --Warlock
        267217, -- Nether Portal (Shadow)
        1122,   -- Summon Infernal (Fire)
        205180, -- Summon Darkglare (Shadow)
        386997, -- Soul Rot (Nature)
        265187, -- Summon Demonic Tyrant (Shadow)
        267171, -- Demonic Strength (Shadow)
        104316, -- Call Dreadstalkers (Shadow)
        6789,   -- Mortal Coil (Shadow)
        196586, -- Dimensional Rift (Physical, Holy, Fire, Nature, Frost, Shadow, Arcane)
        80240,  -- Havoc (Shadow)
        
        --Warrior
})

lists.Disarm = {
    --Death Knight
    [51271] = true,  -- Pillar of Frost
    [279302] = true, -- Frostwyrm's Fury
    [305392] = true, -- Chill Streak
    [207289] = true, -- Unholy Assault
    [315443] = true, -- Abomination Limb
    [49206] = true,  -- Summon Gargoyle
    [288853] = true, -- Raise Abomination
    [275699] = true, -- Apocalypse
    [63560] = true,  -- Dark Transformation
    
    
    --Demon Hunter
    [191427] = true, -- Metamorphosis
    [258860] = true, -- Essence Break
    [323639] = true, -- The Hunt
    
    --Hunter
    [360952] = true, -- Coordinated Assault
    [288613] = true, -- Trueshot
    [19574] = true,  -- Bestial Wrath
    [375891] = true, -- Death Chakram
    [260402] = true, -- Double Tap
    
    --Paladin
    [343721] = true, -- Final Reckoning
    [343527] = true, -- Execution Sentence
    [231895] = true, -- Crusade
    
    --Rogue
    [360194] = true, -- Deathmark
    [13750] = true,  -- Adrenaline Rush
    [121471] = true, -- Shadow Blades
    [385616] = true, -- Echoing Reprimand
    [343142] = true, -- Dreadblades
    [212283] = true, -- Symbols of Death
    
    --Shaman
    [51533] = true,  -- Feral Spirit
    [384352] = true, -- Doom Winds
    
    --Warrior
    [107574] = true, -- Avatar
    [376079] = true, -- Spear of Bastion
    [1719] = true,   -- Recklessness
    [262161] = true, -- Warbreaker
    [384318] = true, -- Thunderous Roar
    [385059] = true, -- Odyn's Fury
    [118038] = true, -- Die by the Sword (will cancel it)
}

lists.CC = arrayToLuT({
        --disorient
        207167, -- Blinding Sleet
        207685, -- Sigil of Misery
        33786,  -- Cyclone
        360806, -- Sleep Walk
        1513,   -- Scare Beast
        31661,  -- Dragon's Breath
        198909, -- Song of Chi-ji
        202274, -- Hot Trub
        105421, -- Blinding Light
        10326,  -- Turn Evil
        205364, -- Dominate Mind
        605,    -- Mind Control
        8122,   -- Psychic Scream
        226943, -- Mind Bomb
        2094,   -- Blind
        118699, -- Fear
        130616, -- Fear (Horrify)
        5484,   -- Howl of Terror
        261589, -- Seduction (Grimoire of Sacrifice)
        6358,   -- Seduction (Succubus)
        5246,   -- Intimidating Shout 1
        316593, -- Intimidating Shout 2 (TODO: not sure which one is correct in 9.0.1)
        316595, -- Intimidating Shout 3
        331866, -- Agent of Chaos (Venthyr Covenant)
        
        --incapacitate
        217832, -- Imprison
        221527, -- Imprison (Honor talent)
        2637,   -- Hibernate
        99,     -- Incapacitating Roar
        378441, -- Time Stop
        3355,   -- Freezing Trap
        203337, -- Freezing Trap (Honor talent)
        213691, -- Scatter Shot
        383121, -- Mass Polymorph
        118,    -- Polymorph
        28271,  -- Polymorph (Turtle)
        28272,  -- Polymorph (Pig)
        61025,  -- Polymorph (Snake)
        61305,  -- Polymorph (Black Cat)
        61780,  -- Polymorph (Turkey)
        61721,  -- Polymorph (Rabbit)
        126819, -- Polymorph (Porcupine)
        161353, -- Polymorph (Polar Bear Cub)
        161354, -- Polymorph (Monkey)
        161355, -- Polymorph (Penguin)
        161372, -- Polymorph (Peacock)
        277787, -- Polymorph (Baby Direhorn)
        277792, -- Polymorph (Bumblebee)
        321395, -- Polymorph (Mawrat)
        391622, -- Polymorph (Duck)
        82691,  -- Ring of Frost
        115078, -- Paralysis
        357768, -- Paralysis 2 (Perpetual Paralysis?)
        20066,  -- Repentance
        9484,   -- Shackle Undead
        200196, -- Holy Word: Chastise
        1776,   -- Gouge
        6770,   -- Sap
        51514,  -- Hex
        196942, -- Hex (Voodoo Totem)
        210873, -- Hex (Raptor)
        211004, -- Hex (Spider)
        211010, -- Hex (Snake)
        211015, -- Hex (Cockroach)
        269352, -- Hex (Skeletal Hatchling)
        309328, -- Hex (Living Honey)
        277778, -- Hex (Zandalari Tendonripper)
        277784, -- Hex (Wicker Mongrel)
        197214, -- Sundering
        710,    -- Banish
        6789,   -- Mortal Coil
        107079, -- Quaking Palm (Pandaren racial)
        
        --silence
        47476,  -- Strangulate
        204490, -- Sigil of Silence
        410065, -- Reactive Resin
        202933, -- Spider Sting
        356727, -- Spider Venom
        354831, -- Wailing Arrow 1
        355596, -- Wailing Arrow 2
        217824, -- Shield of Virtue
        15487,  -- Silence
        1330,   -- Garrote
        196364, -- Unstable Affliction Silence Effect
        
        --stun
        210141, -- Zombie Explosion
        334693, -- Absolute Zero (Breath of Sindragosa)
        108194, -- Asphyxiate (Unholy)
        221562, -- Asphyxiate (Blood)
        91800,  -- Gnaw (Ghoul)
        91797,  -- Monstrous Blow (Mutated Ghoul)
        287254, -- Dead of Winter
        179057, -- Chaos Nova
        205630, -- Illidan's Grasp (Primary effect)
        208618, -- Illidan's Grasp (Secondary effect)
        211881, -- Fel Eruption
        200166, -- Metamorphosis (PvE stun effect)
        203123, -- Maim
        163505, -- Rake (Prowl)
        5211,   -- Mighty Bash
        202244, -- Overrun
        325321, -- Wild Hunt's Charge
        372245, -- Terror of the Skies
        117526, -- Binding Shot
        357021, -- Consecutive Concussion
        24394,  -- Intimidation
        389831, -- Snowdrift
        119381, -- Leg Sweep
        202346, -- Double Barrel
        385149, -- Exorcism
        853,    -- Hammer of Justice
        255941, -- Wake of Ashes
        64044,  -- Psychic Horror
        200200, -- Holy Word: Chastise Censure
        1833,   -- Cheap Shot
        408,    -- Kidney Shot
        118905, -- Static Charge (Capacitor Totem)
        118345, -- Pulverize (Primal Earth Elemental)
        305485, -- Lightning Lasso
        89766,  -- Axe Toss
        171017, -- Meteor Strike (Infernal)
        171018, -- Meteor Strike (Abyssal)
        30283,  -- Shadowfury
        385954, -- Shield Charge
        46968,  -- Shockwave
        132168, -- Shockwave (Protection)
        145047, -- Shockwave (Proving Grounds PvE)
        132169, -- Storm Bolt
        199085, -- Warpath
        20549,  -- War Stomp (Tauren)
        255723, -- Bull Rush (Highmountain Tauren)
        287712, -- Haymaker (Kul Tiran)
        332423  -- Sparkling Driftglobe Core (Kyrian Covenant)
})


lists.Stun = arrayToLuT({
        
        210141, -- Zombie Explosion
        334693, -- Absolute Zero (Breath of Sindragosa)
        108194, -- Asphyxiate (Unholy)
        221562, -- Asphyxiate (Blood)
        91800,  -- Gnaw (Ghoul)
        91797,  -- Monstrous Blow (Mutated Ghoul)
        287254, -- Dead of Winter
        179057, -- Chaos Nova
        205630, -- Illidan's Grasp (Primary effect)
        208618, -- Illidan's Grasp (Secondary effect)
        211881, -- Fel Eruption
        200166, -- Metamorphosis (PvE stun effect)
        203123, -- Maim
        163505, -- Rake (Prowl)
        5211,   -- Mighty Bash
        202244, -- Overrun
        325321, -- Wild Hunt's Charge
        372245, -- Terror of the Skies
        117526, -- Binding Shot
        357021, -- Consecutive Concussion
        24394,  -- Intimidation
        389831, -- Snowdrift
        119381, -- Leg Sweep
        202346, -- Double Barrel
        385149, -- Exorcism
        853,    -- Hammer of Justice
        255941, -- Wake of Ashes
        64044,  -- Psychic Horror
        200200, -- Holy Word: Chastise Censure
        1833,   -- Cheap Shot
        408,    -- Kidney Shot
        118905, -- Static Charge (Capacitor Totem)
        118345, -- Pulverize (Primal Earth Elemental)
        305485, -- Lightning Lasso
        89766,  -- Axe Toss
        171017, -- Meteor Strike (Infernal)
        171018, -- Meteor Strike (Abyssal)
        30283,  -- Shadowfury
        385954, -- Shield Charge
        46968,  -- Shockwave
        132168, -- Shockwave (Protection)
        145047, -- Shockwave (Proving Grounds PvE)
        132169, -- Storm Bolt
        199085, -- Warpath
        20549,  -- War Stomp (Tauren)
        255723, -- Bull Rush (Highmountain Tauren)
        287712, -- Haymaker (Kul Tiran)
        332423  -- Sparkling Driftglobe Core (Kyrian Covenant)
})

lists.Defensive = arrayToLuT({
        76577,  -- Smoke Bomb
        53480,  -- Road of Sacriface
        116849, -- Life Cocoon
        114030, -- Vigilance
        47788,  -- Guardian Spirit
        31850,  -- Ardent Defender
        871,    -- Shield Wall
        118038, -- Die by the Sword
        104773, -- Unending Resolve
        6940,   -- Blessing of Sacrifice
        108271, -- Astral Shift
        5277,   -- Evasion
        102342, -- Ironbark
        1022,   -- Blessing of Protection
        74001,  -- Combat Readiness
        31224,  -- Cloak of Shadows
        33206,  -- Pain Suppression
        47585,  -- Dispersion
        186265, -- Aspect of Turtle
        48792,  -- Icebound Fortitude
        115176, -- Zen Meditation
        122783, -- Diffuse Magic
        86659,  -- Guardian of Ancient Kings
        642,    -- Divine Shield
        45438,  -- Ice Block
        414658, -- Ice Cold
        498,    -- Divine Protection
        157913, -- Evanesce
        115203, -- Fortifying Brew
        120954, -- Fortifying Brew
        22812,  -- Barkskin
        122278, -- Dampen Harm
        61336,  -- Survival Instincts
        45182,  -- Cheating Death
        198589, -- Blur
        209426, -- Darkness
        196555, -- Netherwalk
        243435, -- Fortifying Brew
        206803, -- Rain from Above
        264735, -- Survival of the Fittest
        363916, -- Obsidian Scales
        374227, -- Zephyr
        448508, -- Jade Sanctuary
        55233, -- Vampiric Blood
        1241059, -- Celestial Infusion
})

lists.BreakableCC = arrayToLuT({
        2094,   -- Blind
        1776,   -- Gouge
        6770,   -- Sap
        15487,  -- Silence
        8122,   -- Psychic Scream
        64044,  -- Psychic Horror
        115078, -- Paralysis
        
        -- Disorient effects
        207167, -- Blinding Sleet
        31661,  -- Dragon's Breath
        2094,   -- Blind
        118699, -- Fear
        5484,   -- Howl of Terror
        5246,   -- Intimidating Shout
        316593, -- Intimidating Shout
        316595, -- Intimidating Shout
        
        -- Incapacitate effects
        2637,   -- Hibernate
        99,     -- Incapacitating Roar
        3355,   -- Freezing Trap
        203337, -- Freezing Trap
        213691, -- Scatter Shot
        118,    -- Polymorph
        28271,  -- Polymorph
        28272,  -- Polymorph
        61025,  -- Polymorph
        61305,  -- Polymorph
        61780,  -- Polymorph
        61721,  -- Polymorph
        126819, -- Polymorph
        161353, -- Polymorph
        161354, -- Polymorph
        161355, -- Polymorph
        161372, -- Polymorph
        277787, -- Polymorph
        277792, -- Polymorph
        321395, -- Polymorph
        391622, -- Polymorph
        113724, -- Ring of Frost
        20066,  -- Repentance
        9484,   -- Shackle Undead
        6770,   -- Sap
        51514,  -- Hex
        196942, -- Hex
        210873, -- Hex
        211004, -- Hex
        211010, -- Hex
        211015, -- Hex
        269352, -- Hex
        309328, -- Hex
        277778, -- Hex
        277784, -- Hex
})

lists.Reflect = arrayToLuT({
        118,    -- Polymorph
        51514,  -- Hex
        33786,  -- Cyclone
        20066,  -- Repentance
        5782,   -- Fear
        116858, -- Chaos Bolt
        394246, -- Chaos Bolt
        356995, -- Disintegrate
        323764, -- Convoke the Spirits
        199786, -- Glacial Spike
        5143,   -- Arcane Missles
        357208, -- Fire Breath
        360806, -- Sleep Walk
        
})

lists.IncorpStunned = arrayToLuT({
        360806, -- Sleep Walk
        2094,   -- Blind
        217832, -- Imprison
        2637,   -- Hibernate
        1513,   -- Scare Beast
        187650, -- Freezing Trap
        118,    -- Polymorph
        115078, -- Paralysis
        10326,  -- Turn Evil
        20066,  -- Repentance
        9484,   -- Shackle Undead
        51514,  -- Hex
        710,    -- Banish
})

lists.Bloodlust = arrayToLuT({
        2825,   -- Bloodlust
        32182,  -- Heroism
        390386, -- Fury of the Aspects
        80353,  -- Time Warp
        466904, -- Harrier's Cry
        264667, -- Primal Rage
        193470, -- Feral Hide Drums
        381301, -- Feral Hide Drums
        444257, --Thunderous Drums
})

lists.Sated = arrayToLuT({
        80354, -- Temporal Displacement (Mage)
        57724, -- Sated (Horde Shaman)
        57723, -- Exhaustion (Alliance Shaman)
        264689, -- Fatigued (Hunter)
        390435, -- Exhaustion (Evoker)
})

lists.ignoreMoving = {
    [79206] = true,  -- Spiritwalkers Grace
    [108839] = true, -- Ice Floes
    [406732] = true, -- Spatial Paradox
    [406789] = true, -- Spatial Paradox
    [358267] = true, -- Hover
}

lists.precastHeals = arrayToLuT({
        438473, --(Gossamer Onslaught)
        438476, --(Alerting Shrill)
        424805, --(Refracting beam. Just before spikes get popped)
        423324, -- (Void Discharge)
        428819, -- (Exhaust Vents)
        428535, -- (Blazing Crescendo)
        
        82326, --Holy Light Test
        19750, --Flash of Light Test
})

lists.pveImmuneNPC = {
    [231788] = true, -- Unstable Crawler Mine
    [233474] = true, -- Gallagio Goon
    [233623] = true, -- Pyrotechnics
    [232612] = true, -- Pyrotechnics
}

lists.Disarmed = arrayToLuT({
        236077, -- Disarmed
        207777, -- Dismantle
        233759, -- Grapple Weapon
        209749, -- Faerie Swarm
        236077, -- Disarm
})

lists.stopcasting = {
    [427609] = true, -- Disrupting Shout
    [342135] = true, -- Interrupting Roar
    [339415] = true, -- Deafening Crash
}

lists.pveMagic = arrayToLuT({
        145206, -- Aqua Bomb (Proving Grounds)
        1214802, -- Pinged Augment Chip (Brann)
        --Season 1
        440313, -- Void Rift (Xal'atath's Affix) (Potentially incorrect - be sure to update in ALL pve tables)
        465051, -- Void Rift (Xal'atath's Affix) (Potentially incorrect - be sure to update in ALL pve tables)  
        325224, -- Anima Injection
        431494, -- Black Edge
        324859, -- Bramblethorn Entanglement
        426735, -- Burning Shadows
        429545, -- Censoring Gear
        328664, -- Chilled
        464876, -- Concussive Smash
        --320788, -- Frozen Binds (Causes AoE roots when dispelled too quickly)
        425974, -- Ground Pound
        449455, -- Howling Fear
        440238, -- Ice Sickles
        --275014, -- Putrid Waters
        --424889, -- Seismic Reverberation
        448561, -- Shadows of Doubt
        443437, -- Shadows of Doubt
        322557, -- Soul Split
        432448, -- Stygian Seed
        451104, -- Bursting Cocoon
        434802, -- hoorifying Shrill
        442210, -- Silken Restraints
        433662, -- Grasping Blood
        433781, -- Ceaseless Swarm
        --433785, -- Grasping Slash
        434083, -- Ambush
        443430, -- Silk Bindings
        --446718, -- Umbral Wave
        --443427, -- Web Bolt
        74837, -- Modgud's Malady
        451871, -- Mass Tremor
        328756, -- Repulsive Visage
        323347, -- Clinging Darkness
        287295, -- Chilled
        324293, -- Rasping Scream
        272571, -- Choking Waters
        257169, -- Terrifying Roar
        --449154, -- Molten Mortar
        428161, -- Molten Metal
        439780, -- Sticky Webs
        --Season 2
        439325, -- Burning Fermentation
        436640, -- Burning Ricochet
        437956, -- Erupting Inferno
        441397, -- Bee Venom
        426145, -- Paranoid Mind
        428019, -- Flashpoint
        426295, -- Flaming Tether
        294929, -- Blazing Chomp
        285460, -- Discom-BOMB-ulator
        294195, -- Arcing Zap
        --295183, -- Capacitor Discharge
        1217821, -- Fiery Jaws
        --473713, -- Kinetic Explosive Gel
        --462737, -- Black Blood Wound
        469799, -- Overcharge
        469800, -- Overcharge
        428170, -- Blinding Light
        451606, -- Holy Flame
        427583, -- Repentance
        427897, -- Heat Wave
        435148, -- Blazing Strike
        263215, -- Tectonic Barrier
        268797, -- Transmute: Enemy to Goo
        280604, -- Iced Spritzer
        268846, -- Echo Blade
        --429493, -- Unstable Corruption
        1214523, -- Feasting Void
        1215600,  -- Withering Touch
        448515, -- Divine Judgment
        469620, -- Creeping Shadow
        424420, -- Cinderblast
        
        
        --Season 3
        1235060, --anima-tainted-armor
        325876, --mark-of-obliteration
        1235762, --turn-to-stone
        1236513, --unstable-anima
        1236514, --unstable-anima
        355915, --glyph-of-restraint
        356324, --empowered-glyph-of-restraint
        357029, --hyperlight-bomb
        358919, --static-mace
        355641, --scintillate
        356943, --lockdown
        346844, --alchemical-residue
        349954, --purification-protocol
        347149, --infinite-breath
        1240097, --time-bomb
        1221483, --arcing-energy
        1241785, --Tainted Blood
        1221484, --arcing-energy
        432454, --Stygian Seed
        432448, --Stygian Seed
        
})

lists.pvePoison = arrayToLuT({
        --Season 1
        440313, -- Void Rift (Xal'atath's Affix) (Potentially incorrect - be sure to update in ALL pve tables)
        465051, -- Void Rift (Xal'atath's Affix) (Potentially incorrect - be sure to update in ALL pve tables)    
        --461487, -- Cultivated Poisons
        326092, -- Debilitating Poison
        340283, -- Poisonous Discharge
        448248, -- Revolting Volley
        275836, -- Stinging Venom
        340288, -- Triple Bite
        443401, -- Venom Strike
        433841, -- Venom Volley
        438618, -- Venomous Spit
        461630, -- Venomous Spray
        436322, -- Poison Bolt
        440160, -- Poison Bolt
        275743, -- Venomous Spray
        340279, -- Poisonous Discharge
        340304, -- Poisonous Secretions
        --Season 2
        269298, -- Toxic Blades
        262270  -- Caustic Compound
})

lists.pveDisease = arrayToLuT({
        --Season 1
        440313, -- Void Rift (Xal'atath's Affix) (Potentially incorrect - be sure to update in ALL pve tables)
        465051, -- Void Rift (Xal'atath's Affix) (Potentially incorrect - be sure to update in ALL pve tables)  
        321821, -- Disgusting Guts
        338353, -- Goresplatter
        320596, -- Heaving Retch
        272588, -- Rotting Wounds
        454440, -- Stinky Vomit
        --Season 2
        427929, -- Nasty Nibble
        1215415, -- Sticky Sludge
        320248, -- Genetic Alteration
        330700, -- Decaying Blight
        341949, -- Withering Blight
        330608  -- Vile Eruption
})

lists.pveCurse = arrayToLuT({
        --Season 1
        440313, -- Void Rift (Xal'atath's Affix) (Potentially incorrect - be sure to update in ALL pve tables)
        465051, -- Void Rift (Xal'atath's Affix) (Potentially incorrect - be sure to update in ALL pve tables)  
        450095, -- Curse of Entropy
        257168, -- Cursed Slash
        322968, -- Dying Breath
        431309, -- Ensnaring Shadows
        451224, -- Enveloping Shadowflame
        426308, -- Void Infection
        --Season 2
        430179, -- Seeping Corruption
        333299, -- Curse of Desolation
        330725,  -- Shadow Vulnerability
        80240, -- Havoc
        356407, --ancient-dread
})

lists.pveBleed = arrayToLuT({
        --Season 1
        438599, -- Bleeding Jab
        323043, -- Bloodletting
        321807, -- Boneflay
        440107, -- Knife Throw
        325021, -- Mistveil Tear
        256709, -- Singing Steel
        447268, -- Skullsplitter
        320200, -- Stitchneedle
        431491, -- Tainted Slash
        451241, -- Shadowflame Slash
        --Season 2
        434773, -- Mean Mug
        441413, -- Shredding Sting
        438975, -- Shredding Sting
        425555, -- Crude Weapons
        1215411, -- Puncture
        293670, -- Chainblade
        468631, -- Harpoon
        1213803, -- Nailed
        427635, -- Grievous Rip
        424426, -- Lunging Strike
        453461, -- Caltrops
        424414, -- Pierce Armor
        257544, -- Jagged Cut
        1213141, -- Heavy Slash
        342675, -- Bone Spear
        333861, -- Ricocheting Blade
        332836, -- Chop
        330532, -- Jagged Quarrel
        323406,  -- Jagged Gash
        
        --Season 3
        1219535, --rift-claws
        1235245,-- ankle-bite
        355830, --quickblade
        347716, --letter-opener
        357827, --frantic-rip
        1248209, --phase-slash
        351119, --shuriken-blitz
        
})

lists.pveFreedom = arrayToLuT({
        434083, -- Ambush
        431494, -- Black Edge
        324859, -- Bramblethorn Entanglement
        328664, -- Chilled
        464876, -- Concussive Smash
        450095, -- Curse of Entropy
        326092, -- Debilitating Poison
        431309, -- Ensnaring Shadows
        448215, -- Expel Webs
        --320788, -- Frozen Binds
        433785, -- Grasping Slash
        425974, -- Ground Pound
        440238, -- Ice Sickles
        451871, -- Mass Tremor
        428161, -- Molten Metal
        322486, -- Overgrowth
        443430, -- Silk Binding
        434722, -- Subjugate
        340300, -- Tongue Lashing
        456773, -- Twilight Wind
        446718, -- Umbral Weave
        439324, -- Umbral Weave
        443427, -- Web Bolt
        1241785, --Tainted Blood
})

lists.pvePurge = arrayToLuT({
        --Season 1
        450756, -- Abyssal Howl
        275826, -- Bolstering Shout
        324776, -- Bramblethorn Coat
        326046, -- Stimulate Resistance
        256957, -- Watertight Shell
        324914, --Nourish the Forest
        431493, -- Dark blade
        --Season 2
        441627, -- Rejuvenating Honey
        293930, -- Overclock
        297133, -- Defensive Countermeasure
        471733, -- Restorative Algae
        465604, -- Battery Bolt
        427346, -- Inner Fire
        444728, -- Templar's Wrath
        469956, -- Lightning-Infused
        430754, -- Void Shell
        333293, -- Bone Shield
        341902, -- Unholy Fervor
        427342,  -- Defend
        1227001, --embrace-of-karesh
        463058, --bloodthirsty-cackle
        1223000, -- embrace-of-karesh
        356549, --Refraction Shield
})

lists.pveEnrage = arrayToLuT({
        324737, -- Enraged
        451040, -- Rage
        451379, -- Reckless Tactic
        451112, -- Tactician's Rage
        320012, -- Unholy Frenzy
        427260, -- Lightning Surge
        425704, -- Enrage (Darkflame, Mole)
        441645, -- Unnatural Bloodlust
        327155, -- Vengeful Rage
        320703, -- Seeting Rage
        272888, -- Ferocity
        425563, -- Mole Frenzy
        441351, -- Bee-stial Wrath
        333241, -- Raging Tantrum
        424419, -- Battle Cry
        424650, -- Panicked!
        441408, -- Thirsty
        441214, -- Spill Drink
        463061, -- Bloodthirsty Cackle
        262092, -- Inhale Vapors
        1213139, -- Overtime
        331510, -- Death Wish
        333242, -- Raging Tantrum
        1216852, -- Galywix enrage
        
        --Season 3
        1221133, --hungering-rage
        326450, --loyal-beasts
        355782, --force-multiplier
        355057, --Cry of Mrrggllrrgg
        356133, --super-saison
        1242072, --intensifying-aggression
        451112, -- Tactician's Rage
        444728, -- Templar's Wrath
        1227001, --embrace-of-karesh
        463058, --bloodthirsty-cackle
        1231608, --alacrity
        1223000, -- embrace-of-karesh
        
})

lists.pveTankBuster = arrayToLuT({
        463217, -- Anima Slash
        321807, -- Boneflay
        451239, -- Brutal Jab
        451238, -- Brutal Jab
        451364, -- Brutal Strike
        464876, -- Concussive Smash
        427382, -- Concussive Smash
        268230, -- Crimson Swipe
        320655, -- Crunch
        450100, -- Crush
        450103, -- Crush
        257168, -- Cursed Slash
        431493, -- Darkblade
        433002, -- Extraction Strike
        427361, -- Fracture
        433785, -- Grasping Slash
        256867, -- Heavy Hitter
        273681, -- Heavy Hitter
        320771, -- Icy Shard
        375877, -- Icy Shard
        375878, -- Icy Shard
        428711, -- Igneous Hammer
        451971, -- Lava Fist
        449444, -- Molten Flurry
        449448, -- Molten Flurry
        320376, -- Mutilate
        338456, -- Mutilate
        320462, -- Necrotic Bolt
        330784, -- Necrotic Bolt
        332650, -- Necrotic Bolt
        461842, -- Oozing Smash
        461577, -- Oozing Smash
        461989, -- Oozing Smash
        321828, -- Patty Cake
        436322, -- Poison Bolt
        442638, -- Poison Bolt
        439646, -- Process of Elimination
        439764, -- Process of Elimination
        439763, -- Process of Elimination
        452151, -- Rigorous Jab
        440468, -- Rime Dagger
        441295, -- Rime Dagger
        451378, -- Rive
        272588, -- Rotting Wounds
        424889, -- Seismic Reverberation
        424888, -- Seismic Smash
        338636, -- Separate Flesh
        334488, -- Sever Flesh
        439621, -- Shade Slash
        439686, -- Shade Slash
        439687, -- Shade Slash
        459210, -- Shadow Claw
        337246, -- Shadow Claw
        451241, -- Shadowflame Slash
        340208, -- Shred Armor
        340474, -- Shred Armor
        256709, -- Singing Steel
        447268, -- Skullsplitter
        447261, -- Skullsplitter
        322557, -- Soul Split
        340707, -- Soul Split
        275836, -- Stinging Venom
        428894, -- Stonebreaker Strike
        434722, -- Subjugate
        435793, -- Tacky Burst
        439793, -- Tacky Burst
        439792, -- Tacky Burst
        431491, -- Tainted Slash
        338357, -- Tenderize
        340130, -- Tenderize
        340070, -- Tenderize
        427001, -- Terrifying Slam
        451117, -- Terrifying Slam
        427002, -- Terrifying Slam
        427007, -- Terrifying Slam
        256616, -- Tooth Breaker
        340288, -- Triple Bite
        340289, -- Triple Bite
        431637, -- Umbral Rush
        431638, -- Umbral Rush
        443401, -- Venom Strike
        443397, -- Venom Strike
        439200, -- Voracious Bite
        438471, -- Voracious Bite
        459627, -- Tank Buster
        
        -- TWW S2
        427929, -- Nasty Nibble
        468672, -- Pinch
        465820, -- Vicious Chomp
        455588, -- Blood Bolt
        470005, -- Vicious Bite
        465666, -- Sparkslam
        473351, -- Electrocrush
        459799, -- Wallop
        469478, -- Sludge Claws
        1215411, -- Puncture
        263601, -- Desperate Measures
        467908, -- Void Claw
        472549, -- Volatile Void
        445457, -- Oblivion Wave
        427629, -- Shoot
        448485, -- Shield Slam
        427950, -- Seal of Flame
        448515, -- Divine Judgment
        424420, -- Cinderblast
        427596, -- Seal of Light's Fury
        444728, -- Templar's Wrath
        435165, -- Blazing Strike
        424414, -- Pierce Armor
        422969, -- Vindictive Wrath
        425565, -- Crude Weapons
        428066, -- Overpowering Roar
        425536, -- Mole Frenzy
        469610, -- Shadow Fang
        422628, -- Eater of the Dead
        422245, -- Rock Buster
        434773, -- Mean Mug
        443487, -- Final Sting
        456891, -- Shoot
        441351, -- Bee Stial Wrath
        441397, -- Bee Venom
        432229, -- Keg Smash
        439031, -- Bottoms Uppercut
        440134, -- Honey Marinade
        436624, -- Cash Cannon
        468672, -- Pinch
        465820, -- Vicious Chomp
        455588, -- Blood Bolt
        470005, -- Vicious Bite
        473351, -- Electocrush
        459799, -- Wallop
        469478, -- Sludge Claws
        466188, -- Thunder Punch
        466189, -- Thunder Punc
        466190, -- Thunder Punchh
        466197, -- Thunder Punch
        263628, -- Charged Shield
        1215411, -- Puncture
        1213141, -- Heavy Slash
        1213139, -- Overtime
        263601, -- Desperate Measures
        268810, -- Unstable Mutation
        259474, -- Searing Reagent
        260318, -- Alpha Cannon
        294073, -- Flying Peck
        1215411, -- Puncture
        1215065, -- Platinum Pummel
        294929, -- Blazing Chomp
        291878, -- Pulse Blast
        330565, -- Shield Bash
        331316, -- Savage Flurry
        331288, -- Colossus Smash
        333845, -- Unbalancing Blow
        330875, -- Spirit Frost
        330697, -- Decaying Strike
        330586, -- Devour Flesh
        320300, -- Necromantic Bolt
        320069, -- Mortal Strike
        320644, -- Brutal Combo
        474087, -- Necrotic Eruption
        323515, -- Hateful Strike
        324079, -- Reaping Scythe
        
        -- S2 Raid
        1214190, -- Eruption Stomp
        1217933, -- Lightning Bash
        460472, -- The Big Hit
        466519, -- Molten Gold Knuckles
        474061, -- Tank Buster
        466178, -- Lightning Bash
        460472, -- The Big Hit
        
        --Season 3
        1221133, --hungering-rage
        1235368, --arcane-slash
        1231608, --alacrity
        1222341, --gloom-bite
        1219535, --rift-claws
        1235060, --anima-tainted-armor
        326450, --loyal-beasts
        1237071, --stone-fist
        1235766, --mortal-strike
        326829, --wicked-bolt
        322936, --crumbling-slam
        328322, --villainous-bolt
        323538, --anima-bolt
        323437, --stigma-of-pride
        352796, --proxy-strike
        355888, --hard-light-baton
        354297, --hyperlight-bolt
        355830, --quickblade
        356967, --hyperlight-backhand
        357229, --chronolight-enhancer
        1240912, --pierce
        1242960, --gang-up
        358919, --static-mace
        347716, --letter-opener
        355477, --power-kick
        356943, --lockdown
        348128, --fully-armed
        350916, --security-slam
        349934, --flagellation-protocol
        355048, --shellcracker
        355057, --Cry of Mrrggllrrgg
        356133, --super-saison
        356843, --brackish-bolt
        354297, --hyperlight-bolt
        346116, --shearing-swings
})

lists.pveInterrupts = arrayToLuT({
        
        450756, -- Abyssal Howl
        449734, -- Acidic Eruption
        429110, -- Alloy Bolt
        426283, -- Arcing Void
        275826, -- Bolstering Shout
        335143, -- Bonemend
        257063, -- Brackish Bolt
        324776, -- Bramblethorn Coat
        429545, -- Censoring Gear
        272571, -- Choking Waters
        452099, -- Congealed Darkness
        322450, -- Consumption
        334748, -- Drain Fluids
        451261, -- Earth Bolt
        322274, -- Enfeeble
        431309, -- Ensnaring Shadows
        320336, -- Frostbolt
        333602, -- Frostbolt
        328667, -- Frostbolt Volley
        338353, -- Goresplatter
        327396, -- Grim Fate
        442536, -- Grimweave Blast
        322938, -- Harvest Essence
        434802, -- Horrifying Shrill
        449455, -- Howling Fear
        451871, -- Mass Tremor
        452162, -- Mending Web
        430097, -- Molten Metal
        320171, -- Necrotic Bolt
        320462, -- Necrotic Bolt
        431303, -- Night Bolt
        324914, -- Nourish the Forest
        321828, -- Patty Cake
        445207, -- Piercing Wail
        436322, -- Poison Bolt
        324293, -- Rasping Scream
        434793, -- Resonant Barrage
        429109, -- Restoring Metals
        448248, -- Revolting Volley
        76711,  -- Sear Mind
        428086, -- Shadow Bolt
        447966, -- Shadowflame Bolt
        76369,  -- Shadowflame Bolt
        443430, -- Silk Binding
        323057, -- Spirit Bolt
        322767, -- Spirit Bolt
        340544, -- Stimulate Regeneration
        326046, -- Stimulate Resistance
        454440, -- Stinky Vomit
        429422, -- Stone Bolt
        431333, -- Tormenting Beam
        443433, -- Twist Thoughts
        432520, -- Umbral Barrier
        433841, -- Venom Volley
        434122, -- Void Bolt
        446086, -- Void Wave
        272581, -- Water Bolt
        256957, -- Watertight Shell
        451113, -- Web Bolt
        443427, -- Web Bolt
        434786, -- Web Bolt
        
        
        430109, -- Lightning Bolt
        427260, -- Lightning Surge
        430238, -- Void Bolt
        427357, -- Holy Smite
        427356, -- Greater Heal
        427469, -- Fireball
        427357, -- Holy Smite (duplicate)
        424421, -- Fireball
        424420, -- Cinderblast
        427469, -- Fireball (duplicate)
        444743, -- Fireball Volley
        424419, -- Battle Cry
        423051, -- Burning Light
        423536, -- Holy Smite
        423665, -- Embrace the Light
        423479, -- Wicklighter Bolt
        425536, -- Mole Frenzy
        424322, -- Explosive Flame
        428563, -- Flame Bolt
        426677, -- Candleflame Bolt
        426295, -- Flaming Tether
        422541, -- Drain Light
        426145, -- Paranoid Mind
        427157, -- Call Darkspawn
        427176,  -- Drain Light
        453909, -- Boiling Flames
        441627, -- Rejuvenating Honey
        441242, -- Free Samples
        441351, -- Bee Stial Wrath
        440687, -- Honey Volley
        462771, -- Surveying Beam
        463061, -- Bloodthirsty Cackle
        468631, -- Harpoon
        465813, -- Lethargic Venom
        455588, -- Blood Bolt
        471733, -- Restorative Algae
        1214780, -- Maximum Distortion
        268185, -- Iced Spritzer
        269302, -- Toxic Blades
        263202, -- Rock Lance
        263215, -- Tectonic Barrier
        268702, -- Furious Quake
        268797,  -- Transmute: Enemy to Goo
        301088, -- Detonate
        293827, -- Giga Wallop
        293729, -- Tune Up
        330784, -- Necrotic Bolt
        341902, -- Unholy Fervor
        330562, -- Demoralizing Shout
        330810, -- Bind Soul
        342675, -- Bone Spear
        330784, -- Necrotic Bolt (duplicate)
        330868, -- Necrotic Bolt Volley
        330875, -- Spirit Frost
        341977, -- Meat Shield
        330703, -- Decaying Filth
        341969, -- Withering Discharge
        320300, -- Necromantic Bolt
        1216475, -- Necrotic Bolt
        324589,  -- Death Bolt
        
        
        
        --9/26/24 Liquid
        451288, -- Black Bulwark (The Bloodbound Horror, Raid Fight)
        --452806, -- Acidic Eruption (Rasha'nan, Raid Fight) Removed 2/22 Liquid (can cause raid to wipe lol)
        446700, -- Poison Burst (Broodtwister Ovi'nax, Raid Fight)
        450449, -- Regenerating Carapace (Zekvir)
        450914, -- Blood-Infused Carapace (Zekvir)
        450505, -- Enfeebling Spittle (Zekvir)
        
        --12/2/24 Devro
        324293, -- Rasping Scream
        320462, -- Necrotic Bolt
        334748, -- Drain Fluids
        434802, -- Horrifying Shrill
        449251, -- Web Bolt
        434786, -- Web Bolt
        436322, -- Poison Bolt
        438200, -- Poison Bolt
        433841, -- Venom Volley
        326046, -- Stimulate Resistance
        340544, -- Stimulate REgeneration
        275826, -- Bolstering Shout
        450756, -- Abyssal Howl
        431303, -- Night Bolt
        
        320300, --ecromantic-bolt
        1216476, -- necrotic-bolt
        426145, -- aranoid-mind
        342675, -- bone-spear
        432959, -- void-volley
        453909, -- boiling-flames
        454319, -- boiling-flames
        441627, -- rejuvenating-honey
        
        --060125 timemeansnothing
        454318, -- boiling-flames again
        454319, -- boiling-flames again
        1219041, --Gallwix static zap
        
        --08/07/2025
        1222815, --arcane-bolt
        1221483, --arcing-energy
        1221484, --arcing-energy
        1221532, --erratic-ritual
        1248699, --consume-spirit?
        1248701, --consume-spirit?
        338003, --wicked-bolt
        326450, --loyal-beasts
        325700, --collect-sins
        325701, --siphon-life
        1229474, --gorge
        1229510, --arcing-zap
        328322, --villainous-bolt
        323538, --anima-bolt
        355934, --hard-light-barrier
        354297, --hyperlight-bolt
        356324, --empowered-glyph-of-restraint
        347775, --spam-filter
        355641, --scintillate
        355642, --hyperlight-salvo
        357260, --Unstable Rift
        355057, --Cry of Mrrggllrrgg
        356407, --Ancient Dread
        357188, --double-technique
        1241032, --final-warning
        353836, --hyperlight-bolt
        350922, --menacing-shout
        355225, --waterbolt
        356843, --brackish-bolt
        352347, --valorous-bolt
        351119, --shuriken-blitz
        442210, --Silken Restraints
        463058, --bloodthirsty-cackle
        
        -- 08/18/2025 Darko
        -- Operation Floodgate
        465871, -- Blood Blast
        465666, -- Sparkslam
        1214468, -- Trickshot
        465595, -- Lightning Bolt
        462771, -- Surveying Beam
})

lists.pveStops = arrayToLuT({
        432967, -- Alarm Shrill
        429110, -- Alloy Bolt
        321780, -- Animate Dead
        426283, -- Arcing Void
        430805, -- Arcing Void
        272546, -- Banana Rampage
        462220, -- Blazing Shadowflame
        320614, -- Blood Gorge
        321807, -- Boneflay
        335143, -- Bonemend
        257063, -- Brackish Bolt
        324776, -- Bramblethorn Coat
        451364, -- Brutal Strike
        450597, -- Web Blast (Zekvir)
        256640, -- Burning Tar
        438877, -- Call of the Brood
        429545, -- Censoring Gear
        272571, -- Choking Waters
        431493, -- Darkblade
        --321834, -- Dodge Ball
        334748, -- Drain Fluids
        451261, -- Earth Bolt
        429427, -- Earth Burst Totem
        431309, -- Ensnaring Shadows
        451224, -- Enveloping Shadowflame
        433845, -- Erupting Webs
        433002, -- Extraction Strike
        272888, -- Ferocity
        328146, -- Fetid Gas
        320822, -- Final Bargain
        321247, -- Final Harvest
        256639, -- Fire Bomb
        321891, -- Freeze Tag Fixation
        320336, -- Frostbolt
        328667, -- Frostbolt Volley
        338353, -- Goresplatter
        428703, -- Granite Eruption
        433785, -- Grasping Slash
        327396, -- Grim Fate
        442536, -- Grimweave Blast
        322938, -- Harvest Essence
        449455, -- Howling Fear
        --453161, -- Impale
        433740, -- Infestation
        448030, -- Knife Throw
        321226, -- Land of the Dead
        451871, -- Mass Tremor
        452162, -- Mending Web
        257641, -- Molten Slug
        320171, -- Necrotic Bolt
        320462, -- Necrotic Bolt
        333488, -- Necrotic Breath
        431303, -- Night Bolt
        324914, -- Nourish the Forest
        456696, -- Obsidian Stomp
        445207, -- Piercing Wail
        447141, -- Pulverizing Pounce
        327127, -- Repair Flesh
        434793, -- Resonant Barrage
        429109, -- Restoring Metals
        448248, -- Revolting Volley
        272542, -- Ricochet
        272588, -- Rotting Wounds
        76711,  -- Sear Mind
        76369,  -- Shadowflame Bolt
        451241, -- Shadowflame Slash
        --448975, -- Shield Stampede
        272528, -- Shoot
        333629, -- Shoot
        328687, -- Shoot
        443430, -- Silk Binding
        256709, -- Singing Steel
        256627, -- Slobber Knocker
        322767, -- Spirit Bolt
        275835, -- Stinging Venom Coating
        454440, -- Stinky Vomit
        429422, -- Stone Bolt
        428894, -- Stonebreaker Strike
        451112, -- Tactician's Rage
        334747, -- Throw Flesh
        431333, -- Tormenting Beam
        --438622, -- Toxic Rupture
        432520, -- Umbral Barrier
        431637, -- Umbral Rush
        320012, -- Unholy Frenzy
        443401, -- Venom Strike
        433841, -- Venom Volley
        438618, -- Venomous Spit
        446086, -- Void Wave
        325418, -- Volatile Acid
        272581, -- Water Bolt
        256957, -- Watertight Shell
        443427, -- Web Bolt
        434786, -- Web Bolt
        434824, -- Web Spray
        427342, -- Defend
        427359, -- Defend
        
        430109, -- Lightning Bolt
        427260, -- Lightning Surge
        430238, -- Void Bolt
        427357, -- Holy Smite
        427356, -- Greater Heal
        427469, -- Fireball
        427357, -- Holy Smite (duplicate)
        424421, -- Fireball
        424420, -- Cinderblast
        427469, -- Fireball (duplicate)
        444743, -- Fireball Volley
        424419, -- Battle Cry
        423051, -- Burning Light
        423536, -- Holy Smite
        423665, -- Embrace the Light
        423479, -- Wicklighter Bolt
        425536, -- Mole Frenzy
        424322, -- Explosive Flame
        428563, -- Flame Bolt
        426677, -- Candleflame Bolt
        426295, -- Flaming Tether
        422541, -- Drain Light
        426145, -- Paranoid Mind
        427157, -- Call Darkspawn
        427176,  -- Drain Light
        453909, -- Boiling Flames
        441627, -- Rejuvenating Honey
        441242, -- Free Samples
        441351, -- Bee Stial Wrath
        440687, -- Honey Volley
        1214468, -- Trickshot
        462771, -- Surveying Beam
        463061, -- Bloodthirsty Cackle
        468631, -- Harpoon
        465813, -- Lethargic Venom
        455588, -- Blood Bolt
        471733, -- Restorative Algae
        465595, -- Lightning Bolt
        1214780, -- Maximum Distortion
        268185, -- Iced Spritzer
        269302, -- Toxic Blades
        263202, -- Rock Lance
        263215, -- Tectonic Barrier
        268702, -- Furious Quake
        268797,  -- Transmute: Enemy to Goo
        301088, -- Detonate
        293827, -- Giga Wallop
        293729, -- Tune Up
        330784, -- Necrotic Bolt
        341902, -- Unholy Fervor
        330562, -- Demoralizing Shout
        330810, -- Bind Soul
        342675, -- Bone Spear
        330784, -- Necrotic Bolt (duplicate)
        330868, -- Necrotic Bolt Volley
        330875, -- Spirit Frost
        341977, -- Meat Shield
        330703, -- Decaying Filth
        341969, -- Withering Discharge
        320300, -- Necromantic Bolt
        1216475, -- Necrotic Bolt
        324589,  -- Death Bolt
        
        423305, -- Null Upheaval
        427342, -- Defend
        446776, -- Pounce
        423665, -- Embrace the Light
        422541, -- Drain Light
        421875, -- Kol-To Arms
        428268, -- Underhanded Track Tics
        427157, -- Call Darkspawn
        453909, -- Boiling Flames
        439365, -- Spouting Stout
        440082, -- Oozing Honey
        438025, -- Snack Time
        465128, -- Wind Up
        462771, -- Surveying Beam
        465682, -- Surprise Inspection
        471736, -- Jettison Kelp
        471585, -- Mobilize Mechadrones
        258674, -- Throw Wrench
        268185, -- Iced Spritzer
        267354, -- Fan of Knives
        263209, -- Throw Rock
        257593, -- Call Earthrager
        260189, -- Configuration Drill
        293729, -- Tune Up
        294865, -- Roaring Flame
        330810, -- Bind Soul
        341977, -- Meat Shield
        --331618, -- Oppressive Banner
        473959, -- Draw Soul
        322795, -- Meat Hooks
        324449,  -- Manifest Death    
        1215412, -- Corrosive Gunk
        1215412 , --TimeMeansNothing
        
        
        --Season 3
        1222815, --arcane-bolt
        1221483, --arcing-energy
        1221484, --arcing-energy
        1221532, --erratic-ritual
        1248699, --consume-spirit?
        1248701, --consume-spirit?
        338003, --wicked-bolt
        326450, --loyal-beasts
        325700, --collect-sins
        325701, --siphon-life
        1229474, --gorge
        1229510, --arcing-zap
        328322, --villainous-bolt
        323538, --anima-bolt
        355934, --hard-light-barrier
        354297, --hyperlight-bolt
        356324, --empowered-glyph-of-restraint
        347775, --spam-filter
        355641, --scintillate
        355642, --hyperlight-salvo
        357260, --Unstable Rift
        355057, --Cry of Mrrggllrrgg
        356407, --Ancient Dread
        357188, --double-technique
        1241032, --final-warning
        353836, --hyperlight-bolt
        350922, --menacing-shout
        355225, --waterbolt
        356843, --brackish-bolt
        352347, --valorous-bolt
        351119, --shuriken-blitz
        442210, --Silken Restraints
})

lists.pveAffix = arrayToLuT({
        461904, -- Cosmic Ascension (orbs)
})

lists.feigned = arrayToLuT({
        5384, -- Feign Death
        58984, -- Shadowmeld
        11327, -- Vanish
        32612, -- Invisibility
        110960, -- Greater Invisibility
})

lists.incomingTargeted = arrayToLuT({
        427616, -- Energized Barrage
        462771, -- Surveying Beam
        462776, -- Surveying Beam
        437721, -- Boiling Flames
        437733, -- Boiling Flames
        453909, -- Boiling Flames
        453989, -- Boiling Flames
        454318, -- Boiling Flames
        454319, -- Boiling Flames
        441119, -- Bee-Zooka
        441344, -- Bee-Zooka
        426275, -- One-Hand Headlock
        426277, -- One-Hand Headlock
        426619, -- One-Hand Headlock
        448787, -- Purification
        424421, -- Fireball
        424420, -- Cinderblast
        446776, -- Pounce
        447439, -- Savage Mauling
        447443, -- Savage Mauling
        262794, -- Mind Lash
        1215916, -- Mind Lash
        269099, -- Charged Shot
        269100, -- Charged Shot
        269429, -- Charged Shot
        1217279, -- Uppercut
        1217280, -- Uppercut
        270042, -- Azerite Catalyst
        260811, -- Homing Missile
        260813, -- Homing Missile
        --291928, -- Mega-Zap
        285150, -- Foe Flipper
        285152, -- Foe Flipper
})

lists.incomingAoE = arrayToLuT({
        --Liberation of Undermine
        --Vexie Fullthrottle and The Geargrinders
        471403, -- Unrelenting Carnage
        459974, -- Bomb Voyage
        459627, -- Tank Buster (causes Exhaust Fumes in Heroic+) (cast bar)
        460603, -- Mechanical Breakdown (causes Backfire)
        465865, -- Tank Buster (DBM timer)
        
        --Cauldron of Carnage
        465863, -- Colossal Clash
        465872, -- Colossal Clash
        472220, -- Blistering Spite
        473650, -- Scrapbomb
        472223, -- Galvanized Spite
        
        --Rik Reverb
        466093, -- Haywire
        473260, -- Blaring Drop
        473655, -- Hype Fever
        466866, -- Echoing Chant
        
        --Stix Bunkjunker
        464399, -- Electromagnetic Sorting
        
        --Sprocketmonger Lockenstock
        465232, -- Sonic Ba-Boom
        1214872, -- Pyro Party Pack
        466860, -- Bleeding Edge (causes Voidsplosion)
        
        --One-Armed Bandit
        469993, -- Foul Exhaust
        461068, -- Fraud Detected (might not be possible to predict due to raid requirements)
        
        --Mug-Zee
        --468658, -- Elemental Carnage
        --468694, -- Uncontrolled Destruction
        --474461, -- Earthshaker Gaol
        
        --Gallywix
        
        
        --Nerub-ar Palace
        --Ulgrax
        435136, -- VenomousLash
        457668, -- CarnivorousContest
        436200, -- JuggernautCharge
        438012, -- HungeringBellows
        
        --Bloodbound Horror
        443203, -- CrimsonRain
        452237, -- Bloodcurdle
        444363, -- GruesomeDisgorge
        445936, -- SpewingHemorrhage
        442530, -- Goresplatter
        
        --Sikran
        433519, -- PhaseBlades
        442428, -- Decimate
        456420, -- ShatteringSweep
        
        --Rasha'nan
        439811, -- ErosiveSpray
        439784, -- SpinneretsStrands
        455373, -- InfestedSpawn
        439795, -- WebReave
        
        --Broodtwister
        442432, -- IngestBlackBlood
        441362, -- VolatileConcoction
        
        --Nexus-Princes Ky'veza
        437620, -- NetherRift
        438245, -- TwilightMassacre
        437343, -- Queensbane
        435405, -- StarlessNight
        
        --The Silken Court
        440246, -- RecklessCharge
        438656, -- VenomousRain
        441791, -- BurrowedEruption
        450980, -- ShatterExistence
        441626, -- WebVortex
        442994, -- UnleashedSwarm
        
        --Queen Ansurek
        439814, -- SilkenTomb
        440899, -- Liquefy
        447411, -- Wrest
        447967, -- GloomTouch
        438976, -- RoyalCondemnation
        
        --Dungeons
        --Season 2
        --Rookery
        427404, -- Localized Storm
        430812, -- Attracting Shadows
        430805, -- Arcing Void
        1214523, -- Feasting Void
        1214628, -- Unleash Darkness
        1214324, -- Crashing Thunder
        444123, -- Lightning Torrent
        424958, -- Crush Reality
        425048, -- Dark Gravity
        423393, -- Entropy
        423305, -- Null Upheaval
        429029, -- Corruption Overload
        
        --Priory
        427609, -- Disrupting Shout
        448492, -- Thunderclap
        427897, -- Heat Wave
        464240, -- Reflective Shield
        448791, -- Sacred Toll
        435156, -- Light Expulsion
        444743, -- Fireball Volley
        451763, -- Radiant Flame
        --424419, -- Battle Cry This is kicked.
        446368, -- Sacrificial Pyre
        423051, -- Burning Light
        --423015, -- Castigator's Shield
        423539, -- Inner Fire
        428169, -- Blinding Light
        423665, -- Embrace the Light   
        424431, -- Holy Radiance 
        424432, -- Holy Radiance
        
        --Darkflame Cleft
        428066, -- Overpowering Roar
        424322, -- Explosive Flame
        430171, -- Quenching Blast
        1218117, -- Massive Stomp
        422541, -- Drain Light
        428268, -- Underhanded Track Tics
        443835, -- Blazing Storms
        425394, -- Dousing Breath
        423099, -- Enkindling Inferno
        420665, -- Eerie Molds
        426943, -- Rising Gloom
        427176, -- Drain Light
        428266, -- Eternal Darkness
        
        --Cinderbrew
        463218, -- Volatile Keg
        463206, -- Tenderize
        441434, -- Failed Batch
        448619, -- Reckless Delivery
        442995, -- Swarming Surprise
        440687, -- Honey Volley
        442525, -- Happy Hour
        439365, -- Spouting Stout
        440104, -- Fill Er Up
        439524, -- Fluttering Wing
        435789, -- Cindering Wounds
        435622, -- Let It Hail    
        
        --Floodgate
        1214468, -- Trickshot
        468680,  -- Crabsplosion
        465827,  -- Warp Blood
        471736,  -- Jettison Kelp
        469721,  -- Backwash
        1216611, -- Battery Discharge
        1214780, -- Maximum Distortion
        469981,  -- Kill O Block Barrier
        460156,  -- Jumpstart
        460867,  -- Big Bada Boom
        470038,  -- Razorchoke Vines
        473070,  -- Awaken the Swamp
        465456,  -- Turbo Charge
        
        --Motherlode
        267354, -- Fan of Knives
        263628, -- Charged Shield
        473168, -- Rapid Extraction
        268702, -- Furious Quake
        269429, -- Charged Shot
        262347, -- Static Pulse
        256493, -- Blazing Azerite
        257597, -- Azerite Infusion
        258622, -- Resonant Quake
        271456, -- Drill Smash   
        
        --Workshop
        301088,  -- Detonate
        1215409, -- Mega Drill
        1215412, -- Corrosive Gunk
        473436,  -- High Explosive Rockets
        473436,  -- High Explosive Rockets (duplicate)
        1216443, -- Electrical Storm
        1215103, -- Ground Pound
        294929,  -- Blazing Chomp
        292022,  -- Explosive Leap
        291946,  -- Venting Flames
        291626,  -- Cutting Beam
        292290,  -- Protocol Ninety Nine
        292264,  -- Mega Zap
        283551,  -- Magneto Arm
        
        --Theatre of Pain
        333241,  -- Raging Tantrum
        1215850, -- Earthcrusher
        342135,  -- Interrupting Roar
        342135,  -- Interrupting Roar (duplicate)
        333839,  -- Swift Strikes
        333827,  -- Seismic Stomp
        330716,  -- Soulstorm
        341969,  -- Withering Discharge
        345245,  -- Disease Cloud
        1215600, -- Withering Touch
        333292,  -- Searing Death
        1215741, -- Mighty Smash
        320050,  -- Might of Maldraxxus
        473959,  -- Draw Soul
        323825,  -- Grasping Rift
        324449,  -- Manifest Death
        339573,  -- Echoes of Carnage
        
        --Season 1
        --Ara-Kara
        438476, -- Alerting Shrill
        438473, -- Gossamer Onslaught
        438877, -- Call of the Brood
        432227, -- Venom Volley
        461487, -- Cultivated Poisons
        --Trash
        433841, -- Venom Volley
        436322, -- Poison Bolt (single target but random so should prep everyone for it)
        448248, -- Revolting Volley
        
        --City of Threads
        448560, -- Shadows of Doubt
        434832, -- Vociferous Indoctrination
        441216, -- Viscous Darkness
        441395, -- Dark Pulse
        443436, -- Shadows of Doubt (trash)
        437700, -- Tremor Slam (boss)
        438860, -- Umbral Weave (boss)
        447271, -- Tremor Slam (trash)
        446717, -- Umbral Weave (trash)
        
        --Dawnbreaker
        425264, -- Obsidian Blast
        --426860, -- Dark Orb
        426787, -- Shadowy Decay (boss)
        451104, -- Bursting Cocoon
        431305, -- Dark Floes
        434089, -- Spinneret's Strands
        448888, -- Erosive Spray
        451102, -- Shadowy Decay (trash)
        450854, -- Dark Orb (trash)
        
        --Grim Batol
        448847, -- Commanding Roar
        448882, -- Rock Spike
        456741, -- Twilight Buffet
        451939, -- Umbral Wind
        451965, -- Molten Wake
        
        --Mists of Tirna-Scithe
        324922, -- Furious Thrashing
        460092, -- Acid Nova
        
        --Necrotic Wake
        320596, -- Heaving Retch
        327397, -- Grim Fate
        
        --Siege of Boralus
        257732, -- Shattering Bellow
        257883, -- Break Water
        
        --Stonevault
        424879, -- Earth Shatterer
        428535, -- Blazing Crescendo
        443954, -- Exhaust Vents
        427854, -- Entropic Reckoning
        425974, -- Ground Pound
        449154, -- Molten Mortar
        428879, -- Smash Rock
})

lists.containsDanger = arrayToLuT({
        
        
})

lists.HealerIds = arrayToLuT({
        105,  -- rdru
        1468, -- pres
        270,  -- mw
        65,   -- hpala
        256,  -- disc
        257,  -- hpri
        264   -- Rsham
})

lists.MeleeIds = arrayToLuT({
        250, --bdk
        251, --fdk
        252, --uhdk
        577, --havoc
        581, --vdh lessgooo
        255, --survival
        268, --brewmaster
        269, --ww
        66,  --prot pala
        70,  -- ret
        259, -- assa
        260, -- outlaw
        261, --sub
        263, -- enha
        71,  -- arms
        72,  -- fury
        73,  -- prot warr
})

lists.CasterIds = arrayToLuT({
        102,  -- balance
        1467, -- devo
        1473, -- aug
        62,   -- Arcane
        63,   -- fire
        64,   -- frost
        258,  -- spri
        262,  -- ele
        265,  -- affli
        266,  -- demo
        267,  -- destro
})

lists.RangedIds = arrayToLuT({
        102,  -- balance
        1467, -- devo
        1473, -- aug
        62,   -- Arcane
        63,   -- fire
        64,   -- frost
        258,  -- spri
        262,  -- ele
        265,  -- affli
        266,  -- demo
        267,  -- destro
        253,  -- bm
        254,  -- mm
})

-- TWW S1
lists.ALL_SET_IDS_S1 = {
    [1696] = true,
    [1695] = true,
    [1694] = true,
    [1693] = true,
    [1692] = true,
    [1691] = true,
    [1690] = true,
    [1689] = true,
    [1688] = true,
    [1687] = true,
    [1686] = true,
    [1685] = true,
    [1684] = true,
    
}

-- TWW S2, MISSING: DH, HUNTER, WARLOCK, SHAMAN
lists.ALL_SET_IDS = {
    [1867] = true, -- DK
    [1869] = true, -- Druid
    [1879] = true, -- War
    [1873] = true, -- Monk
    [1875] = true, -- Priest
    [1874] = true, -- Paladin
    [1872] = true, -- Mage
    [1876] = true, -- Rogue
    [1870] = true, -- Evoker
    [1868] = true, -- DH
    -- Guessing the rest
    [1871] = true,
    [1877] = true,
    [1878] = true,
    [1866] = true,
}

-- TWW S3 
lists.ALL_SET_IDS = {
    [1919] = true, -- Death Knight: Hollow Sentinel's Wake3
    [1920] = true, -- Demon Hunter: Charhound's Vicious Hunt4
    [1921] = true, -- Druid: Ornaments of the Mother Eagle5
    [1922] = true, -- Evoker: Spellweaver's Immaculate Design6
    [1923] = true, -- Hunter: Midnight Herald's Pledge7
    [1924] = true, -- Mage: Augur's Ephemeral Plumage8
    [1925] = true, -- Monk: Crash of Fallen Storms9
    [1926] = true, -- Paladin: Vows of the Lucent Battalion10
    [1927] = true, -- Priest: Eulogy to a Dying Star11
    [1928] = true, -- Rogue: Shroud of the Sudden Eclipse
    [1929] = true, -- Shaman: Howls of Channeled Fury13
    [1930] = true, -- Warlock: Inquisitor's Feast of Madness14
    [1931] = true, -- Warrior: Chains of the Living Weapon15
}

MakuluFramework.lists = lists

