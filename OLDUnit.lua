local _, MakuluFramework  = ...
MakuluFramework           = MakuluFramework or _G.MakuluFramework

local MF                  = MakuluFramework
local cacheContext        = MakuluFramework.Cache
local bc                  = MakuluFramework.callBlizz
local GetTimeToDie        = MakuluFramework.GetTimeToDie
local GetDmgPerSec        = MakuluFramework.GetDmgPerSec
local SpecInfo

local unitCachePool       = cacheContext:getConstCacheCell()
local unitGuidLookup      = cacheContext:getConstCacheCell()
local unitCombatCachePool = cacheContext:getCombatCacheCell()

local UnitExists          = UnitExists
local UnitIsPlayer        = UnitIsPlayer
local UnitGUID            = UnitGUID

local UnitAura            = UnitAura
local auraInfo
local GetAuraDataByIndex  = C_UnitAuras.GetAuraDataByIndex

local UnitHealthMax       = UnitHealthMax
local UnitHealth          = UnitHealth
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs

local Action              = Action or {}

local ActionUnit          = Action.Unit

local UnitCanAttack       = UnitCanAttack
local UnitTokenFromGUID   = UnitTokenFromGUID
local UnitIsFriend        = UnitIsFriend
local UnitIsUnit          = UnitIsUnit
local UnitCastingInfo     = UnitCastingInfo
local UnitChannelInfo     = UnitChannelInfo
local UnitPower           = UnitPower
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsDeadOrGhost   = UnitIsDeadOrGhost
local UnitClassification  = UnitClassification
local UnitName            = UnitName

local IsPlayerSpell       = IsPlayerSpell

local TMW                 = _G.TMW

local GetTime             = GetTime
local rawget              = rawget
local pairs               = pairs
local ipairs              = ipairs
local math                = math

local MakLists            = MakuluFramework.lists

local Unit                = {}
Unit.__index              = Unit

local idStr               = "id"
local actionStr           = "Action"
local guidStr             = "guid"

local kickPercent         = 35
local meldDuration        = 65
local shortHalfSecond     = 500
local minReactionTime     = 200
local channelKickTime     = 500

local unitActions         = {}
local me_self             = nil

local function generateNewRandomKicks()
    kickPercent = math.random(35, 65)
    meldDuration = math.random(200, 400)
    shortHalfSecond = math.random(400, 600)
    minReactionTime = math.random(150, 300)
    channelKickTime = math.random(400, 900)

    return C_Timer.After(math.random(15, 30), generateNewRandomKicks)
end

local time = function()
    if TMW and TMW.time then return TMW.time end

    return GetTime()
end

generateNewRandomKicks()

local function tableCrossOver(a, b)
    local swapped = false
    local scanning = a
    local lookup = b

    if #b < #a then
        scanning = b
        lookup = a
        swapped = true
    end

    for k, v in pairs(scanning) do
        local found = lookup[k]
        if found then
            if swapped then
                return found
            else
                return v
            end
        end
    end

    return false
end

local function getAurasUptime(aura)
    if not aura or aura.duration == 0 or aura.expiration == 0 then return 0 end
    return (GetTime() * 1000) - (aura.expiration - aura.duration)
end

MF.tableCrossOver = tableCrossOver
MF.auraUptime = getAurasUptime

-- This will create an interator of items found in second param
local function TableMatchingIter(a, b, callback, terminating)
    local swapped = false

    local scanning = a
    local lookup = b

    if #b < #a then
        scanning = b
        lookup = a
        swapped = true
    end

    for k, v in pairs(scanning) do
        local found = lookup[k]
        if found then
            if swapped then
                if callback(found) and terminating then return found end
            else
                if callback(v) and terminating then return v end
            end
        end
    end
end

local function findLongestDuration(auras, lookup)
    local longestDuration = 0
    local longestAura = nil

    TableMatchingIter(auras, lookup, function(aura)
        if aura.expiration > longestDuration then
            longestAura = aura
            longestDuration = aura.expiration
        end
    end)

    return (longestDuration - (GetTime() * 1000)), longestAura
end

local function getUnitGUIDLookup()
    return unitGuidLookup:GetOrSet(1, function()
        return {}
    end)
end

local function storeUnitGuid(guid, id)
    local lookup = getUnitGUIDLookup()
    lookup[guid] = id
end

local function getIdFromGuid(guid)
    local lookup = getUnitGUIDLookup()
    return lookup[guid]
end

function Unit:ActionUnit()
    return ActionUnit(rawget(self, idStr))
end

function Unit:Guid()
    return rawget(self, guidStr)
end

function Unit:CallerId()
    return rawget(self, idStr)
end

function Unit:Name()
    return self.cache:GetOrSet("Name", function()
        return UnitName(Unit.CallerId(self)) or ""
    end)
end

function Unit:NpcId()
    return self.cache:GetOrSet("NpcId", function()
        local guid = Unit.Guid(self)
        if guid then
            local unit_type = strsplit("-", guid)
            if unit_type == "Creature" or unit_type == "Vehicle" then
                local _, _, _, _, _, npc_id = strsplit("-", guid)
                return tonumber(npc_id)
            elseif unit_type == "Player" then
                return 0 -- let's just make it return non-nil I guess
            end
        end
    end)
end

function Unit:UnitToken()
    return self.cache:GetOrSet("UnitToken", function()
        return UnitTokenFromGUID(rawget(self, guidStr))
    end)
end

function Unit:ClassID()
    return self.cache:GetOrSet("Class", function()
        local _, _, classID = UnitClass(Unit.CallerId(self))
        return classID or 0
    end)
end

-- JACK HALP
function Unit:SpecID()
    return self.cache:GetOrSet("Spec", function()
        SpecInfo = SpecInfo or MakuluFramework.Specs

        if Unit.IsMe(self) then
            if WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC then
                local specIndex = GetSpecialization()
                if specIndex then
                    local specId = GetSpecializationInfo(specIndex)
                    return specId or 0
                end
            else -- TODO: MoP Unit Spec Detection
                return 0
            end
        end

        if not SpecInfo then return 0 end

        return SpecInfo.TryGetSpec(self) or 0
    end)
