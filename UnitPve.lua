local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local MF                 = MakuluFramework

local Unit               = MakuluFramework.Unit
local Cache              = MakuluFramework.Cache
local tableCrossOver     = MakuluFramework.tableCrossOver
local MakLists           = MakuluFramework.lists
local ConstUnit          = MakuluFramework.ConstUnits
local MakMulti         = MakuluFramework.MultiUnits
local UnitGUID           = MakuluFramework.GetGuid

local SpellState = MakuluFramework.spellState


local Action             = Action or {}
local MultiUnits         = Action.MultiUnits
local BossMods         = Action.BossMods

local player = ConstUnit.player
local target = ConstUnit.target

function Unit:IncorpStunned()
    return self.cache:GetOrSet("IncorpStunned", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.IncorpStunned)
    end)
end

function Unit:PvEPurge()
    return self.cache:GetOrSet("PVEPurge", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.pvePurge)
    end)
end

---------------Keeping in only for Mistweaver-----------
local lockedTarget = nil
function Unit:PvEInterrupt(spellAction, minPercent, minEndTime, isCC, aoe)
    local casting = Unit.CastOrChanelInfo(self)
    if not casting then return false end
    local spellId = casting.spellId
    local interrupt = MakLists.pveInterrupts[spellId]
    local stops = MakLists.pveStops[spellId]
    local targetGUID = UnitGUID("target")
    local isCurrentTarget = self.guid == targetGUID
    local _, _, _, lagWorld = GetNetStats()
    local maxMinEndTime = math.max(Action.GetCurrentGCD() + ((lagWorld / 1000) * 2), minEndTime or 0)
    if isCurrentTarget or lockedTarget == targetGUID then
        lockedTarget = targetGUID
        if aoe and spellAction:IsReady() and (interrupt or (isCC and stops)) and casting.percent >= minPercent and casting.endTime > maxMinEndTime and (CheckInteractDistance("target", 3)) then
            return true
        elseif not aoe then
            if interrupt and ((isCC and not Unit.ActionUnit(self):IsBoss()) or not isCC) and Unit.IsSafeToKick(self) and spellAction:IsReady() and spellAction:IsSpellInRange("target") and casting.percent >= minPercent then
                return true
            elseif isCC and stops and Unit.IsSafeToKickCC(self) and spellAction:IsReady() and (spellAction:IsSpellInRange("target") or CheckInteractDistance("target", 3)) and casting.percent >= minPercent and casting.endTime > maxMinEndTime then
                return true
            end
        end
    elseif not isCurrentTarget and Action.GetToggle(2, "AutoInterrupt") and spellAction:IsReady() and not aoe and (interrupt or (isCC and stops)) and (spellAction:IsSpellInRange("target") or CheckInteractDistance("target", 3)) then
        return "Switch"
    end
    return false
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Combat end
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_ENABLED" then
        AlreadyAssignedInterrupt = nil
    end
end)

----------------------------


local currentSeason = {
    [2648] = true, -- The Rookery
    [2649] = true, -- Priory of the Sacred Flame
    [2651] = true, -- Darkflame Cleft
    [2652] = false, -- The Stonevault
    [2660] = false, -- Ara-Kara, City of Echoes
    [2661] = true, -- Cinderbrew Meadery
    [2662] = false, -- The Dawnbreaker
    [2669] = false, -- City of Threads
    [2290] = false, -- Mists of Tirna Scithe
    [2286] = false, -- The Necrotic Wake
    [1822] = false, -- Siege of Boralus
    [670] = false, -- Grim Batol
    [1594] = true, -- The MOTHERLODE!!
    [2293] = true, -- Theatre of Pain
    [2097] = true, -- Operation: Mechagon
    [2773] = true, -- Operation: Floodgate
}

local ccImmune = {
    [218324] = true, -- Sureki Attendant
}

