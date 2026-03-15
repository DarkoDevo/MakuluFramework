local _, MakuluFramework      = ...
MakuluFramework               = MakuluFramework or _G.MakuluFramework
local Action           = _G.Action

local ConstUnit        = MakuluFramework.ConstUnits
local cacheContext     = MakuluFramework.Cache
local ConstCell        = cacheContext:getConstCacheCell()
local MultiUnit         = MakuluFramework.MultiUnits

local player = ConstUnit.player
local target = ConstUnit.target

local utilsCache              = nil

MakuluFramework.printOptional = function(result)
    if result == nil then
        return 'nil'
    end

    return result
end

MakuluFramework.printBool     = function(result)
    return (result and "true") or "false"
end

MakuluFramework.callBlizz     = function(method, ...)
    return method(...)
end

MakuluFramework.TtoL          = function(array)
    local newLuT = {}
    for _, item in pairs(array) do
        newLuT[item] = true
    end

    return newLuT
end

MakuluFramework.AtoL          = function(array)
    local newLuT = {}
    for _, item in ipairs(array) do
        newLuT[item] = true
    end

    return newLuT
end

MakuluFramework.getSpecId     = function()
    return GetSpecializationInfo(GetSpecialization())
end

local debounceCache           = {}

MakuluFramework.debounce      = function(key, min, reset, func, verify)
    local matching = debounceCache[key]
    local now = GetTime() * 1000

    if not matching then
        debounceCache[key] = now
        return
    end

    if matching + reset < now then
        debounceCache[key] = now
        return
    end

    if matching + min > now then return end

    if func() then
        debounceCache[key] = nil
    end
    return
end

MakuluFramework.debounceSpell = function(key, min, reset, spell, unit, icon)
    local matching = debounceCache[key]
    local now = GetTime() * 1000

    if not matching then
        debounceCache[key] = now
        return
    end

    if matching + reset < now then
        debounceCache[key] = now
        return
    end

    if matching + min > now then return end

    local result

    if unit then
        result = spell:Cast(unit, nil, icon)
    else
        result = spell:Cast()
    end

    return result
end

local pvpInstances            = {
    ["pvp"] = true, -- bg
    ["arena"] = true
}

local IsInInstance            = IsInInstance

MakuluFramework.InPvpInstance = function()
    if not utilsCache then
        utilsCache = MakuluFramework.Cache:getConstCacheCell()
    end

    return utilsCache:GetOrSet("inpvp", function()
        local _, instanceType = IsInInstance()

        if not instanceType or not pvpInstances[instanceType] then
            return false, false
        end

        return true, instanceType == "arena"
    end)
end

MakuluFramework.lowerFirstLetter = function(str)
    return string.lower(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

-- You dont see me here jack :)

local TrinketAnalyzer = {}
TrinketAnalyzer.__index = TrinketAnalyzer

-- Cache frequently used global functions
local GetInventoryItemLink = GetInventoryItemLink
local string_find = string.find
local string_lower = string.lower
local string_match = string.match
local tonumber = tonumber

local function safe_lower(str)
    return str and string_lower(str) or ""
end

