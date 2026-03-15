local brokencyde = {}

if not brokencyde.druid then
    return
end

local druidAll = brokencyde.druid.all

if awful.player.class2 ~= "DRUID" then
    return
end

if brokencyde.loadedFiles["fake-cast"] then
    return
end

brokencyde.loadedFiles["fake-cast"] = true

brokencyde.casts = {}
brokencyde.lastCast = nil
brokencyde.kicks = {}

local function getSpellsSchools()
    if GetSpecialization() == 2 then
        return {
            [druidAll.cyclone.id] = { school = "Nature", type = 'cc', castType = 'cast' },
        }
    end
end

-- in tick
brokencyde.storeCasts()
brokencyde.fakeCast()
brokencyde.initializeEnemyKicks()

-- in on event
awful.onEvent(function(info, event, source, dest)
    if event == "SPELL_CAST_SUCCESS" and brokencyde.isInterrupt(info[13]) and dest.name == awful.player.name then
        brokencyde.successfullyKicked(source)
    end

    if event == "SPELL_INTERRUPT" then
        brokencyde.addInterrupt(info[13], dest)
    end
end)

-- definitions
function brokencyde.isInterrupt(spellName)
    local interrupts = {
        brokencyde.MIND_FREEZE,
        brokencyde.SKULL_BASH,
        brokencyde.SOLAR_BEAM,
        brokencyde.COUNTER_SHOT,
        brokencyde.COUNTERSPELL,
        brokencyde.SPEAR_HAND_STRIKE,
        brokencyde.AVENGERS_SHIELD,
        brokencyde.REBUKE,
        brokencyde.KICK,
        brokencyde.WIND_SHEAR,
        brokencyde.SPELL_LOCK,
        brokencyde.OPTICAL_BLAST,
        brokencyde.PUMMEL,
        brokencyde.MUZZLE,
        brokencyde.DISRUPT,
        brokencyde.SPELL_LOCK_GRIMOIRE,
        brokencyde.QUELL
    }

    for _, interrupt in ipairs(interrupts) do
        if interrupt == spellName then
            return true
        end
    end

    return false
end

function brokencyde.addInterrupt(interruptName, onUnit)
    brokencyde.interrupts[onUnit.name] = { interruptedAt = GetTime(), duration = getInterruptDuration(interruptName) }
end

function brokencyde.getCastTime()
    if awful.player.casting and awful.player.casting4 then
        return GetTime() - (awful.player.casting4 * 0.001)
    end

    if awful.player.channeling and awful.player.channel4 then
        return GetTime() - (awful.player.channel4 * 0.001)
    end

    return 0
end

function brokencyde.storeCasts()
    if awful.player.casting then
        brokencyde.casts[awful.player.castingid] = { castTimeComplete = brokencyde.getCastTime(), castType = 'cast' }
        brokencyde.lastCast = awful.player.castingid
    end

    if awful.player.channeling then
        brokencyde.casts[awful.player.channelingid] = { castTimeComplete = brokencyde.getCastTime(), castType = 'channel' }
        brokencyde.lastCast = awful.player.channelingid
    end
end

function brokencyde.successfullyKicked(kicker)
    --if not brokencyde.settings.fakeCast then
    --    return false
    --end

    if not brokencyde.lastCast then
        return false
    end

    local cast = brokencyde.casts[brokencyde.lastCast]

    if not cast then
        return false
    end

    if not brokencyde.kicks[kicker.guid] then
        brokencyde.kicks[kicker.guid] = {}
    else
        if awful.player.buff(brokencyde.PRECOGNITION) then
            brokencyde.lastKickFaked.chances = brokencyde.lastKickFaked.chances + 1
            return false
        end
    end

    local school = 'Nature'
    local type = 'cc'
    local lastCast = getSpellsSchools()[brokencyde.lastCast]

    if lastCast then
        school = lastCast.school
        type = lastCast.type
    end

    table.insert(brokencyde.kicks[kicker.guid], {
        school = school,
        type = type,
        castTimeComplete = math.min(cast.castTimeComplete, 0.8),
        castType = cast.castType,
        chances = 2,
    })
end

function brokencyde.fakeCastedRecently()
    if awful.player.buff(brokencyde.PRECOGNITION) then
        return false
    end

    if awful.player.buff(brokencyde.ANCESTRAL_GIFT) then
        return false
    end

    if awful.player.casting8 then
        return false
    end

    if awful.player.channel7 then
        return false
    end

    return brokencyde.lastFakeCastAttempt and GetTime() - brokencyde.lastFakeCastAttempt < brokencyde.random(0.3, 0.5)
