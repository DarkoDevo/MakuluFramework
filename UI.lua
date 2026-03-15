local _, MakuluFramework   = ...
MakuluFramework            = MakuluFramework or _G.MakuluFramework

MakuluAware                = {}
MakuluAware.__index        = MakuluAware
MakuluAware.activeMessages = {}
MakuluAware.messageFrames  = {}
MakuluAware.messageTexts   = {}
MakuluAware.customFontSize = 20  -- Default font size, will be loaded from persistent storage

local GetTime              = GetTime

MakuluAware.colors         = {
    White = { 1, 1, 1, 1 },
    Blue = { 0, 0, 1, 1 },
    Red = { 1, 0, 0, 1 },
    Green = { 0, 1, 0, 1 },
    Purple = { 128 / 255, 0, 128 / 255, 1 },
    Rogue = { 1, 0.96, 0.41, 1 },
    Paladin = { 0.96, 0.55, 0.73, 1 },
    Warlock = { 0.58, 0.51, 0.79, 1 },
    Priest = { 1, 1, 1, 1 },
    Mage = { 0.41, 0.8, 0.94, 1 },
    Hunter = { 0.67, 0.83, 0.45, 1 },
    Shaman = { 0, 0.44, 0.87, 1 },
    Warrior = { 0.78, 0.61, 0.43, 1 },
    DeathKnight = { 0.77, 0.12, 0.23, 1 },
    Monk = { 0, 1, 0.59, 1 },
    Druid = { 1, 0.49, 0.04, 1 },
    DemonHunter = { 0.64, 0.19, 0.79, 1 },
    Evoker = { 0.41, 0.8, 0.94, 1 },
}

function MakuluAware.new()
    local instance = setmetatable({}, MakuluAware)
    instance.timeSinceLastUpdate = 0
    instance.isEnabled = false -- Default to false
    return instance
end

-- Enable the message system
function MakuluAware:enable()
    self.isEnabled = true
end

-- Disable the message system
function MakuluAware:disable()
    self.isEnabled = false
end

function MakuluAware:BumpText(text, length)
    local frame = self.messageTexts[text]
    if not frame then return end
    
    local found = self.activeMessages[frame]
    if not found then return end
    
    local now = GetTime()
    found.updated = now
    
    length = length or 5
    
    C_Timer.After(length, function()
            if found.updated ~= now then return end
            self:removeMessage(frame, text)
    end)
    
    return true
end

local IconWidth = 50
local IconPadding = 10

local innerSize = 45
local innerTextureSize = 39

local animInTime = 0.5
local animTransitionTime = 0.2
local animOutTime = 0.2

local measuringFontString

function MakuluAware:displayMessage(text, color, length, icon, isPriority)
    if not self.isEnabled then return end
    if self.messageTexts[text] then
        if self:BumpText(text, length) then
            return
        end
    end
    
    local frame = self:getNextAvailableFrame()
    
    -- Measure the text width (match display flags to avoid deltas)
    measuringFontString = measuringFontString or UIParent:CreateFontString(nil, "ARTWORK")
    -- Use current font size for accurate width measurement
    local fontSize = self.customFontSize or 20
    measuringFontString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    measuringFontString:SetWordWrap(false)
    measuringFontString:SetNonSpaceWrap(false)
    measuringFontString:SetText(text)
    measuringFontString:SetAlpha(0)
    measuringFontString:Show()
    local textWidth = math.ceil(measuringFontString:GetStringWidth()) + 2 -- small safety buffer
    measuringFontString:Hide()
    
    frame:ClearAllPoints()
    
    -- Position at anchor frame location (will be repositioned immediately after)
    if self.anchorFrame then
        local anchorX, anchorY = self.anchorFrame:GetCenter()
        if anchorX and anchorY then
            frame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", anchorX, anchorY)
        else
            -- Fallback if anchor not positioned yet
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    else
        -- Fallback if anchor doesn't exist
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    frame:SetFrameStrata("TOOLTIP") -- Keep on top
    
    -- Create subframes once
    if not frame._textFrame then
        frame._textFrame = CreateFrame("Frame", nil, frame)
        
        local fontString = frame._textFrame:CreateFontString(nil, "ARTWORK")
        frame._fontString = fontString
        
        -- Use saved font size if available, otherwise default to 20
        local fontSize = self.customFontSize or 20
        fontString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        fontString:SetShadowOffset(2, -2)
        fontString:SetJustifyH("RIGHT")
        fontString:SetJustifyV("MIDDLE")
        fontString:SetWordWrap(false)
        fontString:SetNonSpaceWrap(false)
        fontString:SetMaxLines(1)
    end
    
    -- Reserve space on the left if an icon is shown
    local leftInset = 0
    if icon then
        leftInset = IconWidth + IconPadding
    end
    
    -- Size the outer frame to fit: [icon column] + [text width]
    local frameWidth = leftInset + textWidth
    frame:SetSize(frameWidth, 50)
    
    -- Make the text frame span from leftInset to the right edge
    frame._textFrame:ClearAllPoints()
    frame._textFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame._textFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame._textFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", leftInset, 0)
    frame._textFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", leftInset, 0)
    
    -- Anchor the fontstring to all four edges of the text frame
    local fontString = frame._fontString
    fontString:ClearAllPoints()
    fontString:SetPoint("LEFT",   frame._textFrame, "LEFT", 0, 0)
    fontString:SetPoint("RIGHT",  frame._textFrame, "RIGHT", 0, 0)
    fontString:SetPoint("TOP",    frame._textFrame, "TOP", 0, 0)
    fontString:SetPoint("BOTTOM", frame._textFrame, "BOTTOM", 0, 0)
    
    -- Apply text and color
    fontString:SetText(text)
    local colorValues = self.colors[color] or self.colors.White
    fontString:SetTextColor(unpack(colorValues))
    length = length or 5
    frame._textFrame:Show()
    
    -- Icon handling: ensure the icon column actually reserves width on the left
    if icon then
        if not frame._iconFrame then
            local iconFrame = CreateFrame("Frame", nil, frame)
            frame._iconFrame = iconFrame
            
            iconFrame.tex = iconFrame:CreateTexture(nil, "ARTWORK")
            iconFrame.tex:SetAllPoints(iconFrame)
            iconFrame.tex:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
            iconFrame.tex:SetColorTexture(0, 0, 0, 1)
            
            iconFrame.mask = iconFrame:CreateMaskTexture()
            iconFrame.mask:SetAllPoints(iconFrame.tex)
            iconFrame.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            iconFrame.tex:AddMaskTexture(iconFrame.mask)
            
            iconFrame._innerTexture = iconFrame:CreateTexture(nil, "ARTWORK")
            iconFrame._innerTexture:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
            iconFrame._innerTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            iconFrame._innerTexture:SetSize(innerTextureSize, innerTextureSize)
            
            local mask = iconFrame:CreateMaskTexture()
            mask:SetAllPoints(iconFrame._innerTexture)
            mask:SetSize(innerTextureSize, innerTextureSize)
            mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            iconFrame._innerTexture:AddMaskTexture(mask)
        end
        
        frame._iconFrame:ClearAllPoints()
        frame._iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
        frame._iconFrame:SetSize(IconWidth, 50) -- reserve full column width
        frame._iconFrame._innerTexture:SetTexture(icon)
        frame._iconFrame:Show()
    else
        if frame._iconFrame then frame._iconFrame:Hide() end
    end
    
    -- Animation plumbing (unchanged, just reset)
    frame.scaleAnim = nil
    frame.animGroup = frame.animGroup or frame:CreateAnimationGroup()
    frame:SetAlpha(0)
    frame:Show()
    
    -- Track message
    local now = GetTime()
    
    -- Get initial position from anchor frame
    local initialPosition = 0
    if self.anchorFrame then
        local _, anchorY = self.anchorFrame:GetCenter()
        if anchorY then
            initialPosition = anchorY
        end
    end
    
    local storedMessage = {
        text = text,
        isPriority = isPriority or false,
        updated = now,
        position = initialPosition,
        isNew = true,
        currScale = 0.5,
        destroying = false
    }
    
    self.activeMessages[frame] = storedMessage
    self.messageTexts[text] = frame
    
    self:adjustMessagePositions()
    
    -- Auto-remove after length unless bumped
    return C_Timer.After(length, function()
            if storedMessage.updated ~= now then return end
            self:removeMessage(frame, text)
    end)
