local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local Events             = MakuluFramework.Events

local simpleCacheLookup  = function(callback, cache, min, max)
    return function(guid, obj, time)
        local found = cache[guid]

        if not found or found.timeout < time then
            local result = callback(obj)
            local random = math.random(min, max) / 100
            cache[guid] = {
                timeout = time + random,
                stored = result
            }

            return result
        end

        return found.stored
    end
end

local UnitIsPlayer       = UnitIsPlayer
local PlayersLookup      = {}
local IsPlayerCache      = simpleCacheLookup(UnitIsPlayer, PlayersLookup, 450, 650)

local CanAttackLookup    = {}
local UnitCanAttack      = UnitCanAttack
local CanAttackCallback  = function(obj) return UnitCanAttack("player", obj) end
local CanAtackCache      = simpleCacheLookup(CanAttackCallback, CanAttackLookup, 500, 2000)

Events.registerReset(function()
    PlayersLookup = {}
    CanAttackLookup = {}
end)

MakuluFramework.QuickCache = {
    IsPlayer = IsPlayerCache,
    CanAttack = CanAtackCache
}
