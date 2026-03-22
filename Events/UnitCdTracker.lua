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

local syntheticCooldownOverrides = {
    [19574] = function()
        local action = rawget(_G, "Action")
        if not action then
            return 0
        end

        if rawget(action, "PlayerSpec") ~= 253 then
            return 0
        end

        local learned = false
        if type(IsPlayerSpell) == "function" then
            local ok, result = pcall(IsPlayerSpell, 231548)
            learned = ok and result or false
        end

        if not learned and type(action.IsTalentLearned) == "function" then
            local ok, result = pcall(action.IsTalentLearned, action, 231548)
            learned = ok and result or false
        end

        if learned then
            return 30000
        end

        return 0
    end,
}

local syntheticChargeDurationOverrides = {
    [217200] = 12, -- Barbed Shot
}

local playerCastEffectRules = {
    [19574] = {
        {
            effect = "grant_charge",
            spellId = 217200, -- Barbed Shot
            amount = 1,
            requiresTalent = 193532, -- Scent of Blood
        },
    },
}

local guid_cds = {

}

local charge_snapshots = {

}

local power_snapshots = {

}

local actionPowerMethodMap = {
    [0] = { current = "Mana", max = "ManaMax", percent = "ManaPercentage", regen = "ManaRegen" },
    [2] = { current = "Focus", max = "FocusMax", percent = "FocusPercentage", regen = "FocusRegen" },
    [3] = { current = "Energy", max = "EnergyMax", percent = "EnergyPercentage", regen = "EnergyRegen" },
}

local function get_action_spell(spellId)
    local lookup = SpellLookup[spellId]
    return lookup and rawget(lookup, "actionSpell") or nil
end

local function resolve_synthetic_cooldown_override(spellId)
    local override = syntheticCooldownOverrides[spellId]
    if type(override) == "number" then
        return override
    end

    if type(override) == "function" then
        local ok, resolved = pcall(override, spellId)
        if ok and type(resolved) == "number" and resolved > 0 then
            return resolved
        end
    end

    return 0
end

local function get_runtime_player_cooldown_ms(spellId)
    local actionSpell = get_action_spell(spellId)
    if not actionSpell then
        return 0
    end

    if type(actionSpell.GetCooldown) == "function" then
        local ok, cooldown = pcall(actionSpell.GetCooldown, actionSpell)
        if ok and type(cooldown) == "number" and cooldown > 0 then
            return cooldown * 1000
        end
    end

    return 0
end

local function get_action_player()
    local action = rawget(_G, "Action")
    local player = action and rawget(action, "Player")
    if type(player) == "table" then
        return player
    end

    return nil
end

local function read_action_player_number(player, methodName)
    local method = player and methodName and rawget(player, methodName)
    if type(method) ~= "function" then
        return nil
    end

    local ok, value = pcall(method, player)
    if ok and type(value) == "number" then
        return value
    end

    return nil
end

local function get_action_player_power_info(powerId)
    local methodMap = actionPowerMethodMap[powerId]
    local player = methodMap and get_action_player()
    if not player then
        return nil
    end

    local current = read_action_player_number(player, methodMap.current)
    local max = read_action_player_number(player, methodMap.max)
    local percent = read_action_player_number(player, methodMap.percent)
    local regenPerSecond = read_action_player_number(player, methodMap.regen)

    if type(max) == "number" and max > 0 then
        if type(current) ~= "number" and type(percent) == "number" then
            current = math.max(0, math.min(max, math.floor((max * percent / 100) + 0.5)))
        end

        if type(current) == "number" then
            return {
                current = math.max(0, math.min(max, current)),
                max = max,
                percent = type(percent) == "number" and percent or math.max(0, math.min(100, (current / max) * 100)),
                regenPerSecond = type(regenPerSecond) == "number" and math.max(0, regenPerSecond) or 0,
                updatedAt = GetTime(),
                kind = "fallback",
                stale = true,
            }
        end
    end

    return nil
