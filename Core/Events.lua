local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local registeredEvents = {}

local frame = MakuluFramework.Frame.get()

local function on_event(self, event, ...)
    local registered = registeredEvents[event]
    if not registered then return end

    for _, callback in ipairs(registered) do
        callback(event, ...)
    end
end

local function register_event(event_name, callback)
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
    registerReset = register_reset
}
