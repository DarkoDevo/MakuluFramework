local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local SpellLookup = MakuluFramework.spellLookup
local Events = MakuluFramework.Events
local CU = MakuluFramework.ConstUnits
local MultiUnits = MakuluFramework.MultiUnits

local SpellState = MakuluFramework.spellState
local player = MakuluFramework.ConstUnits.player

local function shouldFakeCast(unit)
    return true
end

local specKickLookup = {}

local function rogueWillKickMe(unit)
    if player.physImmune then
        return false
    end

    if unit:GetCD("Kick") > 0 then
        return false
    end

    if unit:Distance() > 9 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[259] = rogueWillKickMe
specKickLookup[260] = rogueWillKickMe
specKickLookup[261] = rogueWillKickMe

local function warriorWillKickMe(unit)
    if player.physImmune then
        return false
    end

    if unit:GetCD("Pummel") > 0 then
        return false
    end

    if unit:Distance() > 9 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[71] = warriorWillKickMe
specKickLookup[72] = warriorWillKickMe
specKickLookup[73] = warriorWillKickMe

local function paladinWillKickMe(unit)
    if player.physImmune then
        return false
    end

    if unit:GetCD("Rebuke") > 0 then
        return false
    end

    if unit:Distance() > 8 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[65] = paladinWillKickMe
specKickLookup[66] = paladinWillKickMe
specKickLookup[70] = paladinWillKickMe

local function monkWillKickMe(unit)
    if player.physImmune then
        return false
    end

    if unit:GetCD("Spear Hand Strike") > 0 then
        return false
    end

    if unit:Distance() > 9 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[268] = monkWillKickMe
specKickLookup[269] = monkWillKickMe
specKickLookup[270] = monkWillKickMe

local function deathKnightWillKickMe(unit)
    if player.magicImmune then
        return false
    end

    if unit:GetCD("Mind Freeze") > 0 then
        return false
    end

    if unit:Distance() > 16 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[250] = deathKnightWillKickMe
specKickLookup[251] = deathKnightWillKickMe
specKickLookup[252] = deathKnightWillKickMe

local function demonHunterWillKickMe(unit)
    if player.physImmune then
        return false
    end

    if unit:GetCD("Disrupt") > 0 then
        return false
    end

    if unit:Distance() > 11 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[577] = demonHunterWillKickMe
specKickLookup[581] = demonHunterWillKickMe

local function evokerWillKickMe(unit)
    if player.physImmune then
        return false
    end

    if unit:GetCD("Quell") > 0 then
        return false
    end

    if unit:Distance() > 26 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[1467] = evokerWillKickMe
specKickLookup[1468] = evokerWillKickMe
specKickLookup[1473] = evokerWillKickMe

local function mageWillKickMe(unit)
    if player.magicImmune then
        return false
    end

    if unit:GetCD("Counterspell") > 0 then
        return false
    end

    if unit:Distance() > 41 then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[62] = mageWillKickMe
specKickLookup[63] = mageWillKickMe
specKickLookup[64] = mageWillKickMe

local function warlockWillKickMe(unit)
    if not unit:Buff(196099) then
        return false
    end

    if player.magicImmune then
        return false
    end

    if unit:GetCD("Spell Lock") > 0 then
        return false
    end

    if unit:Distance() > 41 then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[265] = warlockWillKickMe
specKickLookup[266] = warlockWillKickMe
specKickLookup[267] = warlockWillKickMe

local function warlockPetWillKickMe(unit)
    if unit.id ~= 417 then
        return false
    end

    if player.magicImmune then
        return false
    end

    if unit:Distance() > 41 then
        return false
    end

    if unit:GetCD("Spell Lock") > 0 then
        return false
    end

    return shouldFakeCast(unit)
end

local function shamanWillKickMe(unit)
    if player.magicImmune then
        return false
    end

    if unit:GetCD("Wind Shear") > 0 then
        return false
    end

    if unit:Distance() > 31 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[262] = shamanWillKickMe
specKickLookup[263] = shamanWillKickMe
specKickLookup[264] = shamanWillKickMe

local function hunterWillKickMe(unit)
    -- local unitSpec = unit:Spec()
    local distance
    -- if unitSpec == 255 then
    --     if unit:GetCD("Muzzle") > 0 then
    --         return false
    --     end
    --     distance = 8
    -- else
        if unit:GetCD("Counter Shot") > 0 then
            return false
        end
        distance = 40
    -- end

    if player.physImmune then
        return false
    end

    if unit:Distance() > distance then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[253] = hunterWillKickMe
specKickLookup[254] = hunterWillKickMe
specKickLookup[255] = hunterWillKickMe

local function druidWillKickMe(unit)
    if not unit.isMelee then
        return false
    end

    if unit:GetCD("Skull Bash") > 0 then
        return false
    end

    if unit:Distance() > 13 then
        return false
    end

    if not unit:FacingUnit(player, 120) then
        return false
    end

    return shouldFakeCast(unit)
end

specKickLookup[102] = druidWillKickMe
specKickLookup[103] = druidWillKickMe
specKickLookup[104] = druidWillKickMe

