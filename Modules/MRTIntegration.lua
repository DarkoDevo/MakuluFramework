local Tinkr, MakuluFramework = ...

-- MRT (Method Raid Tools) Integration Module
-- This module provides integration with Method Raid Tools addon for accessing raid notes and instructions
-- Updated to support Kaze MRT Timers format

local MRTIntegration = {}

-- Safe string find function to prevent nil value errors
local function safeFind(text, pattern)
    if not text or not pattern or type(text) ~= "string" or type(pattern) ~= "string" then
        return false
    end
    return string.find(text, pattern) ~= nil
end

-- Cache for MRT data to avoid frequent global variable access
local mrtCache = {
    isLoaded = false,
    notes = {},
    lastUpdate = 0,
    updateInterval = 5, -- Update every 5 seconds
}

-- Cache for Kaze MRT Timer data
local kazeCache = {
    isLoaded = false,
    timers = {},
    lastUpdate = 0,
    updateInterval = 1, -- Update every 1 second for more responsive timing
}

-- Function to check if MRT is loaded and available
local function isMRTLoaded()
    if mrtCache.isLoaded then
        return true
    end

    -- Check for MRT global variables
    if _G.VMRT and _G.VMRT.Note then
        mrtCache.isLoaded = true
        return true
    end

    -- Alternative check for different MRT versions
    if _G.MRT and _G.MRT.Note then
        mrtCache.isLoaded = true
        return true
    end

    return false
end

-- Function to check if Kaze MRT Timers is loaded and available
local function isKazeLoaded()
    -- Use pcall to prevent errors from breaking the function
    local success, result = pcall(function()
        if kazeCache.isLoaded then
            return true
        end

        -- Check for WeakAuras and active Kaze MRT Timer auras
        if _G.WeakAuras and type(_G.WeakAuras.GetData) == "function" then
            local allAuras = _G.WeakAuras.GetData()
            if allAuras and type(allAuras) == "table" then
                for auraId, auraData in pairs(allAuras) do
                    if auraData and type(auraData) == "table" and
                       auraData.id and type(auraData.id) == "string" and auraData.id ~= "" then
                        local lowerName = string.lower(auraData.id)
                        -- Look for Kaze MRT Timer patterns
                        if (string.find(lowerName, "kaze", 1, true) and string.find(lowerName, "mrt", 1, true)) or
                           (string.find(lowerName, "kaze", 1, true) and string.find(lowerName, "timer", 1, true)) or
                           string.find(lowerName, "kazemrt", 1, true) then
                            kazeCache.isLoaded = true
                            return true
                        end
                    end
                end
            end
        end

        -- Check for WeakAuras saved variables
        if _G.WeakAurasSaved and type(_G.WeakAurasSaved) == "table" and
           _G.WeakAurasSaved.displays and type(_G.WeakAurasSaved.displays) == "table" then
            for displayName, displayData in pairs(_G.WeakAurasSaved.displays) do
                if displayName and type(displayName) == "string" and displayName ~= "" then
                    local lowerName = string.lower(displayName)
                    if (string.find(lowerName, "kaze", 1, true) and string.find(lowerName, "mrt", 1, true)) or
                       (string.find(lowerName, "kaze", 1, true) and string.find(lowerName, "timer", 1, true)) or
                       string.find(lowerName, "kazemrt", 1, true) then
                        kazeCache.isLoaded = true
                        return true
                    end
                end
            end
        end

        -- Check for common Kaze global variables
        if _G.KazeMRTTimers or _G.KAZE_MRT or _G.KazeTimers then
            kazeCache.isLoaded = true
            return true
        end

        -- Check if aura_env contains Kaze-related data
        if _G.aura_env and type(_G.aura_env) == "table" then
            for key, value in pairs(_G.aura_env) do
                if key and type(key) == "string" and key ~= "" then
                    local lowerKey = string.lower(key)
                    if string.find(lowerKey, "kaze", 1, true) or string.find(lowerKey, "mrt", 1, true) then
                        kazeCache.isLoaded = true
                        return true
                    end
                end
            end
        end

        return false
    end)

    if success then
        return result
    else
        -- If there was an error, assume Kaze is not loaded
        return false
    end
end

