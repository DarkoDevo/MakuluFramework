local _, MakuluFramework = ...
MakuluFramework = MakuluFramework or _G.MakuluFramwork

local FRAME_NAME = "MAKULU_FRAME"
local frame = nil

local function getFrame()
    if frame then return frame end

    frame = _G[FRAME_NAME] or CreateFrame("Frame", FRAME_NAME)
    _G[FRAME_NAME] = frame
    frame:UnregisterAllEvents()
    frame:SetScript("OnEvent", nil)

    return frame
end

MakuluFramework.Frame = {
    get = getFrame
}