end

function Unit:HealthMax()
    return self.cache:GetOrSet("HealthMax", function()
        return UnitHealthMax(Unit.CallerId(self)) or 1
    end)
end

function Unit:HealthActual()
    return self.cache:GetOrSet("HealthActual", function()
        return UnitHealth(Unit.CallerId(self)) or 0
    end)
end

function Unit:Health()
    return self.cache:GetOrSet("Health", function()
        return (Unit.HealthActual(self) / Unit.HealthMax(self)) * 100
    end)
end

function Unit:TotalHealAbsorbs()
    return self.cache:GetOrSet("TotalHealAbsorbs", function()
        return UnitGetTotalHealAbsorbs(Unit.CallerId(self)) or 0
    end)
end

function Unit:HealAbsorbPercentage()
    return self.cache:GetOrSet("HealAbsorbPercentage", function()
        local maxHealth = Unit.HealthMax(self)
        return maxHealth > 0 and (Unit.TotalHealAbsorbs(self) / maxHealth) * 100 or 0
    end)
end

function Unit:TotalAbsorbs()
    return self.cache:GetOrSet("TotalAbsorbs", function()
        return UnitGetTotalAbsorbs(Unit.CallerId(self)) or 0
    end)
end

function Unit:AbsorbPercentage()
    return self.cache:GetOrSet("AbsorbPercentage", function()
        local maxHealth = Unit.HealthMax(self)
        return maxHealth > 0 and (Unit.TotalAbsorbs(self) / maxHealth) * 100 or 0
    end)
end

function Unit:EffectiveHealthPercentage()
    return self.cache:GetOrSet("EffectiveHealthPercentage", function()
        return math.max((Unit.Health(self) + Unit.AbsorbPercentage(self)) - Unit.HealAbsorbPercentage(self), 1) -- return 1% hp to prevent us thinking the unit is dead
    end)
end

function Unit:Shield()
    return self.cache:GetOrSet("Shield", function()
        return UnitGetTotalAbsorbs(Unit.CallerId(self))
    end)
end

local specId

function Unit:IsHealer()
    return self.cache:GetOrSet("Healer", function()
        specId = Unit.SpecID(self)
        if specId > 0 and SpecInfo then
            return SpecInfo.isHealer(specId)
        end
        
        return Unit.ActionUnit(self):IsHealer()
    end)
end

function Unit:IsTank()
    return self.cache:GetOrSet("Tank", function()
        specId = Unit.SpecID(self)
        if specId > 0 and SpecInfo then
            return SpecInfo.isMelee(specId)
        end

        return Unit.ActionUnit(self):IsTank()
    end)
end

function Unit:PvEGroupRole()
    return self.cache:GetOrSet("PvEGroupRole" .. Unit.CallerId(self), function()
        return UnitGroupRolesAssigned(Unit.CallerId(self))
    end)
end

function Unit:IsMelee()
    return self.cache:GetOrSet("Melee", function()
        specId = Unit.SpecID(self)
        if specId > 0 and SpecInfo then
            return SpecInfo.isMelee(specId)
        end

        return Unit.ActionUnit(self):IsMelee()
    end)
end

function Unit:IsCaster()
    return self.cache:GetOrSet("Caster", function()
        specId = Unit.SpecID(self)
        if specId > 0 and SpecInfo then
            return SpecInfo.isCaster(specId)
        end

        return not Unit.ActionUnit(self):IsMelee()
    end)
end

function Unit:IsRanged()
    return self.cache:GetOrSet("Ranged", function()
        specId = Unit.SpecID(self)
        if specId > 0 and SpecInfo then
            return SpecInfo.isRanged(specId)
        end

        return not Unit.ActionUnit(self):IsMelee()
    end)
end

function Unit:SetPieces()
    return unitCombatCachePool:GetOrSet(rawget(self, guidStr) .. "SetPieces", function()
        local equippedCount = 0
        for i = 1, 19 do
            local itemID = GetInventoryItemID("player", i)
            if itemID then
                local itemSetID = select(16, GetItemInfo(itemID))
                if itemSetID and MakLists.ALL_SET_IDS[itemSetID] then
                    equippedCount = equippedCount + 1
                end
            end
        end
        return equippedCount
    end)
end

function Unit:Has2Set()
    return unitCombatCachePool:GetOrSet(rawget(self, guidStr) .. "Has2Set", function()
        if self:SetPieces() >= 2 then
            return true
        end
        return false
    end)
end

function Unit:Has4Set()
    return unitCombatCachePool:GetOrSet(rawget(self, guidStr) .. "Has4Set", function()
        if self:SetPieces() >= 4 then
            return true
        end
        return false
    end)
end


local dummyVariants = {
    "dummy",
    "Dummy",
    "Kelpfist",
    "Crystalmaw",
    "манекен",
    -- "trip"
}

function Unit:IsDummy()
    return self.cache:GetOrSet("Dummy", function()
        local name = Unit.Name(self)
        for _, variant in ipairs(dummyVariants) do
            if string.find(name, variant) then return true end
        end
    end)
end

function Unit:CombatTime()
    return self.cache:GetOrSet("CombatTime", function()
        return Unit.ActionUnit(self):CombatTime()
    end)
end


function Unit:GetClassification()
    return self.cache:GetOrSet("Classification", function()
        return UnitClassification(Unit.CallerId(self))
    end)
end

local bossClassification = {
    ["worldboss"] = true,
}

function Unit:IsBoss()
    return bossClassification[Unit.GetClassification(self)] or UnitIsUnit(Unit.CallerId(self), "boss1") or UnitIsUnit(Unit.CallerId(self), "boss2") or UnitIsUnit(Unit.CallerId(self), "boss3")
end

function Unit:InCombat()
    return self.cache:GetOrSet("InCombat", function()
        return UnitAffectingCombat(Unit.CallerId(self))
    end)
end