-- Function to get raw MRT notes
function MRTIntegration.getRawNotes()
    -- ALWAYS show this debug message to confirm our changes are loaded
    if _G.Aware and type(_G.Aware.displayMessage) == "function" then
        _G.Aware:displayMessage("DEBUG: getRawNotes() called - FRAMEWORK UPDATED!", "Purple", 3)
    end

    if not isMRTLoaded() then
        if _G.Aware and type(_G.Aware.displayMessage) == "function" then
            _G.Aware:displayMessage("DEBUG: MRT not loaded", "Red", 2)
        end
        return {}
    end

    local currentTime = GetTime and GetTime() or 0

    -- Only update cache periodically to avoid performance issues
    if currentTime - mrtCache.lastUpdate < mrtCache.updateInterval then
        return mrtCache.notes
    end

    mrtCache.lastUpdate = currentTime
    mrtCache.notes = {}

    -- Debug: Check what MRT globals exist
    if _G.Aware and type(_G.Aware.displayMessage) == "function" then
        _G.Aware:displayMessage("DEBUG: Checking MRT globals...", "Yellow", 2)
        _G.Aware:displayMessage("DEBUG: _G.VMRT exists: " .. tostring(_G.VMRT ~= nil), "Yellow", 2)
        if _G.VMRT then
            _G.Aware:displayMessage("DEBUG: _G.VMRT.Note exists: " .. tostring(_G.VMRT.Note ~= nil), "Yellow", 2)
        end
        _G.Aware:displayMessage("DEBUG: _G.MRT exists: " .. tostring(_G.MRT ~= nil), "Yellow", 2)
        if _G.MRT then
            _G.Aware:displayMessage("DEBUG: _G.MRT.Note exists: " .. tostring(_G.MRT.Note ~= nil), "Yellow", 2)
        end
    end

    -- Try VMRT first (most common)
    if _G.VMRT and _G.VMRT.Note then
        mrtCache.notes = {
            text1 = _G.VMRT.Note.Text1 or "",
            text2 = _G.VMRT.Note.Text2 or "",
            text3 = _G.VMRT.Note.Text3 or "",
            -- Some versions have additional text fields
            text4 = _G.VMRT.Note.Text4 or "",
            text5 = _G.VMRT.Note.Text5 or "",
        }

        -- Debug: Show what we found
        if _G.Aware and type(_G.Aware.displayMessage) == "function" then
            for key, value in pairs(mrtCache.notes) do
                if value and value ~= "" then
                    local preview = string.sub(value, 1, 50) .. (string.len(value) > 50 and "..." or "")
                    _G.Aware:displayMessage("DEBUG: " .. key .. ": " .. preview, "Cyan", 2)
                end
            end
        end
    -- Fallback to MRT
    elseif _G.MRT and _G.MRT.Note then
        mrtCache.notes = {
            text1 = _G.MRT.Note.Text1 or "",
            text2 = _G.MRT.Note.Text2 or "",
            text3 = _G.MRT.Note.Text3 or "",
        }

        -- Debug: Show what we found
        if _G.Aware and type(_G.Aware.displayMessage) == "function" then
            for key, value in pairs(mrtCache.notes) do
                if value and value ~= "" then
                    local preview = string.sub(value, 1, 50) .. (string.len(value) > 50 and "..." or "")
                    _G.Aware:displayMessage("DEBUG: " .. key .. ": " .. preview, "Cyan", 2)
                end
            end
        end
    else
        if _G.Aware and type(_G.Aware.displayMessage) == "function" then
            _G.Aware:displayMessage("DEBUG: No MRT Note structure found", "Red", 2)
        end
    end

    return mrtCache.notes
end

-- Function to get Kaze MRT Timer data
function MRTIntegration.getKazeTimers()
    -- Use pcall to prevent errors
    local success, result = pcall(function()
        if not isKazeLoaded() then
            return {}
        end

        local currentTime = (GetTime and GetTime()) or 0

        -- Only update cache periodically to avoid performance issues
        if kazeCache and kazeCache.lastUpdate and kazeCache.updateInterval and
           currentTime - kazeCache.lastUpdate < kazeCache.updateInterval then
            return kazeCache.timers or {}
        end

        -- Ensure kazeCache exists
        if not kazeCache then
            kazeCache = {
                isLoaded = false,
                timers = {},
                lastUpdate = 0,
                updateInterval = 1,
            }
        end

        kazeCache.lastUpdate = currentTime
        kazeCache.timers = {}

        -- Method 1: Try to get Kaze timer data from direct global variables
        if _G.KazeMRTTimers and type(_G.KazeMRTTimers) == "table" and
           _G.KazeMRTTimers.timers and type(_G.KazeMRTTimers.timers) == "table" then
            kazeCache.timers = _G.KazeMRTTimers.timers
            return kazeCache.timers
        elseif _G.KAZE_MRT and type(_G.KAZE_MRT) == "table" and
               _G.KAZE_MRT.timers and type(_G.KAZE_MRT.timers) == "table" then
            kazeCache.timers = _G.KAZE_MRT.timers
            return kazeCache.timers
        elseif _G.KazeTimers and type(_G.KazeTimers) == "table" then
            kazeCache.timers = _G.KazeTimers
            return kazeCache.timers
        end

        -- Method 2: Try to access WeakAura aura_env data
        if _G.WeakAuras and type(_G.WeakAuras.GetLoadedDisplays) == "function" then
            local loadedDisplays = _G.WeakAuras.GetLoadedDisplays()
            if loadedDisplays and type(loadedDisplays) == "table" then
                for displayId in pairs(loadedDisplays) do
                    if displayId and type(displayId) == "string" and displayId ~= "" then
                        local lowerName = string.lower(displayId)
                        if (string.find(lowerName, "kaze", 1, true) and string.find(lowerName, "mrt", 1, true)) or
                           (string.find(lowerName, "kaze", 1, true) and string.find(lowerName, "timer", 1, true)) then
                            -- Try to get the aura environment
                            if _G.WeakAuras.GetAuraEnvironment and type(_G.WeakAuras.GetAuraEnvironment) == "function" then
                                local auraEnv = _G.WeakAuras.GetAuraEnvironment(displayId)
                                if auraEnv and type(auraEnv) == "table" then
                                    -- Look for timer data in various possible locations
                                    if auraEnv.timers and type(auraEnv.timers) == "table" then
                                        kazeCache.timers = auraEnv.timers
                                        return kazeCache.timers
                                    elseif auraEnv.mrtTimers and type(auraEnv.mrtTimers) == "table" then
                                        kazeCache.timers = auraEnv.mrtTimers
                                        return kazeCache.timers
                                    elseif auraEnv.kazeTimers and type(auraEnv.kazeTimers) == "table" then
                                        kazeCache.timers = auraEnv.kazeTimers
                                        return kazeCache.timers
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Method 3: Parse from MRT notes using Kaze format patterns
        local mrtNotes = MRTIntegration.getRawNotes()
        if mrtNotes and type(mrtNotes) == "table" and next(mrtNotes) then
            local allText = ""
            for _, noteText in pairs(mrtNotes) do
                if noteText and type(noteText) == "string" and noteText ~= "" then
                    allText = allText .. " " .. noteText
                end
            end

            if allText and allText ~= "" then
                local parsedTimers = MRTIntegration.parseKazeFormat(allText)
                if parsedTimers and type(parsedTimers) == "table" then
                    kazeCache.timers = parsedTimers
                end
            end
        end

        -- Method 4: Try to access WeakAura data structures directly
        if _G.WeakAuras and type(_G.WeakAuras.GetData) == "function" then
            local allAuras = _G.WeakAuras.GetData()
            if allAuras and type(allAuras) == "table" then
                for _, auraData in pairs(allAuras) do
                    if auraData and type(auraData) == "table" and
                       auraData.id and type(auraData.id) == "string" and auraData.id ~= "" then
                        local lowerName = string.lower(auraData.id)
                        if (string.find(lowerName, "kaze", 1, true) and string.find(lowerName, "mrt", 1, true)) or
                           (string.find(lowerName, "kaze", 1, true) and string.find(lowerName, "timer", 1, true)) then
                            -- Try various data locations in the aura
                            if auraData.config and type(auraData.config) == "table" then
                                if auraData.config.customText and type(auraData.config.customText) == "string" then
                                    local parsedTimers = MRTIntegration.parseKazeFormat(auraData.config.customText)
                                    if parsedTimers and type(parsedTimers) == "table" and #parsedTimers > 0 then
                                        kazeCache.timers = parsedTimers
                                        return kazeCache.timers
                                    end
                                end
                                if auraData.config.text and type(auraData.config.text) == "string" then
                                    local parsedTimers = MRTIntegration.parseKazeFormat(auraData.config.text)
                                    if parsedTimers and type(parsedTimers) == "table" and #parsedTimers > 0 then
                                        kazeCache.timers = parsedTimers
                                        return kazeCache.timers
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            end
        end

        return kazeCache.timers or {}
    end)

    if success and result then
        return result
    else
        -- If there was an error, return empty table
        return {}
    end