function Unit:ShouldInterrupt(spell, isCC, aoe, distance)
    local casting = Unit.CastOrChanelInfo(self)
    if not casting then return false end

    local isCC = isCC or false
    local aoe = aoe or false
    local distance = distance or 5

    local _, instanceType, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local dungeon = difficultyID == 8 or difficultyID == 23
    --[[local interruptible = not casting.notInterrupt
    local outsideDungeonKick = not dungeon and (interruptible or isCC)]]

    local spellId = casting.spellId
    local raidBoss = instanceType == "raid" and Unit.IsBoss(self)
    local interrupt = MakLists.pveInterrupts[spellId] or (not dungeon and not raidBoss)
    local stops = MakLists.pveStops[spellId] or not dungeon
    local affix = MakLists.pveAffix[spellId] and aoe

    if not spell:IsKnown() then return false end
    if not spell:ReadyToUse() then return false end

    local inRange = spell:HasRange(self) and spell:InRange(self) or not spell:HasRange(self)
    if not inRange then return end

    local npcId = Unit.NpcId(self)
    local immuneToCC = ccImmune[npcId] or Unit.IsBoss(self)

    local safeToKick = not isCC and Unit.IsSafeToKick(self)
    local safeToKickCC = isCC and Unit.IsSafeToKickCC(self) and not immuneToCC

    local custom = true
    if spell.condition and type(spell.condition) == "function" then
        custom = spell.condition()
    end

    if interrupt and safeToKick and custom then
        return true
    end
    if (stops or affix) and safeToKickCC and (aoe and Unit.Distance(self) <= distance or not aoe) and custom then
        return true
    end

    return false
end

local constCell = Cache:getConstCacheCell()
function targetForInterrupt(interruptSpells)
    return constCell:GetOrSet("targetForInterrupt", function()
        local activeEnemies = MultiUnits:GetActiveUnitPlates()

        if not Action.GetToggle(2, "AutoInterrupt") then return false end
        local _, instanceType = GetInstanceInfo()
        --if instanceType ~= "party" and instanceType ~= "raid" then return false end
        if instanceType == "arena" or instanceType == "pvp" then return false end

        for _, spellInfo in ipairs(interruptSpells) do
            if target:ShouldInterrupt(spellInfo.spell, spellInfo.isCC, spellInfo.aoe, spellInfo.distance) then
                return false
            end
        end

        for enemyGUID in pairs(activeEnemies) do
            local enemy = Unit:new(enemyGUID)
            local isCurrentTarget = enemy:IsTarget()

            for _, spellInfo in ipairs(interruptSpells) do
                
                local casting = enemy.castOrChannelInfo
                if not casting then
                    break
                end

                local shouldInterrupt = enemy:ShouldInterrupt(spellInfo.spell, spellInfo.isCC, spellInfo.aoe, spellInfo.distance)
                
                if spellInfo.aoe then
                    return false
                elseif not isCurrentTarget and shouldInterrupt then
                    return true
                end
            end
        end

        return false
    end)
end

function makInterrupt(interruptSpells)
    if not target.canAttack then return false end 
    local casting = target.castOrChannelInfo
    if casting then
        if casting.percent < 32 and not target.channeling then return false end
        if casting.percent > 67 and target.channeling then return false end

        for _, spellInfo in ipairs(interruptSpells) do
            if target:ShouldInterrupt(spellInfo.spell, spellInfo.isCC, spellInfo.aoe, spellInfo.distance) then
                return spellInfo.spell:Cast(target)
            end
            if target.pvpKick then 
                return spellInfo.spell:Cast(target)
            end
        end
    end

    return constCell:GetOrSet("aoeInterrupt", function()
        for _, spellInfo in ipairs(interruptSpells) do
            if spellInfo.aoe then
                local activeEnemies = MultiUnits:GetActiveUnitPlates()
                for enemyGUID in pairs(activeEnemies) do
                    local enemy = Unit:new(enemyGUID)

                    local casting = enemy.castOrChannelInfo
                    if not casting then
                        break
                    end
    
                    local shouldInterrupt = enemy:ShouldInterrupt(spellInfo.spell, spellInfo.isCC, spellInfo.aoe, spellInfo.distance)
                    
                    if (shouldInterrupt or (enemy and enemy.pvpKick)) and casting.percent > 59 and (spellInfo.distance and enemy.distance <= spellInfo.distance) then
                        return spellInfo.spell:Cast()
                    end
                end
            end
        end
    end)