function Unit:CanAttack()
    return self.cache:GetOrSet("CanAttack", function()
        return not Unit.IsDeadOrGhost(self) and UnitCanAttack("player", Unit.CallerId(self))
    end)
end

function Unit:IsDeadOrGhost()
    return self.cache:GetOrSet("Dead", function()
        return UnitIsDeadOrGhost(Unit.CallerId(self))
    end)
end

function Unit:GetPower(powerId)
    return self.cache:GetOrSet("Power" .. powerId, function()
        return UnitPower(Unit.CallerId(self), powerId)
    end)
end

function Unit:GetPowerMax(powerId)
    return self.cache:GetOrSet("PowerMax" .. powerId, function()
        return UnitPowerMax(Unit.CallerId(self), powerId)
    end)
end

function Unit:TTD()
    return self.cache:GetOrSet("TTD", function()
        return GetTimeToDie(self)
    end)
end

function Unit:DPS()
    return self.cache:GetOrSet("DPS", function()
        return GetDmgPerSec(self)
    end)
end

local powerTypers = {
    ["mana"] = 0,
    ["rage"] = 1,
    ["focus"] = 2,
    ["energy"] = 3,
    ["comboPoints"] = 4,
    ["cp"] = 4,
    ["rune"] = 5,
    ["runicPower"] = 6,
    ["soulShards"] = 7,
    ["lunarPower"] = 8,
    ["holyPower"] = 9,
    ["alternatePower"] = 10,
    ["maelstrom"] = 11,
    ["chi"] = 12,
    ["insanity"] = 13,
    ["arcaneCharges"] = 16,
    ["fury"] = 17,
    ["pain"] = 18,
    ["essence"] = 19,
}

local function makePowersFunc(name, powerId)
    local capitalised = (name:gsub("^%l", string.upper))
    local unitAttr = "Get" .. capitalised

    Unit[unitAttr] = function(self)
        return Unit.GetPower(self, powerId)
    end
    unitActions[name] = Unit[unitAttr]

    local maxUnitAttr = unitAttr .. "Max"
    Unit[maxUnitAttr] = function(self)
        return Unit.GetPowerMax(self, powerId)
    end
    unitActions[name .. "Max"] = Unit[maxUnitAttr]

    local pctUnitAttr = unitAttr .. "Pct"
    Unit[pctUnitAttr] = function(self)
        return (Unit.GetPower(self, powerId) / Unit.GetPowerMax(self, powerId)) * 100
    end
    unitActions[name .. "Pct"] = Unit[pctUnitAttr]
    unitActions[name .. "pct"] = Unit[pctUnitAttr]

    local deficitUnitAttr = unitAttr .. "Deficit"
    Unit[deficitUnitAttr] = function(self)
        return Unit.GetPowerMax(self, powerId) - Unit.GetPower(self, powerId)
    end
    unitActions[name .. "Deficit"] = Unit[deficitUnitAttr]
end

local function build_powers_attr()
    for name, powerId in pairs(powerTypers) do
        makePowersFunc(name, powerId)
    end
end

local buffsKey           = "Buffs"
local buffOurs           = "BuffOurs"
local helpfulStr         = "HELPFUL"
local _, spellName, count, spellId, duration, expiration, mine, source
local _onlyOurs          = false

local auraInfo
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex

local function make_aura_fetcher(filter)
    return function()
        local target = Unit.CallerId(me_self)
        local buffPool = {}

        for i = 1, 1000 do
            auraInfo = GetAuraDataByIndex(target, i, filter)
            if not auraInfo then
                return buffPool
            elseif not _onlyOurs or (auraInfo.sourceUnit and auraInfo.sourceUnit == "player") then
                auraInfo.count = auraInfo.applications
                auraInfo.duration = auraInfo.duration * 1000
                auraInfo.expiration = auraInfo.expirationTime * 1000
                auraInfo.mine = auraInfo.sourceUnit and auraInfo.sourceUnit == "player"
                auraInfo.points = auraInfo.points
                auraInfo.idx = i
                auraInfo.filter = filter

                buffPool[auraInfo.name] = auraInfo
                buffPool[auraInfo.spellId] = auraInfo
            end
        end

        return buffPool
    end
end

local get_buffs = make_aura_fetcher(helpfulStr)

function Unit:GetBuffs(onlyOurs)
    me_self = self
    _onlyOurs = onlyOurs
    return self.cache:GetOrSet((onlyOurs and buffOurs) or buffsKey, get_buffs)
end

local debuffsKey = "DeBuffs"
local debuffsOurs = "DebuffsOurs"
local harmfulStr = "HARMFUL"

local get_debuffs = make_aura_fetcher(harmfulStr)

function Unit:GetDeBuffs(onlyOurs)
    me_self = self
    _onlyOurs = onlyOurs
    return self.cache:GetOrSet((onlyOurs and debuffsOurs) or debuffsKey, get_debuffs)
end

function Unit:HasBuff(spell, onlyOurs)
    return Unit.GetBuffs(self, onlyOurs)[spell] ~= nil
end

function Unit:Buff(spell, onlyOurs)
    return Unit.GetBuffs(self, onlyOurs)[spell]
end

function Unit:BuffFrom(toCheck, onlyOurs)
    return tableCrossOver(Unit.GetBuffs(self, onlyOurs), toCheck)
end

function Unit:BuffFromCB(toCheck, callback, onlyOurs)
    return TableMatchingIter(Unit.GetBuffs(self, onlyOurs), toCheck, callback, true)
end

function Unit:HasBuffCount(spell, onlyOurs)
    local foundBuff = Unit.GetBuffs(self, onlyOurs)[spell]
    return (foundBuff ~= nil and foundBuff.count) or 0
end

function Unit:HasBuffPoints(spell, onlyOurs)
    local foundBuff = Unit.GetBuffs(self, onlyOurs)[spell]
    return (foundBuff ~= nil and foundBuff.points) or 0
end

function Unit:HasBuffRemain(spell, remaining, onlyOurs)
    local foundBuff = Unit.GetBuffs(self, onlyOurs)[spell]
    if foundBuff == nil then
        return false
    end

    return foundBuff.expiration - (time() * 1000) > remaining