-- Initialize localizedKeywords and wowGlobalStrings immediately
local localizedKeywords = (function()
    local locale = GetLocale()
    local keywords = {
        offensive = {
            ["enUS"] = {"increases damage", "grants.+power", "inflicts.+damage", "chance to deal", "strike", "blast", "bolt", "increases your.+by", "your attacks", "unleashes", "barrage", "highest secondary stat", "increases primary stat", "frost damage", "essence to deal"},
            ["ruRU"] = {"увеличивает урон", "дает.+силу", "наносит.+урон", "шанс нанести", "удар", "взрыв", "заряд", "увеличивает ваш.+на", "ваши атаки", "высвобождает", "шквал", "нанося", "Повышает искусность на", "характеристику", "Перстень приората"},
            ["esES"] = {"aumenta el daño", "otorga.+poder", "inflige.+daño", "probabilidad de causar", "golpe", "explosión", "descarga", "aumenta tu.+en", "tus ataques", "desata", "andanada"},
            ["frFR"] = {"augmente les dégâts", "accorde.+puissance", "inflige.+dégâts", "chance de causer", "frappe", "explosion", "éclair", "augmente votre.+de", "vos attaques", "libère", "barrage"}
        },
        defensive = {
            ["enUS"] = {"shield", "barrier", "reduces damage taken", "increases your armor", "restores.+health", "heals you", "protects you", "absorbs damage", "increases your maximum health", "reduces the duration of", "removes harmful effects"},
            ["ruRU"] = {"щит", "барьер", "уменьшает получаемый урон", "увеличивает вашу броню", "восстанавливает.+здоровье", "исцеляет вас", "защищает вас", "поглощает урон", "увеличивает ваше максимальное здоровье", "уменьшает длительность", "снимает вредные эффекты"},
            ["esES"] = {"escudo", "barrera", "reduce el daño recibido", "aumenta tu armadura", "restaura.+salud", "te cura", "te protege", "absorbe daño", "aumenta tu salud máxima", "reduce la duración de", "elimina efectos dañinos"},
            ["frFR"] = {"bouclier", "barrière", "réduit les dégâts subis", "augmente votre armure", "restaure.+santé", "vous soigne", "vous protège", "absorbe les dégâts", "augmente votre santé maximale", "réduit la durée de", "dissipe les effets néfastes"}
        },
        utility = {
            ["enUS"] = {"teleport", "invisibility", "summons", "creates", "transforms you", "grants you the ability", "increases your.+for", "reduces the cooldown", "allows you to", "releases", "grants control", "banish", "polymorph"},
            ["ruRU"] = {"телепорт", "невидимость", "призывает", "создает", "превращает вас", "дает вам способность", "увеличивает ваш.+на", "уменьшает время восстановления", "позволяет вам", "высвобождает", "дает контроль", "изгнание", "превращение"},
            ["esES"] = {"teletransporta", "invisibilidad", "invoca", "crea", "te transforma", "te otorga la habilidad", "aumenta tu.+durante", "reduce el tiempo de reutilización", "te permite", "libera", "otorga control", "desterrar", "polimorfia"},
            ["frFR"] = {"téléporte", "invisibilité", "invoque", "crée", "vous transforme", "vous accorde la capacité", "augmente votre.+pendant", "réduit le temps de recharge", "vous permet de", "libère", "accorde le contrôle", "bannir", "métamorphose"}
        }
    }
    return {
        offensive = keywords.offensive[locale] or keywords.offensive["enUS"],
        defensive = keywords.defensive[locale] or keywords.defensive["enUS"],
        utility = keywords.utility[locale] or keywords.utility["enUS"]
    }
end)()