end

local function advance_power_snapshot(snapshot)
    if not snapshot then
        return nil
    end

    local current = tonumber(snapshot.current) or 0
    local max = tonumber(snapshot.max) or 0
    local updatedAt = tonumber(snapshot.updatedAt) or 0
    local regenPerSecond = tonumber(snapshot.regenPerSecond) or 0
    if max <= 0 then
        return snapshot
    end

    if current < max and updatedAt > 0 and regenPerSecond > 0 then
        local elapsed = GetTime() - updatedAt
        if elapsed > 0 then
            current = math.min(max, current + (elapsed * regenPerSecond))
        end
    end

    snapshot.current = math.max(0, math.min(max, current))
    snapshot.percent = max > 0 and math.max(0, math.min(100, (snapshot.current / max) * 100)) or 0
    snapshot.updatedAt = GetTime()
    return snapshot
end

local function remember_power_snapshot(powerId, info)
    local snapshot = advance_power_snapshot(power_snapshots[powerId])
    if type(info) ~= "table" then
        if snapshot then
            power_snapshots[powerId] = snapshot
            return snapshot
        end

        local fallback = get_action_player_power_info(powerId)
        if fallback then
            power_snapshots[powerId] = fallback
        end
        return fallback
    end

    local max = tonumber(info.max) or 0
    local current = tonumber(info.current)
    if max <= 0 or type(current) ~= "number" then
        if snapshot then
            power_snapshots[powerId] = snapshot
            return snapshot
        end

        local fallback = get_action_player_power_info(powerId)
        if fallback then
            power_snapshots[powerId] = fallback
        end
        return fallback
    end

    snapshot = snapshot or get_action_player_power_info(powerId) or {}
    snapshot.max = max
    snapshot.current = math.max(0, math.min(max, current))
    snapshot.percent = max > 0 and math.max(0, math.min(100, (snapshot.current / max) * 100)) or 0
    snapshot.updatedAt = GetTime()

    local regenPerSecond = tonumber(info.regenPerSecond)
    if type(regenPerSecond) == "number" and regenPerSecond >= 0 then
        snapshot.regenPerSecond = regenPerSecond
    elseif type(snapshot.regenPerSecond) ~= "number" then
        local fallback = get_action_player_power_info(powerId)
        snapshot.regenPerSecond = fallback and fallback.regenPerSecond or 0
    end

    snapshot.kind = info.kind or snapshot.kind or "tracked"
    snapshot.stale = info.stale

    power_snapshots[powerId] = snapshot
    return snapshot
end

local function spend_power_on_cast(spellId)
    local action = rawget(_G, "Action")
    local getSpellPowerCost = action and rawget(action, "GetSpellPowerCost")
    if type(getSpellPowerCost) ~= "function" then
        return
    end

    local ok, cost, powerId = pcall(getSpellPowerCost, spellId)
    cost = tonumber(cost) or 0
    powerId = tonumber(powerId) or -1
    if not ok or cost <= 0 or powerId < 0 then
        return
    end

    local snapshot = advance_power_snapshot(power_snapshots[powerId])
    if not snapshot then
        local fallback = get_action_player_power_info(powerId)
        if fallback then
            power_snapshots[powerId] = fallback
        end
        return
    end

    local max = tonumber(snapshot.max) or 0
    if max <= 0 then
        return
    end

    snapshot.current = math.max(0, math.min(max, (tonumber(snapshot.current) or 0) - cost))
    snapshot.percent = max > 0 and math.max(0, math.min(100, (snapshot.current / max) * 100)) or 0
    if type(snapshot.regenPerSecond) ~= "number" then
        local fallback = get_action_player_power_info(powerId)
        snapshot.regenPerSecond = fallback and fallback.regenPerSecond or 0
    end
    snapshot.updatedAt = GetTime()
    snapshot.kind = "tracked"
    snapshot.stale = true
    power_snapshots[powerId] = snapshot
