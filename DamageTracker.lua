local _, MakuluFramework = ...
MakuluFramework          = MakuluFramework or _G.MakuluFramework

local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo

local TTDTracker = {}
TTDTracker.__index = TTDTracker

function TTDTracker:New()
    local self = setmetatable({}, TTDTracker)
    self.damageData = {}
    return self
end

function TTDTracker:ResetUnit(unitGUID)
    self.damageData[unitGUID] = {
        recentDamage = {},
        lastUpdateTime = GetTime(),
        hitCount = 0
    }
end

function TTDTracker:AddDamage(unitGUID, amount)
    if not self.damageData[unitGUID] then
        self:ResetUnit(unitGUID)
    end

    local data = self.damageData[unitGUID]
    local currentTime = GetTime()

    -- Add new damage entry
    table.insert(data.recentDamage, {time = currentTime, amount = amount})
    data.hitCount = data.hitCount + 1
    data.lastUpdateTime = currentTime

    -- Remove old entries (older than 5 seconds)
    local cutoffTime = currentTime - 5
    while #data.recentDamage > 0 and data.recentDamage[1].time < cutoffTime do
        table.remove(data.recentDamage, 1)
    end
end

function TTDTracker:GetDPS(unit)
    local data = self.damageData[unit.guid]
    if not data or data.hitCount < 3 or #data.recentDamage == 0 then
        return 0
    end

    local currentTime = GetTime()
    local totalDamage = 0
    local oldestTime = currentTime

    for _, entry in ipairs(data.recentDamage) do
        totalDamage = totalDamage + entry.amount
        oldestTime = math.min(oldestTime, entry.time)
    end

    local duration = currentTime - oldestTime
    if duration <= 0 then
        return 0
    end

    return totalDamage / duration
end

function TTDTracker:GetTTD(unit)
    local dps = self:GetDPS(unit)
    if dps <= 0 then
        return math.huge
    end

    return math.max(0, (unit.healthActual / dps) * 1000) -- Convert to milliseconds
end

local tracker = TTDTracker:New()

local frame = CreateFrame("Frame")
if type(CombatLogGetCurrentEventInfo) == "function" then
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

frame:SetScript("OnEvent", function(self, event)
    if type(CombatLogGetCurrentEventInfo) ~= "function" then
        return
    end

    local _, eventType, _, _, _, _, _, destGUID, _, _, _, arg1, _, _, arg4 = CombatLogGetCurrentEventInfo()
    if not eventType or not destGUID then
        return
    end

    if eventType == "SWING_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" then
        local amount = eventType == "SWING_DAMAGE" and arg1 or arg4
        if type(amount) == "number" and amount > 0 then
            tracker:AddDamage(destGUID, amount)
        end
    end
end)

-- Global function to get TTD
local function GetTimeToDie(unit)
    return tracker:GetTTD(unit)
end

-- Global function to get DPS
local function GetDmgPerSec(unit)
    return tracker:GetDPS(unit)
end

-- Debug function
local function DebugTTDAndDPS(unit)
    local ttd = GetTimeToDie(unit)
    local dps = GetDmgPerSec(unit)
    local unitGUID = UnitGUID(unit)
    local data = tracker.damageData[unitGUID]
    if data then
        local totalDamage = 0
        for _, entry in ipairs(data.recentDamage) do
            totalDamage = totalDamage + entry.amount
        end
        local duration = GetTime() - (data.recentDamage[1] and data.recentDamage[1].time or GetTime())
        print(string.format("Unit: %s, TTD: %.2f ms, DPS: %.2f, Total Recent Damage: %.2f, Hit Count: %d, Duration: %.2f s",
            unit, ttd, dps, totalDamage, data.hitCount, duration))
    end
end

-- Usage:
-- /run DebugTTDAndDPS("target")
-- /run print("TTD:", GetTTD("target"), "ms", "DPS:", GetDPS("target"))

MakuluFramework.GetTimeToDie = GetTimeToDie
MakuluFramework.GetDmgPerSec = GetDmgPerSec