local wowGlobalStrings = {
    offensive = {
        safe_lower(_G.SPELL_STAT1_NAME), -- Strength
        safe_lower(_G.SPELL_STAT2_NAME), -- Agility
        safe_lower(_G.SPELL_STAT3_NAME), -- Stamina
        safe_lower(_G.SPELL_STAT4_NAME), -- Intellect
        safe_lower(_G.ITEM_MOD_DAMAGE_PER_SECOND_SHORT),
        safe_lower(_G.ITEM_MOD_CRIT_RATING_SHORT),
        safe_lower(_G.ITEM_MOD_HASTE_RATING_SHORT),
        safe_lower(_G.ITEM_MOD_MASTERY_RATING_SHORT),
        safe_lower(_G.ITEM_MOD_VERSATILITY),
        safe_lower(_G.ATTACK_POWER_TOOLTIP),
        safe_lower(_G.SPELL_POWER),
        safe_lower(_G.ITEM_MOD_SPELL_POWER_SHORT),
        safe_lower(_G.ITEM_MOD_ATTACK_POWER_SHORT),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_SHORT),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_MAGICAL),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_MAGICAL_SHORT),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_PHYSICAL),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_PHYSICAL_SHORT),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_RANGED),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_RANGED_SHORT),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_SPELL),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_SPELL_SHORT),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_VERSUS),
        safe_lower(_G.ITEM_MOD_DAMAGE_DONE_VERSUS_SHORT)
    },
    defensive = {
        safe_lower(_G.ITEM_MOD_DAMAGE_ABSORB),
        safe_lower(_G.RESISTANCE2_NAME), -- Fire Resistance
        safe_lower(_G.RESISTANCE3_NAME), -- Nature Resistance
        safe_lower(_G.RESISTANCE4_NAME), -- Frost Resistance
        safe_lower(_G.RESISTANCE5_NAME), -- Shadow Resistance
        safe_lower(_G.RESISTANCE6_NAME), -- Arcane Resistance
        safe_lower(_G.ITEM_MOD_ARMOR_SHORT),
        safe_lower(_G.ITEM_MOD_DODGE_RATING_SHORT),
        safe_lower(_G.ITEM_MOD_PARRY_RATING_SHORT),
        safe_lower(_G.ITEM_MOD_BLOCK_RATING_SHORT),
        safe_lower(_G.ITEM_MOD_HEALING_DONE),
        safe_lower(_G.HEALTH),
        safe_lower(_G.ITEM_MOD_HEALTH),
        safe_lower(_G.ITEM_MOD_HEALTH_REGEN_SHORT),
        safe_lower(_G.ITEM_MOD_HEALTH_REGENERATION_SHORT),
        safe_lower(_G.ITEM_MOD_HEALTH_REGENERATION),
        safe_lower(_G.ITEM_MOD_HEALTH_REGEN),

    },
    utility = {
        safe_lower(_G.ITEM_MOD_MOVEMENT_SPEED),
        safe_lower(_G.ITEM_SPELL_TRIGGER_ON_USE)
    }
}

-- Remove any empty strings from wowGlobalStrings
for category, strings in pairs(wowGlobalStrings) do
    for i = #strings, 1, -1 do
        if strings[i] == "" then
            table.remove(strings, i)
        end
    end
end

function TrinketAnalyzer:New()
    local self = setmetatable({}, self)
    self.trinketOverrides = {}
    self:Initialize()
    return self
end

function TrinketAnalyzer:Initialize()
    self.cache = {}
    self.lastInCombat = InCombatLockdown()
end

function TrinketAnalyzer:AddOverride(itemID, conditions)
    self.trinketOverrides[itemID] = conditions
end

function TrinketAnalyzer:AnalyzeTrinketBySlot(slotID)
    local itemLink = GetInventoryItemLink("player", slotID)
    if not itemLink then
        return nil
    end

    local itemID = self:GetItemIDFromLink(itemLink)
    if self.cache[itemID] then
        return unpack(self.cache[itemID])
    end
    local isOnUse, isOffensive, isDefensive, isUtility = self:AnalyzeTrinket(itemLink)
    self.cache[itemID] = {isOnUse, isOffensive, isDefensive, isUtility}
    return isOnUse, isOffensive, isDefensive, isUtility
end

function TrinketAnalyzer:AnalyzeTrinket(itemLink)
    local itemID = self:GetItemIDFromLink(itemLink)
    if self.trinketOverrides[itemID] then
        local conditions = self.trinketOverrides[itemID]
        if type(conditions) == "function" then
            return conditions()
        elseif type(conditions) == "string" then
            local func, err = loadstring("return " .. conditions)
            if func then
                return func()
            else
                print("Error in override conditions:", err)
            end
        else
            print("Invalid override type for item ID:", itemID)
        end
        return nil
    end

    local tooltip = GameTooltip
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)

    local isOnUse, isOffensive, isDefensive, isUtility = false, false, false, false

    for i = 1, tooltip:NumLines() do
        local text = safe_lower(_G["GameTooltipTextLeft"..i]:GetText() or "")

        if not isOnUse and string_find(text, "^" .. safe_lower(_G.USE) .. ":") then 
            isOnUse = true

            if not isOffensive then
                isOffensive = self:CheckKeywords(text, "offensive")
            end
    
            if not isDefensive then
                isDefensive = self:CheckKeywords(text, "defensive")
            end
    
            if not isUtility then
                isUtility = self:CheckKeywords(text, "utility")
            end

            if isOnUse and (isOffensive or isDefensive or isUtility) then
                break
            end
        end
    end

    tooltip:Hide()
    return isOnUse, isOffensive, isDefensive, isUtility
