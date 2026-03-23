local _, MakuluFramework           = ...
MakuluFramework                    = MakuluFramework or _G.MakuluFramework

local Unit                         = MakuluFramework.Unit
local cacheContext                 = MakuluFramework.Cache
local player                       = MakuluFramework.ConstUnits.player

local TMW                          = _G.TMW

local rawget, rawset               = rawget, rawset
local setmetatable                 = setmetatable
local select                       = select

local GetTime                      = GetTime

local C_Spell                      = C_Spell
local IsUsableSpell                = C_Spell.IsSpellUsable
local GetSpellCooldown             = C_Spell.GetSpellCooldown
local GetSpellInfo                 = C_Spell.GetSpellInfo
local GetSpellCharges              = C_Spell.GetSpellCharges
local SpellHasRange                = C_Spell.SpellHasRange
local GetSpellCastCount            = C_Spell.GetSpellCastCount
local IsSpellInRange               = C_Spell.IsSpellInRange

local GetHaste                     = GetHaste

local GetSpellBaseCooldown         = GetSpellBaseCooldown
local IsSpellKnown                 = IsSpellKnown
local IsSpellKnownOrOverridesKnown = IsSpellKnownOrOverridesKnown

local gcdInfo                      = cacheContext:getConstCacheCell()
local gcdSpell                     = 61304

local spellCombatCachePool         = cacheContext:getCombatCacheCell()
local spellLookup                  = {}

local Action           = _G.Action

local spellState                   = {
    icon = nil,
    casted = false,
    castingLockdown = false,
    gcdHold = false
}

local time                         = function()
    if TMW and TMW.time then return TMW.time end

    return GetTime()
end

local Compat                       = MakuluFramework.Compat or {}
MakuluFramework.Compat            = Compat
local huge                         = math.huge
local issecretvalue                = _G.issecretvalue
local scrubsecretvalues            = _G.scrubsecretvalues
local GetSpellCooldownSecrecy      = _G.GetSpellCooldownSecrecy
local C_Secrets                    = _G.C_Secrets

local function getGcd()
    return gcdInfo:GetOrSet("gcd", function()
        local info = GetSpellCooldown(gcdSpell)

        return (info.duration == 0 and 0) or ((info.duration - (time() - info.startTime)) * 1000)
    end)
end

local function getMaxGcd()
    return gcdInfo:GetOrSet("maxGcd", function()
        return (1.5 / (1 + GetHaste() / 100)) * 1000
    end)
end

local dumbCasts = {}

local addDumbCast = function(spellId)
    dumbCasts[spellId] = true
end

local Spell = {}

local function getCooldown(spellId)
    local cooldownInfo = GetSpellCooldown(spellId)

    if cooldownInfo and cooldownInfo.duration and cooldownInfo.duration ~= 0 then
        return (cooldownInfo.duration - (time() - cooldownInfo.startTime)) * 1000
    end

    return 0
end

function Spell:Cooldown()
    return self.cache:GetOrSet("Cooldown", function()
        return getCooldown(rawget(self, "spellId"))
    end)
end

function Spell:SpellGcd()
    return self.cache:GetOrSet("SpellGcd", function()
        local _, gcd = GetSpellBaseCooldown(rawget(self, "spellId"))
        return gcd
    end)
end

function Spell:SpecificBlockers()
    return false
end

function Spell:ReadyToUse()
    if spellState.casted then return false end

    return self.cache:GetOrSet("IsUsable", function()
        -- First lets return early if we're on gcd no need to spam here..
        local offGcd = rawget(self, "offGcd")
        if not rawget(self, "offGcd") and getGcd() > 300 then
            return false
        end

        if not offGcd and spellState.gcdHold then
            return false
        end

        -- Check for any platform specific reasosn
        if Spell.SpecificBlockers(self) then
            return false
        end

        -- If spell is on calldown then it's definintely not usable
        if Spell.Cooldown(self) > 300 then
            return false
        end

        -- Check if it's blocked in ggl
        local actionSpell = rawget(self, "actionSpell")
        if actionSpell and (actionSpell:IsBlocked() or actionSpell:IsBlockedByQueue()) then
            return false
        end

        local _, nomana = IsUsableSpell(rawget(self, "id"))
        if not rawget(self, "ignoreResource") and nomana then return end

        return true
    end)
