-- Accessibility.lua
-- UI accessibility enhancements (screen reader support, etc.)

SSW = SSW or {}
SSW.Access = SSW.Access or {}

-- Track if accessibility is enabled
SSW.Access.isEnabled = false

-- Apply accessibility features to a frame
function SSW.Access.ApplyToFrame(frame, label)
    if not frame then return end
    
    frame.accessible = true
    frame.accessibleLabel = label or "Frame"
    
    -- Add tooltip hint for accessibility
    if frame.SetScript then
        local oldOnEnter = frame:GetScript("OnEnter")
        frame:SetScript("OnEnter", function(self)
            if oldOnEnter then oldOnEnter(self) end
            if SSW.Access.isEnabled then
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(self.accessibleLabel or "Interactive element")
                GameTooltip:Show()
            end
        end)
        
        local oldOnLeave = frame:GetScript("OnLeave")
        frame:SetScript("OnLeave", function(self)
            if oldOnLeave then oldOnLeave(self) end
            GameTooltip:Hide()
        end)
    end
end

-- Apply to send window (called from UI.lua)
function SSW.Access.ApplyToSendWindow(win)
    if not win then return end
    SSW.Access.ApplyToFrame(win, "Solo Shuffle Whisperer Send Window")
end

-- Toggle accessibility mode
function SSW.Access.Toggle()
    SSW.Access.isEnabled = not SSW.Access.isEnabled
    SSW.Print("Accessibility mode: " .. (SSW.Access.isEnabled and "ON" or "OFF"))
end

-- Initialize
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    -- Check if accessibility addons are loaded
    if C_AddOns.IsAddOnLoaded("ConsolePort") or C_AddOns.IsAddOnLoaded("FrameSort") then
        SSW.Access.isEnabled = true
    end
end)