end

function TrinketAnalyzer:CheckKeywords(text, category)
    for _, keyword in ipairs(localizedKeywords[category]) do
        if string_find(text, keyword) then
            return true
        end
    end
    for _, keyword in ipairs(wowGlobalStrings[category]) do
        if string_find(text, keyword) then
            return true
        end
    end
    return false
end

function TrinketAnalyzer:GetItemIDFromLink(itemLink)
    local itemID = string_match(itemLink, "item:(%d+)")
    return tonumber(itemID)
end

function TrinketAnalyzer:IsActionBlocked(slot)
    local toggleIndex = (slot == 13 and 1) or (slot == 14 and 2) or 0
    if toggleIndex == 0 then
        return true
    end

    return not Action.GetToggle(1, "Trinkets")[toggleIndex]
end

function TrinketAnalyzer:GetCooldown(slot)
    local start, duration, enabled = GetInventoryItemCooldown("player", slot)
    if not enabled then return 0 end

    if start == 0 then return 0 end

    return math.max(((start + duration) - GetTime()) * 1000, 0)
end

function TrinketAnalyzer:IsTrinketReady(slot)
    if self:IsActionBlocked(slot) then
        return false -- Action is blocked by toggle
    end

    return self:GetCooldown(slot) == 0
end

function TrinketAnalyzer:ShouldUseTrinket(slotID, trinketType)
    -- Check if we've just entered combat
    local inCombat = InCombatLockdown()
    if inCombat and not self.lastInCombat then
        self.cache = {}  -- Clear the cache when entering combat
    end
    self.lastInCombat = inCombat

    local isOnUse, isOffensive, isDefensive, isUtility = self:AnalyzeTrinketBySlot(slotID)

    if not isOnUse then
        return false
    end

    if not self:IsTrinketReady(slotID) then
        return false
    end

    return (trinketType == "Damage" and isOffensive) or
           (trinketType == "Defensive" and isDefensive) or
           (trinketType == "SelfHealing" and isDefensive) or
           (trinketType == "TargetHealing" and isDefensive) or
           (trinketType == "Utility" and isUtility)
end

local makTrinket = TrinketAnalyzer:New()

MakuluFramework.TrinketAnalyzer = makTrinket

MakuluFramework.Trinket = function(trinket_id, usage_type)
    if trinket_id == 1 then trinket_id = 13 end
    if trinket_id == 2 then trinket_id = 14 end
    return makTrinket:ShouldUseTrinket(trinket_id, usage_type)
end

MakuluFramework.TrinketOverride = function(trinket_id, conditions)
    makTrinket:AddOverride(trinket_id, conditions)
end

local PotionAnalyzer = {}
PotionAnalyzer.__index = PotionAnalyzer

function PotionAnalyzer:New()
    local self = setmetatable({}, self)
    self:Initialize()
    return self
end

function PotionAnalyzer:Initialize()
    self.cache = {}
    self.itemCountCache = {}
    self.lastInCombat = InCombatLockdown()
end

function IsPotionUsable(itemID, itemCount)
    itemCount = itemCount or GetItemCount(itemID, false, false)
    
    if itemCount == 0 then
        return false
    end
    
    local isUsable, notEnoughMana = IsUsableItem(itemID)
    if not isUsable then
        return false
    end
    
    local startTime, duration, enable = GetItemCooldown(itemID)
    if duration > 0 then
        return false
    end
    
    return true
end

