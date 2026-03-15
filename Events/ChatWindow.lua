local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local Events = MakuluFramework.Events

local chat_window_focussed = false

local function on_chat_window_message(event, ...)
    print(event)
    if event ~= "CHAT_MSG_SYSTEM" then return end

    local message = ...
    if message == "Chat suspended." then
        chat_window_focussed = true
        print("Chat window is now focused")
    elseif message == "Chat resumed." then
        chat_window_focussed = false
        print("Chat window is no longer focused")
    end
end

-- print('Loaded chat window')

-- Events.register("CHAT_MSG_SYSTEM", on_chat_window_message)

local has_chat_window = function()
    return ACTIVE_CHAT_EDIT_BOX ~= nil
end


MakuluFramework.ChatWindowOpen = has_chat_window
