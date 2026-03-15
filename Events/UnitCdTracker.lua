local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local SpellLookup = MakuluFramework.spellLookup
local Events = MakuluFramework.Events
local CU = MakuluFramework.ConstUnits

local GetTime = GetTime
local GetSpellBaseCooldown = GetSpellBaseCooldown
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local spellCache = {

}

local guid_cds = {

}

Events.registerReset(function()
    guid_cds = {}
end)

local function get_spell_cd(spellId)
    local found = spellCache[spellId]
    if found then return found end

    found = GetSpellBaseCooldown(spellId)
    spellCache[spellId] = found

    return found
end

local function on_spell_cast(sourceGUID, spellId, spellNamea)
    local units_cd = guid_cds[sourceGUID]
    if not units_cd then
        units_cd = {}
        guid_cds[sourceGUID] = units_cd
    end

    local spellsCd = (GetTime() * 1000) + get_spell_cd(spellId)

    units_cd[spellId] = spellsCd
    units_cd[spellNamea] = spellsCd
end

local function get_unit_spell_cd(guid, spell)
    local units_cd = guid_cds[guid]
    if not units_cd then
        return 0
    end

    local spell_cd = units_cd[spell]
    if not spell_cd then return 0 end

    return math.max(0, (spell_cd - (GetTime() * 1000)))
end

local function player_casted(spellId)
    local lookup = SpellLookup[spellId]
    if not lookup then return end

    return rawset(lookup, "lastUsed", (GetTime() * 1000))
end

local function on_spell_cast_success(event, ...)
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool =
        CombatLogGetCurrentEventInfo()

    if subevent == "SPELL_CAST_SUCCESS" then
        if sourceGUID == rawget(CU.player, "guid") then
            player_casted(spellID)
        end

        return on_spell_cast(sourceGUID, spellID, spellName)
    end
end
Events.register("COMBAT_LOG_EVENT_UNFILTERED", on_spell_cast_success)

MakuluFramework.CD = {
    Get = get_unit_spell_cd
}
