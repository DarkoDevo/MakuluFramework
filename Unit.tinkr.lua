local Tinkr, MakuluFramework    = ...

local MF                        = MakuluFramework

local Evaluator                 = Tinkr:require('Util.Modules.Evaluator')

local Unit                      = MakuluFramework.Unit
local cacheContext              = MakuluFramework.Cache
local Lists                     = MakuluFramework.lists

local unitCombatCachePool       = cacheContext:getCombatCacheCell()

local uX, uY, uZ

local Object                    = Object
local ObjectTarget              = ObjectTarget
local ObjectGUID                = ObjectGUID
local ObjectPosition            = ObjectPosition
local ObjectId                  = ObjectId
local ObjectHeight              = ObjectHeight
local ObjectSpecializationID    = ObjectSpecializationID
local ObjectRotation            = ObjectRotation
local ObjectCombatReach         = ObjectCombatReach
local ObjectCastingTarget       = ObjectCastingTarget

local UnitIsMounted             = UnitIsMounted

local TraceLine                 = TraceLine
local FastDistance              = FastDistance
local FastDistance2D            = FastDistance2D
local GetUnitAttachmentPosition = GetUnitAttachmentPosition

function Unit:Position()
    return self.cache:GetOrSet("Position", function()
        uX, uY, uZ = ObjectPosition(rawget(self, 'guid'))
        return { x = uX, y = uY, z = uZ }
    end)
end

function Unit:PositionNoCache()
    uX, uY, uZ = ObjectPosition(rawget(self, 'guid'))
    return { x = uX, y = uY, z = uZ }
end

function Unit:Target()
    return self.cache:GetOrSet("Target", function()
        local target = ObjectTarget(Unit.CallerId(self))
        if not target then return nil end

        local guid = ObjectGUID(target)
        return Unit:new(guid)
    end)
end

function Unit:CastTarget()
    return self.cache:GetOrSet("CastTarget", function()
        local target = ObjectCastingTarget(Unit.CallerId(self))
        if not target then return nil end

        local guid = ObjectGUID(target)
        return Unit:new(guid)
    end)
end

function Unit:Spec()
    local guid = rawget(self, 'guid')
    return unitCombatCachePool:GetOrSet("spec" .. guid, function()
        return ObjectSpecializationID(Unit.CallerId(self))
    end)
end

local unitTypes = {
    ["Healer"] = Lists.HealerIds,
    ["Melee"] = Lists.MeleeIds,
    ["Caster"] = Lists.CasterIds,
    ["Ranged"] = Lists.RangedIds,
}

for name, lookup in pairs(unitTypes) do
    local key = 'Is' .. name

    Unit[key] = function(self)
        return unitCombatCachePool:GetOrSet(rawget(self, 'guid') .. key, function()
            local spec = Unit.Spec(self)
            if not spec then return false end

            return lookup[spec]
        end)
    end
end

function Unit:IsTank()
    return false
end

function Unit:Rotation()
    return self.cache:GetOrSet("Rotation", function()
        return ObjectRotation(Unit.CallerId(self))
    end)
end

function Unit:CombatReach()
    return self.cache:GetOrSet("CombatReach", function()
        return ObjectCombatReach(Unit.CallerId(self))
    end)
end

function Unit:FacingUnit(unit, degrees)
    local rot = Unit.Rotation(self)
    local playerPos = Unit.Position(self)
    local unitPos = Unit.Position(unit)

    if not playerPos.x or not unitPos.x or not rot then
        return false
    end

    local angle = math.atan2(unitPos.y - playerPos.y, unitPos.x - playerPos.x) - rot
    angle = math.deg(angle)
    angle = angle % 360
    if angle > 180 then
        angle = angle - 360
    end

    return math.abs(angle) < degrees
end

function Unit:FacingDegrees(degrees)
    return Unit.FacingUnit(MF.CU.player, self, degrees)
end

function Unit:Facing()
    return self.cache:GetOrSet("Facing", function()
        return Unit.FacingDegrees(self, 90)
    end)
end

function Unit:Id()
    return self.cache:GetOrSet("Id", function()
        local guid = rawget(self, 'guid')
        local id = ObjectId(guid)
        return id or ""
    end)
end

function Unit:Distance()
    return self.cache:GetOrSet("Distance", function()
        local playerPos = Unit.Position(MF.CU.player)
        local unitPos = Unit.Position(self)
        if not playerPos.x or not unitPos.x then
            return 99999
        end

        return FastDistance2D(playerPos.x, playerPos.y, unitPos.x, unitPos.y)
    end)