end

function Unit:BuffRemains(spell, onlyOurs)
    local foundBuff = Unit.GetBuffs(self, onlyOurs)[spell]
    if foundBuff == nil then
        return 0
    end

    return foundBuff.expiration - (time() * 1000)
end

function Unit:BuffDuration(spell, onlyOurs)
    local foundBuff = Unit.GetBuffs(self, onlyOurs)[spell]
    return (foundBuff ~= nil and foundBuff.duration) or 0
end

function Unit:HasBuffFor(spell, onlyOurs)
    local foundBuff = Unit.GetBuffs(self, onlyOurs)[spell]
    if foundBuff == nil then
        return 0
    end

    local currentTimeMS = time() * 1000

    local timeApplied = currentTimeMS - (foundBuff.expiration - foundBuff.duration)

    return timeApplied
end

function Unit:HasBuffFromFor(listOfBuffs, minTime)
    local currentTimeMS = time() * 1000

    return TableMatchingIter(Unit.GetBuffs(self), listOfBuffs, function(aura)
        local timeApplied = currentTimeMS - (aura.expiration - aura.duration)
        return timeApplied >= minTime
    end, true)
end

function Unit:HasDeBuff(spell, onlyOurs)
    return Unit.GetDeBuffs(self, onlyOurs)[spell] ~= nil
end

function Unit:Debuff(spell, onlyOurs)
    return Unit.GetDeBuffs(self, onlyOurs)[spell]
end

function Unit:DebuffFrom(toCheck, onlyOurs)
    return tableCrossOver(Unit.GetDeBuffs(self, onlyOurs), toCheck)
end

function Unit:DebuffFromCB(toCheck, callback, onlyOurs)
    return TableMatchingIter(Unit.GetDeBuffs(self, onlyOurs), toCheck, callback, true)
end

function Unit:HasDeBuffCount(spell, onlyOurs)
    local foundDebuff = Unit.GetDeBuffs(self, onlyOurs)[spell]
    return (foundDebuff ~= nil and foundDebuff.count) or 0
end

function Unit:DebuffDuration(spell, onlyOurs)
    local foundDebuff = Unit.GetDeBuffs(self, onlyOurs)[spell]
    return (foundDebuff ~= nil and foundDebuff.duration) or 0
end

function Unit:DebuffPandemic(spell)
    local foundDebuff = Unit.GetDeBuffs(self, true)[spell]
    return not foundDebuff or foundDebuff.expiration - (time() * 1000) <= foundDebuff.duration * 0.3
end

function Unit:HasDeBuffRemain(spell, remaining, onlyOurs)
    local foundDebuff = Unit.GetDeBuffs(self, onlyOurs)[spell]
    if foundDebuff == nil then
        return false
    end

    return foundDebuff.expiration - (time() * 1000) > remaining
end

function Unit:DebuffRemains(spell, onlyOurs)
    local foundDebuff = Unit.GetDeBuffs(self, onlyOurs)[spell]
    if foundDebuff == nil then
        return 0
    end

    return foundDebuff.expiration - (time() * 1000)
end

function Unit:HasDeBuffFor(spell)
    local foundDeBuff = Unit.GetDeBuffs(self)[spell]
    if foundDeBuff == nil then
        return 0
    end

    return (time() * 1000)- (foundDeBuff.expiration - foundDeBuff.duration)
end

function Unit:HasDeBuffFromFor(listOfDeBuffs, minTime, canDispel)
    local currentTimeMS = time() * 1000

    return TableMatchingIter(Unit.GetDeBuffs(self), listOfDeBuffs, function(aura)
        if canDispel and not aura.dispelName then return false end
        local timeApplied = currentTimeMS - (aura.expiration - aura.duration)
        return timeApplied >= minTime
    end, true)
end

function Unit:Poisoned()
    return self.cache:GetOrSet("Poisoned", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.pvePoison)
    end)
end

function Unit:Cursed()
    return self.cache:GetOrSet("Cursed", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.pveCurse)
    end)
end

function Unit:Bleeding()
    return self.cache:GetOrSet("Bleeding", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.pveBleed)
    end)
end

function Unit:Diseased()
    return self.cache:GetOrSet("Diseased", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.pveDisease)
    end)
end

function Unit:Magicked()
    return self.cache:GetOrSet("Magicked", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.pveMagic)
    end)
end

function Unit:Enraged()
    return self.cache:GetOrSet("Enraged", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.pveEnrage)
    end)
end

function Unit:Feigned()
    return self.cache:GetOrSet("Feigned", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.feigned)
    end)
end

function Unit:Bloodlust()
    return self.cache:GetOrSet("Bloodlust", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.Bloodlust)
    end)
end

function Unit:Sated()
    return self.cache:GetOrSet("Sated", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.Sated)
    end)
end

function Unit:SatedRemains()
    return self.cache:GetOrSet("SatedRemains", function()
        local sated = Unit.DebuffFrom(self, MakLists.Sated)
        if not sated then
            return 0
        end

        return sated.expiration - (time() * 1000)
    end)
end

function Unit:Cds()
    return self.cache:GetOrSet("CdsUp", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.DPSCooldownList) or MakuluFramework.__cdEventActive(rawget(self, "guid")) > 0
    end)
end

function Unit:CdsRemain()
    return self.cache:GetOrSet("CdsRemain", function()
        return math.max(findLongestDuration(Unit.GetBuffs(self), MakLists.DPSCooldownList), MakuluFramework.__cdEventActive(rawget(self, "guid")) * 1000)
    end)
end

function Unit:magicCds()
    return self.cache:GetOrSet("MagicCdsUp", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.MagicCds)
    end)
end

function Unit:InCC()
    return self.cache:GetOrSet("InCC", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.CC) or Unit.HealLocked(self)
    end)
end

function Unit:InStun()
    return self.cache:GetOrSet("InStun", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.Stun)
    end)
end

function Unit:InBreakableCC()
    return self.cache:GetOrSet("BCC", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.BreakableCC)
    end)
end