end

-- Function to parse Kaze MRT Timer format
function MRTIntegration.parseKazeFormat(text)
    -- Use pcall to prevent errors
    local success, result = pcall(function()
        local timers = {}

        if not text or type(text) ~= "string" or text == "" then
            return timers
        end

    -- Kaze MRT Timers supports multiple formats:
    -- 1. {time:1:30,spell:31884,text:Wings}
    -- 2. {time:90,spell:642,text:Bubble}
    -- 3. |cFFFFFF00{time:2:15}|r Wings
    -- 4. {time:1:30} Wings
    -- 5. 1:30 Wings (simple format)

    -- Parse complex Kaze-style timer entries with spell IDs
    for entry in string.gmatch(text, "{[^}]*time[^}]*}") do
        local timer = {}

        -- Extract time (supports both MM:SS and SS formats)
        local minutes, seconds = string.match(entry, "time:(%d+):(%d+)")
        if minutes and seconds then
            timer.time = (tonumber(minutes) * 60) + tonumber(seconds)
        else
            local totalSeconds = string.match(entry, "time:(%d+)")
            if totalSeconds then
                timer.time = tonumber(totalSeconds)
            end
        end

        -- Extract spell ID
        local spellId = string.match(entry, "spell:(%d+)")
        if spellId then
            timer.spellId = tonumber(spellId)
        end

        -- Extract text/description
        local description = string.match(entry, "text:([^,}]+)")
        if description then
            timer.text = description
        end

        -- Only add timer if we have at least time and either spell or text
        if timer.time and (timer.spellId or timer.text) then
            table.insert(timers, timer)
        end
    end

    -- Parse colored text formats like "|cFFFFFF00{time:2:15}|r Wings"
    for timeStr, description in string.gmatch(text, "|c%w*{time:([^}]+)}|r%s*([^\n\r]+)") do
        local timer = {}

        -- Parse time
        local minutes, seconds = string.match(timeStr, "(%d+):(%d+)")
        if minutes and seconds then
            timer.time = (tonumber(minutes) * 60) + tonumber(seconds)
        else
            local totalSeconds = tonumber(timeStr)
            if totalSeconds then
                timer.time = totalSeconds
            end
        end

        if description then
            timer.text = string.trim and string.trim(description) or description
            -- Try to extract spell ID from description if it contains spell references
            local spellId = string.match(description, "spell:(%d+)")
            if spellId then
                timer.spellId = tonumber(spellId)
            end
        end

        if timer.time and timer.text then
            table.insert(timers, timer)
        end
    end

    -- Parse simple {time:X:XX} followed by text on same line
    for timeStr, description in string.gmatch(text, "{time:([^}]+)}%s*([^\n\r{]+)") do
        local timer = {}

        -- Parse time
        local minutes, seconds = string.match(timeStr, "(%d+):(%d+)")
        if minutes and seconds then
            timer.time = (tonumber(minutes) * 60) + tonumber(seconds)
        else
            local totalSeconds = tonumber(timeStr)
            if totalSeconds then
                timer.time = totalSeconds
            end
        end

        if description then
            timer.text = string.trim and string.trim(description) or description
            -- Try to extract spell ID from description
            local spellId = string.match(description, "spell:(%d+)")
            if spellId then
                timer.spellId = tonumber(spellId)
            end
        end

        if timer.time and timer.text then
            -- Check if this timer already exists to avoid duplicates
            local exists = false
            for _, existingTimer in ipairs(timers) do
                if existingTimer.time == timer.time and existingTimer.text == timer.text then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(timers, timer)
            end
        end
    end

    -- Parse very simple format: "1:30 Wings" or "90 Wings"
    for timeStr, description in string.gmatch(text, "(%d+:?%d*)%s+([A-Za-z][^\n\r{]+)") do
        local timer = {}

        -- Parse time
        local minutes, seconds = string.match(timeStr, "(%d+):(%d+)")
        if minutes and seconds then
            timer.time = (tonumber(minutes) * 60) + tonumber(seconds)
        else
            local totalSeconds = tonumber(timeStr)
            if totalSeconds and totalSeconds > 0 and totalSeconds < 3600 then -- Reasonable time range
                timer.time = totalSeconds
            end
        end

        if description and timer.time then
            timer.text = string.trim and string.trim(description) or description
            -- Only add if description looks like an ability name (not just random text)
            if string.len(timer.text) > 2 and string.len(timer.text) < 50 then
                -- Check if this timer already exists to avoid duplicates
                local exists = false
                for _, existingTimer in ipairs(timers) do
                    if existingTimer.time == timer.time and existingTimer.text == timer.text then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(timers, timer)
                end
            end
        end
    end

        -- Post-process timers to add spell IDs based on text descriptions
        for _, timer in ipairs(timers) do
            if timer and type(timer) == "table" and timer.text and not timer.spellId then
                timer.spellId = MRTIntegration.getSpellIdFromText(timer.text)
            end
        end

        return timers
    end)

    if success and result then
        return result
    else
        -- If there was an error, return empty table
        return {}
    end
