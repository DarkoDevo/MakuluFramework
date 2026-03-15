local Tinkr, MakuluFramework = ...

MakuluFramework = MakuluFramework or _G.MakuluFramework or {}
local InCombatLockdown = InCombatLockdown

local GetTime = GetTime

local Cache = MakuluFramework.Cache
local ConstUnits = MakuluFramework.ConstUnits
local ConstUnitsReload = MakuluFramework.ConstUnitsReload
local spellState = MakuluFramework.spellState or {}

local kickLockdown = false

local player = ConstUnits.player

local function registerIcon(icon)
    spellState.icon = icon
    spellState.casted = kickLockdown
end

-- Returns true is we should halt exection
local function mainStart(icon)
    kickLockdown = false
    spellState.castingLockdown = false
    spellState.gcdHold = false

    registerIcon(icon)
    -- Cache:printStats()
    Cache:resetCache(InCombatLockdown())
    -- local start = time()
    ConstUnitsReload()

    -- local took = time() - start
    -- print('Execution took: ' .. took)

    local kicked = player:Interrupted()
    if kicked and (GetTime() - kicked) < 0.3 then
        spellState.casted = true
        kickLockdown = true
        return true
    end
end

local function funcEnd()
    return spellState.casted
end

local function tableToLocal(table, localTable)
    for key, value in pairs(table) do
        localTable[key] = value
    end
end

MakuluFramework.start = mainStart
MakuluFramework.endFunc = funcEnd

MakuluFramework.registerIcon = registerIcon
MakuluFramework.tableToLocal = tableToLocal
