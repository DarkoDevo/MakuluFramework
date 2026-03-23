local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local SpellLookup = MakuluFramework.spellLookup
local CU = MakuluFramework.ConstUnits

local CreateFrame = CreateFrame
local GetTime = GetTime
local GetSpellBaseCooldown = GetSpellBaseCooldown
local GetSpellCharges = rawget(_G, "GetSpellCharges")
local IsPlayerSpell = _G.IsPlayerSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local C_Spell = _G.C_Spell
local LegacyGetSpellInfo = rawget(_G, "GetSpellInfo")

local function get_spell_name(spellId)
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local info = C_Spell.GetSpellInfo(spellId)
        if type(info) == "table" then
            return info.name
        end
    end

    if type(LegacyGetSpellInfo) == "function" then
        return LegacyGetSpellInfo(spellId)
    end

    return nil
end

local spellCache = {

}

local guid_cds = {

}


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

    local cooldownMs = 0
    if sourceGUID == rawget(CU.player, "guid") then
        cooldownMs = get_runtime_player_cooldown_ms(spellId)
    end

    if cooldownMs <= 0 then
        cooldownMs = get_spell_cd(spellId)
    end

    local spellsCd = (GetTime() * 1000) + cooldownMs

    units_cd[spellId] = spellsCd
    if spellNamea then
        units_cd[spellNamea] = spellsCd
    end
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
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            return on_spell_cast_success()
        end


MakuluFramework.CD = {
    Get = get_unit_spell_cd
}

MakuluFramework.Charges = {
    Remember = remember_charge_snapshot,
    Get = get_charge_snapshot,
}

MakuluFramework.Power = {
    Remember = remember_power_snapshot,
    Get = get_power_snapshot,
}