end

-- Reposition all message frames immediately (no animation)
-- Called during drag operations and when positions need immediate update
-- Messages always stack upward from the anchor frame position
function MakuluAware:repositionMessagesImmediate()
    -- Get anchor frame position
    if not self.anchorFrame then
        return
    end
    
    local anchorX, anchorY = self.anchorFrame:GetCenter()
    if not anchorX or not anchorY then
        return
    end
    
    -- Get active frames and sort by priority/time
    local activeFrames = self:getActiveFramesInOrder()
    
    table.sort(activeFrames, function(a, b)
            local aMessage = self.activeMessages[a]
            local bMessage = self.activeMessages[b]
            
            if not aMessage or not bMessage then return false end
            
            local isAPriority = aMessage.isPriority
            local isBPriority = bMessage.isPriority
            
            if isAPriority == isBPriority then
                return aMessage.updated < bMessage.updated
            else
                return isAPriority
            end
    end)
    
    -- Position each message stacking upward from anchor
    for i = #activeFrames, 1, -1 do
        local frame = activeFrames[i]
        local storedMessage = self.activeMessages[frame]
        local index = #activeFrames - i
        
        -- Stack messages upward with 55 pixel spacing
        local targetY = anchorY + (55 * index)
        
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", anchorX, targetY)
        storedMessage.position = targetY
    end
end

function MakuluAware:adjustMessagePositions()
    -- Get anchor frame position
    if not self.anchorFrame then
        return
    end
    
    local anchorX, anchorY = self.anchorFrame:GetCenter()
    if not anchorX or not anchorY then
        return
    end
    
    local index = 0
    local activeFrames = self:getActiveFramesInOrder()
    
    table.sort(activeFrames, function(a, b)
            local aMessage = self.activeMessages[a]
            local bMessage = self.activeMessages[b]
            
            if not aMessage or not bMessage then return false end
            
            local isAPriority = aMessage.isPriority
            local isBPriority = bMessage.isPriority
            
            if isAPriority == isBPriority then
                return aMessage.updated < bMessage.updated
            else
                return isAPriority
            end
    end)
    
    for i = #activeFrames, 1, -1 do
        local frame = activeFrames[i]
        local storedMessage = self.activeMessages[frame]
        
        -- Calculate target position stacking upward from anchor
        local targetY = anchorY + (55 * index)
        local doingTranslation = storedMessage.position ~= targetY
        
        local animGroup = frame.animGroup
        local currentScale = storedMessage.currScale
        
        if animGroup:IsPlaying() then
            if frame.scaleAnim then
                local startSize = frame.scaleAnim:GetScaleFrom()
                local endSize = frame.scaleAnim:GetScaleTo()
                currentScale = startSize + ((endSize - startSize) * frame.scaleAnim:GetSmoothProgress())
            end
            
            animGroup:Stop()
        end
        animGroup:RemoveAnimations()
        
        local fade = animGroup:CreateAnimation("Alpha")
        local targetAlpha = math.max(1 - (0.25 * (index)), 0)
        if currentScale ~= 1 then
            local toScale = 1
            scale = animGroup:CreateAnimation("Scale")
            scale:SetScaleFrom(currentScale, currentScale)
            scale:SetScaleTo(toScale, toScale)
            scale:SetOrigin("CENTER", 0, 0)
            scale:SetDuration(animTransitionTime)
            scale:SetSmoothing("IN")
            
            frame.scaleAnim = scale
            storedMessage.isNew = false
        end
        fade:SetFromAlpha(frame:GetAlpha())
        fade:SetToAlpha(targetAlpha)
        fade:SetDuration(animTransitionTime)
        fade:SetSmoothing("IN_OUT")
        
        local move
        local scale
        if doingTranslation then
            local _, _, _, _, yOfs = frame:GetPoint()
            local translationY = targetY - yOfs
            
            move = animGroup:CreateAnimation("Translation")
            move:SetOffset(0, translationY)
            move:SetDuration(animTransitionTime)
            move:SetSmoothing("IN_OUT")
        end
        
        if currentScale ~= 1 then
            scale = animGroup:CreateAnimation("Scale")
            scale:SetScaleFrom(currentScale, currentScale)
            scale:SetScaleTo(targetAlpha, targetAlpha)
            scale:SetOrigin("CENTER", 0, 0)
            scale:SetDuration(animTransitionTime)
            scale:SetSmoothing("IN")
            
            frame.scaleAnim = scale
            storedMessage.isNew = false
        end
        
        animGroup:SetScript("OnFinished", function()
                frame:SetAlpha(targetAlpha)
                
                if frame.scaleAnim then
                    if frame.scaleAnim:GetProgress() == 1 then
                        storedMessage.currScale = frame.scaleAnim:GetScaleTo()
                        frame.scaleAnim = nil
                    end
                end
                
                -- Position frame at target location (relative to anchor frame)
                frame:ClearAllPoints()
                frame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", anchorX, targetY)
                storedMessage.position = targetY
        end)
        
        animGroup:Play()
        index = index + 1
    end
