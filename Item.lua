local _, MakuluFramework           = ...
MakuluFramework                    = MakuluFramework or _G.MakuluFramework

local TMW                          = _G.TMW

local cacheContext                 = MakuluFramework.Cache
local SpellState = MakuluFramework.spellState
local player                       = MakuluFramework.ConstUnits.player

local GetItemCount = C_Item.GetItemCount
local GetItemCooldown = C_Item.GetItemCooldown
local IsUsableItem = C_Item.IsUsableItem

local GetTime = GetTime

local Item = {}

local time                         = function()
    if TMW and TMW.time then return TMW.time end

    return GetTime()
end

local function getCooldown(itemId)
    local startTimeSeconds, durationSeconds = GetItemCooldown(itemId)

    if startTimeSeconds and durationSeconds and durationSeconds ~= 0 then
        return (durationSeconds - (time() - startTimeSeconds)) * 1000
    end

    return 0
end

function Item:Count()
  return self.cache:GetOrSet("ItemCount", function()
      return GetItemCount(rawget(self, "itemId"))
  end)
end

function Item:Cooldown()
  return self.cache:GetOrSet("Cooldown", function()
    return getCooldown(rawget(self, "itemId"))
  end)
end

function Item:Usable()
  return self.cache:GetOrSet("Usable", function()
    if Item.Count(self) < 1 then return end

    if Item.Cooldown(self) > 300 then
      return
    end

    local actionSpell = rawget(self, "actionSpell")
    if actionSpell and (actionSpell:IsBlocked() or actionSpell:IsBlockedByQueue()) then
        return false
    end

    local _, noMana = IsUsableItem(rawget(self, "itemId"))
    if noMana == 1 then return end

    return true
  end)
end

function Item:Use(spellOverride)
  if SpellState.casted or not SpellState.icon then return false end

  SpellState.casted = true
  local actionSpell = rawget(self, "actionSpell")
  if spellOverride then
    actionSpell = rawget(spellOverride, "actionSpell")
  end

  return actionSpell:Show(SpellState.icon)
end

function Item:Callback(arg1, arg2)
    local callbackMethod = arg2 or arg1
    local key = (callbackMethod == arg2 and arg1) or nil

    if key == nil then
        self.baseCallback = callbackMethod
        return
    end

    self.callbacks[key] = callbackMethod
end

local itemActions = {
  cooldown = Item.Cooldown,
  cd = Item.Cooldown,
  count = Item.Count,
}

local baseCallbackStr = "baseCallback"
local callbacksStr = "callbacks"

local function itemIndex(item, key)
  local property = rawget(item, key)
  if property ~= nil then
      return property
  end

  local index = itemActions[key]

  if index then
    return index(item)
  end

  return Item[key]
end

local function itemCall(self, ...)
  if SpellState.casted then return false end 
  local casting = player.castOrChannelInfo

  if casting and not rawget(self, "ignoreCasting") then
      if casting.spellId == rawget(self, "id") then return end
  end

  if not Item.Usable(self) then return false end
  local firstKey = select(1, ...)
  if firstKey == nil or type(firstKey) ~= "string" then
      return rawget(self, baseCallbackStr)(self, ...)
  end

  return rawget(self, callbacksStr)[firstKey](self, select(2, ...))
end

function Item:new(itemId, itemInfo, actionSpell)
  itemInfo = itemInfo or {}

  local baseCallback = function (item)
    return Item.Use(item)
  end

  local item = {
    itemId = itemId,
    id = itemId,
    ignoreCasting = itemInfo.ignoreCasting,

    wowName = C_Item.GetItemNameByID(itemId),
    cache = cacheContext:getConstCacheCell(),
    actionSpell = actionSpell,
    baseCallback = baseCallback,
    callbacks = {},
  }

  setmetatable(item, { __index = itemIndex, __call = itemCall })

  return item
end

MakuluFramework.Item = Item
