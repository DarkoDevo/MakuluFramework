local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local Events = MakuluFramework.Events

local GetTime = GetTime
local GetSchoolString = C_Spell.GetSchoolString
local band = bit.band
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, _, extraSpellID, extraSpellName, extraSchool

local unit_kicked = {}

local bitMasks = {
    1,
    2,
    4,
    8,
    16,
    32,
    64
}

local schoolLookup = {}

for i = 1, 7, 1 do
    schoolLookup[bitMasks[i]] = GetSchoolString(bitMasks[i])
end

local lockoutDurations = {
    [47528] = 3, -- Mind Freeze
    [183752] = 3, -- Disrupt
    [106839] = 3, -- Skull Bash
    [93985] = 3, -- Skull Bash
    [78675] = 5, -- Solar beam
    [97547] = 5, -- Solar beam (alternate ID)
    [351338] = 4, -- Quell
    [187707] = 3, -- Muzzle
    [147362] = 3, -- Counter shot
    [2139] = 5, -- Counterspell
    [116705] = 3, -- Spear Hand Strike
    [31935] = 3, -- Avengers shield
    [96231] = 3, -- Rebuke
    [15487] = 4, -- Silence
    [1766] = 3, -- kick
    [57994] = 2, -- Wind shear
    [119910] = 5, -- Spell lockshear
    [132409] = 5, -- Spell lock (pet)
    [6552] = 3, -- Pummel
    [386071] = 6, -- Disrupting shout
    [91802] = 2, -- Shambling rush
    [91807] = 2, -- Shambling rush
    [347008] = 4, -- Axe Toss
    [19647] = 5, -- Spell Lock
    [427609] = 6, -- Disrupting shout2
}

local function track_kicks()
    if type(CombatLogGetCurrentEventInfo) ~= "function" then
        return
    end

    timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, _, extraSpellID, extraSpellName, extraSchool =
        CombatLogGetCurrentEventInfo()

    if subevent ~= "SPELL_INTERRUPT" or not destGUID or not destFlags or not spellID or not extraSchool then return end

    if band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and
        band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0 then
        local lockoutDuration = lockoutDurations[spellID]
        if not lockoutDuration then
            print(string.format("[LockoutTracker] Report to dev: Missing lockout duration for spell %s (%d).", spellName, spellID))
            lockoutDuration = 3 -- Default to 3 seconds if not found
        end
        local endTime = GetTime() + lockoutDuration

        local kick_table = unit_kicked[destGUID]
        if not kick_table then
            kick_table = {}
            unit_kicked[destGUID] = kick_table
        end

        for i = 1, 7, 1 do
            if band(extraSchool, bitMasks[i]) > 0 then
                kick_table[bitMasks[i]] = endTime
            end
        end

        -- print(string.format("%s is locked out of %s spells for %d seconds by %s.",
        --     destName, GetSchoolString(extraSchool), lockoutDuration, spellName))
    end
end


if Events.isEventSupported("COMBAT_LOG_EVENT_UNFILTERED") then
    Events.register("COMBAT_LOG_EVENT_UNFILTERED", track_kicks)
end

local function unitLockedRemains(guid, school)
    local unit = unit_kicked[guid]
    if not unit then return 0 end

    local expires = unit[school]
    if not expires then return 0 end

    return (expires - GetTime()) * 1000
end

local function unitLocked(guid, school)
    local unit = unit_kicked[guid]
    if not unit then return false end

    local expires = unit[school]
    if not expires then return false end

    return expires > GetTime()
end

MakuluFramework.Lockouts = {
    LockRemains = unitLockedRemains,
    Locked = unitLocked,
    Schools = schoolLookup
}

MakuluFramework.Unit.reindex()