end

-- Function to map common ability names to spell IDs
function MRTIntegration.getSpellIdFromText(text)
    if not text or type(text) ~= "string" then
        return nil
    end

    local lowerText = string.lower(text)

    -- Holy Paladin spell mappings
    local spellMappings = {
        -- Avenging Wrath / Wings
        ["wings"] = 31884,
        ["avenging wrath"] = 31884,
        ["avengingwrath"] = 31884,
        ["aw"] = 31884,

        -- Divine Shield / Bubble
        ["bubble"] = 642,
        ["divine shield"] = 642,
        ["divineshield"] = 642,
        ["ds"] = 642,

        -- Aura Mastery
        ["aura mastery"] = 31821,
        ["auramastery"] = 31821,
        ["mastery"] = 31821,
        ["am"] = 31821,

        -- Tyr's Deliverance
        ["tyr"] = 200652,
        ["tyrs"] = 200652,
        ["tyr's deliverance"] = 200652,
        ["tyrdeliverance"] = 200652,
        ["deliverance"] = 200652,

        -- Divine Toll
        ["divine toll"] = 375576,
        ["divinetoll"] = 375576,
        ["toll"] = 375576,
        ["dt"] = 375576,

        -- Lay on Hands
        ["lay on hands"] = 633,
        ["layonhands"] = 633,
        ["loh"] = 633,

        -- Add more mappings for other classes as needed
        -- Death Knight
        ["anti-magic shell"] = 48707,
        ["ams"] = 48707,
        ["death grip"] = 49576,
        ["grip"] = 49576,

        -- Warrior
        ["shield wall"] = 871,
        ["wall"] = 871,
        ["rallying cry"] = 97462,
        ["rally"] = 97462,

        -- Priest
        ["guardian spirit"] = 47788,
        ["gs"] = 47788,
        ["divine hymn"] = 64843,
        ["hymn"] = 64843,
    }

    -- Check for exact matches first
    if spellMappings[lowerText] then
        return spellMappings[lowerText]
    end

    -- Check for partial matches
    for keyword, spellId in pairs(spellMappings) do
        if string.find(lowerText, keyword) then
            return spellId
        end
    end

    return nil
end

-- Helper function to safely check if a spell has timing instructions (supports both MRT and Kaze timers)
function MRTIntegration.hasSpellTiming(instructions, spellId, currentTime)
    -- Use pcall to prevent errors
    local success, result = pcall(function()
        -- Safety checks for all parameters
        if not instructions or type(instructions) ~= "table" then
            return false
        end

        if not spellId or (type(spellId) ~= "string" and type(spellId) ~= "number") then
            return false
        end

        -- Convert spellId to string for consistency
        spellId = tostring(spellId)
        if spellId == "" then
            return false
        end

        -- Ensure currentTime is a valid number (default to 0 if invalid)
        if not currentTime or type(currentTime) ~= "number" or currentTime < 0 then
            currentTime = 0
        end

        -- First check Kaze timers if available (prioritize Kaze over traditional MRT)
        if instructions.kazeTimers and type(instructions.kazeTimers) == "table" and #instructions.kazeTimers > 0 then
            local currentTimeSeconds = currentTime / 1000 -- Convert to seconds
            local spellIdNum = tonumber(spellId)

            for _, timer in ipairs(instructions.kazeTimers) do
                if timer and type(timer) == "table" and
                   timer.spellId and type(timer.spellId) == "number" and
                   timer.time and type(timer.time) == "number" then
                    if timer.spellId == spellIdNum then
                        -- Check if current time is within timing window (±2 seconds)
                        if math.abs(currentTimeSeconds - timer.time) < 2 then
                            return true
                        end
                    end
                end
            end

            -- If we have Kaze timers but no match, don't fall back to traditional MRT
            -- This ensures Kaze takes priority when available
            return false
        end

        -- Fallback to traditional MRT spell timings if no Kaze timers
        if not instructions.spellTimings or type(instructions.spellTimings) ~= "table" then
            return false
        end

        -- Check if this spell has timing instructions
        local spellTimings = instructions.spellTimings[spellId]
        if not spellTimings or type(spellTimings) ~= "table" or #spellTimings == 0 then
            return false
        end

        -- Check if current time is within any of the specified timings (±2 seconds)
        for _, timing in ipairs(spellTimings) do
            if timing and type(timing) == "number" and timing >= 0 then
                if math.abs(currentTime - (timing * 1000)) < 2000 then
                    return true
                end
            end
        end

        return false
    end)

    if success then
        return result
    else
        -- If there was an error, return false
        return false
    end
