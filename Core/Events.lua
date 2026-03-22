local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local registeredEvents = {}
local erroredCallbacks = {}

local frame = MakuluFramework.Frame.get()
local traceback = _G.debugstack or debug.traceback
local print = _G.print
local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo

local function is_event_supported(event_name)
    if event_name == "COMBAT_LOG_EVENT_UNFILTERED" then
        return type(CombatLogGetCurrentEventInfo) == "function"
    end

    return true
end

local function on_event(self, event, ...)
    local registered = registeredEvents[event]
    if not registered then return end

    local disabled = erroredCallbacks[event]

    for index, callback in ipairs(registered) do
        if type(callback) == "function" and not (disabled and disabled[index]) then
            local ok, err = xpcall(callback, traceback, event, ...)
            if not ok then
                disabled = disabled or {}
                disabled[index] = true
                erroredCallbacks[event] = disabled
                if print then
                    print(string.format("[MakuluFramework] Disabled failing %s callback: %s", event, tostring(err)))
                end
            end
        end
    end
end

local function register_event(event_name, callback)
    if not is_event_supported(event_name) then
        return
    end

    if registeredEvents[event_name] then
        table.insert(registeredEvents[event_name], callback)
        return
    end

    registeredEvents[event_name] = { callback }
    frame:RegisterEvent(event_name)
end

frame:SetScript("OnEvent", on_event)

local resetListeners = {}

local resetEvents = {
    "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
    "PLAYER_ENTERING_WORLD",
}

local function onResetCalled(event, ...)
    for _, callback in ipairs(resetListeners) do
        callback(event, ...)
    end
end

for _, event in ipairs(resetEvents) do
    register_event(event, onResetCalled)
end

local function register_reset(callback)
    table.insert(resetListeners, callback)
end

MakuluFramework.Events = {
    register = register_event,
    registerReset = register_reset,
    isEventSupported = is_event_supported,
}