local classKickLookup = {}

classKickLookup[1] = warriorWillKickMe
classKickLookup[2] = paladinWillKickMe
classKickLookup[3] = hunterWillKickMe
classKickLookup[4] = rogueWillKickMe

classKickLookup[6] = deathKnightWillKickMe
classKickLookup[7] = shamanWillKickMe
classKickLookup[8] = mageWillKickMe
classKickLookup[9] = warlockWillKickMe
classKickLookup[10] = monkWillKickMe
classKickLookup[11] = druidWillKickMe
classKickLookup[12] = demonHunterWillKickMe
classKickLookup[13] = evokerWillKickMe


local function willUnitKickMe(unit)
    --if not unit.los then return end
    if unit.channeling then return end

    local unitSpec = unit:Spec()
    if not unitSpec then return end

    local lookup = specKickLookup[unitSpec]
    if not lookup then return end

    if unit.cc then return end

    return lookup(unit)
end

local function willGglUnitKickMe(unit)
    --if not unit.los then return end
    if unit.channeling then return end

    local unitClassId = unit:ClassID()
    if not unitClassId then return end
    if not unit.los then return end

    local lookup = classKickLookup[unitClassId]
    if not lookup then return end

    if unit.cc then return end

    return lookup(unit)
end

local fakeJitter = 0
local channelFake = 400
local waitTime = 500

local function generateRandomFakes()
    fakeJitter = math.random(0, 10) - 5
    channelFake = math.random(400, 600) - 5
    waitTime = math.random(400, 1050)
end
generateRandomFakes()

local lastJuke = 0

local state = {
    fake_cap = 2,
    blacklist = {}
}

local function regen_state()
    state.fake_cap = math.random(2, 3)
end

local function player_casted(spellId)
    local lookup = SpellLookup[spellId]
    if not lookup then
        return
    end

    if lookup:CastTime() > 0 then
        regen_state()
    end
end

local function on_spell_cast_success(event, ...)
    if type(CombatLogGetCurrentEventInfo) ~= "function" then
        return
    end

    local _, subevent, _, sourceGUID, sourceName, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()

    if subevent == "SPELL_CAST_SUCCESS" and spellID then
        if sourceGUID == rawget(CU.player, "guid") or sourceName == "player" then
            player_casted(spellID)
        end
    end
end

local fake_casting_enabled = false

local function enable_fake_cast()
    if fake_casting_enabled then return end

    if Events.isEventSupported("COMBAT_LOG_EVENT_UNFILTERED") then
        Events.register("COMBAT_LOG_EVENT_UNFILTERED", on_spell_cast_success)
    end
    fake_casting_enabled = true
end

local function register_fake_blacklist(blacklist)
    state.blacklist = blacklist
end

local function jukeKick(stop_casting)
    local castInfo = player.castOrChannelInfo
    if not castInfo then return end

    if state.blacklist[castInfo.name]
        or state.blacklist[castInfo.spellId] then
        return
    end
    if state.fake_cap == 0 then return end

    if not castInfo.channel and castInfo.percent < math.max((40 + fakeJitter), 10) then return end
    if castInfo.channel and castInfo.elapsed < channelFake then return end
    generateRandomFakes()

    stop_casting = stop_casting or SpellStopCasting
    stop_casting()
    stop_casting()

    lastJuke = GetTime() * 1000
    state.fake_cap = state.fake_cap - 1
    return true
end

local function checkWait()
    local difference = (GetTime() * 1000) - lastJuke

    if difference > waitTime then
        generateRandomFakes()
        return true
    else
        SpellState.castingLockdown = true
        return false
    end
end

local function do_fake_casting()
    checkWait()

    local castInfo = player.castOrChannelInfo
    if not castInfo then return end

    if player:IsKickImmune() then return end

    MultiUnits.enemyPlayers:ForEach(function(enemy)
        if not enemy.exists then return end
        if enemy.dead then return end

        if willUnitKickMe(enemy) then
          --  print(enemy.name .. " could kick us juking")
            jukeKick()
        end
    end)
end

local function do_ggl_fake_casting(icon)
    checkWait()

    local castInfo = player.castOrChannelInfo
    if not castInfo then return end

    if player:IsKickImmune() then return end

    local stop_casting = function()
        --print('FAKE CASTING BITCHES')
        local CONST                               = Action.Const
        local ACTION_CONST_STOPCAST               = CONST.STOPCAST
        SpellState.casted = true
        return Action:Show(icon, ACTION_CONST_STOPCAST)
    end

    MultiUnits.arena:ForEach(function(enemy)
        if not enemy.exists then return end
        if enemy.dead then return end

        if willGglUnitKickMe(enemy) then
          --  print(enemy.name .. " could kick us juking")
            jukeKick(stop_casting)
        end
    end)

end

MakuluFramework.FakeCasting = {
    willKick = willUnitKickMe,
    juke = jukeKick,
    check = checkWait,
    enable = enable_fake_cast,
    blacklist = register_fake_blacklist,
    fakeCast = do_fake_casting,
    gglFakeCast = do_ggl_fake_casting,
}