end

-- Helper function to check if a spell is mentioned in MRT but has no specific timing
function MRTIntegration.hasSpellWithoutTiming(instructions, spellId)
    -- Safety checks
    if not instructions or type(instructions) ~= "table" then
        return false
    end

    if not spellId or type(spellId) ~= "string" or spellId == "" then
        return false
    end

    -- Check if spellTimings exists and is a table
    if not instructions.spellTimings or type(instructions.spellTimings) ~= "table" then
        return true -- If no spellTimings table, assume no specific timing
    end

    -- Check if this spell has timing instructions
    local spellTimings = instructions.spellTimings[spellId]
    return not spellTimings or type(spellTimings) ~= "table" or #spellTimings == 0
end

-- Function to parse MRT notes for specific class/spec instructions
function MRTIntegration.parseForClass(className, specName)
    -- Debug output
    if _G.Aware and type(_G.Aware.displayMessage) == "function" then
        _G.Aware:displayMessage("DEBUG: MRTIntegration.parseForClass called for " .. tostring(className) .. " " .. tostring(specName), "Purple", 2)
    end

    local notes = MRTIntegration.getRawNotes()
    local kazeTimers = MRTIntegration.getKazeTimers()

    if _G.Aware and type(_G.Aware.displayMessage) == "function" then
        local noteCount = 0
        if notes and type(notes) == "table" then
            for _ in pairs(notes) do noteCount = noteCount + 1 end
        end
        _G.Aware:displayMessage("DEBUG: Found " .. tostring(noteCount) .. " MRT notes", "Purple", 2)

        local kazeCount = 0
        if kazeTimers and type(kazeTimers) == "table" then
            kazeCount = #kazeTimers
        end
        _G.Aware:displayMessage("DEBUG: Found " .. tostring(kazeCount) .. " Kaze timers", "Purple", 2)
    end

    local instructions = {
        cooldownTimings = {},
        priorityTargets = {},
        specialPhases = {},
        customInstructions = {},
        raidHealing = false,
        kazeTimers = kazeTimers, -- Add Kaze timer data
        -- Holy Paladin
        useLayOnHands = false,
        useWings = false,
        useBubble = false,
        useAuraMastery = false,
        useTyrDeliverance = false,
        useDivineToll = false,
        -- Holy Priest
        useGuardianSpirit = false,
        useApotheosis = false,
        useDivineHymn = false,
        useSalvation = false,
        useVoidShift = false,
        -- Discipline Priest
        useBarrier = false,
        useRapture = false,
        useEvangelism = false,
        -- Restoration Druid
        useTranquility = false,
        useIncarnation = false,
        useConvoke = false,
        useFlourish = false,
        useIronbark = false,
        -- Restoration Shaman
        useSpiritLink = false,
        useHealingTide = false,
        useAscendance = false,
        useAncestralGuidance = false,
        -- Mistweaver Monk
        useRevival = false,
        useYulon = false,
        useLifeCocoon = false,
        -- Preservation Evoker
        useRewind = false,
        useTimeDilation = false,
        useStasis = false,
    }
    
    if not notes or not next(notes) then
        return MRTIntegration.validateInstructions(instructions)
    end
    
    -- Combine all note texts for parsing
    local allText = ""
    for _, noteText in pairs(notes) do
        if noteText and noteText ~= "" and type(noteText) == "string" then
            allText = allText .. " " .. string.lower(noteText)
        end
    end

    -- Debug: Show what text we're parsing
    if _G.Aware and type(_G.Aware.displayMessage) == "function" then
        if allText and allText ~= "" then
            local textPreview = string.sub(allText, 1, 300) .. (string.len(allText) > 300 and "..." or "")
            _G.Aware:displayMessage("DEBUG: Parsing text: " .. textPreview, "Purple", 2)
            _G.Aware:displayMessage("DEBUG: Total text length: " .. string.len(allText), "Purple", 2)

            -- Show the raw notes before combining
            _G.Aware:displayMessage("DEBUG: === RAW NOTES CONTENT ===", "Cyan", 2)
            for key, noteText in pairs(notes) do
                if noteText and noteText ~= "" and type(noteText) == "string" then
                    local rawPreview = string.sub(noteText, 1, 200) .. (string.len(noteText) > 200 and "..." or "")
                    _G.Aware:displayMessage("DEBUG: " .. key .. ": " .. rawPreview, "Cyan", 2)
                end
            end
            _G.Aware:displayMessage("DEBUG: === END RAW NOTES ===", "Cyan", 2)

            -- Check for common MRT patterns
            local timePatterns = 0
            for _ in string.gmatch(allText, "{time:[^}]+}") do
                timePatterns = timePatterns + 1
            end
            _G.Aware:displayMessage("DEBUG: Found " .. timePatterns .. " time patterns", "Purple", 2)

            local spellPatterns = 0
            for _ in string.gmatch(allText, "{spell:[^}]+}") do
                spellPatterns = spellPatterns + 1
            end
            _G.Aware:displayMessage("DEBUG: Found " .. spellPatterns .. " spell patterns", "Purple", 2)
        else
            _G.Aware:displayMessage("DEBUG: No text to parse", "Purple", 2)
        end
    end

    -- Ensure allText is never nil and is a valid string
    if not allText or allText == "" or type(allText) ~= "string" then
        return MRTIntegration.validateInstructions(instructions)
    end
    
    -- Parse MRT time format with spell associations: {time:X:XX}...{spell:XXXXX}
    -- This creates a mapping of spell IDs to their specific timings
    instructions.spellTimings = {} -- New field to store spell-specific timings

    -- Find all time entries with their associated spells
    for timeEntry in string.gmatch(allText, "{time:[^}]+}.-{spell:[^}]+}") do
        -- Extract timing from this entry - handle formats like {time:0:04|0:04} or {time:1:30}
        local minutes, seconds = string.match(timeEntry, "{time:(%d+):(%d+)")
        if minutes and seconds then
            local mins = tonumber(minutes)
            local secs = tonumber(seconds)
            if mins and secs and mins >= 0 and secs >= 0 and secs < 60 then
                local totalSeconds = (mins * 60) + secs

                -- Extract spell ID from this entry
                local spellId = string.match(timeEntry, "{spell:(%d+)")
                if spellId and type(spellId) == "string" and spellId ~= "" then
                    -- Store spell-specific timing with additional safety checks
                    if not instructions.spellTimings then
                        instructions.spellTimings = {}
                    end
                    if not instructions.spellTimings[spellId] then
                        instructions.spellTimings[spellId] = {}
                    end
                    if type(instructions.spellTimings[spellId]) == "table" then
                        table.insert(instructions.spellTimings[spellId], totalSeconds)
                    end

                    -- Also add to general cooldown timings for backward compatibility
                    if type(instructions.cooldownTimings) == "table" then
                        table.insert(instructions.cooldownTimings, totalSeconds)
                    end
                end
            end
        end
    end

    -- Parse cooldown timings (e.g., "wings at 30s", "cd at 1:30", "use at 90")
    for timing in string.gmatch(allText, "at%s+(%d+)s?") do
        local seconds = tonumber(timing)
        if seconds and seconds > 0 then
            table.insert(instructions.cooldownTimings, seconds)
        end
    end

    -- Parse time formats like "1:30" or "2:15" (fallback for plain text)
    for minutes, seconds in string.gmatch(allText, "(%d+):(%d+)") do
        local mins = tonumber(minutes)
        local secs = tonumber(seconds)
        if mins and secs and mins >= 0 and secs >= 0 and secs < 60 then
            local totalSeconds = (mins * 60) + secs
            -- Only add if not already added by {time:X:XX} parsing
            local alreadyExists = false
            for _, existingTiming in ipairs(instructions.cooldownTimings) do
                if existingTiming == totalSeconds then
                    alreadyExists = true
                    break
                end
            end
            if not alreadyExists then
                table.insert(instructions.cooldownTimings, totalSeconds)
            end
        end
    end
    
    -- Parse priority targets (e.g., "heal tank", "focus healer", "priority dps")
    for target in string.gmatch(allText, "heal%s+([%w]+)") do
        table.insert(instructions.priorityTargets, target)
    end
    
    for target in string.gmatch(allText, "priority%s+([%w]+)") do
        table.insert(instructions.priorityTargets, target)
    end
    
    for target in string.gmatch(allText, "focus%s+([%w]+)") do
        table.insert(instructions.priorityTargets, target)
    end
    
    -- Parse phase information (e.g., "phase 2", "p3", "transition")
    for phase in string.gmatch(allText, "phase%s+(%d+)") do
        table.insert(instructions.specialPhases, tonumber(phase))
    end
    
    for phase in string.gmatch(allText, "p(%d+)") do
        table.insert(instructions.specialPhases, tonumber(phase))
    end
    
    -- Class-specific parsing
    if className and specName then
        local classSpec = string.lower(className .. " " .. specName)
        
        -- Look for class-specific instructions
        if safeFind(allText, classSpec) then
            -- Extract the line containing class-specific instructions
            for line in string.gmatch(allText, "[^\r\n]*" .. classSpec .. "[^\r\n]*") do
                table.insert(instructions.customInstructions, line)
            end
        end
        
        -- Look for spec-specific keywords and spell IDs
        if specName == "Holy" then
            if className == "Paladin" then
                -- Holy Paladin specific parsing - both keywords and spell IDs
                -- Lay on Hands: 633
                if safeFind(allText, "lay.*on.*hands") or safeFind(allText, "loh") or
                   safeFind(allText, "{spell:633}") then
                    instructions.useLayOnHands = true
                end

                -- Avenging Wrath: 31884
                if safeFind(allText, "wings") or safeFind(allText, "avenging.*wrath") or
                   safeFind(allText, "{spell:31884}") then
                    instructions.useWings = true
                    if _G.Aware and type(_G.Aware.displayMessage) == "function" then
                        _G.Aware:displayMessage("DEBUG: Found Wings instruction in MRT notes", "Green", 2)
                    end
                end

                -- Divine Shield: 642
                if safeFind(allText, "bubble") or safeFind(allText, "divine.*shield") or
                   safeFind(allText, "{spell:642}") then
                    instructions.useBubble = true
                end

                -- Aura Mastery: 31821
                if safeFind(allText, "aura.*mastery") or safeFind(allText, "mastery") or
                   safeFind(allText, "{spell:31821}") then
                    instructions.useAuraMastery = true
                end

                -- Tyr's Deliverance: 200652
                if safeFind(allText, "tyr") or safeFind(allText, "deliverance") or
                   safeFind(allText, "{spell:200652}") then
                    instructions.useTyrDeliverance = true
                end

                -- Divine Toll: 375576
                if safeFind(allText, "divine.*toll") or safeFind(allText, "toll") or
                   safeFind(allText, "{spell:375576}") then
                    instructions.useDivineToll = true
                end
            elseif className == "Priest" then
                -- Holy Priest specific parsing - both keywords and spell IDs
                -- Guardian Spirit: 47788
                if safeFind(allText, "guardian.*spirit") or safeFind(allText, "gs") or
                   safeFind(allText, "{spell:47788}") then
                    instructions.useGuardianSpirit = true
                end

                -- Apotheosis: 200183
                if safeFind(allText, "apotheosis") or safeFind(allText, "apothe") or
                   safeFind(allText, "{spell:200183}") then
                    instructions.useApotheosis = true
                end

                -- Divine Hymn: 64843
                if safeFind(allText, "divine.*hymn") or safeFind(allText, "hymn") or
                   safeFind(allText, "{spell:64843}") then
                    instructions.useDivineHymn = true
                end

                -- Holy Word: Salvation: 265202
                if safeFind(allText, "salvation") or safeFind(allText, "holy.*word.*salvation") or
                   safeFind(allText, "{spell:265202}") then
                    instructions.useSalvation = true
                end

                -- Void Shift: 108968
                if safeFind(allText, "void.*shift") or safeFind(allText, "voidshift") or
                   safeFind(allText, "{spell:108968}") then
                    instructions.useVoidShift = true
                end
            end
        elseif specName == "Discipline" and className == "Priest" then
            -- Discipline Priest specific parsing - both keywords and spell IDs
            -- Power Word: Barrier: 62618
            if safeFind(allText, "barrier") or safeFind(allText, "power.*word.*barrier") or
               safeFind(allText, "{spell:62618}") then
                instructions.useBarrier = true
            end

            -- Rapture: 47536
            if safeFind(allText, "rapture") or
               safeFind(allText, "{spell:47536}") then
                instructions.useRapture = true
            end

            -- Evangelism: 246287
            if safeFind(allText, "evangelism") or safeFind(allText, "evang") or
               safeFind(allText, "{spell:246287}") then
                instructions.useEvangelism = true
            end
        elseif specName == "Restoration" then
            if className == "Druid" then
                -- Restoration Druid specific parsing - both keywords and spell IDs
                -- Tranquility: 740
                if safeFind(allText, "tranquility") or safeFind(allText, "tranq") or
                   safeFind(allText, "{spell:740}") then
                    instructions.useTranquility = true
                end

                -- Incarnation Tree of Life: 33891
                if safeFind(allText, "incarnation") or safeFind(allText, "tree.*form") or safeFind(allText, "tree") or
                   safeFind(allText, "{spell:33891}") then
                    instructions.useIncarnation = true
                end

                -- Convoke the Spirits: 391528
                if safeFind(allText, "convoke") or safeFind(allText, "convoke.*spirits") or
                   safeFind(allText, "{spell:391528}") then
                    instructions.useConvoke = true
                end

                -- Flourish: 197721
                if safeFind(allText, "flourish") or
                   safeFind(allText, "{spell:197721}") then
                    instructions.useFlourish = true
                end

                -- Ironbark: 102342
                if safeFind(allText, "ironbark") or
                   safeFind(allText, "{spell:102342}") then
                    instructions.useIronbark = true
                end
            elseif className == "Shaman" then
                -- Restoration Shaman specific parsing - both keywords and spell IDs
                -- Spirit Link Totem: 98008
                if safeFind(allText, "spirit.*link") or safeFind(allText, "slt") or
                   safeFind(allText, "{spell:98008}") then
                    instructions.useSpiritLink = true
                end

                -- Healing Tide Totem: 108280
                if safeFind(allText, "healing.*tide") or safeFind(allText, "htt") or
                   safeFind(allText, "{spell:108280}") then
                    instructions.useHealingTide = true
                end

                -- Ascendance: 114052
                if safeFind(allText, "ascendance") or safeFind(allText, "asc") or
                   safeFind(allText, "{spell:114052}") then
                    instructions.useAscendance = true
                end

                -- Ancestral Guidance: 108281
                if safeFind(allText, "ancestral.*guidance") or safeFind(allText, "ag") or
                   safeFind(allText, "{spell:108281}") then
                    instructions.useAncestralGuidance = true
                end
            end
        elseif specName == "Mistweaver" and className == "Monk" then
            -- Mistweaver Monk specific parsing - both keywords and spell IDs
            -- Revival: 115310
            if safeFind(allText, "revival") or
               safeFind(allText, "{spell:115310}") then
                instructions.useRevival = true
            end

            -- Invoke Yu'lon: 322118
            if safeFind(allText, "yu.*lon") or safeFind(allText, "yulon") or
               safeFind(allText, "{spell:322118}") then
                instructions.useYulon = true
            end

            -- Life Cocoon: 116849
            if safeFind(allText, "life.*cocoon") or safeFind(allText, "cocoon") or
               safeFind(allText, "{spell:116849}") then
                instructions.useLifeCocoon = true
            end
        elseif specName == "Preservation" and className == "Evoker" then
            -- Preservation Evoker specific parsing - both keywords and spell IDs
            -- Rewind: 363534
            if safeFind(allText, "rewind") or
               safeFind(allText, "{spell:363534}") then
                instructions.useRewind = true
            end

            -- Time Dilation: 357170
            if safeFind(allText, "time.*dilation") or safeFind(allText, "dilation") or
               safeFind(allText, "{spell:357170}") then
                instructions.useTimeDilation = true
            end

            -- Stasis: 370537
            if safeFind(allText, "stasis") or
               safeFind(allText, "{spell:370537}") then
                instructions.useStasis = true
            end
        end
    end

    -- Debug: Show final instructions
    if _G.Aware and type(_G.Aware.displayMessage) == "function" then
        _G.Aware:displayMessage("DEBUG: Final instructions - useWings: " .. tostring(instructions.useWings), "Green", 2)
        if instructions.spellTimings and instructions.spellTimings["31884"] then
            _G.Aware:displayMessage("DEBUG: Wings timings found: " .. #instructions.spellTimings["31884"], "Green", 2)
        end
    end

    -- Validate and sanitize the instructions before returning
    return MRTIntegration.validateInstructions(instructions)
end

-- Function to get encounter-specific notes
function MRTIntegration.getEncounterNotes()
    if not isMRTLoaded() then
        return nil
    end
    
    -- Try to get current encounter information
    local encounterID = 0
    local encounterName = ""
    
    -- Check if we're in an encounter (safely check if function exists)
    if IsEncounterInProgress and IsEncounterInProgress() then
        -- This would need more specific logic to get encounter details
        -- For now, just return general notes
        return MRTIntegration.getRawNotes()
    end
    
    return nil
end

-- Function to check if specific MRT features are available
function MRTIntegration.hasFeature(featureName)
    if not isMRTLoaded() then
        return false
    end
    
    local features = {
        notes = _G.VMRT and _G.VMRT.Note,
        reminders = _G.VMRT and _G.VMRT.Reminder,
        raidcooldowns = _G.VMRT and _G.VMRT.RaidCooldowns,
        visualnotes = _G.VMRT and _G.VMRT.VisualNote,
    }
    
    return features[featureName] or false
end

-- Function to validate and sanitize instructions object
function MRTIntegration.validateInstructions(instructions)
    if not instructions or type(instructions) ~= "table" then
        instructions = {}
    end

    -- Ensure all required fields exist and are the correct type
    local requiredArrayFields = {"cooldownTimings", "priorityTargets", "specialPhases", "customInstructions"}
    for _, field in ipairs(requiredArrayFields) do
        if not instructions[field] or type(instructions[field]) ~= "table" then
            instructions[field] = {}
        end
    end

    -- Ensure spellTimings exists and is a table
    if not instructions.spellTimings or type(instructions.spellTimings) ~= "table" then
        instructions.spellTimings = {}
    end

    -- Validate each spell timing entry
    for spellId, timings in pairs(instructions.spellTimings) do
        if type(timings) ~= "table" then
            instructions.spellTimings[spellId] = {}
        else
            -- Validate each timing value
            local validTimings = {}
            for _, timing in ipairs(timings) do
                if type(timing) == "number" and timing >= 0 then
                    table.insert(validTimings, timing)
                end
            end
            instructions.spellTimings[spellId] = validTimings
        end
    end

    return instructions
end

-- Function to get upcoming Kaze timers for display
function MRTIntegration.getUpcomingKazeTimers(instructions, currentTime, lookAheadSeconds)
    if not instructions or not instructions.kazeTimers or not currentTime then
        return {}
    end

    lookAheadSeconds = lookAheadSeconds or 30 -- Default to 30 seconds ahead
    local currentTimeSeconds = currentTime / 1000
    local upcomingTimers = {}

    for _, timer in ipairs(instructions.kazeTimers) do
        if timer.time then
            local timeUntil = timer.time - currentTimeSeconds
            if timeUntil > 0 and timeUntil <= lookAheadSeconds then
                table.insert(upcomingTimers, {
                    timeUntil = timeUntil,
                    spellId = timer.spellId,
                    text = timer.text,
                    originalTimer = timer
                })
            end
        end
    end

    -- Sort by time until
    table.sort(upcomingTimers, function(a, b)
        return a.timeUntil < b.timeUntil
    end)

    return upcomingTimers
end

-- Function to check if Kaze timers are being used
function MRTIntegration.isUsingKazeTimers()
    return isKazeLoaded()
end

-- Debug function to test Kaze integration
function MRTIntegration.debugKazeIntegration()
    -- Use pcall to prevent errors
    local success, result = pcall(function()
        local debug = {
            kazeLoaded = false,
            weakAurasLoaded = _G.WeakAuras ~= nil,
            mrtLoaded = false,
            timers = {},
            globals = {},
            weakAuraDisplays = {}
        }

        -- Safely check if Kaze is loaded
        local kazeSuccess, kazeLoaded = pcall(isKazeLoaded)
        debug.kazeLoaded = kazeSuccess and kazeLoaded or false

        -- Safely check if MRT is loaded
        local mrtSuccess, mrtLoaded = pcall(isMRTLoaded)
        debug.mrtLoaded = mrtSuccess and mrtLoaded or false

        -- Check for various global variables
        debug.globals.KazeMRTTimers = _G.KazeMRTTimers ~= nil
        debug.globals.KAZE_MRT = _G.KAZE_MRT ~= nil
        debug.globals.KazeTimers = _G.KazeTimers ~= nil
        debug.globals.aura_env = _G.aura_env ~= nil

        -- Get timer data
        if debug.kazeLoaded then
            local timerSuccess, timers = pcall(MRTIntegration.getKazeTimers)
            debug.timers = timerSuccess and timers or {}
        end

        -- Check WeakAura displays
        if _G.WeakAuras and type(_G.WeakAuras.GetData) == "function" then
            local auraSuccess, allAuras = pcall(_G.WeakAuras.GetData)
            if auraSuccess and allAuras and type(allAuras) == "table" then
                for _, auraData in pairs(allAuras) do
                    if auraData and type(auraData) == "table" and
                       auraData.id and type(auraData.id) == "string" and auraData.id ~= "" then
                        local lowerName = string.lower(auraData.id)
                        if string.find(lowerName, "kaze", 1, true) or string.find(lowerName, "mrt", 1, true) then
                            table.insert(debug.weakAuraDisplays, auraData.id)
                        end
                    end
                end
            end
        end

        return debug
    end)

    if success and result then
        return result
    else
        -- Return safe default if there was an error
        return {
            kazeLoaded = false,
            weakAurasLoaded = false,
            mrtLoaded = false,
            timers = {},
            globals = {},
            weakAuraDisplays = {},
            error = "Debug function failed"
        }
    end
end

-- Export the module
if MakuluFramework then
    MakuluFramework.MRTIntegration = MRTIntegration
end

return MRTIntegration