end

function Spell:IsKnown()
    local spellId = rawget(self, "id")
    return self.cache:GetOrSet("learned" .. spellId, function()
        if rawget(self, "ignoreResource") then
            return rawget(self, "learnCheck")(spellId, rawget(self, "petSpell"))
        else
            local usable, nomana = IsUsableSpell(spellId)
            return usable and rawget(self, "learnCheck")(spellId, rawget(self, "petSpell"))
        end
    end)
end

function Spell:IsImmune(target)
    if rawget(self, "heal") then
    	if target.isMe then return false end
	return target.healImmune
    end
	
    local damageType = rawget(self, "damageType")
    if not damageType then return false end

    -- Assume totem is not immune
    if target:IsTotem() then return false end

    -- Dont check self immununity if casting on me
    if target.isMe then return false end
    if target.totalImmune then return true end

    if damageType == "physical" then
        if target.physImmune then return true end
    elseif damageType == "magic" then
        if target.magicImmune then return true end
    end

    if rawget(self, "cc") then
        if target.ccImmune then return true end
    end

    return false
end

function Spell:Usable(target)
    if not Spell.ReadyToUse(self) then return end

    local actionSpell = rawget(self, "actionSpell")
    local targId = rawget(target, "id")
    local targeted = rawget(self, "targeted")

    if targeted and Spell.IsImmune(self, target) then return end

    return not actionSpell or true
end

function Spell:Cast(target, skipSet, spellOverride)
    if rawget(self, "isFakeSpell") then
        local actionSpell = rawget(self, "actionSpell")
        return actionSpell:Show(spellState.icon)
    end

    target = target or player
    if spellState.casted or not spellState.icon then return false end
    if not Spell.Usable(self, target) then return false end
    if not Spell.InRange(self, target) then return end
    if target.dead then return end

    if rawget(self, "targeted") then
        if not target.los then return end
    end

    if not skipSet then
        spellState.casted = true

        rawset(self, "lastAttemptTime", (GetTime() * 1000))

        if spellOverride then
            local actionSpell = rawget(spellOverride, "actionSpell")
            return actionSpell:Show(spellState.icon)
        end

        local actionSpell = rawget(self, "actionSpell")
        return actionSpell:Show(spellState.icon)
    end

    return true
end

function Spell:CastMeta(target, skipSet, spellOverride)
    if rawget(self, "isFakeSpell") then
        local actionSpell = rawget(self, "actionSpell")
        return actionSpell:Show(spellState.icon)
    end

    target = target or player
    if spellState.casted or not spellState.icon then return false end
    if not Spell.Usable(self, target) then return false end
    if not Spell.InRange(self, target) then return end
    if target.dead then return end

    if rawget(self, "targeted") then
        if not target.los then return end
    end

    if not skipSet then
        spellState.casted = true

        rawset(self, "lastAttemptTime", (GetTime() * 1000))

        if spellOverride then
            local actionSpell = rawget(spellOverride, "actionSpell")
            return actionSpell:Show(spellState.icon)
        end

        local actionSpell = rawget(self, "actionSpell")
        return actionSpell:Show(spellState.icon)
    end

    return true
end

function Spell:SpellInfo()
    return self.cache:GetOrSet("SpellInfo", function()
        return GetSpellInfo(rawget(self, "spellId"))
    end)
end

function Spell:Range()
    local info = Spell.SpellInfo(self)
    if not info then return -1 end

    return info.maxRange or info.minRange or -1
end

