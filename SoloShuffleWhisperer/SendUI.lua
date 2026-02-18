-- SendUI.lua
-- Send window for Solo Shuffle Whisperer - Player table UI

SSW = SSW or {}
SSW.UI = SSW.UI or {}

-- Local references to helper functions
local ClassIconTag = SSW.UI.ClassIconTag
local SpecIconTag = SSW.UI.SpecIconTag
local RoleIconTag = SSW.UI.RoleIconTag
local RoleText = SSW.UI.RoleText
local GetClassColorStr = SSW.UI.GetClassColorStr

-- Layout constants
local CHECKBOX_INLINE_X = 150  -- Horizontal position for inline checkboxes after dropdown
local CHECKBOX_Y = -39         -- Vertical position for inline checkboxes

-- =========================================
-- SEND WINDOW
-- =========================================

local sendWin = CreateFrame("Frame", "SSW_SendWin", UIParent, "BasicFrameTemplateWithInset")
sendWin:SetSize(720, 580)
sendWin:SetPoint("CENTER", 0, 80)
sendWin:SetMovable(true)
sendWin:EnableMouse(true)
sendWin:RegisterForDrag("LeftButton")
sendWin:SetScript("OnDragStart", sendWin.StartMoving)
sendWin:SetScript("OnDragStop", sendWin.StopMovingOrSizing)
sendWin:SetFrameStrata("HIGH")
sendWin:SetFrameLevel(100)
sendWin:Hide()

SSW.UI.sendWin = sendWin

sendWin.title = sendWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
sendWin.title:SetPoint("TOPLEFT", 18, -8)
sendWin.title:SetText("Solo Shuffle Whisperer")

-- Status bar
local statusBg = CreateFrame("Frame", nil, sendWin, "BackdropTemplate")
statusBg:SetPoint("TOPLEFT", 12, -35)
statusBg:SetPoint("TOPRIGHT", -12, -35)
statusBg:SetHeight(45)
statusBg:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
statusBg:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
statusBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

sendWin.statusText = sendWin:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
sendWin.statusText:SetPoint("TOPLEFT", statusBg, "TOPLEFT", 10, -8)

sendWin.subText = sendWin:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
sendWin.subText:SetPoint("TOPLEFT", sendWin.statusText, "BOTTOMLEFT", 0, -4)

sendWin.noteLine = sendWin:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
sendWin.noteLine:SetPoint("TOPLEFT", 12, -88)
sendWin.noteLine:SetWidth(680)
sendWin.noteLine:SetJustifyH("LEFT")

-- Separator
local sep1 = sendWin:CreateTexture(nil, "ARTWORK")
sep1:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
sep1:SetPoint("TOPLEFT", 12, -100)
sep1:SetPoint("TOPRIGHT", -12, -100)
sep1:SetHeight(8)

-- Header
local headerBg = CreateFrame("Frame", nil, sendWin, "BackdropTemplate")
headerBg:SetPoint("TOPLEFT", 12, -108)
headerBg:SetPoint("TOPRIGHT", -12, -108)
headerBg:SetHeight(26)
headerBg:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, tileSize = 16,
})
headerBg:SetBackdropColor(0.1, 0.1, 0.1, 0.5)

local h1 = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
h1:SetPoint("LEFT", 28, 0)
h1:SetText("Player (Spec)")
h1:SetTextColor(1, 0.82, 0, 1)

local h2 = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
h2:SetPoint("LEFT", 268, 0)
h2:SetText("Message")
h2:SetTextColor(1, 0.82, 0, 1)

-- Helper function to update checkbox visibility based on dropdown selection
local function UpdateCheckboxVisibility(r)
    -- Show BNet checkbox only when GOOD message is selected
    if r.msg1Index and r.msg1Index > 0 then
        r.cbBnet:Show()
        if r.cbBnetLabel then r.cbBnetLabel:Show() end
        r.cbIgnore:Hide()
        if r.cbIgnoreLabel then r.cbIgnoreLabel:Hide() end
    -- Show Ignore checkbox only when BAD message is selected
    elseif r.badMsgIndex and r.badMsgIndex > 0 then
        r.cbBnet:Hide()
        if r.cbBnetLabel then r.cbBnetLabel:Hide() end
        r.cbIgnore:Show()
        if r.cbIgnoreLabel then r.cbIgnoreLabel:Show() end
    -- Hide both when no message is selected
    else
        r.cbBnet:Hide()
        if r.cbBnetLabel then r.cbBnetLabel:Hide() end
        r.cbIgnore:Hide()
        if r.cbIgnoreLabel then r.cbIgnoreLabel:Hide() end
    end