end

-- Get active frames in order
function MakuluAware:getActiveFramesInOrder()
    local activeFrames = {}
    for frame, isActive in pairs(self.activeMessages) do
        if isActive and not frame.destroying then
            table.insert(activeFrames, frame)
        end
    end
    return activeFrames
end

-- Update font size for all active messages
function MakuluAware:updateAllMessagesFontSize(fontSize)
    if not fontSize or fontSize < 10 or fontSize > 48 then
        return
    end
    
    self.customFontSize = fontSize
    
    -- Update all active message frames
    for frame, isActive in pairs(self.activeMessages) do
        if isActive and frame._fontString then
            local fontPath, _, fontFlags = frame._fontString:GetFont()
            frame._fontString:SetFont(fontPath or "Fonts\\FRIZQT__.TTF", fontSize, fontFlags or "OUTLINE")
            
            -- Recalculate frame width based on new font size
            if frame._fontString:GetText() then
                -- Update measuring font string to new size
                measuringFontString = measuringFontString or UIParent:CreateFontString(nil, "ARTWORK")
                measuringFontString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
                measuringFontString:SetWordWrap(false)
                measuringFontString:SetNonSpaceWrap(false)
                measuringFontString:SetText(frame._fontString:GetText())
                measuringFontString:SetAlpha(0)
                measuringFontString:Show()
                local textWidth = math.ceil(measuringFontString:GetStringWidth()) + 2
                measuringFontString:Hide()
                
                -- Calculate left inset for icon if present
                local leftInset = 0
                if frame._iconFrame then
                    leftInset = IconWidth + IconPadding
                end
                
                -- Resize frame to fit new text width
                local frameWidth = leftInset + textWidth
                frame:SetSize(frameWidth, 50)
            end
        end
    end
end

-- Remove a message
function MakuluAware:removeMessage(frame, text)
    local animGroup = frame.animGroup
    animGroup:Stop()
    animGroup:RemoveAnimations()
    
    local fade = animGroup:CreateAnimation("Alpha")
    fade:SetFromAlpha(frame:GetAlpha())
    fade:SetToAlpha(0)
    fade:SetDuration(0.2)
    
    animGroup:SetScript("OnFinished", function()
            frame:SetAlpha(0)
            frame:Hide()
            
            frame.destroying = false
            self.activeMessages[frame] = false
    end)
    
    self.messageTexts[text] = nil
    frame.destroying = true
    animGroup:Play()
    self:adjustMessagePositions()
end

-- Get the next available frame
function MakuluAware:getNextAvailableFrame()
    for frame, isActive in pairs(self.activeMessages) do
        if not isActive and not frame.destroying then
            return frame
        end
    end
    
    local newFrame = CreateFrame("Frame", nil, UIParent)
    self.activeMessages[newFrame] = false
    return newFrame
end

-- Initialize and enable Aware system
MakuluFramework.Aware = MakuluAware.new()
MakuluFramework.MakuluAware = MakuluFramework.Aware
MakuluFramework.Aware:enable()

-- Manual Positioning System
-- Create an invisible anchor frame that can be dragged to adjust offset from TMW group 3
MakuluAware.anchorFrame = nil
-- New offset storage structure: stores offset relative to TMW Group 3
-- x = horizontal offset from TMW center
-- y = vertical offset from TMW top edge
MakuluAware.offsetFromTMW = {
    x = 0,
    y = 10  -- Default 10 pixels above TMW top edge
}
MakuluAware.tmwPositionTracker = nil  -- Timer for tracking TMW movement

