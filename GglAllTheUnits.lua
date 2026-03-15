local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local Cache              = MakuluFramework.Cache
local Unit               = MakuluFramework.Unit
local Plates             = MakuluFramework.Plates
local UnitGUID           = MakuluFramework.GetGuid
local PartyRoster        = MakuluFramework.MultiUnits._getPartyRoster

local PerLoopCache       = Cache:getConstCacheCell()

local pairs = pairs
local ipairs = ipairs

local hardCodedTypes = {
    "boss1",
    "boss2",
    "boss3",
    "boss4",
    "boss5",

    "target",
    "focus",
    "mouseover",
}

local function addKnownHardCodedNames(lut)
    for _, name in ipairs(hardCodedTypes) do
        local guid = UnitGUID(name)
        if guid and not lut[guid] then
            lut[guid] = Unit:newGUID(guid, name)
        end
    end

    for _, party in ipairs(PartyRoster()) do
        local guid = UnitGUID(party)
        if guid and not lut[guid] then
            lut[guid] = Unit:newGUID(guid, party)
        end
    end
end

local insert = table.insert

-- Returns index of GUID to mak units
local function getAllTheUnits()
    return PerLoopCache:GetOrSet("allTheUnits", function ()
        local allMakUnits = Plates.units()
        addKnownHardCodedNames(allMakUnits)

        return allMakUnits
    end)
end

local rawget = rawget

local function getEnemyUnits()
    return PerLoopCache:GetOrSet("enemyUnits", function ()
        local allUnits = getAllTheUnits()
        local enemyUnits = {}

        for _, unit in pairs(allUnits) do
            if not Unit.IsFriendly(unit) then
                insert(enemyUnits, unit)
            end
        end

        return enemyUnits
    end)
end

local function getAllEnemyPlayers()
    return PerLoopCache:GetOrSet("enemyPlayers", function ()
        local allEnemies = getEnemyUnits()
        local enemyPlayers = {}

        for _, unit in ipairs(allEnemies) do
            if not Unit.IsPlayer(unit) then
                insert(enemyPlayers, unit)
            end
        end

        return enemyPlayers
    end)
end

local function getAllTotems()
    return PerLoopCache:GetOrSet("allTotems", function ()
        local allUnits = getAllTheUnits()
        local totems = {}

        for _, unit in pairs(allUnits) do
            if not Unit.IsTotem(unit) then
                insert(totems, unit)
            end
        end

        return totems
    end)
end

local AllTheUnits = {
    enemyUnits = getEnemyUnits,
    enemyPlayers = getAllEnemyPlayers,
    totems = getAllTotems,
    getAllTheUnits = getAllTheUnits,
}

MakuluFramework.AllTheUnits = AllTheUnits