end

function brokencyde.addFakeCastAttempt()
    brokencyde.lastFakeCastAttempt = GetTime()
end

local function shouldFakeCast(enemyGuid)
    local spellId = nil

    if awful.player.casting then
        spellId = awful.player.castingid
    end

    if awful.player.channeling then
        spellId = awful.player.channelingid
    end

    if not spellId then
        return false
    end

    if not brokencyde.kicks[enemyGuid] then
        return false
    end

    if not getSpellsSchools()[spellId] then
        return false
    end

    --if awful.player.castPct > brokencyde.random(79, 88) then
    --    return false
    --end

    local currentSchool = getSpellsSchools()[spellId].school
    local currentType = getSpellsSchools()[spellId].type
    local currentCastType = getSpellsSchools()[spellId].castType
    local currentTime = brokencyde.getCastTime()

    for i, kick in ipairs(brokencyde.kicks[enemyGuid]) do
        local sameSchool = kick.school == currentSchool
        local sameType = kick.type == currentType
        local kickCastTimeComplete = kick.castTimeComplete

        if currentCastType == 'cast' and kick.castType == 'channel' then
            kickCastTimeComplete = math.max(kickCastTimeComplete, 0.8)
        end

        if currentTime >= (kickCastTimeComplete - 0.1) and (sameSchool or sameType) then
            if kick.chances > 0 then
                kick.chances = kick.chances - 1
                brokencyde.lastKickFaked = kick
                return true
            else
                table.remove(brokencyde.kicks[enemyGuid], i)
            end
        end
    end

    return false
end

local function rogueWillKickMe(unit)
    if unit:Spec() ~= 259 and unit:Spec() ~= 260 and unit:Spec() ~= 261 then
        return false
    end

    if not unit.player then
        return false
    end

    if player.physImmune then
        return false
    end

    if unit:GetCD("Kick") > 0 then
        return false
    end

    if unit:DistanceTo(player) > 9 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function warriorWillKickMe(unit)
    -- if unit:Spec() ~= 71 and unit:Spec() ~= 72 and unit:Spec() ~= 73 then
    --     return false
    -- end

    if not unit.isDummy then
        return false
    end

    if player.physImmune then
        return false
    end

    -- if unit:GetCD("Pummel") > 0 then
    --     return false
    -- end

    if unit.channeling then
        return false
    end

    -- if unit:DistanceTo(player) > 9 then
    --     return false
    -- end

    -- if not unit:FacingUnit(player, 120) then
    --     return false
    -- end

    return shouldFakeCast(unit.guid)
end

local function paladinWillKickMe(unit)
    if unit:Spec() ~= 65 and unit:Spec() ~= 66 and unit:Spec() ~= 70 then
        return false
    end

    if not unit.player then
        return false
    end

    if player.physImmune then
        return false
    end

    if unit:GetCD("Rebuke") > 0 then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:DistanceTo(player) > 8 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function monkWillKickMe(unit)
    if unit:Spec() ~= 268 and unit:Spec() ~= 269 and unit:Spec() ~= 270 then
        return false
    end

    if not unit.player then
        return false
    end

    if player.physImmune then
        return false
    end

    if unit:GetCD("Spear Hand Strike") > 0 then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:DistanceTo(player) > 9 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function deathKnightWillKickMe(unit)
    if unit:Spec() ~= 250 and unit:Spec() ~= 251 and unit:Spec() ~= 252 then
        return false
    end

    if not unit.player then
        return false
    end

    if player.magicImmune then
        return false
    end

    if unit:GetCD("Mind Freeze") > 0 then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:DistanceTo(player) > 16 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function demonHunterWillKickMe(unit)
    if unit:Spec() ~= 577 and unit:Spec() ~= 581 then
        return false
    end

    if not unit.player then
        return false
    end

    if player.physImmune then
        return false
    end

    if unit:GetCD("Disrupt") > 0 then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:DistanceTo(player) > 11 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function evokerWillKickMe(unit)
    if unit:Spec() ~= 1467 and unit:Spec() ~= 1468 and unit:Spec() ~= 1473 then
        return false
    end

    if not unit.player then
        return false
    end

    if player.physImmune then
        return false
    end

    if unit:GetCD("Quell") > 0 then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:DistanceTo(player) > 26 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function mageWillKickMe(unit)
    if unit:Spec() ~= 62 and unit:Spec() ~= 63 and unit:Spec() ~= 64 then
        return false
    end

    if not unit.player then
        return false
    end

    if player.magicImmune then
        return false
    end

    if unit:GetCD("Counterspell") > 0 then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:DistanceTo(player) > 41 then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function warlockWillKickMe(unit)
    if unit:Spec() ~= 265 and unit:Spec() ~= 266 and unit:Spec() ~= 267 then
        return false
    end

    if not unit.player then
        return false
    end

    if not unit:Buff(196099) then
        return false
    end

    if player.magicImmune then
        return false
    end

    if unit:GetCD("Spell Lock (Grimoire)") > 0 then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:DistanceTo(player) > 41 then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function warlockPetWillKickMe(unit)
    if unit.id ~= 417 then
        return false
    end

    if player.magicImmune then
        return false
    end

    if unit:DistanceTo(player) > 41 then
        return false
    end

    if unit:GetCD("Spell Lock") > 0 then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function shamanWillKickMe(unit)
    if unit:Spec() ~= 262 and unit:Spec() ~= 263 and unit:Spec() ~= 264 then
        return false
    end

    if not unit.player then
        return false
    end

    if unit.channeling then
        return false
    end

    if player.magicImmune then
        return false
    end

    if unit:GetCD("Wind Shear") > 0 then
        return false
    end

    if unit:DistanceTo(player) > 31 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function hunterWillKickMe(unit)
    if unit:Spec() ~= 253 and unit:Spec() ~= 254 and unit:Spec() ~= 255 then
        return false
    end

    if not unit.player then
        return false
    end

    if unit:GetCD("Counter Shot") > 0 then
        return false
    end

    if player.physImmune then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:DistanceTo(player) > 40 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function druidWillKickMe(unit)
    if unit:Spec() ~= 102 and unit:Spec() ~= 103 and unit:Spec() ~= 104 then
        return false
    end

    if not unit.isMelee then
        return false
    end

    if not unit.player then
        return false
    end

    if unit.channeling then
        return false
    end

    if unit:GetCD("Skull Bash") > 0 then
        return false
    end

    if unit:DistanceTo(player) > 13 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit.guid)