end

function makMin(debuff, ttd)
    return constCell:GetOrSet("minDebuff", function()
        local ttd = ttd or 0

        local activeEnemies = MultiUnits:GetActiveUnitPlates()
        local _, instanceType = GetInstanceInfo()
        --[[if instanceType ~= "party" and instanceType ~= "raid" then 
            return false
        end]]

        local minDuration = math.huge  
        local minDurationEnemy = nil

        for enemyGUID in pairs(activeEnemies) do
            local enemy = Unit:new(enemyGUID)
            
            if enemy.exists and not enemy.dead then
                local debuffDuration = enemy:DebuffRemains(debuff)
                local shouldBother = enemy.ttd >= ttd
                
                if debuffDuration > 0 and debuffDuration < minDuration and shouldBother then
                    minDuration = debuffDuration
                    minDurationEnemy = enemy
                end
            end
        end

        if minDurationEnemy then
            return minDurationEnemy, minDuration
        else
            return false
        end
    end)
end

function targetMin(debuff)
    local minEnemy, duration = makMin(debuff)
    if not minEnemy then 
        return false
    end

    if minEnemy.isTarget then 
        return false
    end

    if target:ShouldInterrupt() then 
        return false
    end

    return true
end

local bigAoE = {
    --Liberation of Undermine
    --Vexie Fullthrottle and The Geargrinders
    471403, -- Unrelenting Carnage
    459974, -- Bomb Voyage
    459627, -- Tank Buster (causes Exhaust Fumes in Heroic+)
    460603, -- Mechanical Breakdown (causes Backfire)

    --Cauldron of Carnage
    465833, -- Colossal Clash
    472222, -- Blistering Spite
    473650, -- Scrapbomb
    472225, -- Galvanized Spite

    --Rik Reverb
    466093, -- Haywire
    473260, -- Blaring Drop
    473655, -- Hype Fever

    --Stix Bunkjunker
    464399, -- Electromagnetic Sorting

    --Sprocketmonger Lockenstock
    465232, -- Sonic Ba-Boom
    1214872, -- Pyro Party Pack
    1215218, -- Bleeding Edge (causes Voidsplosion)

    --One-Armed Bandit
    469993, -- Foul Exhaust
    461068, -- Fraud Detected (might not be possible to predict due to raid requirements)

    --Mug-Zee
    468658, -- Elemental Carnage
    468694, -- Uncontrolled Destruction
    474461, -- Earthshaker Gaol

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
    465827, -- Warp Blood
    471736, -- Jettison Kelp
    469721, -- Backwash
    1216611, -- Battery Discharge
    427404, -- Localized Storm
    430812, -- Attracting Shadows
    1214523, -- Feasting Void
    1214628, -- Unleash Darkness
    464240, -- Reflective Shield
    448791, -- Sacred Toll
    444743, -- Fireball Volley
    451763, -- Radiant Flame
    424322, -- Explosive Flame
    422541, -- Drain Light
    463218, -- Volatile Keg
    441434, -- Failed Batch
    448619, -- Reckless Delivery
    440687, -- Honey Volley
    267354, -- Fan of Knives
    263628, -- Charged Shield
    473168, -- Rapid Extraction
    268702, -- Furious Quake
    269429, -- Charged Shot
    301088, -- Detonate
    1215409, -- Mega Drill
    473436, -- High Explosive Rockets
    333241, -- Raging Tantrum
    330716, -- Soulstorm
    341969, -- Withering Discharge

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

}

