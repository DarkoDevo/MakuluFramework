local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local SpellState = MakuluFramework.spellState
local Gcd = MakuluFramework.gcd

local GetTime = GetTime

local function hold_framework()
  SpellState.casted = true
end

local function all_ready(args)
  for i = 1, #args, 1 do
    local next_in_queue = args[i]
    if type(next_in_queue) ~= "number" then
      local spell_next = next_in_queue[1]

      if spell_next.cd > 1000 then
        return false
      end
    end
  end

  return true
end

local function check_smart_start(args)
  local estimated_timer = Gcd()

  for i = 1, #args, 1 do
    local next_in_queue = args[i]
    if type(next_in_queue) ~= "number" then
      local spell_next = next_in_queue[1]

      if estimated_timer < spell_next.cd then
        return false
      end

      local gap = math.max(spell_next:CastTime(), 1000)
      estimated_timer = estimated_timer + gap
    else
      estimated_timer = estimated_timer + next_in_queue
    end
  end

  return true
end

local function reset(self)
  self.position = 1
  self.trigger_last_sent = 0
end

local function call_next_sequence(self, args)
  if self.position > #args then
    if not self.auto_loop then
      return
    end

    self.position = 1
    self.trigger_last_sent = 0
  end

  if self.smart_start and self.position == 1 then
    if not check_smart_start(args) then return end
  end

  local next_in_queue = args[self.position]
  if type(next_in_queue) == "number" then
    if self.trigger_last_sent == 0 then
      self.trigger_last_sent = GetTime()
      hold_framework()

      return
    end

    local delta = GetTime() - self.trigger_last_sent
    if (delta * 1000) > next_in_queue then
      self.position = self.position + 1
      self.trigger_last_sent = 0
      return call_next_sequence(self, args)
    end

    if self.locked and self.position > 1 then
      hold_framework()
    end
    return
  end

  local spell_next = next_in_queue[1]

  local last_used = rawget(spell_next, "lastUsed")

  if self.trigger_last_sent > 0 and last_used > self.trigger_last_sent then
    self.position = self.position + 1
    self.trigger_last_sent = 0

    return call_next_sequence(self, args)
  end

  if self.skip and spell_next.cd > Gcd() + 200 then
    self.position = self.position + 1
    self.trigger_last_sent = 0

    return call_next_sequence(self, args)
  end
  
  if spell_next.cd > 1000 then
    if self.locked and self.position > 1 then
      hold_framework()
    end
    return
  end

  if not rawget(spell_next, "offGcd") and Gcd() > 300 then
    return hold_framework()
  end

  local spell = table.remove(next_in_queue, 1)

  if spell(unpack(next_in_queue)) and self.trigger_last_sent == 0 then
    self.trigger_last_sent = GetTime() * 1000
  end
end

local function sequenceCall(self, ...)
  return call_next_sequence(self, { ... })
end

local function new_cast_sequence(config)
  config = config or {
    auto_loop = false,
    locked = false,
    skip = false
  }

  config.position = 1
  config.trigger_last_sent = 0
  config.Reset = reset

  setmetatable(config, { __call = sequenceCall }) -- make Account handle lookup
  return config
end


MakuluFramework.CastSequence = {
  new = new_cast_sequence,
  check_ready = check_smart_start,
  all_ready = all_ready
}