function Spell:Cost()
    return self.cache:GetOrSet("Cost", function()
        local cost = C_Spell.GetSpellPowerCost(rawget(self, "spellId"))[1]
        if not cost then return cost end

        return cost.cost
    end)
end

function Spell:CastTime()
    return self.cache:GetOrSet("CastTime", function()
        return Spell.SpellInfo(self).castTime
    end)
end

function Spell:InRange(target)
    local targetId = rawget(target, "id")
    return self.cache:GetOrSet("Range" .. targetId, function()
        return IsSpellInRange(rawget(self, "wowName"), targetId) ~= false
    end)
end

function Spell:HasRange()
    return self.cache:GetOrSet("HasRange", function()
        return SpellHasRange(rawget(self, "spellId"))
    end)
end

function Spell:Count()
    return self.cache:GetOrSet("Count", function()
        return GetSpellCastCount(rawget(self, "spellId"))
    end)
end

function Spell:Charges()
    local info = GetSpellCharges(rawget(self, "spellId"))

    return info.currentCharges
end

function Spell:MaxCharges()
    local info = GetSpellCharges(rawget(self, "spellId"))

    return info.maxCharges
end

function Spell:Fraction()
    return self.cache:GetOrSet("Frac", function()
        local info = GetSpellCharges(rawget(self, "spellId"))
        if info.currentCharges == info.maxCharges then
            return info.currentCharges
        end

        if info.cooldownStartTime == 0 then
            return info.currentCharges
        end

        local amount = GetTime() - info.cooldownStartTime
        local percent = amount / info.cooldownDuration

        return info.currentCharges + percent
    end)
end

function Spell:TimeToFullCharges()
    local info = GetSpellCharges(rawget(self, "spellId"))
    if info.currentCharges == info.maxCharges then
        return 0
    end

    if info.cooldownStartTime == 0 then
        return 0
    end

    local missing = info.maxCharges - info.currentCharges - 1

    local amount = GetTime() - info.cooldownStartTime
    local remaining = info.cooldownDuration - amount

    if missing > 0 then
        remaining = remaining + (missing * info.cooldownDuration)
    end

    return remaining * 1000
end

function Spell:Used()
    return (GetTime() * 1000) - rawget(self, "lastUsed")
end

function Spell:LastAttempt()
    return (GetTime() * 1000) - rawget(self, "lastAttemptTime")
end

function Spell:ToolTip()
    if not self or not self.id then
        return 0
    end

    local tooltipText = C_TooltipInfo.GetSpellByID(self.id).lines[4].leftText

    local ttValue = {}

    if tooltipText then
        for num in string.gmatch(tooltipText, "%d+%.?%d*") do
            local number = tonumber(num)
            local formattedNumber = string.format("%.2f", number)
            table.insert(ttValue, formattedNumber)
        end
    end

    return ttValue
end

function Spell:Callback(arg1, arg2)
    local callbackMethod = arg2 or arg1
    local key = (callbackMethod == arg2 and arg1) or nil

    if key == nil then
        self.baseCallback = callbackMethod
        return
    end

    self.callbacks[key] = callbackMethod
end

local spellActions = {
    cooldown = Spell.Cooldown,
    spellGcd = Spell.SpellGcd,
    count = Spell.Count,
    cost = Spell.Cost,
    charges = Spell.Charges,
    maxCharges = Spell.MaxCharges,
    frac = Spell.Fraction,
    cd = Spell.Cooldown,
    isKnown = Spell.IsKnown,
    known = Spell.IsKnown,
    hasRange = Spell.HasRange,
    used = Spell.Used,
    lastAttempt = Spell.LastAttempt
}

local function spellIndex(spell, key)
    local property = rawget(spell, key)
    if property ~= nil then
        return property
    end

    local spellAction = spellActions[key]
    if spellAction then
        return spellAction(spell)
    else
        return Spell[key]
    end
end