-- Function to create the draggable anchor frame
function MakuluAware:createAnchorFrame()
    if self.anchorFrame then
        return
    end
    
    local anchor = CreateFrame("Frame", "MakuluAwareAnchor", UIParent, "BackdropTemplate")
    anchor:SetSize(60, 60)
    anchor:SetFrameStrata("TOOLTIP")
    anchor:SetFrameLevel(1000)
    
    -- Backdrop for visibility during configuration
    anchor:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    anchor:SetBackdropColor(0.1, 0.5, 0.8, 0.8) -- Blue tint
    anchor:SetBackdropBorderColor(0.2, 0.6, 1, 1)
    
    -- Icon texture
    local icon = anchor:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    anchor.icon = icon
    
    -- Label
    local label = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", anchor, "BOTTOM", 0, 2)
    label:SetText("DRAG")
    label:SetTextColor(1, 1, 1, 1)
    anchor.label = label
    
    -- Enable dragging
    anchor:EnableMouse(true)
    anchor:SetMovable(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetClampedToScreen(true)
    
    -- Drag handlers
    anchor:SetScript("OnDragStart", function(self)
            if TMW and not TMW.Locked then
                -- Get current position before clearing anchor points
                local centerX, centerY = self:GetCenter()
                if not centerX or not centerY then
                    return
                end
                
                -- Convert from anchored positioning to absolute positioning
                -- This prevents the frame from snapping back to its anchor point during drag
                self:ClearAllPoints()
                self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
                
                -- Now start moving with absolute positioning
                self:StartMoving()
                self.isDragging = true
                -- Highlight during drag
                self:SetBackdropColor(0.2, 0.7, 1, 0.9)
            end
    end)
    
    anchor:SetScript("OnDragStop", function(self)
            if self.isDragging then
                -- Capture position BEFORE stopping drag
                local currentX, currentY = self:GetCenter()
                
                -- Stop drag operation
                self:StopMovingOrSizing()
                self.isDragging = false
                self:SetBackdropColor(0.1, 0.5, 0.8, 0.8)
                
                -- Calculate and save new offset from captured position
                MakuluFramework.Aware:saveOffsetFromPosition(currentX, currentY)
                
                -- Update all positions using new offset
                MakuluFramework.Aware:updateAllPositions()
            end
    end)
    
    -- OnUpdate handler for real-time message repositioning during drag
    anchor:SetScript("OnUpdate", function(self, elapsed)
            if self.isDragging and MakuluFramework.Aware then
                -- During drag, reposition messages to follow anchor frame in real-time
                MakuluFramework.Aware:repositionMessagesImmediate()
            end
    end)
    
    -- Tooltip
    anchor:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Makulu Aware Anchor", 1, 1, 1)
            GameTooltip:AddLine("Drag to adjust message position", 0.7, 0.7, 0.7, true)
            GameTooltip:AddLine("Messages will appear above this anchor", 0.7, 0.7, 0.7, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Only visible when TMW is unlocked", 0.5, 0.5, 0.5, true)
            GameTooltip:Show()
    end)
    
    anchor:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
    end)
    
    -- Start hidden
    anchor:Hide()
    
    self.anchorFrame = anchor
    
    -- Load saved offset from database
    self:loadOffsetFromDB()
    
    -- Calculate and apply initial positions
    self:updateAllPositions()
    
    -- Start tracking TMW Group 3 movement
    self:startTMWPositionTracking()
end

-- ============================================================================
-- NEW POSITIONING SYSTEM: Event-Driven Relative Positioning
-- ============================================================================

-- Calculate absolute position from TMW Group 3 position + stored offset
-- This is the SINGLE SOURCE OF TRUTH for all positioning calculations
-- Returns: absoluteX, absoluteY (or nil, nil if TMW not found)
function MakuluAware:calculateAbsolutePosition()
    local tmwGroupFrame = _G["TellMeWhen_Group3"]
    
    if not tmwGroupFrame or not tmwGroupFrame:IsObjectType("Frame") then
        -- TMW Group 3 not found, return nil to trigger fallback
        return nil, nil
    end
    
    -- Get TMW Group 3 center and dimensions
    local tmwCenterX, tmwCenterY = tmwGroupFrame:GetCenter()
    if not tmwCenterX or not tmwCenterY then
        return nil, nil
    end
    
    local tmwHeight = tmwGroupFrame:GetHeight()
    local tmwTop = tmwCenterY + (tmwHeight / 2)
    
    -- Calculate absolute position from stored offset
    local absoluteX = tmwCenterX + self.offsetFromTMW.x
    local absoluteY = tmwTop + self.offsetFromTMW.y
    
    return absoluteX, absoluteY
end

-- Update all UI element positions (anchor frame + all messages)
-- This is called whenever position needs to be recalculated:
-- - After loading saved offset
-- - After user drags anchor frame
-- - When TMW Group 3 moves
-- - On lock/unlock state transitions
function MakuluAware:updateAllPositions()
    -- Calculate absolute position from offset
    local absoluteX, absoluteY = self:calculateAbsolutePosition()
    
    -- Fallback if TMW Group 3 not found
    if not absoluteX or not absoluteY then
        absoluteX = UIParent:GetWidth() / 2
        absoluteY = UIParent:GetHeight() - 120
    end
    
    -- Update anchor frame position
    if self.anchorFrame then
        self.anchorFrame:ClearAllPoints()
        self.anchorFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", absoluteX, absoluteY)
    end
    
    -- Update all message positions
    self:repositionMessagesImmediate()
end

-- Start tracking TMW Group 3 position to detect movement
-- When TMW moves, automatically update message positions to maintain relative offset
function MakuluAware:startTMWPositionTracking()
    -- Don't create multiple trackers
    if self.tmwPositionTracker then
        return
    end
    
    local tmwGroupFrame = _G["TellMeWhen_Group3"]
    if not tmwGroupFrame or not tmwGroupFrame:IsObjectType("Frame") then
        -- TMW Group 3 not found, try again later
        C_Timer.After(1, function()
                if MakuluFramework.Aware then
                    MakuluFramework.Aware:startTMWPositionTracking()
                end
        end)
        return
    end
    
    -- Store initial position
    local lastX, lastY = tmwGroupFrame:GetCenter()
    if not lastX or not lastY then
        return
    end
    
    -- Create ticker to check for TMW movement every 0.1 seconds
    self.tmwPositionTracker = C_Timer.NewTicker(0.1, function()
            local tmwFrame = _G["TellMeWhen_Group3"]
            if not tmwFrame then
                return
            end
            
            local currentX, currentY = tmwFrame:GetCenter()
            if not currentX or not currentY then
                return
            end
            
            -- Check if TMW moved (threshold: 1 pixel to avoid floating point noise)
            if math.abs(currentX - lastX) > 1 or math.abs(currentY - lastY) > 1 then
                lastX, lastY = currentX, currentY
                
                -- TMW moved, update all positions to maintain relative offset
                MakuluFramework.Aware:updateAllPositions()
            end
    end)
    
end

-- Stop tracking TMW position (cleanup)
function MakuluAware:stopTMWPositionTracking()
    if self.tmwPositionTracker then
        self.tmwPositionTracker:Cancel()
        self.tmwPositionTracker = nil
        
    end
end

