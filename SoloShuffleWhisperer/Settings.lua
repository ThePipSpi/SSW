-- Settings.lua - Settings window for Solo Shuffle Whisperer
SSW = SSW or {}; SSW.Settings = SSW.Settings or {}

-- Create main config frame
local configWin = CreateFrame("Frame", "SSW_ConfigFrame", UIParent, "BasicFrameTemplateWithInset")
configWin:SetSize(450, 400); configWin:SetPoint("CENTER", 0, 60); configWin:SetFrameStrata("HIGH"); configWin:SetFrameLevel(100)
configWin:SetMovable(true); configWin:EnableMouse(true); configWin:RegisterForDrag("LeftButton")
configWin:SetScript("OnDragStart", configWin.StartMoving); configWin:SetScript("OnDragStop", configWin.StopMovingOrSizing); configWin:Hide()
configWin.title = configWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
configWin.title:SetPoint("TOPLEFT", 14, -10); configWin.title:SetText("Solo Shuffle Whisperer - Settings")

-- Scroll frame setup
local scrollFrame = CreateFrame("ScrollFrame", nil, configWin, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", configWin.InsetBg, "TOPLEFT", 4, -4); scrollFrame:SetPoint("BOTTOMRIGHT", configWin.InsetBg, "BOTTOMRIGHT", -24, 50)
local scrollChild = CreateFrame("Frame"); scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(scrollFrame:GetWidth()); scrollChild:SetHeight(1)

-- Section header helper
local function AddSectionHeader(parent, text, yOff)
    local sep = parent:CreateTexture(nil, "ARTWORK"); sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 14, yOff); sep:SetPoint("TOPRIGHT", -14, yOff); sep:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", 18, yOff - 6); lbl:SetTextColor(1, 0.82, 0); lbl:SetText(text)
    return yOff - 22, sep, lbl
end

-- Custom Text Lines section
local y = AddSectionHeader(scrollChild, "CUSTOM MESSAGE LINES", -10)
local custLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
custLabel:SetPoint("TOPLEFT", 18, y); custLabel:SetWidth(400); custLabel:SetJustifyH("LEFT")
custLabel:SetText("Write your own messages below. They appear in the send window message dropdown.\nPlaceholders: {praise}, {role}, {spec}, {btag}")

local CUSTOM_BOX_H, CUSTOM_GAP, customBoxes = 22, 4, {}
for ci = 1, SSW.MAX_CUSTOM_LINES do
    local boxY = y - 32 - ((ci - 1) * (CUSTOM_BOX_H + CUSTOM_GAP))
    local numLbl = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    numLbl:SetPoint("TOPLEFT", 18, boxY - 3); numLbl:SetText(tostring(ci) .. ".")
    local box = CreateFrame("EditBox", "SSW_CustomBox" .. ci, scrollChild, "InputBoxTemplate")
    box:SetSize(360, CUSTOM_BOX_H); box:SetPoint("TOPLEFT", 36, boxY); box:SetAutoFocus(false); box:SetMaxLetters(140); box.idx = ci
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end); box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self)
        if not SSW_Config then return end; SSW_Config.customLines = SSW_Config.customLines or {}
        local val = strtrim(self:GetText()); SSW_Config.customLines[self.idx] = (val ~= "") and val or nil
        if SSW.UI and SSW.UI.RebuildRowMessageDropdowns then SSW.UI.RebuildRowMessageDropdowns() end
    end)
    customBoxes[ci] = box
end

-- BAD MODE section
local yBadMode = y - 32 - (SSW.MAX_CUSTOM_LINES * (CUSTOM_BOX_H + CUSTOM_GAP)) - 20
local UpdateBadCustomBoxesVisibility -- Forward declaration

local cbBadMode = CreateFrame("CheckButton", nil, scrollChild, "ChatConfigCheckButtonTemplate")
cbBadMode:SetPoint("TOPLEFT", 18, yBadMode); cbBadMode.Text:ClearAllPoints()
cbBadMode.Text:SetPoint("LEFT", cbBadMode, "RIGHT", 6, 1); cbBadMode.Text:SetWidth(370); cbBadMode.Text:SetJustifyH("LEFT")
cbBadMode.Text:SetText("|cFFFF4444BAD MODE|r - Unlock negative/critical messages")
cbBadMode:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    if checked then StaticPopup_Show("SSW_BAD_MODE_WARNING")
    else
        SSW_Config.badModeEnabled = false; SSW.Print("BAD MODE disabled.")
        if SSW.UI and SSW.UI.RebuildRowMessageDropdowns then
            SSW.UI.RebuildRowMessageDropdowns()
        end
        if SSW.UI and SSW.UI.rows then
            for i = 1, SSW.MAX_ROWS do
                local r = SSW.UI.rows[i]
                -- Reset BAD message selections when disabling BAD MODE
                if r and r.badMsgIndex then
                    r.badMsgIndex = nil
                    if r.dropdown then
                        UIDropDownMenu_SetText(r.dropdown, "Choose one...")
                    end
                end
            end
        end
        UpdateBadCustomBoxesVisibility()
    end
end)

local badModeWarning = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
badModeWarning:SetPoint("TOPLEFT", cbBadMode, "BOTTOMLEFT", 0, -5); badModeWarning:SetWidth(370); badModeWarning:SetJustifyH("LEFT")
badModeWarning:SetText("|cFFFF8800WARNING:|r May result in reports. Use responsibly."); badModeWarning:SetTextColor(1, 0.5, 0, 1)

