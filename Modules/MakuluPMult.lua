local Events     = MakuluFramework.Events
local Unit = MakuluFramework.Unit
local ConstUnits = MakuluFramework.ConstUnits

local player     = ConstUnits.player

local hooks      = {}

local function onCombatLogEvent(event, ...)
  local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool = CombatLogGetCurrentEventInfo()
  if sourceGUID ~= player.guid then return end
  if not spellID then return end

  local hook = hooks[spellID]
  if not hook then return end

  if subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH" then
    hook.stored[destGUID] = hook.pmul()
  elseif subevent == "SPELL_AURA_REMOVED" then
    hook.stored[destGUID] = nil
  end
end

function Unit:PMulState(debuff)
  local matched = hooks[debuff]
  if not matched then 
    print("Not tracking debuff: " .. debuff)
    return 0
  end

  return matched.stored[rawget(self, "guid")] or 0
end

local eventsSetup = false

local function registerPMulti(debuff, pmulFunc)
  if not eventsSetup then
    Events.register("COMBAT_LOG_EVENT_UNFILTERED", onCombatLogEvent)
    Events.registerReset(function()
      for _, i in pairs(hooks) do
        i.stored = {}
      end
    end)
    eventsSetup = true
  end
  
  hooks[debuff] = {
    pmul = pmulFunc,
    stored = {}
  }
end

MakuluFramework.Pmul = {
  register = registerPMulti
}