-- Calculate and save offset from an absolute position
-- Called after user drags the anchor frame to a new position
-- Converts absolute screen coordinates to relative offset from TMW Group 3
function MakuluAware:saveOffsetFromPosition(absoluteX, absoluteY)
    local tmwGroupFrame = _G["TellMeWhen_Group3"]
    if not tmwGroupFrame or not tmwGroupFrame:IsObjectType("Frame") then
        print("|cFFFF0000[ERROR]|r Cannot save offset: TMW Group 3 not found")
        return
    end
    
    -- Get TMW Group 3 position
    local tmwCenterX, tmwCenterY = tmwGroupFrame:GetCenter()
    if not tmwCenterX or not tmwCenterY then
        print("|cFFFF0000[ERROR]|r Cannot save offset: TMW Group 3 position invalid")
        return
    end
    
    local tmwHeight = tmwGroupFrame:GetHeight()
    local tmwTop = tmwCenterY + (tmwHeight / 2)
    
    -- Calculate offset from TMW Group 3
    -- x offset = horizontal distance from TMW center
    -- y offset = vertical distance from TMW top edge
    self.offsetFromTMW.x = absoluteX - tmwCenterX
    self.offsetFromTMW.y = absoluteY - tmwTop
    
    -- Save to persistent storage
    if not MakuluFramework or not MakuluFramework.SavePersistentValue then
        print("|cFFFF0000[ERROR]|r Cannot save offset: SavePersistentValue not available")
        return
    end
    
    MakuluFramework.SavePersistentValue("MakuluAwareLiveOffset", self.offsetFromTMW, true)
end

-- Load saved offset from database
-- Called on addon load and when TMW is unlocked
function MakuluAware:loadOffsetFromDB()
    -- Safety check: ensure TryGetPersistValue is available
    if not MakuluFramework or not MakuluFramework.TryGetPersistValue then
        print("|cFFFF0000[ERROR]|r Cannot load offset: TryGetPersistValue not available, using defaults")
        self.offsetFromTMW.x = 0
        self.offsetFromTMW.y = 10
        return
    end
    
    local offsetData = MakuluFramework.TryGetPersistValue("MakuluAwareLiveOffset", true)
    
    if offsetData and type(offsetData) == "table" then
        -- Backward compatibility: check for old format (customOffsetX/Y) and convert
        if offsetData.x ~= nil and offsetData.y ~= nil then
            -- New format
            self.offsetFromTMW.x = offsetData.x
            self.offsetFromTMW.y = offsetData.y
        else
            -- Old format or corrupted data, use defaults
            print("|cFFFFFF00[WARNING]|r Saved offset data invalid, using defaults")
            self.offsetFromTMW.x = 0
            self.offsetFromTMW.y = 10
        end
    else
        -- No saved offset found, use defaults
        self.offsetFromTMW.x = 0
        self.offsetFromTMW.y = 10
    end
end

-- Reset anchor to default position
function MakuluAware:resetAnchorPosition()
    -- Reset to default offset
    self.offsetFromTMW.x = 0
    self.offsetFromTMW.y = 10
    
    -- Clear saved position from database
    if MakuluFramework and MakuluFramework.SavePersistentValue then
        MakuluFramework.SavePersistentValue("MakuluAwareLiveOffset", nil, true)
    end
    
    -- Update all positions with new default offset
    self:updateAllPositions()
end

-- Defer anchor frame creation until MakuluFramework is fully loaded
-- This ensures TryGetPersistValue and SavePersistentValue are available
C_Timer.After(0.1, function()
        if MakuluFramework.Aware and MakuluFramework.TryGetPersistValue then
            MakuluFramework.Aware:createAnchorFrame()
        else
            print("|cFFFF0000[ERROR]|r Cannot create anchor frame - MakuluFramework not ready")
            if not MakuluFramework.Aware then
                print("|cFFFF0000[ERROR]|r MakuluFramework.Aware is nil")
            end
            if not MakuluFramework.TryGetPersistValue then
                print("|cFFFF0000[ERROR]|r MakuluFramework.TryGetPersistValue is nil")
            end
        end
end)

-- Test Message Feature for TMW Configuration Mode
-- Shows a test message when TMW is unlocked to help users visualize message positioning
MakuluAware.testMessageActive = false
MakuluAware.testMessageText = nil
MakuluAware.testMessageTimer = nil
MakuluAware.resizeHandle = nil

-- Function to load saved font size from persistent storage
function MakuluAware:loadFontSize()
    if not MakuluFramework or not MakuluFramework.TryGetPersistValue then
        print("|cFFFF0000[ERROR]|r Cannot load font size - MakuluFramework not ready")
        return
    end
    
    local savedFontSize = MakuluFramework.TryGetPersistValue("MakuluAwareFontSize", true)
    if savedFontSize and savedFontSize >= 10 and savedFontSize <= 48 then
        self.customFontSize = savedFontSize
    else
        self.customFontSize = 20  -- Default font size
    end
end

-- Function to save font size to persistent storage
function MakuluAware:saveFontSize()
    if not MakuluFramework or not MakuluFramework.SavePersistentValue then
        print("|cFFFF0000[ERROR]|r Cannot save font size - MakuluFramework not ready")
        return
    end
    
    MakuluFramework.SavePersistentValue("MakuluAwareFontSize", self.customFontSize, true)
end

-- Function to get player's class icon texture
local function getPlayerClassIcon()
    -- Try to get spec icon first (more specific)
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            local specID, specName, description, icon = GetSpecializationInfo(specIndex)
            if icon then
                return icon
            end
        end
    end
    
    -- Fallback to class icon
    local _, classFile = UnitClass("player")
    if classFile then
        -- Use standard class icon texture path
        if classFile == "EVOKER" then
            return "Interface\\Icons\\ClassIcon_Evoker"
        else
            return "Interface\\Icons\\ClassIcon_" .. classFile
        end
    end
    
    return nil
end

-- Function to get player's specialization name
local function getPlayerSpecName()
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            local specID, specName = GetSpecializationInfo(specIndex)
            if specName then
                return specName
            end
        end
    end
    
    -- Fallback to class name if spec not available
    local className = UnitClass("player")
    return className or "Unknown"
end

