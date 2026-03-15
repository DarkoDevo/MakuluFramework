local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local MF                 = MakuluFramework

local Unit               = MakuluFramework.Unit

local ConstUnits         = {
    player = Unit:new('NIL_UNIT_player'),
    target = Unit:new('NIL_UNIT_target'),
    focus = Unit:new('NIL_UNIT_focus'),
    mouseover = Unit:new('NIL_UNIT_mouseover'),

    party1 = Unit:new('NIL_UNIT_party1'),
    party2 = Unit:new('NIL_UNIT_party2'),
    party3 = Unit:new('NIL_UNIT_party3'),
    party4 = Unit:new('NIL_UNIT_party4'),

    arena1 = Unit:new('NIL_UNIT_arena1'),
    arena2 = Unit:new('NIL_UNIT_arena2'),
    arena3 = Unit:new('NIL_UNIT_arena3'),

    healer = Unit:new('NIL_UNIT_OURS'),
    enemyHealer = Unit:new('NIL_UNIT_ENEMY'),

    tank = Unit:new('NIL_UNIT_TANK'),

    pet = Unit:new('NIL_UNIT_pet') -- added pet here sir jack
}

local normal_consts      = {
    player = "player",
    target = "target",
    focus = "focus",
    mouseover = "mouseover",

    party1 = "party1",
    party2 = "party2",
    party3 = "party3",
    party4 = "party4",

    arena1 = "arena1",
    arena2 = "arena2",
    arena3 = "arena3",

    pet = "pet" -- added pet here sir jackson
}

local function isHealer(unit)
    return unit.exists and unit.isHealer
end

local function update_healer_from_list(list, to_update)
    local healer = list:Find(isHealer)

    if not healer then
        healer = Unit:new("NIL_UNIT")
        -- else
        --     print('Found our healer: ' .. healer.name)
    end

    rawset(to_update, "cache", rawget(healer, "cache"))
    rawset(to_update, "guid", rawget(healer, "guid"))
    rawset(to_update, "id", rawget(healer, "id"))
end

local function isTank(unit)
    return unit.exists and unit.isTank
end

local function update_tank(to_update)
    local tank = MF.MultiUnits.party:Find(isTank)

    if not tank then
        tank = Unit:new("NIL_UNIT")
    end

    rawset(to_update, "cache", rawget(tank, "cache"))
    rawset(to_update, "guid", rawget(tank, "guid"))
    rawset(to_update, "id", rawget(tank, "id"))
end

local function update_special()
    update_healer_from_list(MF.MultiUnits.party, ConstUnits.healer)

    if MF.InPvpInstance() then
        update_healer_from_list(MF.MultiUnits.arena, ConstUnits.enemyHealer)
    else
        local to_update = ConstUnits.enemyHealer
        local healer = Unit:new("NIL_UNIT")

        rawset(to_update, "cache", rawget(healer, "cache"))
        rawset(to_update, "guid", rawget(healer, "guid"))
        rawset(to_update, "id", rawget(healer, "id"))
    end

    return update_tank(ConstUnits.tank)
end

local function reloadConstUnits()
    for target, unit in pairs(normal_consts) do
        local update = Unit:new(target)
        local to_update = ConstUnits[unit]

        rawset(to_update, "cache", rawget(update, "cache"))
        rawset(to_update, "guid", rawget(update, "guid"))
        rawset(to_update, "id", rawget(update, "id"))
    end

    return update_special()
end

MakuluFramework.ConstUnits = ConstUnits
MakuluFramework.CU = ConstUnits
MakuluFramework.ConstUnitsReload = reloadConstUnits