end

-- Rows
local rows = {}
for i = 1, SSW.MAX_ROWS do
    local r = CreateFrame("Frame", nil, sendWin)
    r:SetSize(696, 72)
    r:SetPoint("TOPLEFT", 12, -134 - ((i-1) * 74))
    r:Hide()

    -- Background
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetColorTexture(0, 0, 0, (i % 2 == 0) and 0.15 or 0.05)

    -- Border
    r.border = r:CreateTexture(nil, "BORDER")
    r.border:SetColorTexture(0.3, 0.3, 0.3, 0.3)
    r.border:SetPoint("BOTTOMLEFT", 0, 0)
    r.border:SetPoint("BOTTOMRIGHT", 0, 0)
    r.border:SetHeight(1)

    -- Player name and icons
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.text:SetPoint("TOPLEFT", 8, -8)
    r.text:SetWidth(210)
    r.text:SetJustifyH("LEFT")
    
    -- Clickable name overlay button to open check-pvp.fr URL
    r.nameBtn = CreateFrame("Button", nil, r)
    r.nameBtn:SetPoint("TOPLEFT", r.text, "TOPLEFT", 0, 0)
    r.nameBtn:SetPoint("BOTTOMRIGHT", r.text, "BOTTOMRIGHT", 0, 0)
    r.nameBtn:SetHighlightTexture("Interface\\BUTTONS\\UI-Common-MouseHilight")
    r.nameBtn:GetHighlightTexture():SetAlpha(0.3)
    
    r.nameBtn:SetScript("OnEnter", function(self)
        if r.pvpUrl and r.pvpUrl ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Click to open check-pvp.fr", 1, 1, 1)
            GameTooltip:AddLine("View this player's profile", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    end)
    
    r.nameBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    r.nameBtn:SetScript("OnClick", function(self)
        if r.pvpUrl and r.pvpUrl ~= "" then
            local urlToCopy = r.pvpUrl
            
            if not StaticPopupDialogs["SSW_COPY_URL"] then
                StaticPopupDialogs["SSW_COPY_URL"] = {
                    text = "Copy this URL (Ctrl+C):",
                    button1 = "Close",
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    hasEditBox = true,
                    OnShow = function(self, data)
                        local editBox = self.editBox
                        if editBox and editBox.SetText then
                            editBox:SetText(data or "")
                            editBox:HighlightText()
                            editBox:SetFocus()
                        else
                            C_Timer.After(0.05, function()
                                local eb = self.editBox
                                if eb and eb.SetText then
                                    eb:SetText(data or "")
                                    eb:HighlightText()
                                    eb:SetFocus()
                                end
                            end)
                        end
                    end,
                    EditBoxOnEscapePressed = function(self)
                        self:GetParent():Hide()
                    end,
                }
            end
            StaticPopup_Show("SSW_COPY_URL", nil, nil, urlToCopy)
        end
    end)
    
    r.nameBtn:Hide()
    
    -- PvP Check Button
    r.pvpBtn = CreateFrame("Button", nil, r)
    r.pvpBtn:SetSize(20, 20)
    r.pvpBtn:SetPoint("LEFT", r.text, "RIGHT", 4, 0)
    r.pvpBtn:SetHighlightTexture("Interface\\BUTTONS\\UI-Common-MouseHilight")
    
    r.pvpBtn.icon = r.pvpBtn:CreateTexture(nil, "ARTWORK")
    r.pvpBtn.icon:SetAllPoints()
    r.pvpBtn.icon:SetTexture("Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-1")
    r.pvpBtn.icon:SetVertexColor(0.8, 0.6, 1)
    
    r.pvpBtn:SetScript("OnEnter", function(self)
        if r.pvpUrl and r.pvpUrl ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Check PvP Profile", 1, 1, 1)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Key Information:", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("• Current & Best CR", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("• Season Performance", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("• Alt Characters", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("• Achievement History", 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Click player name to open", 0.5, 0.7, 1)
            GameTooltip:Show()
        end
    end)
    
    r.pvpBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    r.pvpBtn:Hide()

    -- Checkbox "+ BNet" (only shown when GOOD message selected, inline after dropdown)
    r.cbBnet = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbBnet:SetSize(26, 26)
    r.cbBnet:SetPoint("TOPLEFT", CHECKBOX_INLINE_X, CHECKBOX_Y)
    r.cbBnet:SetEnabled(true)
    r.cbBnet:Hide()  -- Hidden by default, shown when GOOD message selected
    
    -- Label for BNet checkbox
    r.cbBnetLabel = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.cbBnetLabel:SetPoint("LEFT", r.cbBnet, "RIGHT", 2, 0)
    r.cbBnetLabel:SetText("+BNet")
    r.cbBnetLabel:Hide()
    
    -- Checkbox "Ignore" (only shown when BAD message selected, inline after dropdown)
    r.cbIgnore = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbIgnore:SetSize(26, 26)
    r.cbIgnore:SetPoint("TOPLEFT", CHECKBOX_INLINE_X, CHECKBOX_Y)
    r.cbIgnore:SetEnabled(true)
    r.cbIgnore:Hide()  -- Hidden by default, shown when BAD message selected
    
    -- Label for Ignore checkbox
    r.cbIgnoreLabel = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.cbIgnoreLabel:SetPoint("LEFT", r.cbIgnore, "RIGHT", 2, 0)
    r.cbIgnoreLabel:SetText("Ignore")
    r.cbIgnoreLabel:Hide()
    
    r.cbIgnore:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Ignore player after sending message", 1, 1, 1)
        GameTooltip:Show()
    end)
    r.cbIgnore:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Unified dropdown for all messages
    r.msg1Index = nil  -- Index for GOOD messages
    r.badMsgIndex = nil  -- Index for BAD messages
    
    r.dropdown = CreateFrame("Frame", "SSW_RowDD_" .. i, r, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(r.dropdown, 180)
    r.dropdown:SetPoint("TOPLEFT", 0, -36)
    r.dropdown:SetScale(0.9)
    UIDropDownMenu_SetText(r.dropdown, "Choose one...")
    r.dropdown:Hide()

    UIDropDownMenu_Initialize(r.dropdown, function(self, level)
        local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
        local badList = SSW.GetBadModePresetsWithCustom and SSW.GetBadModePresetsWithCustom() or {}
        
        -- Add "None" option at the top to allow deselection
        local info = UIDropDownMenu_CreateInfo()
        info.text = "-- None --"
        info.checked = (r.msg1Index == nil and r.badMsgIndex == nil)
        info.func = function()
            r.msg1Index = nil
            r.badMsgIndex = nil
            UIDropDownMenu_SetText(r.dropdown, "Choose one...")
            UpdateCheckboxVisibility(r)
            if SSW.UI.UpdateRowPreview then
                SSW.UI.UpdateRowPreview(r)
            end
        end
        UIDropDownMenu_AddButton(info, level)
        
        -- Add separator
        local separator = UIDropDownMenu_CreateInfo()
        separator.text = ""
        separator.isTitle = true
        separator.notCheckable = true
        UIDropDownMenu_AddButton(separator, level)
        
        -- Add GOOD messages
        for idx, txt in ipairs(msg1List) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = txt
            info.checked = (idx == r.msg1Index)
            info.func = function()
                r.msg1Index = idx
                r.badMsgIndex = nil  -- Only one can be selected at a time
                UIDropDownMenu_SetText(r.dropdown, txt)
                UpdateCheckboxVisibility(r)
                if SSW.UI.UpdateRowPreview then
                    SSW.UI.UpdateRowPreview(r)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
        
        -- Add separator before BAD messages if BAD mode is enabled
        if SSW.IsBadModeEnabled and SSW.IsBadModeEnabled() and #badList > 0 then
            local separator = UIDropDownMenu_CreateInfo()
            separator.text = ""
            separator.isTitle = true
            separator.notCheckable = true
            UIDropDownMenu_AddButton(separator, level)
            
            -- Add BAD messages
            for idx, txt in ipairs(badList) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = txt
                info.checked = (idx == r.badMsgIndex)
                info.func = function()
                    r.badMsgIndex = idx
                    r.msg1Index = nil  -- Only one can be selected at a time
                    UIDropDownMenu_SetText(r.dropdown, txt)
                    UpdateCheckboxVisibility(r)
                    if SSW.UI.UpdateRowPreview then
                        SSW.UI.UpdateRowPreview(r)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)

    -- Show dropdowns when row is shown
    function r:ShowDropdowns()
        r.dropdown:Show()
        if not r.msg1Index and not r.badMsgIndex then
            UIDropDownMenu_SetText(r.dropdown, "Choose one...")
        else
            local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
            local badList = SSW.GetBadModePresetsWithCustom and SSW.GetBadModePresetsWithCustom() or {}
            if r.msg1Index then
                local idx = r.msg1Index
                if idx and idx >= 1 and idx <= #msg1List then
                    UIDropDownMenu_SetText(r.dropdown, msg1List[idx])
                end
            elseif r.badMsgIndex then
                local idx = r.badMsgIndex
                if idx and idx >= 1 and idx <= #badList then
                    UIDropDownMenu_SetText(r.dropdown, badList[idx])
                end
            end
        end
        
        -- Update checkbox visibility based on current selection
        UpdateCheckboxVisibility(r)
    end

    -- cbBnet updates preview
    r.cbBnet:SetScript("OnClick", function()
        if SSW.UI.UpdateRowPreview then
            SSW.UI.UpdateRowPreview(r)
        end
    end)

    -- cbIgnore updates preview
    r.cbIgnore:SetScript("OnClick", function()
        if SSW.UI.UpdateRowPreview then
            SSW.UI.UpdateRowPreview(r)
        end
    end)

    rows[i] = r
end

-- Bottom buttons
local sep2 = sendWin:CreateTexture(nil, "ARTWORK")
sep2:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
sep2:SetPoint("BOTTOMLEFT", 12, 60)
sep2:SetPoint("BOTTOMRIGHT", -12, 60)
sep2:SetHeight(8)

local btnBg = CreateFrame("Frame", nil, sendWin, "BackdropTemplate")
btnBg:SetPoint("BOTTOMLEFT", 12, 12)
btnBg:SetPoint("BOTTOMRIGHT", -12, 12)
btnBg:SetHeight(42)
btnBg:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true, tileSize = 16,
})
btnBg:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

local btnNone = CreateFrame("Button", nil, sendWin, "UIPanelButtonTemplate")
btnNone:SetSize(90, 36)
btnNone:SetPoint("BOTTOMLEFT", 18, 15)
btnNone:SetText("None")

local btnSend = CreateFrame("Button", nil, sendWin, "UIPanelButtonTemplate")
btnSend:SetSize(160, 36)
btnSend:SetPoint("LEFT", btnNone, "RIGHT", 8, 0)
btnSend:SetText("Send Whispers")
btnSend:SetNormalFontObject("GameFontNormalLarge")

sendWin:SetScript("OnHide", function()
    if SSW.UnlockSnapshot then
        SSW.UnlockSnapshot()
    end
end)

function SSW.UI.SetSendUIEnabled(enabled)
    btnSend:SetEnabled(enabled)
    btnNone:SetEnabled(enabled)
    btnSend:SetAlpha(enabled and 1 or 0.35)
    btnNone:SetAlpha(enabled and 1 or 0.35)
end

-- None button handler
btnNone:SetScript("OnClick", function()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r:IsShown() then
            -- Reset both dropdowns
            r.msg1Index = nil
            r.badMsgIndex = nil
            UIDropDownMenu_SetText(r.dropdown, "Choose one...")
            UpdateCheckboxVisibility(r)
        end
    end
end)

-- =========================================
-- Preview update (Deprecated - kept for compatibility)
-- =========================================
-- These functions were used for per-row preview text which has been removed from the UI.
-- They are kept as no-ops to prevent errors if external code calls them.
-- Can be removed in a future version after confirming no dependencies.
function SSW.UI.UpdateRowPreview(r)
    -- Preview removed from UI, function kept for compatibility
end

function SSW.UI.UpdateAllPreviews()
    -- Preview removed from UI, function kept for compatibility
end

-- Rebuild row message dropdowns when custom messages change
function SSW.UI.RebuildRowMessageDropdowns()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r and r.dropdown then
            UIDropDownMenu_Initialize(r.dropdown, function(self, level)
                local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
                local badList = SSW.GetBadModePresetsWithCustom and SSW.GetBadModePresetsWithCustom() or {}
                
                -- Add "None" option
                local info = UIDropDownMenu_CreateInfo()
                info.text = "-- None --"
                info.checked = (r.msg1Index == nil and r.badMsgIndex == nil)
                info.func = function()
                    r.msg1Index = nil
                    r.badMsgIndex = nil
                    UIDropDownMenu_SetText(r.dropdown, "Choose one...")
                    UpdateCheckboxVisibility(r)
                end
                UIDropDownMenu_AddButton(info, level)
                
                -- Separator
                local separator = UIDropDownMenu_CreateInfo()
                separator.text = ""
                separator.isTitle = true
                separator.notCheckable = true
                UIDropDownMenu_AddButton(separator, level)
                
                -- GOOD messages
                for idx, txt in ipairs(msg1List) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = txt
                    info.checked = (idx == r.msg1Index)
                    info.func = function()
                        r.msg1Index = idx
                        r.badMsgIndex = nil
                        UIDropDownMenu_SetText(r.dropdown, txt)
                        UpdateCheckboxVisibility(r)
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
                
                -- Separator before BAD messages if BAD mode is enabled
                if SSW.IsBadModeEnabled and SSW.IsBadModeEnabled() and #badList > 0 then
                    local separator = UIDropDownMenu_CreateInfo()
                    separator.text = ""
                    separator.isTitle = true
                    separator.notCheckable = true
                    UIDropDownMenu_AddButton(separator, level)
                    
                    -- BAD messages
                    for idx, txt in ipairs(badList) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = txt
                        info.checked = (idx == r.badMsgIndex)
                        info.func = function()
                            r.badMsgIndex = idx
                            r.msg1Index = nil
                            UIDropDownMenu_SetText(r.dropdown, txt)
                            UpdateCheckboxVisibility(r)
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end
                end
            end)
            
            -- Update displayed text
            if r.dropdown:IsShown() then
                local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
                local badList = SSW.GetBadModePresetsWithCustom and SSW.GetBadModePresetsWithCustom() or {}
                if r.msg1Index and r.msg1Index >= 1 and r.msg1Index <= #msg1List then
                    UIDropDownMenu_SetText(r.dropdown, msg1List[r.msg1Index])
                elseif r.badMsgIndex and r.badMsgIndex >= 1 and r.badMsgIndex <= #badList then
                    UIDropDownMenu_SetText(r.dropdown, badList[r.badMsgIndex])
                end
            end
        end
    end
end

-- =========================================
-- Populate rows from snapshot
-- =========================================
local function ResetRows()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        r.playerName = nil
        r.classFile  = nil
        r.specName   = nil
        r.guid       = nil
        r.specID     = nil
        r.role       = nil
        r.msg1Index  = nil
        r.badMsgIndex = nil
        r.pvpUrl     = nil
        r:Hide()
        r.cbBnet:SetChecked(false)
        r.cbBnet:Hide()
        if r.cbBnetLabel then r.cbBnetLabel:Hide() end
        r.cbIgnore:SetChecked(false)
        r.cbIgnore:Hide()
        if r.cbIgnoreLabel then r.cbIgnoreLabel:Hide() end
        if r.pvpBtn then r.pvpBtn:Hide() end
        if r.nameBtn then r.nameBtn:Hide() end
    end
end

local function PopulateFromSnapshot()
    local snap = SSW.PartySnapshot
    if not snap or not snap.valid or not snap.members then return false end

    local idx = 1
    for _, m in ipairs(snap.members) do
        if idx > SSW.MAX_ROWS then break end
        local r        = rows[idx]
        r.playerName   = m.fullName
        r.classFile    = m.classFile
        r.specName     = m.specName
        r.guid         = m.guid
        r.specID       = m.specID
        r.role         = m.role or "DAMAGER"

        local clean    = SSW.CleanName(m.fullName)
        local roleIcon = RoleIconTag(m.role or "DAMAGER", 14)
        local icon     = SpecIconTag(m.specID, 16)
        if icon == "" then icon = ClassIconTag(m.classFile, 16) end
        local colorStr = GetClassColorStr(m.classFile)

        r.text:SetText(roleIcon .. icon .. "|c" .. colorStr .. clean .. "|r |cffaaaaaa(" .. RoleText(m.role or "DAMAGER") .. ")|r")
        
        if SSW.GetCheckPvpUrl then
            r.pvpUrl = SSW.GetCheckPvpUrl(m.fullName)
            if r.pvpBtn then
                r.pvpBtn:Show()
            end
            if r.nameBtn then
                r.nameBtn:Show()
            end
        end
        
        if r.ShowDropdowns then
            r:ShowDropdowns()
        end
        
        r:Show()
        idx = idx + 1
    end
    return true
end

-- =========================================
-- Status bar
-- =========================================
function SSW.UI.UpdateStatus(isTest)
    sendWin.statusText:SetText("Mode: " .. SSW.ModeText(isTest))

    if isTest then
        sendWin.subText:SetText("|cFFFFFF00TEST MODE|r - Preview only. No whispers will be sent. Select players and press Send to preview messages.")
    elseif SSW.IsArmed() then
        sendWin.subText:SetText("|cFFFF2020LIVE MODE|r - Whispers WILL BE SENT to other players. Double-check your selection before sending!")
    else
        sendWin.subText:SetText("|cFF00FFFFSAFE MODE|r - Preview only. No whispers will be sent. Use /ssw arm to enable LIVE mode.")
    end

    sendWin.noteLine:SetText("Select a message from the dropdown. Click player names to view their PvP profiles.")
end

-- =========================================
-- Public: show window
-- =========================================
function SSW.ShowWhisperWindow(isTest)
    SSW.IsTesting = isTest and true or false

    ResetRows()

    SSW.UI.UpdateStatus(SSW.IsTesting)

    if SSW.IsTesting then
        local t = {
            { fullName = "Shadowstrike-TarrenMill",  classFile = "WARRIOR", specName = "Arms",  specID = 71,  role = "DAMAGER" },
            { fullName = "Frostbite-Ravencrest",     classFile = "MAGE",    specName = "Frost", specID = 64,  role = "DAMAGER" },
            { fullName = "Holyspark-Kazzak",         classFile = "PRIEST",  specName = "Disc",  specID = 256, role = "HEALER" },
            { fullName = "Beastmaster-Silvermoon",   classFile = "HUNTER",  specName = "BM",    specID = 253, role = "DAMAGER" },
            { fullName = "Lightbringer-Draenor",     classFile = "PALADIN", specName = "Ret",   specID = 70,  role = "DAMAGER" },
        }
        SSW.PartySnapshot = {
            takenAt = SSW.Now(),
            members = t, valid = true, locked = false,
        }
        PopulateFromSnapshot()
        sendWin:Show()
        SSW.UI.SetSendUIEnabled(true)
        SSW.UI.UpdateAllPreviews()
        return
    end

    PopulateFromSnapshot()
    sendWin:Show()
    SSW.UI.SetSendUIEnabled(true)
    SSW.UI.UpdateAllPreviews()
end

-- Store rows for Send.lua to access
SSW.UI.rows = rows
SSW.UI.btnSend = btnSend