-- Function to show test message
function MakuluAware:showTestMessage()
    if self.testMessageActive then
        -- Test message already showing
        return
    end
    
    local specName = getPlayerSpecName()
    local classIcon = getPlayerClassIcon()
    local _, classFile = UnitClass("player")
    
    -- Get class color from the colors table
    local classColor = classFile and self.colors[classFile] or "White"
    
    -- Display the test message
    local messageText = specName .. " Messages Will Go Here"
    self.testMessageText = messageText -- Store the actual text for later removal
    
    -- Cancel any existing timer
    if self.testMessageTimer then
        self.testMessageTimer:Cancel()
        self.testMessageTimer = nil
    end
    
    -- Display the message and store the timer
    self.testMessageTimer = self:displayMessage(
        messageText,
        classColor,
        999999, -- Very long duration (won't auto-remove in normal circumstances)
        classIcon,
        true -- Priority message (appears first)
    )
    
    self.testMessageActive = true
end

-- Function to hide test message
function MakuluAware:hideTestMessage()
    if not self.testMessageActive then
        return
    end
    
    -- Cancel the auto-remove timer if it exists
    if self.testMessageTimer then
        self.testMessageTimer:Cancel()
        self.testMessageTimer = nil
    end
    
    -- Find and remove the test message frame
    local frame = self.messageTexts[self.testMessageText]
    if not frame then
        -- Try to find it by searching for the test message pattern
        for text, msgFrame in pairs(self.messageTexts) do
            if text:find("Messages Will Go Here") then
                frame = msgFrame
                self.testMessageText = text
                break
            end
        end
    end
    
    -- Remove the message if found
    if frame then
        self:removeMessage(frame, self.testMessageText)
    end
    
    -- Reset tracking variables
    self.testMessageActive = false
    self.testMessageText = nil
    
    -- Hide resize handle when test message is hidden
    if self.resizeHandle then
        self.resizeHandle:Hide()
    end
end

-- Function to create and show the resize handle
function MakuluAware:createResizeHandle()
    if self.resizeHandle then
        self.resizeHandle:Show()
        return
    end
    
    -- Find the test message frame
    local testMessageFrame = nil
    for text, frame in pairs(self.messageTexts) do
        if text and text:find("Messages Will Go Here") then
            testMessageFrame = frame
            break
        end
    end
    
    if not testMessageFrame then
        print("|cFFFF0000[ERROR]|r Cannot create resize handle - test message frame not found")
        return
    end
    
    -- Create resize handle frame
    local handle = CreateFrame("Frame", "MakuluAwareResizeHandle", testMessageFrame, "BackdropTemplate")
    handle:SetSize(16, 16)
    handle:SetPoint("BOTTOMRIGHT", testMessageFrame, "BOTTOMRIGHT", 2, -2)
    handle:SetFrameStrata("TOOLTIP")
    handle:SetFrameLevel(1001)
    
    -- Backdrop for visibility
    handle:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    handle:SetBackdropColor(0.8, 0.8, 0.8, 0.8)
    handle:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Resize icon texture
    local icon = handle:CreateTexture(nil, "ARTWORK")
    icon:SetSize(10, 10)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    handle.icon = icon
    
    -- Enable dragging
    handle:EnableMouse(true)
    handle:SetMovable(true)
    handle:RegisterForDrag("LeftButton")
    
    -- Track resize state
    handle.isResizing = false
    handle.startY = 0
    handle.startFontSize = self.customFontSize
    
    -- OnDragStart handler
    handle:SetScript("OnDragStart", function(self)
            if TMW and not TMW.Locked then
                self.isResizing = true
                self.startY = GetCursorPosition()
                self.startFontSize = MakuluFramework.Aware.customFontSize
                self:SetBackdropColor(1, 1, 0, 0.9)  -- Yellow highlight during resize
            end
    end)
    
    -- OnDragStop handler
    handle:SetScript("OnDragStop", function(self)
            if self.isResizing then
                self.isResizing = false
                self:SetBackdropColor(0.8, 0.8, 0.8, 0.8)  -- Reset color
                MakuluFramework.Aware:saveFontSize()
            end
    end)
    
    -- OnUpdate handler for real-time resizing
    handle:SetScript("OnUpdate", function(self)
            if self.isResizing then
                local currentY = GetCursorPosition()
                local deltaY = currentY - self.startY
                
                -- Calculate new font size (1 pixel = 0.5 font size change)
                local newFontSize = self.startFontSize + (deltaY * 0.5)
                
                -- Apply constraints
                newFontSize = math.max(10, math.min(48, newFontSize))
                
                -- Update font size
                MakuluFramework.Aware:updateAllMessagesFontSize(newFontSize)
            end
    end)
    
    -- Tooltip
    handle:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Drag to resize text", 1, 1, 1)
            GameTooltip:AddLine("Min: 10 | Max: 48", 0.7, 0.7, 0.7)
            GameTooltip:Show()
    end)
    
    handle:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
    end)
    
    self.resizeHandle = handle
end

-- Function to hide the resize handle
function MakuluAware:hideResizeHandle()
    if self.resizeHandle then
        self.resizeHandle:Hide()
    end
end

-- Integrate with TellMeWhen lock/unlock state
if TMW then
    -- Register callback for TMW lock toggle events
    TMW:RegisterCallback("TMW_LOCK_TOGGLED", function(event, isLocked)
            if not MakuluFramework.Aware then
                return
            end
            
            if isLocked then
                -- TMW locked (normal gameplay mode)
                MakuluFramework.Aware:hideTestMessage()
                
                -- Hide anchor frame
                if MakuluFramework.Aware.anchorFrame then
                    MakuluFramework.Aware.anchorFrame:Hide()
                end
                
                -- Hide resize handle
                MakuluFramework.Aware:hideResizeHandle()
            else
                -- TMW unlocked (configuration mode)
                -- Load saved offset and update all positions
                MakuluFramework.Aware:loadOffsetFromDB()
                MakuluFramework.Aware:updateAllPositions()
                
                -- Show test message
                MakuluFramework.Aware:showTestMessage()
                
                -- Show anchor frame
                if MakuluFramework.Aware.anchorFrame then
                    MakuluFramework.Aware.anchorFrame:Show()
                end
                
                -- Create and show resize handle
                C_Timer.After(0.1, function()
                        MakuluFramework.Aware:createResizeHandle()
                end)
            end
    end)
    
    -- Check initial TMW state on load
    C_Timer.After(1, function()
            if TMW and TMW.Locked ~= nil and MakuluFramework.Aware then
                -- Load saved font size on startup
                MakuluFramework.Aware:loadFontSize()
                
                if not TMW.Locked then
                    -- TMW is unlocked on load
                    MakuluFramework.Aware:loadOffsetFromDB()
                    MakuluFramework.Aware:updateAllPositions()
                    MakuluFramework.Aware:showTestMessage()
                    
                    if MakuluFramework.Aware.anchorFrame then
                        MakuluFramework.Aware.anchorFrame:Show()
                    end
                    
                    -- Create and show resize handle
                    C_Timer.After(0.1, function()
                            MakuluFramework.Aware:createResizeHandle()
                    end)
                end
            end
    end)
