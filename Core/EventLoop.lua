local Tinkr, MakuluFramework = ...

local STOPPED                = 0;
local RUNNING                = 1;
local REQUESTED_STOP         = 2;

local currentCallback        = nil;
local currentDraw            = nil
local loopStatus             = STOPPED;

local GetNetStats            = GetNetStats
local SetCVar                = SetCVar

local Draw                   = Tinkr.Util.Draw:New()

Draw:Sync(function(draw)
    if not currentDraw then return end

    return currentDraw(draw)
end)

local success, message
local time = _G.debugprofilestop
local delay = 0.1

local After = C_Timer.After

local slow = false

local function tuneSQW()
    local _, _, homeLatency, worldLatency = GetNetStats()
    local TargetSQW = (worldLatency + 200)
    if SQW ~= TargetSQW then
        SetCVar("SpellQueueWindow", TargetSQW)
        MakuluFramework.SQW = TargetSQW
    end
end

local function regenDelay()
    if not slow then
        delay = math.random(800, 1400) / 10000
    end
    tuneSQW()

    return After(20, regenDelay)
end

regenDelay()

local additional_hooks = nil

local function register_additional(hook)
    if not additional_hooks then
        additional_hooks = {}
    end

    table.insert(additional_hooks, hook)
end

local function callbackLoop()
    if loopStatus == REQUESTED_STOP then
        loopStatus = STOPPED;
        return;
    end

    -- local start = time()
    local skip = MakuluFramework.start()

    if additional_hooks then
        for _, value in ipairs(additional_hooks) do
            success, message = pcall(value)
            if not success then
                print('Error with script: ' .. message)
            end
        end
    end

    if not skip then
        --  currentCallback()
        ---@diagnostic disable-next-line: need-check-nil, param-type-mismatch only called if curentCallback is nil
        success, message = pcall(currentCallback)
        -- local took = time() - start
        -- print('Execution took: ' .. took)
        if not success then
            print('Error with script: ' .. message)
        end
    end

    return After(delay, callbackLoop)
end

local function loadAndStartLoop()
    currentCallback = MakuluFramework.callback
    if currentCallback == nil then
        print('Callback is nil somehow')
        return
    end

    currentDraw = MakuluFramework.draw

    if currentDraw then
        Draw:Enable()
    else
        Draw:Disable()
    end

    loopStatus = RUNNING;
    callbackLoop()
end

local function stopRotation()
    if loopStatus ~= RUNNING then return end

    loopStatus = REQUESTED_STOP;
end

local function restartRotation()
    return loadAndStartLoop()
end

local function toggleRunning()
    if loopStatus == RUNNING then
        print("|cFFbb44f0Clipper | |cFFFF0000Disabled")
        return stopRotation()
    end

    print("|cFFbb44f0Clipper | |cFF00FF00Enabled")
    return restartRotation()
end

local function slowMode()
    delay = 1
    slow = true

    print('Slow mode enabled')
end

local function speedMode()
    delay = 0.1
    slow = false

    print('Normal mode enabled')
end

MakuluFramework.Commands.register('toggle', toggleRunning, 'Toggle rotation on and off', {})
MakuluFramework.Commands.register('slow', slowMode, 'Slow mode', {})
MakuluFramework.Commands.register('normal', speedMode, 'Normal mode', {})

MakuluFramework.loadAndStartLoop = loadAndStartLoop;
MakuluFramework.stopRotation = stopRotation;
MakuluFramework.newHook = register_additional
