local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local Unit               = MakuluFramework.Unit
local Cache              = MakuluFramework.Cache
local UnitGUID           = MakuluFramework.GetGuid

local PlateCache         = Cache:getConstCacheCell()

local UnitGUID           = UnitGUID

local cachedSeen = {}

local pairs = pairs
local sub = string.sub

local function loadAllNameplate()
    return PlateCache:GetOrSet("plates", function()
        local plates = {}
        local newCached = {}
        for name = 1,200 do
            local nameplate = "NamePlate" .. name
            local guid = UnitGUID(nameplate)

            if guid then
                plates[guid] = nameplate
                plates[nameplate] = guid

                cachedSeen[guid] = nil
                cachedSeen[nameplate] = nil

                newCached[guid] = nameplate
                newCached[nameplate] = guid
            else
                name = 1000
            end
        end

        for key, _ in pairs(cachedSeen) do
            if sub(key, 1, 9) == "NamePlate" then
                local guid = UnitGUID(key)
                if guid then
                    plates[guid] = key
                    plates[key] = guid

                    newCached[guid] = key
                    newCached[key] = guid
                end
            end
        end

        cachedSeen = newCached
        return plates
    end)
end

local function getAllMakUnits()
    return PlateCache:GetOrSet("makUnitPlates", function()
        local plates = loadAllNameplate()
        local makUnits = {}

        for key, val in pairs(plates) do
            if sub(key, 1, 9) ~= "NamePlate" then
                makUnits[key] = Unit:newGUID(key, val)
            end
        end

        return makUnits
    end)
end

local function getPlateAlpha(plate)
    local gPlate = _G[plate]
    if not gPlate then return 1 end
    return gPlate:GetEffectiveAlpha()
end

local Plate = {
    load = loadAllNameplate,
    units = getAllMakUnits,
    alpha = getPlateAlpha
}

MakuluFramework.Plates = Plate