local moderateAoE = {
    --Ara-Kara
    465012, -- Slam

    --City of Threads
    439341, -- Splice
    434137, -- Venomous Spray

    --Dawnbreaker
    431304, -- Dark Floes

    --Siege of Boralus
    269266, -- Slam
    272711, -- Crushing Slam

    --Stonevault
    424795, -- Refracting Beam
}


local incAdds = {
    --DBM alert ID (same format as lists above)
}

function makRamp(spellList)
    local lowestTimer = 99999

    for _, spell in ipairs(spellList) do
        local timer = BossMods:HasAnyAddon() and BossMods:GetTimer(spell) or 0
        if timer > 0 then
            if timer < lowestTimer then
                lowestTimer = timer
            end
        end
    end

    if lowestTimer == 99999 then
        return 99999
    end

    return lowestTimer * 1000
end

function makShouldDefensive()
    return constCell:GetOrSet("should_defensive", function()
        local activeEnemies = MultiUnits:GetActiveUnitPlates()

        for enemyGUID in pairs(activeEnemies) do
            local enemy = Unit:new(enemyGUID)
            local casting = enemy.castOrChannelInfo
            if casting and casting.spellId then
                local spellId = casting.spellId
                if MakLists.incomingAoE[spellId] then
                    if casting.channel then
                        return casting.castLength - casting.remaining
                    else
                        return casting.remaining
                    end
                end
            end
        end
        return 99999
    end)
end

function makIncBuster()
    return constCell:GetOrSet("incBuster", function()
        local activeEnemies = MultiUnits:GetActiveUnitPlates()

        for enemyGUID in pairs(activeEnemies) do
            local enemy = Unit:new(enemyGUID)
            local casting = enemy.castOrChannelInfo
            if casting and casting.spellId then
                local spellId = casting.spellId
                if MakLists.pveTankBuster[spellId] then
                    local destination = enemy.target
                    if destination then
                        if destination.guid == player.guid then
                            if casting.channel then
                                return casting.castLength - casting.remaining
                            else
                                return casting.remaining
                            end
                        end
                    end
                end
            end
        end
        return 99999
    end)
end

function makShouldStopCast()
    return constCell:GetOrSet("should_stopcast", function()
        local activeEnemies = MultiUnits:GetActiveUnitPlates()

        for enemyGUID in pairs(activeEnemies) do
            local enemy = Unit:new(enemyGUID)
            local casting = enemy.castOrChannelInfo
            if casting and casting.spellId then
                local spellId = casting.spellId
                if MakLists.stopcasting[spellId] then
                    return true
                end
            end
        end
        return false
    end)
end

function makFeign()
    return constCell:GetOrSet("pveFeign", function() 
        local activeEnemies = MultiUnits:GetActiveUnitPlates()

        for enemyGUID in pairs(activeEnemies) do
            local enemy = Unit:new(enemyGUID)
            local casting = enemy.castOrChannelInfo
            if casting and casting.spellId then
                local spellId = casting.spellId
                local destination = enemy.target
                if destination then
                    if MakLists.incomingTargeted[spellId] and destination.guid == player.guid then
                        return true
                    end
                end
            end 
        end  
        
        return false 
    end)
end

function incBigDmgIn()
    if makRamp(bigAoE) >= 99999 then
        return makShouldDefensive()
    else
        return makRamp(bigAoE)
    end
end

function incModDmgIn()
    return makRamp(moderateAoE)
end

function incTankBuster()
    return makRamp(MakLists.pveTankBuster)
end

function incAddsIn()
    return makRamp(incAdds)
end

--[[function makContainsDanger()
    return constCell:GetOrSet("contains_danger", function()
        local activeEnemies = MultiUnits:GetActiveUnitPlates()

        for enemyGUID in pairs(activeEnemies) do
            local enemy = Unit:new(enemyGUID)
            local id = enemy.npcId
            if MakLists.dangerEnemy[id] then
                return true
            end
        end
        return false
    end)
end]]

