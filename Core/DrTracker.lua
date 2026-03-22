local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local Events = MakuluFramework.Events
local LinkedTable = MakuluFramework.LinkedTable

local GetTime = GetTime

local COMBATLOG_OBJECT_REACTION_FRIENDLY = _G.COMBATLOG_OBJECT_REACTION_FRIENDLY
local COMBATLOG_OBJECT_TYPE_PLAYER = _G.COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_CONTROL_PLAYER = _G.COMBATLOG_OBJECT_CONTROL_PLAYER
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
local bit_band = _G.bit.band

local DRList = LibStub("DRList-1.0")

local DR_TIME = DRList:GetResetTime()

local tracked = {}
local names = {}

for category, name in pairs(DRList:GetCategories()) do
    tracked[name] = LinkedTable.create_lookup()
    names[category] = name
end

Events.registerReset(function()
    for _, table in pairs(tracked) do
        table = LinkedTable.create_lookup()
    end
end)

local function updateOrInsert(tracking, lookup, destguid, was_apply)
    local DRLevel = 1
    local DrAmount = 1
    if lookup then
        if lookup.data.updated > GetTime() then
            DRLevel = lookup.data.data.dr
            DrAmount = lookup.data.data.amount
        else
            -- This is an old entry we're going to re-use so reset timer
            lookup.data.updated = GetTime() + DR_TIME
        end
    end

    local new_level = DrAmount
    if was_apply then
        new_level = DRList:GetNextDR(DrAmount)
    end

    if not lookup then
        local data = {
            dr = new_level,
            amount = DrAmount + 1,
            active = was_apply,
        }
        LinkedTable.insert(tracking, destguid, data, GetTime() + DR_TIME)
    else
        lookup.data.data.active = was_apply

        if not was_apply then
            lookup.data.updated = GetTime() + DR_TIME
        else
            lookup.data.data.dr = new_level
            lookup.data.data.amount = DrAmount + 1
        end
    end
end

local function on_dr_spell(destguid, category, was_apply)
    local tracking = tracked[category]
    if not tracking then return end

    local lookup = tracking.lookup[destguid]

    updateOrInsert(tracking, lookup, destguid, was_apply)
end

local EventsToLookFor = {
    ["SPELL_AURA_REMOVED"] = true,
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_AURA_REFRESH"] = true,
}

Events.register("COMBAT_LOG_EVENT_UNFILTERED", function(event, ...)
    if type(CombatLogGetCurrentEventInfo) ~= "function" then
        return
    end

    local _, eventType, _, srcGUID, _, srcFlags, _, destGUID, destName, destFlags, _, spellID, _, _, auraType =
        CombatLogGetCurrentEventInfo()
    if not destGUID or not spellID then return end -- sanity check

    if auraType == "DEBUFF" then
        if not EventsToLookFor[eventType] then return end

        local category = DRList:GetCategoryBySpellID(spellID)
        if not category or category == "knockback" then return end
        category = DRList:GetCategoryLocalization(category)

        on_dr_spell(destGUID, category, eventType ~= "SPELL_AURA_REMOVED")
    end
 end)

local function cleanup_loop()
    local total_cleaned = 0
    local now = GetTime()
    for _, table in pairs(tracked) do
        total_cleaned = total_cleaned + LinkedTable.cleanup(table, now)
    end

    return C_Timer.After(5, cleanup_loop)
end

cleanup_loop()

local function get_dr(category, guid)
    local lookup = tracked[category].lookup[guid]
    if not lookup then
        return 1
    end

    if lookup.data.updated < GetTime() then
        return 1
    end

    return lookup.data.data.dr
end

local function get_dr_remains(category, guid)
    local lookup = tracked[category].lookup[guid]
    if not lookup then
        return 0
    end

    local remains = lookup.data.updated - GetTime()

    if remains < 0 then
        return 0
    end

    return remains * 1000
end

MakuluFramework.DR = {}
MakuluFramework.DR.Get = get_dr
MakuluFramework.DR.Remains = get_dr_remains
MakuluFramework.DR.Names = names
