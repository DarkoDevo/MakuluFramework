local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local AtoL             = MakuluFramework.AtoL
local MultiUnits       = MakuluFramework.MultiUnits
local Cache            = MakuluFramework.Cache

local arenaCache = Cache:getConstCacheCell()

local arenaState = {
    cache = arenaCache
}

local highBurstSpecs = AtoL({
    105, -- Windwalker Monk
    1473, -- aug
    1467, -- devo
    62,   -- Arcane
    261, --sub
    263, -- enha
    256, -- Elemental Shaman
    577, --havoc
    254,  -- mm
    251, --fdk
    267,  -- destro
})

local physicalDamageSpecs = AtoL({
    255, -- Survival Hunter
    253,  -- bm
    254,  -- mm
    269, -- Windwalker Monk
    259, -- Assassination Rogue
    260, -- Outlaw Rogue
    261, -- Subtlety Rogue
    71,  -- Arms Warrior
    72,  -- Fury Warrior
    73,  -- Protection Warrior
    103, -- Feral Druid
    104, -- Guardian Druid
})

local onUseCds = {
    [208086] = 10,
    [262161] = 10,
    [167105] = 15,
    [265187] = 15
}

local castedCdsTracker = {}

MakuluFramework.Events.registerReset(function ()
    castedCdsTracker = {}
end)

local function on_unit_spellcast_success(event, ...)
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool =
        CombatLogGetCurrentEventInfo()

    if subevent ~= "SPELL_CAST_SUCCESS" then return end
    local cd = onUseCds[spellID]
    if not cd then return end

    local found = castedCdsTracker[sourceGUID]
    if not found then
        castedCdsTracker[sourceGUID] = GetTime() + cd
        return
    end

    castedCdsTracker[sourceGUID] = math.max(found, GetTime() + cd)
end
MakuluFramework.Events.register("COMBAT_LOG_EVENT_UNFILTERED", on_unit_spellcast_success)

local function hasOnUseCdActive(guid)
    local found = castedCdsTracker[guid]
    if not found then return 0 end

    return math.max(found - GetTime(), 0)
end

MakuluFramework.__cdEventActive = hasOnUseCdActive

function arenaState:getAllEnemies()
    return MultiUnits.arena:Filter(function(unit)
        return unit.exists and not unit.dead
    end)
end

function arenaState:averageEHP()
    return self:getAllEnemies():Average(function(unit)
        return unit.ehp
    end)
end

local ignoreLocked = {
    [253] = true,
    [266] = true
}

function arenaState:getBurstState()
    local as = {
        burstUpAny = false,
        burstUp = false,

        burstRemains = 0,
        burstRemainsAny = 0
    }

    self:getAllEnemies():ForEach(function(unit)
        if unit.isHealer or not unit.cds then return end

        as.burstUpAny = true

        local cdRemains = unit:CdsRemain()
        as.burstRemainsAny = math.max(as.burstRemainsAny, cdRemains)

        if ignoreLocked[unit.specId] or (not unit.cc and not unit:DamageLocked()) then
            as.burstUp = true
            as.burstRemains = math.max(as.burstRemains, cdRemains)
        end
    end)

    return as
end

function arenaState:enemyCdsAny()
    return self:getBurstState().burstUpAny
end

function arenaState:enemyCds()
    return self:getBurstState().burstUp
end

function arenaState:enemyCdRemains()
    return self:getBurstState().burstRemains
end

function arenaState:enemyCdRemainsAny()
    return self:getBurstState().burstRemainsAny
end

local specId
function arenaState:burstyBoiCount()
    return self:getAllEnemies():Count(function(unit)
        specId = unit.specId
        if specId == 0 then return false end
        return highBurstSpecs[specId]
    end)
end

function arenaState:highBurstTeam()
    return self:burstyBoiCount() >= 1
end

function arenaState:teamComposition()
    local teamComposition = {
        melee = 0,
        ranged = 0,
        caster = 0
    }

    self:getAllEnemies():ForEach(function(unit)
        if unit.isHealer then return end

        if unit.isMelee then
            teamComposition.melee = teamComposition.melee + 1
        elseif unit.isRanged then
            teamComposition.ranged = teamComposition.ranged + 1
        end

        if unit.isCaster then
            teamComposition.caster = teamComposition.caster + 1
        end
    end)

    return teamComposition
end

function arenaState:damageType()
    local teamComposition = {
        physical = 0,
        magic = 0,
    }

    self:getAllEnemies():ForEach(function(unit)
        if unit.isHealer then return end

        specId = unit.specId

        if specId == 0 then return end
        if physicalDamageSpecs[specId] then
            teamComposition.physical = teamComposition.physical + 1
        else
            teamComposition.magic = teamComposition.magic + 1
        end
    end)

    return teamComposition
end

function arenaState:lowestUnit()
    local party = MultiUnits.party
    if not party then return nil end

    return party:Lowest(
        function(friendly) return friendly.ehp or 100 end,
        function(friendly) return friendly.exists and not friendly.dead end
    )
end

function arenaState:lowestEhp()
    local lowest = self:lowestUnit()
    if not lowest then return 100 end
    return lowest.ehp or 100
end

local autoLookup = {}

local function generateAutoCachedObject(object)
    for key, value in pairs(object) do
        if type(value) == "function" then
            local remapped = "_" .. key
            object[remapped] = function(self)
                return self.cache:GetOrSet(key, function()
                    return value(self)
                end)
            end

            autoLookup[key] = object[remapped]
        end
    end
end

local found
local function stateIndex(_, key)
    found = autoLookup[key]
    if found then
        return found(arenaState)
    end
    return nil
end

local areanStateMetaTable = {
    __index = stateIndex
}

generateAutoCachedObject(arenaState)

local ArenaState = {}
setmetatable(ArenaState, areanStateMetaTable)

MakuluFramework.ArenaState = ArenaState