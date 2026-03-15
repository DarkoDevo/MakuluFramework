local _, MakuluFramework       = ...
MakuluFramework                = MakuluFramework or _G.MakuluFramework

local Unit                     = MakuluFramework.Unit
local MultiUnits               = MakuluFramework.MultiUnits
local Cache                    = MakuluFramework.Cache
local QuickCache               = MakuluFramework.QuickCache
local KDTree                   = MakuluFramework.KDTree
local Events                   = MakuluFramework.Events

local Group                    = MultiUnits.group

local Object                   = Object
local Objects                  = Objects
local ObjectType               = ObjectType
local ObjectGUID               = ObjectGUID

local GetTime                  = GetTime
local GetNumArenaOpponentSpecs = GetNumArenaOpponentSpecs

local pairs, ipairs            = pairs, ipairs
local insert                   = table.insert

local TinkrCache               = Cache:getConstCacheCell()
local LoopCached               = Cache:getConstCacheCell()

local function _getObjects()
    local guids = {}
    for i, object in ipairs(Objects()) do
        local objectType = ObjectType(object)
        if objectType == 6 or objectType == 5 or objectType == 7 or objectType == 11 then
            local guid = ObjectGUID(object)
            guids[guid] = object
        end
    end

    return guids
end

local function getObjects()
    return TinkrCache:GetOrSetTimeout("allObject", _getObjects, 1000)
end

local allEnemies, allEnemyPlayers

local function _getUnit()
    local objects = getObjects()
    local units = {}

    for guid, i in pairs(objects) do
        local new_unit = Unit:newGUID(guid)
        if new_unit.exists then
            insert(units, new_unit)
        end
    end

    return units
end

local function getUnits()
    return LoopCached:GetOrSet("units", _getUnit)
end

local IsPlayer = QuickCache.IsPlayer
local CanIAttack = QuickCache.CanAttack

local function _loadEnemyUnits()
    local objects = getObjects()
    allEnemies = {}
    allEnemyPlayers = {}

    local time = GetTime()

    for guid, i in pairs(objects) do
        local obj = Object(guid)
        if CanIAttack(guid, obj, time) then
            local new_unit = Unit:newGUID(guid)
            insert(allEnemies, new_unit)

            if IsPlayer(guid, obj, time) then
                insert(allEnemyPlayers, new_unit)
            end
        end
    end
end

local function loadEnemyUnits()
    return LoopCached:GetOrSet("enemyUnits", _loadEnemyUnits)
end

local time = _G.debugprofilestop

local function buildKDTreeUnits()
    return LoopCached:GetOrSet("kd_tree", function()
        local all_units = getUnits()

        local points = {}
        local counter = 1

        for _, unit in pairs(all_units) do
            local position = Unit.Position(unit)
            if position.x then
                insert(points, { position.x, position.y })
                counter = counter + 1
            end
        end

        return KDTree.build(points)
    end)
end

local function getAround(target, distance)
    local kd_tree = buildKDTreeUnits()
    local position = Unit.Position(target)

    return KDTree.search(kd_tree, { position.x, position.y }, distance)
end

local UnitCreatureType = UnitCreatureType
local totemType = "Totem"

local function _getTotems()
    local objects = getObjects()
    local totems = {}
    for guid, i in pairs(objects) do
        if UnitCreatureType(i:unit()) == totemType then
            insert(totems, Unit:new(guid))
        end
    end

    return totems
end

local function getTotems()
    return LoopCached:GetOrSet("totems", _getTotems)
end

local function _getAreaTriggers()
    local objects = getObjects()
    local areaTriggers = {}
    for guid, i in pairs(objects) do
        local objectType = ObjectType(i)
        if objectType == 11 then
            insert(areaTriggers, Unit:new(guid))
        end
    end

    return areaTriggers
end

local function getAreaTriggers()
    return LoopCached:GetOrSet("areaTriggers", _getAreaTriggers)
end

local function getAllEnemies()
    loadEnemyUnits()
    return allEnemies
end

local function getEnemyPlayers()
    loadEnemyUnits()
    return allEnemyPlayers
end

local function _getArenaEnemies()
    local numOpponents = GetNumArenaOpponentSpecs()
    if not numOpponents then return {} end

    local arenas = {}
    for i = 1, numOpponents do
        local new_unit = Unit:new("arena" .. i)
        if new_unit.exists then
            insert(arenas, new_unit)
        end
    end

    return arenas
end

local function getArenaEnemies()
    return LoopCached:GetOrSet("arenas", _getArenaEnemies)
end

local function getEnemies()
    local inPvp, inArena = MakuluFramework.InPvpInstance()
    if not inPvp then
        return getAllEnemies()
    end

    if inArena then
        return getArenaEnemies()
    end

    return getEnemyPlayers()
end

function MultiUnits.GetAllEnemies()
    return Group:FromMultiUnits(getAllEnemies())
end

function MultiUnits.GetEnemyPlayers()
    return Group:FromMultiUnits(getEnemyPlayers())
end

function MultiUnits.GetEnemies()
    return Group:FromMultiUnits(getEnemies())
end

function MultiUnits.GetTotems()
    return Group:FromMultiUnits(getTotems())
end

function MultiUnits.GetAreatriggers()
    return Group:FromMultiUnits(getAreaTriggers())
end

MakuluFramework.KDTree = buildKDTreeUnits
MakuluFramework.around = getAround

MultiUnits.reIndex()