function Unit:Disarmed()
    return self.cache:GetOrSet("Disarmed", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.Disarmed)
    end)
end

function Unit:DisarmRemains()
    return self.cache:GetOrSet("DisarmRemains", function()
        return findLongestDuration(Unit.GetDeBuffs(self), MakLists.Disarmed)
    end)
end

-- This is expensive use sparingly
function Unit:CCRemains()
    return self.cache:GetOrSet("CCRemains", function()
        -- If we've already done the work ahead of time lets use that
        local inCCPreCached = self.cache:Get("InCC")
        if inCCPreCached ~= nil and inCCPreCached == false then
            return Unit.HealLockedRemains(self)
        end

        return math.max(findLongestDuration(Unit.GetDeBuffs(self), MakLists.CC), Unit.HealLockedRemains(self))
    end)
end

function Unit:IsTotalImmune()
    return self.cache:GetOrSet("TotalImmune", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.TotalImmune) or
            tableCrossOver(Unit.GetDeBuffs(self), MakLists.TotalImmuneDebuff)
    end)
end

function Unit:IsPassive()
    return self.cache:GetOrSet("IsPassive", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.Passive)
    end)
end

function Unit:PassiveRemains()
    return self.cache:GetOrSet("PassiveRemains", function()
        return findLongestDuration(Unit.GetBuffs(self), MakLists.Passive)
    end)
end

function Unit:IsHealImmune()
    return self.cache:GetOrSet("HealImmune", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.HealImmuneBuff) or
            tableCrossOver(Unit.GetDeBuffs(self), MakLists.HealImmuneDebuff)
    end)
end

function Unit:IsPhysImmune()
    return self.cache:GetOrSet("PhysImmune", function()
        if Unit.IsTotalImmune(self) then return true end

        return tableCrossOver(Unit.GetBuffs(self), MakLists.PhysicalImmune)
    end)
end

function Unit:IsMagicImmune()
    return self.cache:GetOrSet("MagicImmune", function()
        if Unit.IsTotalImmune(self) then return true end

        return tableCrossOver(Unit.GetBuffs(self), MakLists.MagicImmune)
    end)
end

function Unit:IsKickImmune()
    return self.cache:GetOrSet("KickImmune", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.KickImmune)
    end)
end

function Unit:IsCCImmune()
    return self.cache:GetOrSet("CCImmune", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.CCImmune)
    end)
end

function Unit:IsRooted()
    return self.cache:GetOrSet("Rooted", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.Rooted) or tableCrossOver(Unit.GetDeBuffs(self), MakLists.pveFreedom) 
    end)
end

function Unit:IsSlowed()
    return self.cache:GetOrSet("Slowed", function()
        return tableCrossOver(Unit.GetDeBuffs(self), MakLists.Slowed)
    end)
end

function Unit:IsSlowImmune()
    return self.cache:GetOrSet("SlowImmune", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.SlowImmune)
    end)
end

function Unit:HasDefensives()
    return self.cache:GetOrSet("HasDefensives", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.Defensive)
    end)
end

function Unit:CanCastWhileMoving()
    return self.cache:GetOrSet("CastWhileMoving", function()
        return tableCrossOver(Unit.GetBuffs(self), MakLists.ignoreMoving)
    end)
end

function Unit:GetCD(spell)
    return MF.CD.Get(rawget(self, "guid"), spell)
end

local libRange = nil
function Unit:Distance()
    if libRange == nil then
        libRange = LibStub("LibRangeCheck-3.0") or false
    end

    if libRange == false then return 0 end

    local minRange, maxRange = libRange:GetRange(Unit.CallerId(self))

    if not minRange and not maxRange then return 0 end

    return minRange or maxRange
end

function Unit:MeleeRangeOf(target)
    return false
end

function Unit:MeleeRange()
    return self.cache:GetOrSet("MeleeRange", function()
        return Unit.MeleeRangeOf(MakuluFramework.CU.player, self)
    end)
end

function Unit:Facing()
    return true
end

function Unit:FacingUnit(_a, _b)
    return true
end

function Unit:Los()
    if not MakuluFramework.Plates then return true end
    return self.cache:GetOrSet("LOS", function()
        if Unit.IsTarget(self) then return true end
        if Unit.IsFriendly(self) then return true end

        local plates = MakuluFramework.Plates.load()
        local found = plates[rawget(self, "guid")]

        if not found then return true end
        return MakuluFramwork.Plates.alpha(found) > 0.4
    end)
end

-- ONLY WORKS FOR PLAYER ON PIXEL
function Unit:IsMounted()
    return IsMounted()
end

function Unit:IsStealthed()
    return IsStealthed()
end

function Unit:Exists()
    return self.cache:GetOrSet("Exists", function()
        return UnitExists(Unit.CallerId(self))
    end)
end

function Unit:IsPlayer()
    return self.cache:GetOrSet("IsPlayer", function()
        return UnitIsPlayer(Unit.CallerId(self))
    end)
end

function Unit:IsPet()
    return self.cache:GetOrSet("IsPet", function()
        if Unit.IsPlayer(self) then return end

        return UnitPlayerControlled(Unit.CallerId(self))
    end)
end

function Unit:IsTarget()
    return UnitIsUnit(Unit.CallerId(self), "target")
end

function Unit:IsMe()
    return UnitIsUnit(Unit.CallerId(self), "player")
end

function Unit:IsFriendly()
    return self.cache:GetOrSet("IsFriend", function()
        return UnitIsFriend(Unit.CallerId(self), "player")
    end)
end

local UnitCreatureType = UnitCreatureType
local totemType = "Totem"

function Unit:IsTotem()
    return UnitCreatureType(Unit.CallerId(self)) == totemType
end

function Unit:Target()
    return self.cache:GetOrSet("Target", function()
        local target = Unit:new(Unit.CallerId(self) .. "target")
        if not target or not target.exists then return nil end
        return target
    end)
end

function Unit:IsUnit(other)
    return UnitIsUnit(Unit.CallerId(self), Unit.CallerId(other))
end