-- Custom BAD Lines section
local yBadCustom, badSectionSep, badSectionLabel = AddSectionHeader(scrollChild, "CUSTOM BAD MESSAGE LINES", yBadMode - 50)
local badCustLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
badCustLabel:SetPoint("TOPLEFT", 18, yBadCustom); badCustLabel:SetWidth(400); badCustLabel:SetJustifyH("LEFT")
badCustLabel:SetText("Write your own BAD messages below (only visible when BAD MODE enabled).\nPlaceholders: {praise}, {role}, {spec}, {btag}")

local customBadBoxes, customBadNumLabels = {}, {}
for ci = 1, SSW.MAX_CUSTOM_BAD_LINES do
    local boxY = yBadCustom - 32 - ((ci - 1) * (CUSTOM_BOX_H + CUSTOM_GAP))
    local numLbl = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    numLbl:SetPoint("TOPLEFT", 18, boxY - 3); numLbl:SetText(tostring(ci) .. "."); numLbl:Hide()
    local box = CreateFrame("EditBox", "SSW_CustomBadBox" .. ci, scrollChild, "InputBoxTemplate")
    box:SetSize(360, CUSTOM_BOX_H); box:SetPoint("TOPLEFT", 36, boxY); box:SetAutoFocus(false); box:SetMaxLetters(140); box.idx = ci
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end); box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self)
        if not SSW_Config then return end; SSW_Config.customBadLines = SSW_Config.customBadLines or {}
        local val = strtrim(self:GetText()); SSW_Config.customBadLines[self.idx] = (val ~= "") and val or nil
        if SSW.UI and SSW.UI.RebuildRowMessageDropdowns then SSW.UI.RebuildRowMessageDropdowns() end
    end)
    box:Hide(); customBadBoxes[ci] = box; customBadNumLabels[ci] = numLbl
end

-- Hide BAD section elements by default
badSectionSep:Hide(); badSectionLabel:Hide(); badCustLabel:Hide()
scrollChild.customBadBoxes = customBadBoxes; scrollChild.customBadNumLabels = customBadNumLabels
scrollChild.badCustLabel = badCustLabel; scrollChild.badSectionSep = badSectionSep; scrollChild.badSectionLabel = badSectionLabel
scrollChild.yBadCustomAfter = yBadCustom - 32 - (SSW.MAX_CUSTOM_BAD_LINES * (CUSTOM_BOX_H + CUSTOM_GAP))

-- Update BAD custom boxes visibility
UpdateBadCustomBoxesVisibility = function()
    local enabled = SSW_Config and SSW_Config.badModeEnabled
    badCustLabel:SetShown(enabled); badSectionSep:SetShown(enabled); badSectionLabel:SetShown(enabled)
    for ci = 1, SSW.MAX_CUSTOM_BAD_LINES do
        local box, numLbl = customBadBoxes[ci], customBadNumLabels[ci]
        if box then box:SetShown(enabled) end
        if numLbl then numLbl:SetShown(enabled) end
    end
end

-- BAD MODE confirmation dialog
if not StaticPopupDialogs["SSW_BAD_MODE_WARNING"] then
    StaticPopupDialogs["SSW_BAD_MODE_WARNING"] = {
        text = "|cFFFF4444Enable BAD MODE?|r\n\nThis unlocks the ability to send negative/critical messages to other players.\n\n|cFFFF8800WARNING:|r Using this feature may result in reports or account action if you harass other players.\n\nAre you sure you want to enable this?",
        button1 = "Yes, Enable", button2 = "Cancel",
        OnAccept = function()
            SSW_Config.badModeEnabled = true; cbBadMode:SetChecked(true); SSW.Print("|cFFFF4444BAD MODE|r enabled. Use responsibly.")
            if SSW.UI and SSW.UI.RebuildRowMessageDropdowns then
                SSW.UI.RebuildRowMessageDropdowns()
            end
            UpdateBadCustomBoxesVisibility()
        end,
        OnCancel = function() cbBadMode:SetChecked(false) end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
end

-- Set scroll height and close button
scrollChild:SetHeight(math.abs(yBadCustom) + 200)
local closeBtnCfg = CreateFrame("Button", nil, configWin, "UIPanelButtonTemplate")
closeBtnCfg:SetSize(140, 36); closeBtnCfg:SetPoint("BOTTOM", 0, 10); closeBtnCfg:SetText("Close")
closeBtnCfg:SetNormalFontObject("GameFontNormalLarge"); closeBtnCfg:SetScript("OnClick", function() configWin:Hide() end)

-- OnShow handler
configWin:SetScript("OnShow", function()
    cbBadMode:SetChecked(SSW_Config and SSW_Config.badModeEnabled)
    for ci = 1, SSW.MAX_CUSTOM_LINES do
        local box = customBoxes[ci]
        if box then box:SetText((SSW_Config and SSW_Config.customLines and SSW_Config.customLines[ci]) or "") end
    end
    for ci = 1, SSW.MAX_CUSTOM_BAD_LINES do
        local box = customBadBoxes[ci]
        if box then box:SetText((SSW_Config and SSW_Config.customBadLines and SSW_Config.customBadLines[ci]) or "") end
    end
    UpdateBadCustomBoxesVisibility()
    if SSW.UI and SSW.UI.RebuildRowMessageDropdowns then SSW.UI.RebuildRowMessageDropdowns() end
end)

function SSW.ShowSettings() configWin:Show() end
SSW.Settings.configWin = configWin