function PotionAnalyzer:ShouldUsePotion(itemID)
    local inCombat = InCombatLockdown()
    if inCombat and not self.lastInCombat then
        self.itemCountCache = {}
    end
    self.lastInCombat = inCombat
    if inCombat then
        if not self.itemCountCache[itemID] then
            self.itemCountCache[itemID] = GetItemCount(itemID, false, false)
        end
        return IsPotionUsable(itemID, self.itemCountCache[itemID])
    else
        return IsPotionUsable(itemID)
    end
end

local list_of_off_potions = {
    191387, -- ElementalPotion1 
    191388, -- ElementalPotion2
    191389, -- ElementalPotion3
    191381, -- ElementalUltimate1
    191382, -- ElementalUltimate2
    191383, -- ElementalUltimate3
    212263, -- TemperedPotion1
    212264, -- TemperedPotion2
    212265, -- TemperedPotion3
    212257, -- PotionofUnwaveringFocus1
    212258, -- PotionofUnwaveringFocus2
    212259, -- PotionofUnwaveringFocus3
    212262, -- FrontlinePotion
}

local list_of_mana_potions = {
    212241, -- AlgariManaPotion
}

local list_of_health_stones = {
    36894,
    36893,
    36892,
    36891,
    36890,
    36889,
    22105,
    22104,
    22103,
    19012,
    19013,
    9421,
    19011,
    19010,
    5510,
    19009,
    19008,
    5509,
    19007,
    19006,
    5511,
    19005,
    19004,
    5512,
    224464
}

local list_of_health_potions = {
    191380,
    191379,
    191378,
    187802,
    171267,
}

MakuluFramework.CanUseOffPotion = function()
    for _, potion_id in ipairs(list_of_off_potions) do
        if IsPotionUsable(potion_id) then
            return true
        end
    end
    return false
end

MakuluFramework.CanUseHealthPotion = function()
    for _, potion_id in ipairs(list_of_health_potions) do
        if IsPotionUsable(potion_id) then
            return true
        end
    end
    return false
end

MakuluFramework.CanUseHealthStone = function()
    for _, potion_id in ipairs(list_of_health_stones) do
        if IsPotionUsable(potion_id) then
            return true
        end
    end
    return false
end

MakuluFramework.CanUseManaPotion = function()
    for _, potion_id in ipairs(list_of_mana_potions) do
        if IsPotionUsable(potion_id) then
            return true
        end
    end
    return false
end

MakuluFramework.IsTrinketReady =  function(...)
    return makTrinket:IsTrinketReady(...)
end

-- /run print(_G.MakuluFramework.Trinket(2, "Damage"))

--[[
if analyzer:ShouldUseTrinket(13, "Damage") then
	print("The trinket in slot 13 is an Damage on-use trinket that should be activated!")
end

if analyzer:ShouldUseTrinket(13, "Defensive") then
	print("The trinket in slot 13 is an Defensive on-use trinket that should be activated!")
end

if analyzer:ShouldUseTrinket(13, "Utility") then
	print("The trinket in slot 13 is an Utility on-use trinket that should be activated!")
end

if analyzer:ShouldUseTrinket(14, "Damage") then
	print("The trinket in slot 14 is an Damage on-use trinket that should be activated! But you should know this you fucking dirty cheater!")
end

if analyzer:ShouldUseTrinket(14, "Defensive") then
	print("The trinket in slot 14 is an Defensive on-use trinket that should be activated! But you should know this you fucking dirty cheater!")
end

if analyzer:ShouldUseTrinket(14, "Utility") then
	print("The trinket in slot 14 is an Utility on-use trinket that should be activated! But you should know this you fucking dirty cheater!")
end
]]--


--[[
Tanky Things
]]--

--[[
TRINKET OVERRIDES
]]--
-- Ringing Ritual Mud [ Absorb 10s ] [ Buff ID: 1219102 ]
MakuluFramework.TrinketOverride(232543, function()
    return not MakuluFramework.TrinketBigDefensive() and player.inCombat and (
        MakuluFramework.TankDefensive() or
        player.hp < 40
    ) and (not IsInRaid() or
        (
            IsInRaid() and
            MakuluFramework.AmITankingBoss()
        )
    )
end)

