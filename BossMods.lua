local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local lists           = MakuluFramework.lists

--[[
    DBM Timer Integration
]]--
local BossModTimerChecker = {}

function BossModTimerChecker:New()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.Timers = {}
    o.TimersBySpellID = {}
    o.BigWigsTimers = {}
    o.BigWigsTimersBySpellID = {}

    return o
end

function BossModTimerChecker:RegisterCallbacks()
    -- DBM Support
    if DBM then
        DBM:RegisterCallback("DBM_TimerStart", function(_, id, text, timerRaw, icon, timerType, spellid, colorId)
            local duration = type(timerRaw) == "string" and tonumber(timerRaw:match("%d+")) or timerRaw

            if not self.Timers[id] then
                self.Timers[id] = {
                    text = string.lower(text),
                    start = GetTime(),
                    duration = duration,
                }
            else
                self.Timers[id].text = string.lower(text)
                self.Timers[id].start = GetTime()
                self.Timers[id].duration = duration
            end

            if spellid then 
                self.Timers[id].spellid = spellid
                self.TimersBySpellID[spellid] = self.Timers[id]
            end
        end)

        DBM:RegisterCallback("DBM_TimerStop", function(_, id)
            if self.Timers[id] and self.Timers[id].spellid then
                self.TimersBySpellID[self.Timers[id].spellid] = nil
            end
            self.Timers[id] = nil
        end)
    end

    -- BigWigs Support
    if BigWigs and BigWigs.RegisterMessage then
        BigWigs.RegisterMessage(self, "BigWigs_StartBar", function(event, module, spellId, text, duration, icon)
            local id = module.moduleName .. spellId
            
            if not self.BigWigsTimers[id] then
                self.BigWigsTimers[id] = {
                    text = string.lower(text),
                    start = GetTime(),
                    duration = duration,
                    spellid = spellId
                }
            else
                self.BigWigsTimers[id].text = string.lower(text)
                self.BigWigsTimers[id].start = GetTime()
                self.BigWigsTimers[id].duration = duration
            end

            if spellId and tonumber(spellId) then
                self.BigWigsTimersBySpellID[tonumber(spellId)] = self.BigWigsTimers[id]
            end
        end)

        BigWigs.RegisterMessage(self, "BigWigs_StopBar", function(event, module, spellId, text)
            local id = module.moduleName .. spellId
            
            if self.BigWigsTimers[id] and self.BigWigsTimers[id].spellid then
                self.BigWigsTimersBySpellID[tonumber(self.BigWigsTimers[id].spellid)] = nil
            end
            
            self.BigWigsTimers[id] = nil
        end)

        -- Also handle bars that expire naturally
        BigWigs.RegisterMessage(self, "BigWigs_BarEmphasized", function(event, module, spellId)
            -- This usually fires when a bar is about to end
            -- We'll use it to clean up timers that are likely expired
            self:CleanExpiredTimers()
        end)
    end
end

function BossModTimerChecker:CleanExpiredTimers()
    local now = GetTime()
    
    -- Clean DBM timers
    for id, timer in pairs(self.Timers) do
        if (timer.start + timer.duration) < now then
            if timer.spellid then
                self.TimersBySpellID[timer.spellid] = nil
            end
            self.Timers[id] = nil
        end
    end
    
    -- Clean BigWigs timers
    for id, timer in pairs(self.BigWigsTimers) do
        if (timer.start + timer.duration) < now then
            if timer.spellid and tonumber(timer.spellid) then
                self.BigWigsTimersBySpellID[tonumber(timer.spellid)] = nil
            end
            self.BigWigsTimers[id] = nil
        end
    end
end

function BossModTimerChecker:GetTimeRemaining(text)
    if not text then
        error("Bad argument 'text' (nil value) for function GetTimeRemaining")
    end
    
    local lowestRemaining = 0
    local expirationTime = 0
    
    -- Check DBM timers
    for id, t in pairs(self.Timers) do
        if t.text:match(text) then
            local expTime = t.start + t.duration
            local remaining = expTime - GetTime()
            if remaining > 0 and (lowestRemaining == 0 or remaining < lowestRemaining) then
                lowestRemaining = remaining
                expirationTime = expTime
            end
        end
    end
    
    -- Check BigWigs timers
    for id, t in pairs(self.BigWigsTimers) do
        if t.text:match(text) then
            local expTime = t.start + t.duration
            local remaining = expTime - GetTime()
            if remaining > 0 and (lowestRemaining == 0 or remaining < lowestRemaining) then
                lowestRemaining = remaining
                expirationTime = expTime
            end
        end
    end
    
    return math.max(0, lowestRemaining), expirationTime
end

function BossModTimerChecker:GetTimeRemainingBySpellID(spellID)
    -- First check DBM timers
    if self.TimersBySpellID[spellID] then
        local expirationTime = self.TimersBySpellID[spellID].start + self.TimersBySpellID[spellID].duration
        local remaining = expirationTime - GetTime()
        if remaining > 0 then
            return math.max(0, remaining), expirationTime
        end
    end
    
    -- Then check BigWigs timers
    if self.BigWigsTimersBySpellID[spellID] then
        local expirationTime = self.BigWigsTimersBySpellID[spellID].start + self.BigWigsTimersBySpellID[spellID].duration
        local remaining = expirationTime - GetTime()
        if remaining > 0 then
            return math.max(0, remaining), expirationTime
        end
    end
    
    return 0, 0
end

local timerChecker = BossModTimerChecker:New()
timerChecker:RegisterCallbacks()

local function TankBusterIn()
    for spellID, _ in pairs(lists.pveTankBuster) do
        local remaining, expiration = timerChecker:GetTimeRemainingBySpellID(spellID)
        if remaining > 0 then
            return remaining * 1000
        end
    end
    return makIncBuster()
end

MakuluFramework.TankBusterIn = TankBusterIn  -- Renamed to be more generic
MakuluFramework.DBM_TankBusterIn = TankBusterIn  -- Keep for backward compatibility