local constSpellLut = {
    [133015] = true,
    [237586] = true,
    [237290] = true,
    [607512] = true,
    [136057] = true,
    [535593] = true,
    [133875] = true,
    [133876] = true,
    [136243] = true,
    [135805] = true,
    [135848] = true,
    [133873] = true,
    [133874] = true,
    [134314] = true,
    [134316] = true,
    [134318] = true,
    [134320] = true,
    [134310] = true,
    [319458] = true,
    [1030902] = true,
    [1030910] = true,
    [538745] = true,
    [967532] = true,
    [176108] = true,
}

local baseCallbackStr = "baseCallback"
local callbacksStr = "callbacks"

local function spellCall(self, ...)
    if constSpellLut[rawget(self, "id")] then
        return rawget(self, baseCallbackStr)(self, ...)
    end

    if spellState.casted then return false end
    local casting = player.castOrChannelInfo

    if casting and not rawget(self, "ignoreCasting") then
        if not dumbCasts[casting.spellId] then return end
        if casting.spellId == rawget(self, "id") then return end
    end

    if not Spell.IsKnown(self) then return end
    if not Spell.ReadyToUse(self) then return false end

    local casted = rawget(self, "channel") or Spell.CastTime(self) > 0

    if not rawget(self, "ignoreMoving") and casted and player.moving
        and not player:CanCastWhileMoving() then
        return
    end

    if spellState.castingLockdown and casted then
        return
    end

    local firstKey = select(1, ...)
    if firstKey == nil or type(firstKey) ~= "string" then
        return rawget(self, baseCallbackStr)(self, ...)
    end

    return rawget(self, callbacksStr)[firstKey](self, select(2, ...))
end

function Spell:new(spellId, spellInfo, actionSpell)
    spellInfo = spellInfo or {}

    local targeted = spellInfo.targeted
    if targeted == nil then
        targeted = true
    end

    if spellInfo.dumbCast then
        addDumbCast(spellId)
    end

    local learnCheck = IsSpellKnownOrOverridesKnown
    if spellInfo.noOverride then
      learnCheck = IsSpellKnown
    end

    local spell = {
        cache = cacheContext:getConstCacheCell(),
        spellId = spellId,
        id = spellId,
        wowName = C_Spell.GetSpellName(spellId) or "None",
        spellInfo = spellInfo,
        offGcd = spellInfo.offGcd or false,
        ignoreCasting = spellInfo.ignoreCasting or false,
        ignoreFacing = spellInfo.ignoreFacing or false,
        ignoreRange = spellInfo.ignoreRange or false,
        ignoreMoving = spellInfo.ignoreMoving or false,
        ignoreLos = spellInfo.ignoreLos or false,
        ignoreResource = spellInfo.ignoreResource or false,
        cc = spellInfo.cc or false,
        heal = spellInfo.heal or false,
        actionSpell = actionSpell,
        spellType = spellInfo.spellType,
        damageSpell = spellInfo.damageSpell,
        channel = spellInfo.channel or false,
        targeted = targeted,
        petSpell = spellInfo.pet or nil,
        learnCheck = learnCheck,

        lastUsed = 99999,
        lastAttemptTime = 99999,

        damageType = spellInfo.damageType,

        isFakeSpell = false,

        baseCallback = nil,
        callbacks = {},
    }

    if constSpellLut[spellId] then
        spell.baseCallback = function(self, ...)
            return self:Cast()
        end
    end

    setmetatable(spell, { __index = spellIndex, __call = spellCall }) -- make Account handle lookup

    spellLookup[spellId] = spell

    self.__index = self

    return spell
end