function Unit:Speed()
    return GetUnitSpeed(Unit.CallerId(self)) or 0
end

function Unit:IsMoving()
    return Unit.Speed(self) > 0
end

local talentKey = "talent"

function Unit:TalentKnown(id)
    return unitCombatCachePool:GetOrSet(talentKey .. id, function()
        return IsPlayerSpell(id)
    end)
end

function Unit:TalentRank(id)
    return unitCombatCachePool:GetOrSet(talentKey .. id .. "rank", function()
        local configID = C_ClassTalents.GetActiveConfigID()
        if configID == nil then return end

        local configInfo = C_Traits.GetConfigInfo(configID)
        if configInfo == nil then return end

        for _, treeID in ipairs(configInfo.treeIDs) do
            local nodes = C_Traits.GetTreeNodes(treeID)
            for i, nodeID in ipairs(nodes) do
                local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
                if nodeInfo and nodeInfo.entryIDsWithCommittedRanks then
                    for _, entryID in ipairs(nodeInfo.entryIDsWithCommittedRanks) do
                        local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                        if entryInfo and entryInfo.definitionID then
                            local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                            if definitionInfo.spellID == id then
                                return nodeInfo.ranksPurchased
                            end
                        end
                    end
                end
            end
        end
        return 0
    end)
end

function Unit:TrinketReady(id)
    if id == 1 then id = 13 end
    if id == 2 then id = 14 end

    return self.cache:GetOrSet("TrinketReady" .. id, function()
        local start, duration, enabled = GetInventoryItemCooldown("player", id)
        if enabled == 1 and (start == 0 or (start + duration - GetTime() <= 0)) then
            return true
        else
            return false
        end
    end)
end

function Unit:TrinketCD(id)
    if id == 1 then id = 13 end
    if id == 2 then id = 14 end

    return self.cache:GetOrSet("TrinketCD" .. id, function()
        local start, duration, enabled = GetInventoryItemCooldown("player", id)
        if enabled == 1 and start > 0 then
            local remaining = start + duration - GetTime()
            return remaining > 0 and remaining or 0
        else
            return 0
        end
    end)
end

function Unit:TalentKnownInt(id)
    return unitCombatCachePool:GetOrSet(talentKey .. "int" .. id, function()
        return IsPlayerSpell(id) and 1 or 0
    end)
end

function Unit:BlizzChannelInfo()
    return UnitChannelInfo(Unit.CallerId(self))
end

function Unit:ChannelInfo()
    return self.cache:GetOrSet("ChannelInfo", function()
        local name, text, _, startTimeMS, endTimeMS, _, notInterruptible, spellId, isEmpowered, numEmpowerStages = Unit.BlizzChannelInfo(self)
        if not name then return nil end

        local now = time() * 1000
        local castLength = endTimeMS - startTimeMS
        local elapsed = now - startTimeMS
        local percent = (elapsed / castLength) * 100

        return {
            name = name,
            text = text,
            startTime = startTimeMS,
            endTime = endTimeMS,
            notInterrupt = notInterruptible,
            castLength = endTimeMS - startTimeMS,
            remaining = endTimeMS - now,
            elapsed = elapsed,
            percent = percent,
            spellId = spellId,
            channel = true,
            isEmpowered = isEmpowered,
            empowerStages = numEmpowerStages
        }
    end)
end

function Unit:IsChanneling()
    return Unit.ChannelInfo(self) ~= nil
end

function Unit:BlizzCastInfo()
    return UnitCastingInfo(rawget(self, idStr))
end

function Unit:CastInfo()
    return self.cache:GetOrSet("CastInfo", function()
        local name, text, _, startTimeMS, endTimeMS, _, _, notInterruptible, spellId = Unit.BlizzCastInfo(self)
        if not name then return nil end

        local now = time() * 1000
        local castLength = endTimeMS - startTimeMS
        local elapsed = now - startTimeMS
        local percent = (elapsed / castLength) * 100

        return {
            name = name,
            text = text,
            startTime = startTimeMS,
            endTime = endTimeMS,
            notInterrupt = notInterruptible,
            castLength = endTimeMS - startTimeMS,
            remaining = endTimeMS - now,
            elapsed = elapsed,
            percent = percent,
            spellId = spellId,
            channel = false
        }
    end)
end

function Unit:IsCasting()
    return Unit.CastInfo(self) ~= nil
end

function Unit:IsCastOrChanneling()
    return Unit.CastInfo(self) ~= nil or Unit.ChannelInfo(self) ~= nil
end

function Unit:CastOrChanelInfo()
    return Unit.CastInfo(self) or Unit.ChannelInfo(self)
end

--[[function Unit:CastingFromFor(list, minTime)
    local castInfo = Unit.CastOrChanelInfo(self)
    if not castInfo then return false end

    local spellId = castInfo.spellId
    if not spellId then return false end

    if not list[spellId] then return false end

    if castInfo.elapsed >= minTime then
        return true
    else
        return false
    end
end]]

function Unit:CastingFromFor(list, minTime)
    local castInfo = Unit.CastOrChanelInfo(self)
    if not castInfo then return false end

    local spellId = castInfo.spellId or castInfo.spellID
    if not spellId then return false end

    if not list[spellId] then return false end

    local currentTimeMS = GetTime() * 1000

    local elapsedTimeMS

    if castInfo.startTime and castInfo.endTime then
        elapsedTimeMS = currentTimeMS - castInfo.startTime
    elseif castInfo.duration and castInfo.timeLeft then
        elapsedTimeMS = castInfo.duration - castInfo.timeLeft
    else
        return false
    end

    if elapsedTimeMS >= minTime then
        return true
    else
        return false
    end
end

function Unit:IsSafeToKick()
    local info = Unit.CastOrChanelInfo(self)
    if not info then return false end

    if info.notInterrupt then return false end
    if info.elapsed < minReactionTime then return false end
    if Unit.IsKickImmune(self) then return false end

    return true
end

function Unit:IsSafeToKickCC()
    local info = Unit.CastOrChanelInfo(self)
    if not info then return false end

    if info.elapsed < minReactionTime then return false end

    return true