else
    print("|cFFFFD700Makulu Aware:|r TellMeWhen not found. Test message feature disabled.")
end

-- Slash Commands for Aware System
SLASH_MAKULUAWARE1 = "/aware"
SLASH_MAKULUAWARE2 = "/makuluaware"

SlashCmdList["MAKULUAWARE"] = function(msg)
    msg = msg:lower():trim()
    
    if msg == "reset" then
        -- Reset position to default
        if MakuluFramework.Aware then
            MakuluFramework.Aware:resetAnchorPosition()
        end
        
    elseif msg == "show" then
        -- Show anchor frame
        if MakuluFramework.Aware and MakuluFramework.Aware.anchorFrame then
            MakuluFramework.Aware:updateAllPositions()
            MakuluFramework.Aware.anchorFrame:Show()
        end
        
    elseif msg == "hide" then
        -- Hide anchor frame
        if MakuluFramework.Aware and MakuluFramework.Aware.anchorFrame then
            MakuluFramework.Aware.anchorFrame:Hide()
        end
        
    elseif msg == "test" then
        -- Toggle test message
        if MakuluFramework.Aware then
            if MakuluFramework.Aware.testMessageActive then
                MakuluFramework.Aware:hideTestMessage()
            else
                MakuluFramework.Aware:showTestMessage()
            end
        end
        
    elseif msg == "offset" or msg == "pos" or msg == "position" then
        -- Show current offset
        if MakuluFramework.Aware then
            print(string.format("|cFF00FF00Makulu Aware:|r Current offset from TMW: X=%.1f, Y=%.1f",
                    MakuluFramework.Aware.offsetFromTMW.x,
            MakuluFramework.Aware.offsetFromTMW.y))
        end
        
    elseif msg == "help" or msg == "" then
        -- Show help
        print("|cFF00FF00Makulu Aware Commands:|r")
        print("  |cFFFFFFFF/aware reset|r - Reset position to default")
        print("  |cFFFFFFFF/aware show|r - Show anchor frame")
        print("  |cFFFFFFFF/aware hide|r - Hide anchor frame")
        print("  |cFFFFFFFF/aware test|r - Toggle test message")
        print("  |cFFFFFFFF/aware offset|r - Show current offset")
        print("  |cFFFFFFFF/aware help|r - Show this help")
        print(" ")
        print("|cFF00FF00Manual Positioning:|r")
        print("  1. Unlock TMW (anchor frame appears automatically)")
        print("  2. Drag the blue anchor frame to adjust position")
        print("  3. Lock TMW to save and hide anchor")
        print("  4. Messages will appear above the anchor point")
        
    else
        print("|cFFFF0000Makulu Aware:|r Unknown command. Type '/aware help' for help.")
    end
end

--Makulu Print
--Usage: MakPrint(index, "String text: ", variableToTrack)
local function RGBToHex(r, g, b)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

local function ColorizeText(text, r, g, b)
    local hex = RGBToHex(r, g, b)
    return "|cFF" .. hex .. text .. "|r"
end

local DebugFrame = CreateFrame("Frame", "DebugFrame", UIParent, "BackdropTemplate")
DebugFrame:SetSize(300, 150)
DebugFrame:SetPoint("CENTER")
DebugFrame:EnableMouse(true)
DebugFrame:SetMovable(true)
DebugFrame:SetUserPlaced(true)
DebugFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
DebugFrame:SetBackdropColor(0, 0, 0, 1)
DebugFrame:Hide()

local messages = {}
for i = 1, 12 do
    messages[i] = DebugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messages[i]:SetPoint("TOPLEFT", 10, -10 * i)
    messages[i]:SetWidth(280)
    messages[i]:SetHeight(20)
    messages[i]:SetJustifyH("LEFT")
end

local hideTimer = 5
local timer = 0
local triedFetch = false

function MakPrint(index, prefix, var)
    if messages[index] then
        local coloredPrefix = ColorizeText(prefix, 1, 0, 0)
        local coloredVar = ColorizeText(tostring(var), 0, 1, 0)
        messages[index]:SetText(coloredPrefix .. " " .. coloredVar)
        if not DebugFrame:IsShown() then
            DebugFrame:Show()
            
            if not triedFetch and not DebugFrame.savedPoint then
                triedFetch = true
                DebugFrame.savedPoint = MakuluFramework.TryGetPersistValue("DebugFramePos", true)
            end
            
            if DebugFrame.savedPoint then
                DebugFrame:ClearAllPoints()
                DebugFrame:SetPoint(unpack(DebugFrame.savedPoint))
            end
        end
        timer = 0
    end
end

DebugFrame:SetScript("OnUpdate", function(self, elapsed)
        if self:IsShown() then
            timer = timer + elapsed
            if timer >= hideTimer then
                timer = 0
            end
        end
end)

DebugFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
end)

DebugFrame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        self.savedPoint = {point, relativeTo, relativePoint, x, y}
        MakuluFramework.SavePersistentValue("DebugFramePos", self.savedPoint, true)
end)