local constantSpells = {
    TabTarget = { ID = 133015, Type = "Item", FixedTexture = 133015, Macro = "/targetenemy", Desc = "Tab Target", MacroForbidden = true },
    TargetMouseOver = { ID = 237586, Type = "Item", FixedTexture = 237586, Macro = "/target [@mouseover,exists]", Desc = "Target Mouseover", MacroForbidden = true },
    TargetLastTarget = { ID = 237290, Type = "Item", FixedTexture = 237290, Macro = "/targetlasttarget", Desc = "Target Last Target", MacroForbidden = true },

    TargetArena1 = { ID = 607512, Type = "Item", FixedTexture = 607512, Macro = "/target arena1", Desc = "Target Arena 1", MacroForbidden = true },
    TargetArena2 = { ID = 136057, Type = "Item", FixedTexture = 136057, Macro = "/target arena2", Desc = "Target Arena 2", MacroForbidden = true },
    TargetArena3 = { ID = 535593, Type = "Item", FixedTexture = 535593, Macro = "/target arena3", Desc = "Target Arena 3", MacroForbidden = true },
    TargetArena4 = { ID = 133875, Type = "Item", FixedTexture = 133875, Macro = "/target arena4", Desc = "Target Arena 4", MacroForbidden = true },
    TargetArena5 = { ID = 133876, Type = "Item", FixedTexture = 133876, Macro = "/target arena5", Desc = "Target Arena 5", MacroForbidden = true },

    FocusArena1 = { ID = 136243, Type = "Item", FixedTexture = 136243, Macro = "/focus arena1", Desc = "Focus Arena 1", MacroForbidden = true },
    FocusArena2 = { ID = 135805, Type = "Item", FixedTexture = 135805, Macro = "/focus arena2", Desc = "Focus Arena 2", MacroForbidden = true },
    FocusArena3 = { ID = 135848, Type = "Item", FixedTexture = 135848, Macro = "/focus arena3", Desc = "Focus Arena 3", MacroForbidden = true },
    FocusArena4 = { ID = 133873, Type = "Item", FixedTexture = 133873, Macro = "/focus arena4", Desc = "Focus Arena 4", MacroForbidden = true },
    FocusArena5 = { ID = 133874, Type = "Item", FixedTexture = 133874, Macro = "/focus arena5", Desc = "Focus Arena 5", MacroForbidden = true },

    FocusParty1 = { ID = 134314, Type = "Item", FixedTexture = 134314, Macro = "/focus party1", Desc = "Focus Party 1", MacroForbidden = true },
    FocusParty2 = { ID = 134316, Type = "Item", FixedTexture = 134316, Macro = "/focus party2", Desc = "Focus Party 2", MacroForbidden = true },
    FocusParty3 = { ID = 134318, Type = "Item", FixedTexture = 134318, Macro = "/focus party3", Desc = "Focus Party 3", MacroForbidden = true },
    FocusParty4 = { ID = 134320, Type = "Item", FixedTexture = 134320, Macro = "/focus party4", Desc = "Focus Party 4", MacroForbidden = true },
    FocusPlayer = { ID = 134310, Type = "Item", FixedTexture = 134310, Macro = "/focus player", Desc = "Focus Player", MacroForbidden = true },

    StopCasting = { ID = 319458, Type = "Item", FixedTexture = 319458, Macro = "/stopcasting", Desc = "Stop Casting", MacroForbidden = true },

    Trinket1 = { ID = 1030902, Type = "Trinket", FixedTexture = 1030902, Macro = "/use 13", Desc = "Trinket 1" },
    Trinket2 = { ID = 1030910, Type = "Trinket", FixedTexture = 1030910, Macro = "/use 14", Desc = "Trinket 2" },

    HealthStone = { ID = 538745, Type = "Item", FixedTexture = 538745, Macro = "/use Healthstone", Desc = "Healthstone" },
    HealthPotion = { ID = 967532, Type = "Item", FixedTexture = 967532, Macro = "/use Health Potion", Desc = "Health Potion" },
    Potion = { ID = 176108, Type = "Potion", Texture = 176108 },
    PoolResources = { ID = 279509, Texture = 279509 },
    --[[
    Universal1 = { ID = 133667, Texture = 133667 },
    Universal2 = { ID = 133663, Texture = 133663 },
    Universal3 = { ID = 133658, Texture = 133658 },
    Universal4 = { ID = 133653, Texture = 133653 },
    Universal5 = { ID = 133650, Texture = 133650 },
    Universal6 = { ID = 133648, Texture = 133648 },
    Universal7 = { ID = 133646, Texture = 133646 },
    Universal8 = { ID = 133643, Texture = 133643 },
    Universal9 = { ID = 133639, Texture = 133639 },
    Universal10 = { ID = 133632, Texture = 133632 },
    
    Universal1Unit1 = { ID = 133667, Texture = 133667 },
    Universal2Unit1 = { ID = 133663, Texture = 133663 },
    Universal3Unit1 = { ID = 133658, Texture = 133658 },
    Universal4Unit1 = { ID = 133653, Texture = 133653 },
    Universal5Unit1 = { ID = 133650, Texture = 133650 },
    Universal6Unit1 = { ID = 133648, Texture = 133648 },
    Universal7Unit1 = { ID = 133646, Texture = 133646 },
    Universal8Unit1 = { ID = 133643, Texture = 133643 },
    Universal9Unit1 = { ID = 133639, Texture = 133639 },
    Universal10Unit1 = { ID = 133632, Texture = 133632 },

    Universal1Unit2 = { ID = 133667, Texture = 133667 },
    Universal2Unit2 = { ID = 133663, Texture = 133663 },
    Universal3Unit2 = { ID = 133658, Texture = 133658 },
    Universal4Unit2 = { ID = 133653, Texture = 133653 },
    Universal5Unit2 = { ID = 133650, Texture = 133650 },
    Universal6Unit2 = { ID = 133648, Texture = 133648 },
    Universal7Unit2 = { ID = 133646, Texture = 133646 },
    Universal8Unit2 = { ID = 133643, Texture = 133643 },
    Universal9Unit2 = { ID = 133639, Texture = 133639 },
    Universal10Unit2 = { ID = 133632, Texture = 133632 },

    Universal1Unit3 = { ID = 133667, Texture = 133667 },
    Universal2Unit3 = { ID = 133663, Texture = 133663 },
    Universal3Unit3 = { ID = 133658, Texture = 133658 },
    Universal4Unit3 = { ID = 133653, Texture = 133653 },
    Universal5Unit3 = { ID = 133650, Texture = 133650 },
    Universal6Unit3 = { ID = 133648, Texture = 133648 },
    Universal7Unit3 = { ID = 133646, Texture = 133646 },
    Universal8Unit3 = { ID = 133643, Texture = 133643 },
    Universal9Unit3 = { ID = 133639, Texture = 133639 },
    Universal10Unit3 = { ID = 133632, Texture = 133632 },
    ]]--
}