end

function Unit:UseBigButtons()
    if self.player then return true end

    return not MakuluFramework.InPvpInstance()
end

function Unit:MovementTime()
    return Unit.ActionUnit(self):IsMovingTime()
end

function Unit:StayingTime()
    return Unit.ActionUnit(self):IsStayingTime()
end

local GetActiveLossOfControlData = C_LossOfControl.GetActiveLossOfControlData

function Unit:LoCInfo()
    return self.cache:GetOrSet("LocInfo", function()
        local info = nil

        for i = 1, 20 do
            local data = GetActiveLossOfControlData(i)
            if not data then return info end

            info = info or {}

            table.insert(info, data)
        end

        return info
    end)
end

-- @description 1 = Star, 2 = Circle, 3 = Diamond, 4 = Triangle, 5 = Moon, 6 = Square, 7 = Cross, 8 = Skull
function Unit:RaidMarker()
    return self.cache:GetOrSet("RaidMarker", function()
        return GetRaidTargetIndex(Unit.CallerId(self)) or 0
    end)
end

function Unit:Interrupted()
    local info = Unit.LoCInfo(self)
    if not info then return false end

    local mostRecent = nil
    for _, item in ipairs(info) do
        if item.locType == "SCHOOL_INTERRUPT" then
            if not mostRecent or mostRecent < item.startTime then
                mostRecent = item.startTime
            end
        end
    end

    return mostRecent
end

local healerSpellSchools = {
    [105] = 8, -- "Nature", -- RDRU
    [1468] = 8, --"Nature", -- Pres
    [264] = 8, -- "Nature", -- Pres
    [270] = 8, -- "Nature", -- MW
    [65] = 2, -- "Holy", -- Hpal
    [256] = 2, -- "Holy", -- Disc
    [257] = 2, -- "Holy", -- HPri,
}

function Unit:HealLockedRemains()
    local info = Unit.SpecID(self)
    if info == 0 then return 0 end

    local school = healerSpellSchools[info]
    if not school then return 0 end
    return MakuluFramework.Lockouts.LockRemains(rawget(self, "guid"), school)
end

function Unit:HealLocked()
    return Unit.HealLockedRemains(self) > 0
end

local casterSpellSchools = {
    [102] = 8, -- "Nature", -- Boomy

    [1467] = {16, 64}, -- Devoker Spellfrost (Frost & Arcane)
    [1473] = {4, 8}, -- Aug Volcanic (Fire & Nature)

    [62] = 64, -- Arcane, Arcane Mage!
    [63] = 4, -- Fire is fire
    [64] = 16, -- Frost is frost

    [262] = 4, -- Ele Fire

    [258] = 32, -- Spri Shadow

    [265] = 32, -- Affli Shadow
    --[266] = 32, -- Demo Shadow
    [267] = {4, 8, 16, 32, 64}, -- Destro Everything
}

local vulnerableToDisarm = {
    [250] = true, -- Blood Dk
    [251] = true, -- Frost DK
    [252] = true, -- UH DK

    [577] = true, -- Havoc
    [581] = true, -- Veng

    [254] = true, -- Marks
    [255] = true, -- Survival

    [70] = true, -- Ret

    [259] = true, -- Assa
    [260] = true, -- Outlaw
    [261] = true, -- Sub

    [263] = true, -- Enha
    
    [71] = true, -- Arms
    [72] = true, -- Fury
    [73] = true, -- Prot
}

function Unit:DamageLockRemains()
    local info = Unit.SpecID(self)
    if info == 0 then return 0 end

    local passiveRemains = self:PassiveRemains()

    if vulnerableToDisarm[info] then
        return math.max(Unit.DisarmRemains(self), passiveRemains)
    end

    local school = casterSpellSchools[info]
    if not school then return passiveRemains end

    if type(school) == "number" then
        return math.max(MakuluFramework.Lockouts.LockRemains(rawget(self, "guid"), school), passiveRemains)
    end

    local maxRemains = 0
    for _, s in ipairs(school) do
        local remains = MakuluFramework.Lockouts.LockRemains(rawget(self, "guid"), s)
        if remains > maxRemains then
            maxRemains = remains
        end

        if maxRemains <= 0 then
            return passiveRemains
        end
    end

    return math.max(maxRemains, passiveRemains)
end

function Unit:DamageLocked()
    return Unit.DamageLockRemains(self) > 0
end

function Unit:PvpKick(kickList)
    kickList = kickList or MakLists.arenaKicks

    local castInfo = Unit.CastOrChanelInfo(self)
    if not castInfo then return end
    if not kickList[castInfo.spellId] then return end
    if not Unit.IsSafeToKick(self) then return end

    if castInfo.channel and castInfo.elapsed > channelKickTime then return true end
    if not castInfo.channel and castInfo.percent > kickPercent then return true end

    return false
end

function Unit:PvpGround(kickList)
    kickList = kickList or MakLists.arenaKicks

    local castInfo = Unit.CastOrChanelInfo(self)
    if not castInfo then return end
    if not kickList[castInfo.spellId] then return end
    if not Unit.IsSafeToKick(self) then return end

    if castInfo.channel and castInfo.elapsed > channelKickTime then return true end
    if not castInfo.channel and castInfo.elapsed > 400 then return true end

    return false
end

local function makeDrFunc(type, internal)
    local attr = type .. 'Dr'

    Unit[attr] = function(self)
        return MakuluFramework.DR.Get(internal, rawget(self, "guid"))
    end
    unitActions[attr] = Unit[attr]

    attr = type .. 'DrRemains'
    Unit[attr] = function(self)
        return MakuluFramework.DR.Remains(internal, rawget(self, "guid"))
    end
    unitActions[attr] = Unit[attr]
end

local function addDrAttrs()
    local allNames = MakuluFramework.DR.Names

    for name, internal in pairs(allNames) do
        makeDrFunc(name, internal)
    end
end