end

function Unit:DistanceTo(unit)
    local my_pos = Unit.Position(self)
    local their_pos = Unit.Position(unit)
    if not my_pos.x or not their_pos.x then
        return 99999
    end

    return FastDistance2D(my_pos.x, my_pos.y, their_pos.x, their_pos.y)
end

function Unit:DistanceToPos(x, y, z)
    local my_pos = Unit.Position(self)
    if not my_pos.x then
        return 99999
    end

    return FastDistance2D(my_pos.x, my_pos.y, x, y)
end

function Unit:DistanceToPosition(x, y, z)
    local my_pos = Unit.Position(self)
    if not my_pos.x or not x then
        return 99999
    end

    return FastDistance(my_pos.x, my_pos.y, my_pos.z, x, y, z)
end

local losFlag = bit.bor(0x1, 0x10, 0x100000)

function Unit:LosOf(unit2)
    local guid_1 = rawget(self, 'guid')
    local guid_2 = rawget(unit2, 'guid')

    return self.cache:GetOrSet("los" .. guid_1 .. guid_2, function()
        local unitPos = Unit.Position(Unit:new(guid_1))
        local ah = ObjectHeight(guid_1)
        local attx, atty, attz = GetUnitAttachmentPosition(guid_2, 34)

        if not attx or not unitPos.x then
            return false
        end

        if not ah then
            return false
        end

        if (unitPos.x == 0 and unitPos.y == 0 and unitPos.z == 0) or (attx == 0 and atty == 0 and attz == 0) then
            return true
        end

        if not attx or not unitPos.x then
            return false
        end

        local x, y, z = TraceLine(unitPos.x, unitPos.y, unitPos.z + ah, attx, atty, attz, losFlag)
        if x ~= 0 or y ~= 0 or z ~= 0 then
            return false
        else
            return true
        end
    end)
end

function Unit:LoSCoords(x, y, z)
    local guid = rawget(self, 'guid')

    local unitPos = Unit.Position(self)
    local ah = ObjectHeight(guid)

    if not unitPos.x or not ah then
        return false
    end

    if (unitPos.x == 0 and unitPos.y == 0 and unitPos.z == 0) or (x == 0 and y == 0 and z == 0) then
        return true
    end

    local tx, ty, tz = TraceLine(unitPos.x, unitPos.y, unitPos.z + ah, x, y, z, losFlag)
    if tx ~= 0 or ty ~= 0 or tz ~= 0 then
        return false
    else
        return true
    end
end

local idStr = "id"

function Unit:Los()
    return Unit.LosOf(MF.CU.player, self)
end

local me_self = nil

local function get_obj()
    local obj = Object(rawget(me_self, idStr))
    return (obj and obj:unit()) or "none"
end

function Unit:CallerId()
    me_self = self
    return self.cache:GetOrSet("TinkrObj", get_obj)
end

function Unit:GetAura(target, index, type)
    if target == nil then
        print('Nil target')
        return
    end
    return UnitAura(target, index, type)
end

local UnitCreatureType = UnitCreatureType
local totemType = "Totem"

function Unit:IsTotem()
    return UnitCreatureType(Unit.CallerId(self)) == totemType
end

function Unit:MeleeRangeOf(target)
    local targetGUID = rawget(target, 'guid')

    return self.cache:GetOrSet("InMeleeRange" .. targetGUID, function()
        local myPos = Unit.Position(self)
        local theirPos = Unit.Position(target)

        if not myPos.x or not theirPos.x then
            return false
        end

        local scr = Unit.CombatReach(self)
        local ucr = Unit.CombatReach(target)

        if not scr or not ucr then
            return false
        end

        local dist = math.sqrt((myPos.x - theirPos.x) ^ 2 + (myPos.y - theirPos.y) ^ 2 + (myPos.z - theirPos.z) ^ 2)
        local maxDist = math.max((scr + 1.3333) + ucr, 5.0)
        maxDist = maxDist + 1.0 -- + self:GetMeleeBoost()

        return dist <= maxDist
    end)
end

function Unit:IsMounted()
    return self.cache:GetOrSet("Mounted", function()
        return UnitIsMounted(Unit.CallerId(self))
    end)
end

Unit.reindex()