local racialSpells = {
    WillToSurvive = { ID = 59752 },
    Stoneform = { ID = 20594 },
    Shadowmeld = { ID = 58984 },
    EscapeArtist = { ID = 20589 },
    GiftOfTheNaaru = { ID = 59544 },
    Darkflight = { ID = 68992 },
    WillOfTheForsaken = { ID = 7744 },
    WarStomp = { ID = 20549 },
    Berserking = { ID = 26297 },
    ArcaneTorrent = { ID = 50613 },
    RocketJump = { ID = 69070 },
    RocketBarrage = { ID = 69041 },
    QuakingPalm = { ID = 107079 },
    SpatialRift = { ID = 256948 },
    LightsJudgment = { ID = 255647 },
    Fireblood = { ID = 265221 },
    ArcanePulse = { ID = 260364 },
    BullRush = { ID = 255654 },
    AncestralCall = { ID = 274738 },
    Haymaker = { ID = 287712 },
    Regeneratin = { ID = 291944 },
    BagOfTricks = { ID = 312411 },
    HyperOrganicLightOriginator = { ID = 312924 },
    WingBuffet = { ID = 357214 },
    TailSwipe = { ID = 368970 },
}

local seasonPotions = {
    -- Season 3 DPS Potions (Updated for Patch 11.2)
    FleetingR3 = { Type = "Potion", ID = 212971, Texture = 176108, Macro = "/use item:212971\n/use item:212265\n/use item:212970\n/use item:212264\n/use item:212969\n/use item:212263"},
    FleetingR2 = { Type = "Potion", ID = 212970, Texture = 176108, Macro = "/use item:212971\n/use item:212265\n/use item:212970\n/use item:212264\n/use item:212969\n/use item:212263"},
    FleetingR1 = { Type = "Potion", ID = 212969, Texture = 176108, Macro = "/use item:212971\n/use item:212265\n/use item:212970\n/use item:212264\n/use item:212969\n/use item:212263"},
    TemperedR3 = { Type = "Potion", ID = 212265, Texture = 176108, Macro = "/use item:212971\n/use item:212265\n/use item:212970\n/use item:212264\n/use item:212969\n/use item:212263"},
    TemperedR2 = { Type = "Potion", ID = 212264, Texture = 176108, Macro = "/use item:212971\n/use item:212265\n/use item:212970\n/use item:212264\n/use item:212969\n/use item:212263"},
    TemperedR1 = { Type = "Potion", ID = 212263, Texture = 176108, Macro = "/use item:212971\n/use item:212265\n/use item:212970\n/use item:212264\n/use item:212969\n/use item:212263"},
    PotionofUnwaveringFocus3 = { Type = "Potion", ID = 212259, Texture = 176108, Hidden = true },
    PotionofUnwaveringFocus2 = { Type = "Potion", ID = 212258, Texture = 176108, Hidden = true },
    PotionofUnwaveringFocus1 = { Type = "Potion", ID = 212257, Texture = 176108, Hidden = true },
}