function makBurst()
    local burstToggle = Action.GetToggle(1, "Burst")
    if burstToggle ~= "Auto" and burstToggle ~= "Everything" then
        return false
    end

    if not target.bigButtons then
        return false
    end

    local _, instanceType = GetInstanceInfo()

    if instanceType ~= "party" or (target and target.isDummy) or UnitLevel(player:CallerId()) < 80 then
        return true
    end

    local burstSens = Action.GetToggle(2, "burstSens") or 15

    local gapMultiplier = 0.2 

    local hp82 = burstSens * 1
    local hp81 = burstSens * (1 + gapMultiplier)
    local hp80 = burstSens * (1 + 2 * gapMultiplier)

    if instanceType == "party" then
        local activeEnemies = MultiUnits:GetActiveUnitPlates()
        local count = 0

        for enemyGUID in pairs(activeEnemies) do
            local enemy = Unit:new(enemyGUID)
            local classification = UnitClassification(enemy:CallerId())
            local enemyLevel = UnitLevel(enemy:CallerId())
            local enemyHp = enemy.hp

            if enemy.inCombat then
                if classification == "rareelite" or classification == "elite" or UnitIsUnit(enemy:CallerId(), "boss1") then
                    if (enemyLevel == 82 or UnitIsUnit(enemy:CallerId(), "boss1")) and enemyHp > hp82 then
                        return true
                    elseif enemyLevel == 81 and enemyHp > hp81 then
                        return true
                    elseif enemyLevel == 80 and enemyHp > hp80 then
                        count = count + 1
                        if count >= 3 then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

local bossCheckers = {}
bossCheckers.prototype = {
    -- Ara-Kara
    avanoxx = 213179,
    anubzekt = 215405,
    kikatal = 215407,

    -- Cinderbrew
    aldryr = 210271,
    benk = 218000,
    ipa = 210267,
    goldie = 218523,

    -- City of Threads
    krixvizk = 216619,
    fangs = 216648,
    coaglamation = 216320,
    izo = 216658,

    -- Darkflame Cleft
    waxbeard = 210149,
    blazikon = 208743,
    candleking = 222096,
    darkness = 210797,

    -- Priory
    dailcry = 207946,
    braunpyke = 207939,
    murrpray = 207940,

    -- Dawnbreaker
    shadowcrown = 211087,
    anubikkaj = 211089,
    rashanan = 224552, -- in script, add extra condition for instanceInfo type == "party"

    -- Rookery
    kyrioss = 209230,
    gorren = 207205,
    monstrosity = 207207,

    -- Stonevault
    edna = 210108,
    skamorak = 210156,
    machinists = 213216,
    eirich = 213119,

    -- Nerub-ar Palace
    ulgrax = 215657,
    bloodboundhorror = 214502,
    sikran = 219853,
    -- rashanan = 224552 -- in script, add extra condition for instanceInfo type == "raid"
    ovinax = 214506,
    kyveza = 228470,
    silkencourt = 223779,
    ansurek = 218370,

    --Undermine
    vexie = 225822,
    cauldron = 229181,
    rik = 228648,
    stix = 230322,
    lockenstock = 230583,
    bandit = 228458,
    mugzee = 229953,
    gallywix = 231075,
}

local bossChecker = function(self, key)
    if bossCheckers.prototype[key] then
        return function()
            if target.exists and target.npcId == bossCheckers.prototype[key] and target.hp > 0 then
                return true
            end

            for i = 1, 3 do
                local boss = Unit:new("boss" .. i)
                if boss.exists and boss.npcId == bossCheckers.prototype[key] then
                    return true
                end
            end

            return false
        end
    end
    return nil
end

local bossMetaTable = {
    __index = bossChecker
}

function makBoss()
    local bossCheckers = {}
    setmetatable(bossCheckers, bossMetaTable)
    return bossCheckers
end