end

local function get_power_snapshot(powerId)
    local snapshot = advance_power_snapshot(power_snapshots[powerId])
    if not snapshot then
        snapshot = get_action_player_power_info(powerId)
        if snapshot then
            power_snapshots[powerId] = snapshot
        end
    end

    if not snapshot then
        return nil
    end

    return {
        current = tonumber(snapshot.current) or 0,
        max = tonumber(snapshot.max) or 0,
        percent = tonumber(snapshot.percent) or 0,
        regenPerSecond = tonumber(snapshot.regenPerSecond) or 0,
        updatedAt = tonumber(snapshot.updatedAt) or GetTime(),
        kind = snapshot.kind or "tracked",
        stale = true,
    }
end

local function get_charge_recharge_seconds(spellId, snapshot)
    if snapshot and type(snapshot.cooldownDuration) == "number" and snapshot.cooldownDuration > 0 then
        return snapshot.cooldownDuration
    end

    local actionSpell = get_action_spell(spellId)
    if actionSpell and type(actionSpell.GetSpellBaseCooldown) == "function" then
        local ok, recharge = pcall(actionSpell.GetSpellBaseCooldown, actionSpell)
        if ok and type(recharge) == "number" and recharge > 0 then
            return recharge
        end
    end

    local recharge = GetSpellBaseCooldown(spellId) or 0
    if recharge > 0 then
        return recharge / 1000
    end

    return syntheticChargeDurationOverrides[spellId] or 0
end

local function advance_charge_snapshot(snapshot)
    if not snapshot then
        return nil
    end

    local maxCharges = snapshot.maxCharges or 0
    if maxCharges <= 0 then
        return snapshot
    end

    local currentCharges = snapshot.currentCharges or 0
    if currentCharges >= maxCharges then
        snapshot.currentCharges = maxCharges
        snapshot.cooldownStartTime = 0
        return snapshot
    end

    local duration = snapshot.cooldownDuration or 0
    local startTime = snapshot.cooldownStartTime or 0
    local modRate = snapshot.chargeModRate or 1
    if duration <= 0 or startTime <= 0 or modRate <= 0 then
        return snapshot
    end

    local elapsed = (GetTime() - startTime) * modRate
    if elapsed <= 0 then
        return snapshot
    end

    local regained = math.floor(elapsed / duration)
    if regained <= 0 then
        return snapshot
    end

    snapshot.currentCharges = math.min(maxCharges, currentCharges + regained)
    if snapshot.currentCharges >= maxCharges then
        snapshot.cooldownStartTime = 0
    else
        snapshot.cooldownStartTime = startTime + ((regained * duration) / modRate)
    end

    return snapshot
end

local function remember_charge_snapshot(spellId, info)
    if type(info) ~= "table" then
        return advance_charge_snapshot(charge_snapshots[spellId])
    end

    local maxCharges = tonumber(info.maxCharges) or 0
    if maxCharges <= 0 then
        return advance_charge_snapshot(charge_snapshots[spellId])
    end

    local snapshot = advance_charge_snapshot(charge_snapshots[spellId]) or {}
    snapshot.maxCharges = math.max(maxCharges, snapshot.maxCharges or 0)
    snapshot.currentCharges = math.min(snapshot.maxCharges, math.max(tonumber(info.currentCharges) or 0, 0))
    snapshot.chargeModRate = tonumber(info.chargeModRate) or snapshot.chargeModRate or 1
    snapshot.cooldownDuration = (tonumber(info.cooldownDuration) or 0) > 0 and info.cooldownDuration
        or get_charge_recharge_seconds(spellId, snapshot)

    local startTime = tonumber(info.cooldownStartTime) or 0
    if snapshot.currentCharges >= snapshot.maxCharges then
        snapshot.cooldownStartTime = 0
    elseif startTime > 0 then
        snapshot.cooldownStartTime = startTime
    elseif not snapshot.cooldownStartTime or snapshot.cooldownStartTime <= 0 then
        snapshot.cooldownStartTime = GetTime()
    end

    charge_snapshots[spellId] = snapshot
    return snapshot