function CreateAction(attributes)
    return Action.Create({
        Type = attributes.Type or "Spell",
        ID = attributes.ID,
        Texture = attributes.Texture,
        FixedTexture = attributes.FixedTexture,
        Color = attributes.Color,
        Desc = attributes.Desc,
        MAKULU_INFO = attributes.MAKULU_INFO,
        Hidden = attributes.Hidden,
        QueueForbidden = attributes.QueueForbidden,
        Macro = attributes.Macro,
        Desc = attributes.Desc,
        useMaxRank = attributes.useMaxRank,
        isTalent = attributes.isTalent,
        BlockForbidden = attributes.BlockForbidden,
        QueueForbidden = attributes.QueueForbidden,
        Click = attributes.Click,
        MacroForbidden = attributes.MacroForbidden
    })
end

local buildMakuluFrameworkSpells = function(ActionList)
	local result = {}
	for k, v in pairs(ActionList) do
		result[k] = Spell:new(v.ID, v.MAKULU_INFO, v)
	end
	return result
end

MakuluFramework.CreateActionVar = function(action_list, skip_racial_spells)
    skip_racial_spells = skip_racial_spells or false
    local A = {}
    for name, attributes in pairs(action_list) do
        A[name] = CreateAction(attributes)
    end
    for name, attributes in pairs(constantSpells) do
        A[name] = CreateAction(attributes)
    end
    for name, attributes in pairs(seasonPotions) do
        A[name] = CreateAction(attributes)
    end
    if not skip_racial_spells then
        for name, attributes in pairs(racialSpells) do
            A[name] = CreateAction(attributes)
        end
    end
    local M = buildMakuluFrameworkSpells(A)

    return A, M
end

MakuluFramework.Spell = Spell
MakuluFramework.gcd = getGcd
MakuluFramework.maxGcd = getMaxGcd
MakuluFramework.spellState = spellState
MakuluFramework.spellLookup = spellLookup
MakuluFramework.constantSpells = constantSpells
MakuluFramework.seasonPotions = seasonPotions