-- Modular Platinum Plating [ Armor 30s ]
MakuluFramework.TrinketOverride(168965, function()
    return not MakuluFramework.TrinketBigDefensive() and player.inCombat and (
        MakuluFramework.TankDefensive() or
        player.hp < 40
    ) and (not IsInRaid() or
        (
            IsInRaid() and
            MakuluFramework.AmITankingBoss()
        )
    )
end)

-- Core Recycling Unit [ Heal ] [ Stacking Buff use @ 15+ Stacks Buff ID: 1213758 ]
MakuluFramework.TrinketOverride(168965, function()
    return player.hp < 40 and player:HasBuffCount(1213758) >= 15
end)

-- Chromebustible Bomb Suit [ 75% DR 20s or DMG cap ] [ Buff ID: 466810 ]
MakuluFramework.TrinketOverride(230029, function()
    return not MakuluFramework.TrinketBigDefensive() and player.inCombat and (
        MakuluFramework.TankDefensive() or
        player.hp < 40
    ) and (not IsInRaid() or
        (
            IsInRaid() and
            MakuluFramework.AmITankingBoss()
        )
    )
end)

local bigTrinketDef = {
    466810, -- [Chromebustible Bomb Suit]
    1219102, -- [Ringing Ritual Mud]
    466810, -- [Chromebustible Bomb Suit]
}

local smallerMagicTrinketDef = {

}

local smallerPhysTrinketDef = {
    299869, -- [Modular Platinum Plating]
}

local function trinketDefTimeLeft(trinketList)
    return ConstCell:GetOrSet("trinketDefTime", function()
        if not trinketList then trinketList = bigTrinketDef end
        for _, trinketID in ipairs(trinketList) do
            local remains = player:BuffRemains(trinketID)
            if remains > 0 then
                return remains
            end
        end
        return 0
    end)
end

MakuluFramework.TrinketBigDefensive = function()
    return trinketDefTimeLeft(bigTrinketDef) > 0
end

MakuluFramework.TrinketBigDefensiveTime = function()
    return trinketDefTimeLeft(bigTrinketDef)
end

MakuluFramework.TrinketPhysical = function()
    return trinketDefTimeLeft(smallerPhysTrinketDef) > 0
end

MakuluFramework.TrinketPhysicalTime = function()
    return trinketDefTimeLeft(smallerPhysTrinketDef)
end

MakuluFramework.TrinketMagic = function()
    return trinketDefTimeLeft(smallerMagicTrinketDef) > 0
end

MakuluFramework.TrinketMagicTime = function()
    return trinketDefTimeLeft(smallerMagicTrinketDef)
end

local ActionUnit       = Action.Unit
local MultiUnits       = Action.MultiUnits
local MakUnit          = nil
local plates           = nil

local function TauntStatus(tauntSpell, autoTauntToggle)
    if plates == nil then
        plates = MakuluFramework.Plates.load()
    end
    if MakUnit == nil then
        MakUnit = MakuluFramework.Unit
    end
    if autoTauntToggle == nil then
        autoTauntToggle = "autotaunt"
    end

    if IsInRaid() or not Action.GetToggle(2, autoTauntToggle) then return "None" end

    local activeEnemies = MultiUnits:GetActiveUnitPlates()
    local needToSwitch = false
    local needToTaunt = false

    for unitToCheck in pairs(activeEnemies) do
        local munit = MakUnit:new(unitToCheck)
        if munit and munit.exists and plates[munit.guid] and tauntSpell:InRange(munit) and not Action.IsInPvP and not munit:IsTotem() and not munit:IsDummy() and munit.inCombat then
            local threatStatusE = UnitThreatSituation("player", munit:CallerId())
            local threatStatusT = UnitThreatSituation("player", "target")
            if threatStatusE == 0 or threatStatusE == 2 then
                if not UnitIsUnit("target", munit:CallerId()) and (threatStatusT == 1 or threatStatusT == 3) then
                    needToSwitch = true
                else
                    if tauntSpell:Usable(munit) then
                        needToTaunt = true
                    end
                end
            end
        end
    end

    if needToTaunt then
        return "Taunt"
    elseif needToSwitch then
        return "Switch"
    else
        return "None"
    end