end

local function get_live_charge_info(spellId)
    if type(GetSpellCharges) ~= "function" then
        return nil
    end

    local ok, first, second, third, fourth = pcall(GetSpellCharges, spellId)
    if not ok then
        return nil
    end

    if type(first) == "table" then
        return {
            currentCharges = first.currentCharges,
            maxCharges = first.maxCharges,
            cooldownStartTime = first.cooldownStartTime,
            cooldownDuration = first.cooldownDuration,
            chargeModRate = first.chargeModRate,
        }
    end

    return {
        currentCharges = first,
        maxCharges = second,
        cooldownStartTime = third,
        cooldownDuration = fourth,
    }
end

local function modify_charge_snapshot(spellId, delta)
    if type(delta) ~= "number" or delta == 0 then
        return
    end

    local snapshot = advance_charge_snapshot(charge_snapshots[spellId])
    if not snapshot then
        snapshot = remember_charge_snapshot(spellId, get_live_charge_info(spellId))
    end

    if not snapshot or (snapshot.maxCharges or 0) <= 0 then
        return
    end

    snapshot.currentCharges = math.max(0, math.min(snapshot.maxCharges, (snapshot.currentCharges or 0) + delta))
    if snapshot.currentCharges >= snapshot.maxCharges then
        snapshot.cooldownStartTime = 0
    elseif not snapshot.cooldownStartTime or snapshot.cooldownStartTime <= 0 then
        snapshot.cooldownStartTime = GetTime()
    end

    charge_snapshots[spellId] = snapshot
end

local function adjust_tracked_cooldown(guid, spellId, deltaMs)
    if not guid or not spellId or type(deltaMs) ~= "number" or deltaMs == 0 then
        return
    end

    local units_cd = guid_cds[guid]
    if not units_cd then
        return
    end

    local now = GetTime() * 1000
    local spell_cd = units_cd[spellId]
    if not spell_cd or spell_cd <= now then
        return
    end

    local adjusted = math.max(now, spell_cd + deltaMs)
    units_cd[spellId] = adjusted

    local spellName = get_spell_name(spellId)
    if spellName and units_cd[spellName] then
        units_cd[spellName] = adjusted
    end
end

local function reset_tracked_cooldown(guid, spellId)
    if not guid or not spellId then
        return
    end

    local units_cd = guid_cds[guid]
    if not units_cd then
        return
    end

    units_cd[spellId] = GetTime() * 1000

    local spellName = get_spell_name(spellId)
    if spellName and units_cd[spellName] then
        units_cd[spellName] = units_cd[spellId]
    end
end

local function should_apply_cast_rule(rule)
    if not rule then
        return false
    end

    if rule.requiresTalent and type(IsPlayerSpell) == "function" and not IsPlayerSpell(rule.requiresTalent) then
        return false
    end

    return true
end

local function apply_player_cast_effect_rules(spellId, playerGUID)
    local rules = playerCastEffectRules[spellId]
    if type(rules) ~= "table" then
        return
    end

    for _, rule in ipairs(rules) do
        if should_apply_cast_rule(rule) then
            if rule.effect == "grant_charge" then
                modify_charge_snapshot(rule.spellId, tonumber(rule.amount) or 0)
            elseif rule.effect == "adjust_cooldown" then
                adjust_tracked_cooldown(playerGUID, rule.spellId, tonumber(rule.deltaMs) or 0)
            elseif rule.effect == "reset_cooldown" then
                reset_tracked_cooldown(playerGUID, rule.spellId)
            end
        end
    end
end

