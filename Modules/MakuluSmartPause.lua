local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork


local thanksJack = {
    [0x03] = "F",
    [0x04] = "H",
    [0x05] = "G",
    [0x06] = "Z",
    [0x07] = "X",
    [0x08] = "C",
    [0x09] = "V",
    [0x0B] = "B",
    [0x0C] = "Q",
    [0x0E] = "E",
    [0x0F] = "R",
    [0x10] = "Y",
    [0x11] = "T",
    [0x12] = "1",
    [0x13] = "2",
    [0x14] = "3",
    [0x15] = "4",
    [0x16] = "6",
    [0x17] = "5",
    [0x18] = "Equal",
    [0x19] = "9",
    [0x1A] = "7",
    [0x1B] = "Minus",
    [0x1C] = "8",
    [0x1D] = "0",
    [0x1E] = "RightBracket",
    [0x1F] = "O",
    [0x20] = "U",
    [0x21] = "LeftBracket",
    [0x22] = "I",
    [0x23] = "P",
    [0x25] = "L",
    [0x26] = "J",
    [0x27] = "Quote",
    [0x28] = "K",
    [0x29] = "Semicolon",
    [0x2A] = "Backslash",
    [0x2B] = "Comma",
    [0x2C] = "Slash",
    [0x2D] = "N",
    [0x2E] = "M",
    [0x2F] = "Period",
    [0x32] = "Grave",
}

local keybindCache = {}

function cacheMovementKeybinds()
    local defaultKeybinds = {
        MOVEFORWARD = "w",
        MOVEBACKWARD = "s",
        STRAFELEFT = "a",
        STRAFERIGHT = "d",
        TURNLEFT = "left",
        TURNRIGHT = "right",
        JUMP = "spacebar"
    }

    for action, defaultKeybind in pairs(defaultKeybinds) do
        local keybind = GetBindingKey(action)
        local lowercaseAction = string.lower(action)
        
        -- Check if keybind is not nil before converting to lowercase
        local lowercaseKeybind = keybind and string.lower(keybind) or defaultKeybind
        
        keybindCache[lowercaseAction] = lowercaseKeybind
    end
end

function isBindInTable(letter, tbl)
    for _, value in pairs(tbl) do
        if value == letter then
            return true
        end
    end
    return false
end 

function shouldPause(binds)
    if IsShiftKeyDown() then
        if not isBindInTable("shift", binds) then 
            return true 
        end 
    end

    if IsControlKeyDown() then
        if not isBindInTable("ctrl", binds) then 
            return true 
        end 
    end

    if IsAltKeyDown() then
        if not isBindInTable("alt", binds) then 
            return true 
        end 
    end

    --TINKR
    for key, value in pairs(thanksJack) do
        if GetKeyState(key) then
            if not isBindInTable(value, binds) then 
                return true 
            end 
        end 
    end

    --DAEMONIC/WINDOWS - idk if we ever need this but yeaaa
    -- for charCode = 97, 122 do -- ASCII codes for lowercase letters 'a' to 'z'
    --     local letter = string.char(charCode)
    --     if GetKeyState(letter) == 1 then 
    --         if not isBindInTable(letter, binds) then 
    --             return true 
    --         end 
    --     end 
    -- end

    -- for num = 49, 57 do -- ASCII codes for numbers '1' to '9'
    --     local number = string.char(num)
    --     if GetKeyState(number) == 1 then 
    --         if not isBindInTable(number, binds) then 
    --             return true 
    --         end 
    --     end 
    -- end


end

cacheMovementKeybinds()
local lastPause = 0


MakuluFramework.SmartPause = {
    ShouldPause = shouldPause,
    KeybindCache  = keybindCache,
    LastPause = lastPause,
}