end

local function willBeKicked()
    local result = false

    local enemyLoop = MultiUnit.allEnemies:Filter(function(unit)
        return unit.distance <= 50
    end)

    enemyLoop:ForEach(function(unit)
        if not unit.exists then return false end
        if not unit:Los() then return false end

        -- if unit.target and unit.target.exists and not unit.target:IsUnit(player) then
        --     return false
        -- end

        if rogueWillKickMe(unit) then
            result = true
            return true
        end

        if warriorWillKickMe(unit) then
            result = true
            return true
        end

        if paladinWillKickMe(unit) then
            result = true
            return true
        end

        if monkWillKickMe(unit) then
            result = true
            return true
        end

        if deathKnightWillKickMe(unit) then
            result = true
            return true
        end

        if demonHunterWillKickMe(unit) then
            result = true
            return true
        end

        if evokerWillKickMe(unit) then
            result = true
            return true
        end

        if mageWillKickMe(unit) then
            result = true
            return true
        end

        if warlockWillKickMe(unit) then
            result = true
            return true
        end

        -- if warlockPetWillKickMe(unit) then
        --     result = true
        --     return true
        -- end

        if shamanWillKickMe(unit) then
            result = true
            return true
        end

        if hunterWillKickMe(unit) then
            result = true
            return true
        end

        if druidWillKickMe(unit) then
            result = true
            return true
        end
    end)

    return result
end

function brokencyde.stopCast(reason)
    SpellStopCasting()
    SpellStopCasting()

    if reason ~= false then
        awful.alert("Stopped casting: " .. reason)
    end

    return true
end

function brokencyde.fakeCast()
    if awful.player.buff(brokencyde.PRECOGNITION) then
        return false
    end

    if not awful.player.casting and not awful.player.channeling then
        return false
    end

    if not brokencyde.isInterruptable(awful.player) then
        return false
    end

    if not willBeKicked() then
        return false
    end

    return brokencyde.stopCast("Fake casting") and brokencyde.addFakeCastAttempt()
end

local function getSpellToInitialize()
    return {
        school = "Nature",
        type = 'cc',
        castTimeComplete = 0.6,
        castType = 'cast',
        chances = 1
    }
end

function brokencyde.initializeEnemyKicks()
    awful.enemies.loop(function(enemy)
        if not enemy.isPlayer and enemy.id ~= 417 then
            return false
        end

        if not brokencyde.kicks[enemy.guid] then
            brokencyde.kicks[enemy.guid] = {}

            table.insert(brokencyde.kicks[enemy.guid], getSpellToInitialize())
        end
    end)
end

if brokencyde.fakeCastedRecently() then
    return false
end