local function on_charge_spell_cast(spellId)
    local snapshot = advance_charge_snapshot(charge_snapshots[spellId])
    if not snapshot or (snapshot.maxCharges or 0) <= 0 then
        return
    end

    local currentCharges = snapshot.currentCharges or snapshot.maxCharges or 0
    if currentCharges > 0 then
        snapshot.currentCharges = currentCharges - 1
    else
        snapshot.currentCharges = 0
    end

    snapshot.cooldownDuration = get_charge_recharge_seconds(spellId, snapshot)
    snapshot.chargeModRate = snapshot.chargeModRate or 1
    if snapshot.currentCharges >= snapshot.maxCharges then
        snapshot.cooldownStartTime = 0
    elseif not snapshot.cooldownStartTime or snapshot.cooldownStartTime <= 0 then
        snapshot.cooldownStartTime = GetTime()
    end

    charge_snapshots[spellId] = snapshot
end

local function get_charge_snapshot(spellId)
    local snapshot = advance_charge_snapshot(charge_snapshots[spellId])
    if not snapshot then
        return nil
    end

    return {
        currentCharges = snapshot.currentCharges or 0,
        maxCharges = snapshot.maxCharges or 0,
        cooldownStartTime = snapshot.cooldownStartTime or 0,
        cooldownDuration = snapshot.cooldownDuration or 0,
        chargeModRate = snapshot.chargeModRate or 1,
    }
end

local function get_spell_cd(spellId)
    local found = spellCache[spellId]
    if found then return found end

    local syntheticOverride = syntheticCooldownOverrides[spellId]
    found = resolve_synthetic_cooldown_override(spellId)
    if found > 0 then
        if type(syntheticOverride) ~= "function" then
            spellCache[spellId] = found
        end
        return found
    end

    found = GetSpellBaseCooldown(spellId) or 0
    if found <= 0 then
        local actionSpell = get_action_spell(spellId)
        if actionSpell and type(actionSpell.GetSpellBaseCooldown) == "function" then
            local ok, actionCooldown = pcall(actionSpell.GetSpellBaseCooldown, actionSpell)
            if ok and type(actionCooldown) == "number" and actionCooldown > 0 then
                found = actionCooldown * 1000
            end
        end
    end

    if type(syntheticOverride) ~= "function" then
        spellCache[spellId] = found
    end

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

local function player_casted_unit_spellcast(unitID, _, spellID)
    if unitID ~= "player" or not spellID then
        return
    end

    player_casted(spellID)
    on_charge_spell_cast(spellID)
    spend_power_on_cast(spellID)

    local playerGUID = rawget(CU.player, "guid")
    if not playerGUID then
        return
    end

    apply_player_cast_effect_rules(spellID, playerGUID)

    local spellName = get_spell_name(spellID)
    on_spell_cast(playerGUID, spellID, spellName)
end

local function on_spell_cast_success()
    if type(CombatLogGetCurrentEventInfo) ~= "function" then
        return
    end

    local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()

    if subevent == "SPELL_CAST_SUCCESS" then
        if sourceGUID == rawget(CU.player, "guid") then
            player_casted(spellID)
        end

        if not sourceGUID or not spellID or not spellName then
            return
        end

        return on_spell_cast(sourceGUID, spellID, spellName)
    end
end

local trackerFrame = rawget(MakuluFramework, "unitCdTrackerFrame")
if not trackerFrame and type(CreateFrame) == "function" then
    trackerFrame = CreateFrame("Frame")
    rawset(MakuluFramework, "unitCdTrackerFrame", trackerFrame)
end

if trackerFrame then
    trackerFrame:UnregisterAllEvents()
    trackerFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            return on_spell_cast_success()
        end

        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            return player_casted_unit_spellcast(...)
        end

        if event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or event == "PLAYER_ENTERING_WORLD" then
            guid_cds = {}
            charge_snapshots = {}
            power_snapshots = {}
        end
    end)

    if type(CombatLogGetCurrentEventInfo) == "function" then
        trackerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    trackerFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    trackerFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    trackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
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