MakuluFramework.Boss = makBoss()
-- Example usage:
--local boss = MakuluFramework.Boss
--print(boss.avanoxx())  -- Returns true if fighting Avanoxx, otherwise false
--print(boss.anubzekt()) -- Returns true if fighting Anub'zekt, otherwise false


local incSpell = {}
incSpell.prototype = {
    -- Ara-Kara
    alertingShrill = 438476,
    vociferousIndoctrination = 434829,

    -- City of Threads
    splice = 439341,

    --Ulgrax
    venomousLash = 435136,
    carnivorousContest = 457668,
    swallowingDarkness = 451412,

    --Vexie
    mechanicalBreakdown = 460603,

    --Cauldron
    colossalClash = 465863,

    --Lockenstock
    betaLaunch = 466765,
    bleedingEdge = 466860,
}

local spellCastCounts = {}

MakuluFramework.Events.register("PLAYER_REGEN_ENABLED", function()
    spellCastCounts = {}
end)

local function on_spell_cast_success()
    if type(CombatLogGetCurrentEventInfo) ~= "function" then
        return
    end

    local _, subevent, _, _, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if subevent ~= "SPELL_CAST_SUCCESS" or not spellID then return end

    for key, id in pairs(incSpell.prototype) do
        if spellID == id then
            spellCastCounts[id] = (spellCastCounts[id] or 0) + 1
            break
        end
    end
end
if MakuluFramework.Events.isEventSupported("COMBAT_LOG_EVENT_UNFILTERED") then
    MakuluFramework.Events.register("COMBAT_LOG_EVENT_UNFILTERED", on_spell_cast_success)
end


local incCast = function(self, key, spellTable)
    if spellTable.prototype[key] then
        return constCell:GetOrSet("incSpell", function()
            local activeEnemies = MultiUnits:GetActiveUnitPlates()
            for enemyGUID in pairs(activeEnemies) do
                local enemy = Unit:new(enemyGUID)
                local cast = enemy.castOrChannelInfo
                if cast and cast.spellId == spellTable.prototype[key] then
                    if cast.channel then
                        return cast.castLength - cast.remaining
                    else
                        return cast.remaining
                    end
                end
            end
            return 99999
        end)
    end
    return 99999
end

local spellMetaTable = {
    __index = function(self, key, spellTable)
        local spellKey = key:match("^(.*)Count$")
        if spellKey then
            local spellID = spellTable.prototype[spellKey]
            return spellID and (spellCastCounts[spellID] or 0) or nil
        else
            return incCast(self, key, spellTable)
        end
    end
}

function makIncSpell(spellTable)
    local incSpell = {}
    setmetatable(incSpell, {
        __index = function(self, key)
            return spellMetaTable.__index(self, key, spellTable)
        end
    })
    return incSpell
end

MakuluFramework.incSpell = makIncSpell(incSpell)

local function canAttack()
    local _, instanceType = GetInstanceInfo()
    if instanceType ~= "party" or (target and target.isDummy) then
        return true
    end    

    if Action.GetToggle(2, "dontPull") then
        if target.exists and not target.combat then
            return false
        end
    end

    return true
end

MakuluFramework.canAttack = canAttack()

MakuluFramework.PVE = MakuluFramework.PVE or {
    interrupt = makInterrupt,
    min = makMin,
    boss = makBoss,
    incSpell = makIncSpell,
    burst = makBurst,
    ramp = makRamp,
    shouldDefensive = makShouldDefensive,
    shouldBurst = shouldBurst,
}

Unit.reindex()
--Usage: 
--Add spells to track to incSpell.prototype
--local inc = MakuluFramework.incSpell
--inc.alertingShrill  -- returns remaining time on Alerting Shrill spell cast (cast bars only, not DBM. Use makRamp() for DBM)
--inc.alertingShrillCount -- returns the current cast amount of that spell (for example, will return 2 if it is currently the second time casting, 3 if it is the third time)