end

MakuluFramework.TauntStatus = function(tauntSpell, autoTauntToggle)
    return TauntStatus(tauntSpell, autoTauntToggle)
end

local MakLists         = nil

local function defensiveActive()
    if MakLists == nil then
        MakLists = MakuluFramework.lists
    end
    return player:BuffFrom(MakLists.Defensive) or UnitGetTotalAbsorbs("player") >= player.maxHealth * 0.15
end

MakuluFramework.DefensiveActive = function()
    return defensiveActive()
end

local function shouldDefensive()
    return ConstCell:GetOrSet("shouldDefensiveTanky", function()
        local incomingDamage = makShouldDefensive()
        local dbm_buster = MakuluFramework.DBM_TankBusterIn() or 1000000

        return (incomingDamage < 3500 and 
            (
                not defensiveActive() or 
                MakuluFramework.TrinketBigDefensiveTime() < 1000
            )
        ) or
        (dbm_buster < 3500 and 
            (
                not defensiveActive() or 
                MakuluFramework.TrinketBigDefensiveTime() < dbm_buster
            )
        )
    end)
end

MakuluFramework.TankDefensive = function()
    return shouldDefensive()
end

local function amITankingBoss()
    return ConstCell:GetOrSet("amITankingBoss", function()
        if IsInRaid() then
            for i = 1, 5 do
                local unitID = "boss" .. i
                if UnitExists(unitID) and UnitIsUnit("player", unitID .. "target") then
                    return true
                end
            end
        end
        return false
    end)
end

MakuluFramework.AmITankingBoss = function()
    return amITankingBoss()
end

local makuluKeyPrefix= "efeafefewfw+__"

local currentProfile = nil

local function tryGetCurrentProfile()
    if currentProfile then
        return currentProfile
    end

    if not TMW then
        return nil
    end

    return TMW.db:GetCurrentProfile()
end

MakuluFramework.TryGetPersistValue = function(key, global)
    if not TellMeWhenDB then
        return nil
    end

    local dbStore = TellMeWhenDB.global.ActionDB
    if not global then
        local profile = tryGetCurrentProfile()
        if not profile then
            return nil
        end

        dbStore = TellMeWhenDB.profiles[profile] and TellMeWhenDB.profiles[profile].ActionDB
    end

    if not dbStore then
        return nil
    end

    return dbStore[makuluKeyPrefix .. key]
end

MakuluFramework.SavePersistentValue = function(key, value, global)
    if not TellMeWhenDB then
        return nil
    end

    local dbStore = TellMeWhenDB.global.ActionDB
    if not global then
        local profile = tryGetCurrentProfile()
        if not profile then
            return nil
        end

        dbStore = TellMeWhenDB.profiles[profile] and TellMeWhenDB.profiles[profile].ActionDB
    end

    if not dbStore then
        return nil
    end

    dbStore[makuluKeyPrefix .. key] = value
end

MakuluFramework.NeedRaidBuff = function(buffSpellRow)
    if player.inCombat then return end

    if Action.Zone == "arena" and player.combatTime > 0 then return end

    local missingBuff = MakuluFramework.MultiUnits.party:Any(function(unit) return not unit:Buff(buffSpellRow.wowName) and unit.distance < 40 and not unit.isPet and unit.hp > 0 end)
    local outOfRange = MakuluFramework.MultiUnits.party:Any(function(unit) return unit.distance >= 40 or C_Map.GetBestMapForUnit(player:CallerId()) ~= C_Map.GetBestMapForUnit(unit:CallerId()) end)
    
    if MakuluFramework.MultiUnits.party:Size() <= 5 and outOfRange then return end

    if missingBuff then 
        return true
    end

    return false
end