local function makeLockoutFunc(id, school)
    local attr = school .. 'Locked'

    Unit[attr] = function(self)
        return MakuluFramework.Lockouts.Locked(rawget(self, "guid"), id)
    end
    unitActions[MakuluFramework.lowerFirstLetter(attr)] = Unit[attr]

    attr = school .. 'LockRemains'
    Unit[attr] = function(self)
        return MakuluFramework.Lockouts.LockRemains(rawget(self, "guid"), id)
    end
    unitActions[MakuluFramework.lowerFirstLetter(attr)] = Unit[attr]
end

local function addLockoutAttr()
    if not MakuluFramework.Lockouts then return end
    local allNames = MakuluFramework.Lockouts.Schools

    for id, school in pairs(allNames) do
        makeLockoutFunc(id, school)
    end
end

local function buildDynamicAttrs()
    addDrAttrs()
    build_powers_attr()
    addLockoutAttr()
end

local function computeUnitAction()
    unitActions = {
        guid = Unit.Guid,
        name = Unit.Name,
        npcId = Unit.NpcId,
        specId = Unit.SpecID,
        spec = Unit.SpecID,

        buffs = Unit.GetBuffs,
        debuffs = Unit.GetDeBuffs,
        action = Unit.ActionUnit,
        player = Unit.IsPlayer,
        isTarget = Unit.IsTarget,
        isMe = Unit.IsMe,
        isFriendly = Unit.IsFriendly,
        bigButtons = Unit.UseBigButtons,
        moving = Unit.IsMoving,
        exists = Unit.Exists,
        inCombat = Unit.InCombat,
        combat = Unit.InCombat,
        ttd = Unit.TTD,
        dps = Unit.DPS,

        isBoss = Unit.IsBoss,
        isDummy = Unit.IsDummy,
        isPet = Unit.IsPet,
        classification = Unit.GetClassification,

        combatTime = Unit.CombatTime,
        moveTime = Unit.MovementTime,
        stayTime = Unit.StayingTime,
        speed = Unit.Speed,

        canAttack = Unit.CanAttack,
        maxHealth = Unit.HealthMax,
        healthActual = Unit.HealthActual,
        health = Unit.Health,
        hp = Unit.Health,
        ehp = Unit.EffectiveHealthPercentage,
        shield = Unit.Shield,
        dead = Unit.IsDeadOrGhost,

        target = Unit.Target,
        distance = Unit.Distance,
        facing = Unit.Facing,
        los = Unit.Los,
        inMelee = Unit.MeleeRange,

        cc = Unit.InCC,
        ccRemains = Unit.CCRemains,
        bcc = Unit.InBreakableCC,
        stun = Unit.InStun,

        bloodlust = Unit.Bloodlust,
        sated = Unit.Sated,
        cds = Unit.Cds,
        magicCds = Unit.magicCds,

        isHealer = Unit.IsHealer,
        isTank = Unit.IsTank,
        isMelee = Unit.IsMelee,
        isRanged = Unit.IsRanged,
        isCaster = Unit.IsCaster,

        castInfo = Unit.CastInfo,
        channelInfo = Unit.ChannelInfo,
        castOrChannelInfo = Unit.CastOrChanelInfo,

        casting = Unit.IsCasting,
        channeling = Unit.IsChanneling,
        castOrChannel = Unit.IsCastOrChanneling,
        safeToKick = Unit.IsSafeToKick,
        safeToKickCC = Unit.IsSafeToKickCC,
        pvpKick = Unit.PvpKick,
        pvpGround = Unit.PvpGround,
        healLocked = Unit.HealLocked,

        totalImmune = Unit.IsTotalImmune,
        healImmune = Unit.IsHealImmune,
        physImmune = Unit.IsPhysImmune,
        physicalImmune = Unit.IsPhysImmune,
        magicImmune = Unit.IsMagicImmune,
        slowImmune = Unit.IsSlowImmune,
        ccImmune = Unit.IsCCImmune,

        rooted = Unit.IsRooted,
        slowed = Unit.IsSlowed,
        mounted = Unit.IsMounted,
        stealthed = Unit.IsStealthed,

        poisoned = Unit.Poisoned,
        bleeding = Unit.Bleeding,
        cursed = Unit.Cursed,
        diseased = Unit.Diseased,
        magicked = Unit.Magicked,
        enraged = Unit.Enraged,
        pvePurge = Unit.PvEPurge,

        feigned = Unit.Feigned,

        defensive = Unit.ShouldDefensive,

        hasDefensive = Unit.HasDefensives,
        raidMarker = Unit.RaidMarker,
    }

    buildDynamicAttrs()
end

computeUnitAction()

local function unitIndex(unit, key)
    local property = rawget(unit, key)
    if property ~= nil then
        return property
    end

    local unitAction = unitActions[key]
    if unitAction then
        return unitAction(unit)
    end

    unitAction = Unit[key]
    if unitAction then
        return unitAction
    end

    print('Could not find key: ' .. key)
    return nil
end

local unitGuidCacher = cacheContext:getConstCacheCell()

local function GetGuid(target)
    return unitGuidCacher:GetOrSet(target, function()
        return UnitGUID(target) or target
    end)
end

local unitMetaTable = {
    __index = unitIndex
}

function Unit:new(target)
    local targetGUID = GetGuid(target)
    return unitCachePool:GetOrSet(targetGUID, function()
        storeUnitGuid(targetGUID, target)
        local unit = {
            cache = cacheContext:getCell(),
            callCount = 0,
            guid = targetGUID,
            id = target
        }
        setmetatable(unit, unitMetaTable) -- make Account handle lookup

        return unit
    end)
end

function Unit:newGUID(targetGUID, id)
    return unitCachePool:GetOrSet(targetGUID, function()
        local unit = {
            cache = cacheContext:getCell(),
            callCount = 0,
            guid = targetGUID,
            id = id
        }
        setmetatable(unit, unitMetaTable) -- make Account handle lookup
        return unit
    end)
end

MakuluFramework.Unit = Unit
MakuluFramework.Unit.reindex = computeUnitAction
MakuluFramework.GetGuid = GetGuid
MakuluFramework.__INTERNAL__unitIndex = unitIndex