-- Reload on Spec Change
if WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC then
    local specChangeFrame = CreateFrame("Frame", "specChangeFrame", UIParent, "BasicFrameTemplateWithInset")
    specChangeFrame:SetSize(400, 150)
    specChangeFrame:SetPoint("CENTER", UIParent, "TOP", 0, -200)
    specChangeFrame:Hide()
    
    specChangeFrame.title = specChangeFrame:CreateFontString(nil, "OVERLAY")
    specChangeFrame.title:SetFontObject("GameFontHighlight")
    specChangeFrame.title:SetPoint("LEFT", specChangeFrame.TitleBg, "LEFT", 5, 0)
    specChangeFrame.title:SetText("WeakAura")
    
    specChangeFrame.text = specChangeFrame:CreateFontString(nil, "OVERLAY")
    specChangeFrame.text:SetFontObject("GameFontHighlight")
    specChangeFrame.text:SetPoint("TOP", specChangeFrame, "TOP", 0, -40)
    specChangeFrame.text:SetText("Please reload your UI after changing specializations.\nSorry for the inconvenience!")
    specChangeFrame.text:SetWidth(specChangeFrame:GetWidth() - 20)
    
    local reloadButton = CreateFrame("Button", nil, specChangeFrame, "GameMenuButtonTemplate")
    reloadButton:SetPoint("BOTTOM", specChangeFrame, "BOTTOM", -80, 20)
    reloadButton:SetSize(140, 40)
    reloadButton:SetText("Reload UI")
    reloadButton:SetNormalFontObject("GameFontNormalLarge")
    reloadButton:SetHighlightFontObject("GameFontHighlightLarge")
    
    reloadButton:SetScript("OnClick", function()
            ReloadUI()
    end)
    
    local cancelButton = CreateFrame("Button", nil, specChangeFrame, "GameMenuButtonTemplate")
    cancelButton:SetPoint("BOTTOM", specChangeFrame, "BOTTOM", 80, 20)
    cancelButton:SetSize(140, 40)
    cancelButton:SetText("Cancel")
    cancelButton:SetNormalFontObject("GameFontNormalLarge")
    cancelButton:SetHighlightFontObject("GameFontHighlightLarge")
    
    cancelButton:SetScript("OnClick", function()
            specChangeFrame:Hide()
    end)
    
    local function GetCurrentSpecialization()
        -- MoP Classic compatibility
        if GetSpecialization and GetSpecializationInfo then
            return GetSpecializationInfo(GetSpecialization())
        else
            -- MoP Classic uses GetPrimaryTalentTree()
            return GetPrimaryTalentTree()
        end
    end
    
    local cachedSpecialization = GetCurrentSpecialization()
    
    local wowVersion, _, _, _ = GetBuildInfo()
    
    -- MoP Classic compatibility for spec change detection
    if GetSpecialization and GetSpecializationInfo then
        -- Retail/Modern WoW
        specChangeFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        specChangeFrame:SetScript("OnEvent", function(self, event, unit)
                if unit ~= "player" then return end
                
                local currentSpecialization = GetCurrentSpecialization()
                
                if currentSpecialization ~= cachedSpecialization then
                    cachedSpecialization = currentSpecialization
                    self:Show()
                end
        end)
    else
        -- MoP Classic - use talent tree change events
        specChangeFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        specChangeFrame:SetScript("OnEvent", function(self, event)
                local currentSpecialization = GetCurrentSpecialization()
                
                if currentSpecialization ~= cachedSpecialization then
                    cachedSpecialization = currentSpecialization
                    self:Show()
                end
        end)
    end
end


-- FIRST LOAD ID
if 1 == 2 then
    local f = CreateFrame("Frame", "MakuluSettingsFrame", UIParent)
    f:SetSize(460, 190)
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    -- Background
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(true)
    f.bg:SetColorTexture(0.10, 0.10, 0.10, 0.95) -- very dark gray
    
    -- Subtle gradient overlay (adds depth)
    f.gradient = f:CreateTexture(nil, "BORDER")
    f.gradient:SetAllPoints(true)
    f.gradient:SetTexture("Interface\\Buttons\\WHITE8x8")
    f.gradient:SetGradient("VERTICAL", CreateColor(0.15, 0.15, 0.15, 0.9), CreateColor(0.07, 0.07, 0.07, 0.9))
    
    -- Border (straight edges, black)
    f.border = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
    f.border:SetAllPoints(true)
    f.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
    })
    f.border:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.title:SetPoint("TOP", 0, -12)
    f.title:SetText("Makulu")
    
    -- Text area
    f.message = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.message:SetPoint("TOPLEFT", 15, -45)
    f.message:SetJustifyH("LEFT")
    f.message:SetJustifyV("TOP")
    f.message:SetSize(430, 80)
    f.message:SetText("Thank you for choosing Makulu.\n\nClick 'Apply Recommended Settings' to set up default general settings.\nThis will not change class-specific settings.\n\nIf you prefer, you can skip this setup.")
    
    -- Custom button creation function
    local function CreateMakuluButton(parent, text)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(200, 32)
        
        -- Text
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(text)
        
        -- Background layers
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints(true)
        btn.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.bg:SetVertexColor(0.25, 0.25, 0.25, 1) -- default gray
        
        btn.hl = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.hl:SetAllPoints(true)
        btn.hl:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.hl:SetVertexColor(0.35, 0.35, 0.35, 1) -- lighter hover
        
        btn.pushed = btn:CreateTexture(nil, "ARTWORK")
        btn.pushed:SetAllPoints(true)
        btn.pushed:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.pushed:SetVertexColor(0.15, 0.15, 0.15, 1) -- darker pressed
        btn:SetPushedTexture(btn.pushed)
        
        -- Black border
        btn.border = btn:CreateTexture(nil, "OVERLAY")
        btn.border:SetPoint("TOPLEFT", -1, 1)
        btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
        btn.border:SetColorTexture(0, 0, 0, 1)
        
        return btn
    end
    
    -- Apply Button
    local applyBtn = CreateMakuluButton(f, "Apply Recommended Settings")
    applyBtn:SetPoint("BOTTOMLEFT", 20, 15)
    applyBtn:SetScript("OnClick", function()
            print("Makulu: Apply Recommended Settings clicked!")
            -- Makulu_ApplyRecommendedSettings() -- replace with real function
    end)
    
    -- Skip Button
    local skipBtn = CreateMakuluButton(f, "Skip Setup")
    skipBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    skipBtn:SetScript("OnClick", function()
            print("Makulu: Skip Setup clicked!")
            f:Hide() -- just hides the frame for now
    end)
end

