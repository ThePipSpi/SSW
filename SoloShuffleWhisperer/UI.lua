-- UI.lua
-- Clean layout: Settings + Send UI with per-row Preview + Thank all button

SSW    = SSW or {}
SSW.UI = SSW.UI or {}

-- =========================================
-- Class icon helper
-- =========================================
local CLASS_ICON_TOKEN = {
    WARRIOR     = "Warrior",    PALADIN     = "Paladin",
    HUNTER      = "Hunter",     ROGUE       = "Rogue",
    PRIEST      = "Priest",     DEATHKNIGHT = "DeathKnight",
    SHAMAN      = "Shaman",     MAGE        = "Mage",
    WARLOCK     = "Warlock",    MONK        = "Monk",
    DRUID       = "Druid",      DEMONHUNTER = "DemonHunter",
    EVOKER      = "Evoker",
}

local function ClassIconTag(classFile, size)
    size = size or 16
    if not classFile then return "" end
    local token = CLASS_ICON_TOKEN[classFile]
    if not token then return "" end
    local path = "Interface\\Icons\\ClassIcon_" .. token
    return ("|T%s:%d:%d:0:0|t "):format(path, size, size)
end

local function SpecIconTag(specID, size)
    size   = size or 16
    specID = tonumber(specID)
    if not specID or specID <= 0     then return "" end
    if not GetSpecializationInfoByID then return "" end
    local _, _, _, icon = GetSpecializationInfoByID(specID)
    if not icon then return "" end
    return ("|T%s:%d:%d:0:0|t "):format(tostring(icon), size, size)
end

local function RoleIconTag(role, size)
    size = size or 14
    if not CreateAtlasMarkup then return "" end
    role = tostring(role or "")
    if role == "TANK"    then return CreateAtlasMarkup("roleicon-tiny-tank",   size, size) .. " " end
    if role == "HEALER"  then return CreateAtlasMarkup("roleicon-tiny-healer", size, size) .. " " end
    if role == "DAMAGER" then return CreateAtlasMarkup("roleicon-tiny-dps",    size, size) .. " " end
    return ""
end

local function RoleText(role)
    role = tostring(role or "")
    if role == "TANK"    then return "Tank"   end
    if role == "HEALER"  then return "Healer" end
    if role == "DAMAGER" then return "DPS"    end
    return "Role?"
end

local function GetClassColorStr(classFile)
    local c = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
           or (RAID_CLASS_COLORS and RAID_CLASS_COLORS["PRIEST"])
    return (c and c.colorStr) or "ffffffff"
end

-- =========================================
-- SETTINGS WINDOW
-- =========================================

local configWin = CreateFrame("Frame", "SSW_ConfigFrame", UIParent, "BasicFrameTemplateWithInset")
configWin:SetSize(450, 550)
configWin:SetPoint("CENTER", 0, 60)
configWin:SetFrameStrata("HIGH")
configWin:SetFrameLevel(100)
configWin:SetMovable(true)
configWin:EnableMouse(true)
configWin:RegisterForDrag("LeftButton")
configWin:SetScript("OnDragStart", configWin.StartMoving)
configWin:SetScript("OnDragStop",  configWin.StopMovingOrSizing)
configWin:Hide()

configWin.title = configWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
configWin.title:SetPoint("TOPLEFT", 14, -10)
configWin.title:SetText("Solo Shuffle Whisperer - Settings")

-- Create scroll frame for settings content
local scrollFrame = CreateFrame("ScrollFrame", nil, configWin, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", configWin.InsetBg, "TOPLEFT", 4, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", configWin.InsetBg, "BOTTOMRIGHT", -24, 50)

local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(scrollFrame:GetWidth())
scrollChild:SetHeight(1)

-- Section separator helper
local function AddSectionHeader(parent, text, yOff)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 14, yOff)
    sep:SetPoint("TOPRIGHT", -14, yOff)
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.6)

    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", 18, yOff - 6)
    lbl:SetTextColor(1, 0.82, 0)
    lbl:SetText(text)
    return yOff - 22
end

-- ── Section 1: Custom Text Lines ──
local y = AddSectionHeader(scrollChild, "CUSTOM MESSAGE LINES  (excluded from Random)", -10)

local custLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
custLabel:SetPoint("TOPLEFT", 18, y)
custLabel:SetWidth(400)
custLabel:SetJustifyH("LEFT")
custLabel:SetText("Write your own messages below. They appear in the send window message dropdown but are never picked by \"Random\".\nPlaceholders: {name}, {praise}, {role}, {spec}, {btag}")

local CUSTOM_BOX_H = 22
local CUSTOM_GAP   = 4
local customBoxes  = {}

for ci = 1, SSW.MAX_CUSTOM_LINES do
    local boxY = y - 32 - ((ci - 1) * (CUSTOM_BOX_H + CUSTOM_GAP))
    local numLbl = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    numLbl:SetPoint("TOPLEFT", 18, boxY - 3)
    numLbl:SetText(tostring(ci) .. ".")

    local box = CreateFrame("EditBox", "SSW_CustomBox" .. ci, scrollChild, "InputBoxTemplate")
    box:SetSize(360, CUSTOM_BOX_H)
    box:SetPoint("TOPLEFT", 36, boxY)
    box:SetAutoFocus(false)
    box:SetMaxLetters(140)
    box.idx = ci
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self)
        if not SSW_Config then return end
        SSW_Config.customLines = SSW_Config.customLines or {}
        local val = strtrim(self:GetText())
        SSW_Config.customLines[self.idx] = (val ~= "") and val or nil
        -- Rebuild row message dropdowns with updated custom lines
        SSW.UI.RebuildRowMessageDropdowns()
    end)

    customBoxes[ci] = box
end

-- ── Section 2: Behavior ──
local yBehav = y - 32 - (SSW.MAX_CUSTOM_LINES * (CUSTOM_BOX_H + CUSTOM_GAP)) - 10
yBehav = AddSectionHeader(scrollChild, "BEHAVIOR", yBehav)

-- Sezione Message 1
local section1 = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
section1:SetPoint("TOPLEFT", 12, yBehav - 8)
section1:SetPoint("TOPRIGHT", -12, yBehav - 8)
section1:SetHeight(85)
section1:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
section1:SetBackdropColor(0.05, 0.05, 0.05, 0.5)
section1:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

local lbl1 = section1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lbl1:SetPoint("TOPLEFT", 10, -8)
lbl1:SetText("Global Message 1 Default")
lbl1:SetTextColor(1, 0.82, 0, 1)

local hint1 = section1:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint1:SetPoint("TOPLEFT", lbl1, "BOTTOMLEFT", 0, -2)
hint1:SetText("Default preset (can be changed per-player in send window)")

-- Sezione Message 2
local section2 = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
section2:SetPoint("TOPLEFT", 12, yBehav - 108)
section2:SetPoint("TOPRIGHT", -12, yBehav - 108)
section2:SetHeight(85)
section2:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
section2:SetBackdropColor(0.05, 0.05, 0.05, 0.5)
section2:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

local lbl2 = section2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lbl2:SetPoint("TOPLEFT", 10, -8)
lbl2:SetText("Message 2 (BattleTag)")
lbl2:SetTextColor(1, 0.82, 0, 1)

local hint2 = section2:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint2:SetPoint("TOPLEFT", lbl2, "BOTTOMLEFT", 0, -2)
hint2:SetText("Optional second message with BattleTag info")

-- Checkboxes
local cbAutoGreet = CreateFrame("CheckButton", nil, scrollChild, "ChatConfigCheckButtonTemplate")
cbAutoGreet:SetPoint("TOPLEFT", 18, yBehav - 208)
cbAutoGreet.Text:ClearAllPoints()
cbAutoGreet.Text:SetPoint("LEFT", cbAutoGreet, "RIGHT", 6, 1)
cbAutoGreet.Text:SetWidth(370)
cbAutoGreet.Text:SetJustifyH("LEFT")
cbAutoGreet.Text:SetText("Auto greeting in party (accessibility)")
cbAutoGreet:SetScript("OnClick", function(self)
    SSW_Config.autoGreetEnabled = self:GetChecked() and true or false
end)

-- BAD MODE checkbox with warning
local cbBadMode = CreateFrame("CheckButton", nil, scrollChild, "ChatConfigCheckButtonTemplate")
cbBadMode:SetPoint("TOPLEFT", cbAutoGreet, "BOTTOMLEFT", 0, -10)
cbBadMode.Text:ClearAllPoints()
cbBadMode.Text:SetPoint("LEFT", cbBadMode, "RIGHT", 6, 1)
cbBadMode.Text:SetWidth(370)
cbBadMode.Text:SetJustifyH("LEFT")
cbBadMode.Text:SetText("|cFFFF4444BAD MODE|r - Unlock negative/critical messages")
cbBadMode:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    if checked then
        -- Show warning dialog
        StaticPopup_Show("SSW_BAD_MODE_WARNING")
    else
        SSW_Config.badModeEnabled = false
        SSW.Print("BAD MODE disabled.")
        -- Hide BAD checkboxes in whisper window
        if SSW.UI and SSW.UI.rows then
            for i = 1, SSW.MAX_ROWS do
                local r = SSW.UI.rows[i]
                if r and r.cbBad then
                    r.cbBad:Hide()
                    r.cbBad:SetChecked(false)
                    if r.badDropdown then
                        r.badDropdown:Hide()
                    end
                end
            end
        end
        -- Hide custom BAD message boxes
        UpdateBadCustomBoxesVisibility()
    end
end)

-- BAD MODE warning text
local badModeWarning = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
badModeWarning:SetPoint("TOPLEFT", cbBadMode, "BOTTOMLEFT", 0, -5)
badModeWarning:SetWidth(370)
badModeWarning:SetJustifyH("LEFT")
badModeWarning:SetText("|cFFFF8800WARNING:|r May result in reports. Use responsibly.")
badModeWarning:SetTextColor(1, 0.5, 0, 1)

-- ── Section: Custom BAD Lines (only visible when BAD MODE enabled) ──
local yBadCustom = AddSectionHeader(scrollChild, "CUSTOM BAD MESSAGE LINES  (excluded from Random)", -10)
yBadCustom = yBehav - 265  -- Position below warning (adjusted since delay section removed)

local badCustLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
badCustLabel:SetPoint("TOPLEFT", 18, yBadCustom)
badCustLabel:SetWidth(400)
badCustLabel:SetJustifyH("LEFT")
badCustLabel:SetText("Write your own BAD messages below (only visible when BAD MODE enabled).\nPlaceholders: {role}, {spec}")

local customBadBoxes = {}
local customBadNumLabels = {}
for ci = 1, SSW.MAX_CUSTOM_BAD_LINES do
    local boxY = yBadCustom - 32 - ((ci - 1) * (CUSTOM_BOX_H + CUSTOM_GAP))
    local numLbl = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    numLbl:SetPoint("TOPLEFT", 18, boxY - 3)
    numLbl:SetText(tostring(ci) .. ".")
    
    local box = CreateFrame("EditBox", "SSW_CustomBadBox" .. ci, scrollChild, "InputBoxTemplate")
    box:SetSize(360, CUSTOM_BOX_H)
    box:SetPoint("TOPLEFT", 36, boxY)
    box:SetAutoFocus(false)
    box:SetMaxLetters(140)
    box.idx = ci
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self)
        if not SSW_Config then return end
        SSW_Config.customBadLines = SSW_Config.customBadLines or {}
        local val = strtrim(self:GetText())
        SSW_Config.customBadLines[self.idx] = (val ~= "") and val or nil
        -- Rebuild row message dropdowns with updated custom bad lines
        SSW.UI.RebuildRowMessageDropdowns()
    end)
    
    customBadBoxes[ci] = box
    customBadNumLabels[ci] = numLbl
    
    -- Hide by default (only show when BAD MODE enabled)
    numLbl:Hide()
    box:Hide()
end

-- Store references for showing/hiding
scrollChild.customBadBoxes = customBadBoxes
scrollChild.customBadNumLabels = customBadNumLabels
scrollChild.badCustLabel = badCustLabel
scrollChild.yBadCustomAfter = yBadCustom - 32 - (SSW.MAX_CUSTOM_BAD_LINES * (CUSTOM_BOX_H + CUSTOM_GAP))

-- Helper function to show/hide custom BAD boxes
local function UpdateBadCustomBoxesVisibility()
    local enabled = SSW_Config and SSW_Config.badModeEnabled
    badCustLabel:SetShown(enabled)
    for ci = 1, SSW.MAX_CUSTOM_BAD_LINES do
        local box = customBadBoxes[ci]
        local numLbl = customBadNumLabels[ci]
        if box then
            box:SetShown(enabled)
        end
        if numLbl then
            numLbl:SetShown(enabled)
        end
    end
end

-- BAD MODE confirmation dialog
if not StaticPopupDialogs["SSW_BAD_MODE_WARNING"] then
    StaticPopupDialogs["SSW_BAD_MODE_WARNING"] = {
        text = "|cFFFF4444Enable BAD MODE?|r\n\nThis unlocks the ability to send negative/critical messages to other players.\n\n|cFFFF8800WARNING:|r Using this feature may result in reports or account action if you harass other players.\n\nAre you sure you want to enable this?",
        button1 = "Yes, Enable",
        button2 = "Cancel",
        OnAccept = function()
            SSW_Config.badModeEnabled = true
            SSW.Print("|cFFFF4444BAD MODE|r enabled. Use responsibly.")
            -- Show BAD checkboxes in whisper window
            if SSW.UI and SSW.UI.rows then
                for i = 1, SSW.MAX_ROWS do
                    local r = SSW.UI.rows[i]
                    if r and r.cbBad then
                        r.cbBad:Show()
                    end
                end
            end
            -- Show custom BAD message boxes
            UpdateBadCustomBoxesVisibility()
        end,
        OnCancel = function()
            cbBadMode:SetChecked(false)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

local hint = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint:SetPoint("TOPLEFT", cbAutoGreet, "BOTTOMLEFT", 0, -15)
hint:SetWidth(400)
hint:SetJustifyH("LEFT")
hint:SetText("Available placeholders: {name}, {praise}, {role}, {spec}, {btag}\nMessage 1 can be customized per-player in the send window.")
hint:SetTextColor(0.7, 0.7, 0.7, 1)

local closeBtnCfg = CreateFrame("Button", nil, configWin, "UIPanelButtonTemplate")
closeBtnCfg:SetSize(140, 36)
closeBtnCfg:SetPoint("BOTTOM", 0, 10)
closeBtnCfg:SetText("Close")
closeBtnCfg:SetNormalFontObject("GameFontNormalLarge")
closeBtnCfg:SetScript("OnClick", function() configWin:Hide() end)

local function MakeDropdown(parent, name, width, getItemsFunc, onPick)
    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, width)
    UIDropDownMenu_Initialize(dd, function(self, level)
        local items = type(getItemsFunc) == "function" and getItemsFunc() or getItemsFunc
        local selected = UIDropDownMenu_GetSelectedID(dd) or 1
        for i, txt in ipairs(items) do
            local info   = UIDropDownMenu_CreateInfo()
            info.text    = txt
            info.checked = (i == selected)
            info.func    = function()
                UIDropDownMenu_SetSelectedID(dd, i)
                UIDropDownMenu_SetText(dd, txt)
                onPick(i)
                CloseDropDownMenus()
                if SSW.UI and SSW.UI.sendWin and SSW.UI.sendWin:IsShown()
                   and SSW.UI.UpdateAllPreviews then
                    SSW.UI.UpdateAllPreviews()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    return dd
end

local dd1 = MakeDropdown(scrollChild, "SSW_DD1", 360, function() 
    return SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
end, function(i)
    SSW_Config.msg1Index = i
end)
dd1:SetPoint("TOPLEFT", section1, "TOPLEFT", -2, -32)

local dd2 = MakeDropdown(scrollChild, "SSW_DD2", 360, SSW.MSG2_PRESETS, function(i)
    SSW_Config.msg2Index = i
end)
dd2:SetPoint("TOPLEFT", section2, "TOPLEFT", -2, -32)

-- Calculate scroll child height dynamically
-- Base height is from top to just after behavior section
local baseHeight = math.abs(yBehav - 210) + 80
-- If BAD MODE is enabled, add height for custom BAD boxes
if SSW_Config and SSW_Config.badModeEnabled and scrollChild.yBadCustomAfter then
    local badSectionHeight = math.abs(scrollChild.yBadCustomAfter - yBehav + 210)
    baseHeight = baseHeight + badSectionHeight + 50  -- Extra padding
end
scrollChild:SetHeight(baseHeight)

configWin:SetScript("OnShow", function()
    cbAutoGreet:SetChecked(SSW_Config and SSW_Config.autoGreetEnabled)
    cbBadMode:SetChecked(SSW_Config and SSW_Config.badModeEnabled)
    cbBadMode:SetChecked(SSW_Config and SSW_Config.badModeEnabled)

    local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
    local i1 = tonumber(SSW_Config.msg1Index) or 1
    local i2 = tonumber(SSW_Config.msg2Index) or 1
    if i1 < 1 or i1 > #msg1List then i1 = 1 end
    if i2 < 1 or i2 > #SSW.MSG2_PRESETS then i2 = 1 end

    UIDropDownMenu_SetSelectedID(dd1, i1)
    UIDropDownMenu_SetText(dd1, msg1List[i1])
    UIDropDownMenu_SetSelectedID(dd2, i2)
    UIDropDownMenu_SetText(dd2, SSW.MSG2_PRESETS[i2])
    
    -- Populate custom line edit boxes
    for ci = 1, SSW.MAX_CUSTOM_LINES do
        local box = customBoxes[ci]
        if box then
            local val = (SSW_Config and SSW_Config.customLines and SSW_Config.customLines[ci]) or ""
            box:SetText(val)
        end
    end
    
    -- Populate custom BAD line edit boxes
    for ci = 1, SSW.MAX_CUSTOM_BAD_LINES do
        local box = customBadBoxes[ci]
        if box then
            local val = (SSW_Config and SSW_Config.customBadLines and SSW_Config.customBadLines[ci]) or ""
            box:SetText(val)
        end
    end
    
    -- Show/hide custom BAD boxes based on BAD MODE
    UpdateBadCustomBoxesVisibility()
    
    -- Rebuild row message dropdowns with latest custom lines
    SSW.UI.RebuildRowMessageDropdowns()
end)

function SSW.ShowSettings()
    configWin:Show()
end

-- =========================================
-- SEND WINDOW
-- =========================================

local sendWin = CreateFrame("Frame", "SSW_SendWin", UIParent, "BasicFrameTemplateWithInset")
sendWin:SetSize(720, 580) -- Più larga per layout migliore
sendWin:SetPoint("CENTER", 0, 80) -- Positioned higher to avoid action bars
sendWin:SetMovable(true)
sendWin:EnableMouse(true)
sendWin:RegisterForDrag("LeftButton")
sendWin:SetScript("OnDragStart", sendWin.StartMoving)
sendWin:SetScript("OnDragStop", sendWin.StopMovingOrSizing)
sendWin:Hide()

SSW.UI.sendWin = sendWin

sendWin.title = sendWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
sendWin.title:SetPoint("TOPLEFT", 18, -8)
sendWin.title:SetText("Solo Shuffle Whisperer")

-- Status bar con sfondo
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

-- Separatore
local sep1 = sendWin:CreateTexture(nil, "ARTWORK")
sep1:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
sep1:SetPoint("TOPLEFT", 12, -100)
sep1:SetPoint("TOPRIGHT", -12, -100)
sep1:SetHeight(8)

-- Header con sfondo
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
h2:SetText("BNet")
h2:SetTextColor(1, 0.82, 0, 1)

local h3 = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
h3:SetPoint("LEFT", 328, 0)
h3:SetText("Ignore")
h3:SetTextColor(1, 0.82, 0, 1)

-- Rows
local rows = {}
for i = 1, SSW.MAX_ROWS do
    local r = CreateFrame("Frame", nil, sendWin)
    r:SetSize(696, 72) -- Più alta per layout comodo
    r:SetPoint("TOPLEFT", 12, -134 - ((i-1) * 74))
    r:Hide()

    -- Sfondo alternato
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.bg:SetColorTexture(0, 0, 0, (i % 2 == 0) and 0.15 or 0.05)

    -- Bordo sottile
    r.border = r:CreateTexture(nil, "BORDER")
    r.border:SetColorTexture(0.3, 0.3, 0.3, 0.3)
    r.border:SetPoint("BOTTOMLEFT", 0, 0)
    r.border:SetPoint("BOTTOMRIGHT", 0, 0)
    r.border:SetHeight(1)

    -- Player name e icone (in alto)
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
            -- Store URL in local variable to avoid closure issues
            local urlToCopy = r.pvpUrl
            
            -- Create a copy-paste dialog
            if not StaticPopupDialogs["SSW_COPY_URL"] then
                StaticPopupDialogs["SSW_COPY_URL"] = {
                    text = "Copy this URL (Ctrl+C):",
                    button1 = "Close",
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    hasEditBox = true,
                    OnShow = function(self, data)
                        -- Try to access editBox immediately
                        local editBox = self.editBox
                        if editBox and editBox.SetText then
                            editBox:SetText(data or "")
                            editBox:HighlightText()
                            editBox:SetFocus()
                        else
                            -- Fallback: try after a short delay for WoW 11.0+ compatibility
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
    
    r.nameBtn:Hide() -- Hidden by default, shown when player is set
    
    -- PvP Check Button (info icon with tooltip)
    r.pvpBtn = CreateFrame("Button", nil, r)
    r.pvpBtn:SetSize(20, 20)  -- Increased from 16x16 to 20x20 for easier clicking
    r.pvpBtn:SetPoint("LEFT", r.text, "RIGHT", 4, 0)
    r.pvpBtn:SetHighlightTexture("Interface\\BUTTONS\\UI-Common-MouseHilight")
    
    -- Create a custom icon using texture
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
    
    r.pvpBtn:Hide() -- Hidden by default, shown when player is set

    -- Checkbox "Send" - REMOVED (not needed, selecting from dropdown implies sending)
    r.cbMain = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbMain:SetSize(26, 26)
    r.cbMain:SetPoint("TOPLEFT", 268, -6)
    r.cbMain:SetEnabled(false)
    r.cbMain:Hide()  -- Always hidden now

    -- Checkbox "Use {name}" - HIDDEN per requisito precedente
    r.cbName = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbName:SetSize(26, 26)
    r.cbName:SetPoint("TOPLEFT", 268, -6)
    r.cbName:SetEnabled(false)
    r.cbName:Hide()  -- Always hidden now

    -- Checkbox "+ BNet"
    r.cbBnet = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbBnet:SetSize(26, 26)
    r.cbBnet:SetPoint("TOPLEFT", 268, -6)
    r.cbBnet:SetEnabled(true)

    -- Checkbox "Bad" - REMOVED (use dropdown instead)
    r.cbBad = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbBad:SetSize(26, 26)
    r.cbBad:SetPoint("TOPLEFT", 328, -6)
    r.cbBad:SetEnabled(false)
    r.cbBad:Hide()  -- Always hidden now - use dropdown instead
    
    -- Checkbox "Ignore" (ignore player after sending message)
    r.cbIgnore = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbIgnore:SetSize(26, 26)
    r.cbIgnore:SetPoint("TOPLEFT", 328, -6)
    r.cbIgnore:SetEnabled(true)
    if not SSW.IsBadModeEnabled or not SSW.IsBadModeEnabled() then
        r.cbIgnore:Hide()  -- Only show if BAD MODE enabled
    end
    
    -- Add tooltip for ignore checkbox
    r.cbIgnore:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Ignore player after sending message", 1, 1, 1)
        GameTooltip:Show()
    end)
    r.cbIgnore:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Checkbox "Blame" - REMOVED (use BAD dropdown with ignore checkbox instead)
    r.cbBlame = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbBlame:SetSize(26, 26)
    r.cbBlame:SetPoint("TOPLEFT", 388, -6)
    r.cbBlame:SetEnabled(false)
    r.cbBlame:Hide()  -- Always hidden now
    
    -- Keep old cbIgnoreOnBad reference for compatibility
    r.cbIgnoreOnBad = r.cbIgnore

    -- Dropdown per msg1 (GOOD messages)
    r.msg1Index = 1
    r.dropdown = CreateFrame("Frame", "SSW_RowDD_" .. i, r, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(r.dropdown, 280)
    r.dropdown:SetPoint("TOPLEFT", 0, -30)
    r.dropdown:SetScale(0.9)
    UIDropDownMenu_SetText(r.dropdown, "Select GOOD message...")
    r.dropdown:Hide()

    UIDropDownMenu_Initialize(r.dropdown, function(self, level)
        local selectedIdx = r.msg1Index or 1
        local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
        for idx, txt in ipairs(msg1List) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = txt
            info.checked = (idx == selectedIdx)
            info.func = function()
                r.msg1Index = idx
                UIDropDownMenu_SetSelectedID(r.dropdown, idx)
                UIDropDownMenu_SetText(r.dropdown, txt)
                -- Reset BAD dropdown selection when GOOD is chosen
                r.badMsgIndex = nil
                if r.badDropdown then
                    UIDropDownMenu_SetText(r.badDropdown, "Select BAD message...")
                end
                CloseDropDownMenus()
                if SSW.UI.UpdateRowPreview then
                    SSW.UI.UpdateRowPreview(r)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- BAD MODE dropdown (shown to the right of GOOD dropdown when BAD MODE enabled)
    r.badMsgIndex = nil
    r.badDropdown = CreateFrame("Frame", "SSW_RowBadDD_" .. i, r, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(r.badDropdown, 280)
    r.badDropdown:SetPoint("TOPLEFT", 290, -30)  -- Position to the right of GOOD dropdown
    r.badDropdown:SetScale(0.9)
    UIDropDownMenu_SetText(r.badDropdown, "Select BAD message...")
    r.badDropdown:Hide()

    UIDropDownMenu_Initialize(r.badDropdown, function(self, level)
        local selectedIdx = r.badMsgIndex or 1
        local badList = SSW.GetBadModePresetsWithCustom and SSW.GetBadModePresetsWithCustom() or {}
        for idx, txt in ipairs(badList) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = txt
            info.checked = (idx == selectedIdx)
            info.func = function()
                r.badMsgIndex = idx
                UIDropDownMenu_SetSelectedID(r.badDropdown, idx)
                UIDropDownMenu_SetText(r.badDropdown, txt)
                -- Reset GOOD dropdown selection when BAD is chosen
                r.msg1Index = nil
                UIDropDownMenu_SetText(r.dropdown, "Select GOOD message...")
                CloseDropDownMenus()
                if SSW.UI.UpdateRowPreview then
                    SSW.UI.UpdateRowPreview(r)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Preview (terza riga, più evidente)
    r.preview = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.preview:SetPoint("TOPLEFT", 295, -35)
    r.preview:SetWidth(390)
    r.preview:SetJustifyH("LEFT")

    function r:SetEnabledSubs(enabled)
        -- This function is now deprecated since dropdowns are always shown
        -- Kept for compatibility but does nothing
    end
    
    -- Show dropdowns when row is shown
    function r:ShowDropdowns()
        -- Show GOOD dropdown (always)
        r.dropdown:Show()
        if not r.msg1Index then
            UIDropDownMenu_SetText(r.dropdown, "Select GOOD message...")
        else
            local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
            local idx = r.msg1Index or 1
            if idx >= 1 and idx <= #msg1List then
                UIDropDownMenu_SetSelectedID(r.dropdown, idx)
                UIDropDownMenu_SetText(r.dropdown, msg1List[idx])
            end
        end
        
        -- Show BAD dropdown if BAD MODE is enabled
        if SSW.IsBadModeEnabled and SSW.IsBadModeEnabled() and r.badDropdown then
            r.badDropdown:Show()
            if not r.badMsgIndex then
                UIDropDownMenu_SetText(r.badDropdown, "Select BAD message...")
            else
                local badList = SSW.GetBadModePresetsWithCustom and SSW.GetBadModePresetsWithCustom() or {}
                local idx = r.badMsgIndex or 1
                if idx >= 1 and idx <= #badList then
                    UIDropDownMenu_SetSelectedID(r.badDropdown, idx)
                    UIDropDownMenu_SetText(r.badDropdown, badList[idx])
                end
            end
        end
    end

    -- cbMain is now hidden - kept for compatibility
    r.cbMain:SetScript("OnClick", function(self)
        -- No longer needed
    end)

    -- cbName is hidden - kept for compatibility
    r.cbName:SetScript("OnClick", function()
        -- No longer needed
    end)

    -- cbBnet just updates preview
    r.cbBnet:SetScript("OnClick", function()
        if SSW.UI.UpdateRowPreview then
            SSW.UI.UpdateRowPreview(r)
        end
    end)

    -- cbIgnore just updates preview
    r.cbIgnore:SetScript("OnClick", function()
        if SSW.UI.UpdateRowPreview then
            SSW.UI.UpdateRowPreview(r)
        end
    end)

    rows[i] = r
end

-- Bottom buttons con separatore
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

local btnAll = CreateFrame("Button", nil, sendWin, "UIPanelButtonTemplate")
btnAll:SetSize(90, 36)
btnAll:SetPoint("BOTTOMLEFT", 18, 15)
btnAll:SetText("All")

local btnNone = CreateFrame("Button", nil, sendWin, "UIPanelButtonTemplate")
btnNone:SetSize(90, 36)
btnNone:SetPoint("LEFT", btnAll, "RIGHT", 8, 0)
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
    btnAll:SetEnabled(enabled)
    btnNone:SetEnabled(enabled)
    btnSend:SetAlpha(enabled and 1 or 0.35)
    btnAll:SetAlpha(enabled and 1 or 0.35)
    btnNone:SetAlpha(enabled and 1 or 0.35)

    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r and r:IsShown() then
            -- Checkboxes are now always enabled (no dependency on Send checkbox)
            r.cbBnet:SetAlpha(1)
            if r.cbIgnore and SSW.IsBadModeEnabled and SSW.IsBadModeEnabled() then
                r.cbIgnore:SetAlpha(1)
            end
        end
    end
end

-- All button handler
btnAll:SetScript("OnClick", function()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r:IsShown() then
            -- Select first GOOD message for all
            r.msg1Index = 1
            r.badMsgIndex = nil
            local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
            if #msg1List > 0 then
                UIDropDownMenu_SetSelectedID(r.dropdown, 1)
                UIDropDownMenu_SetText(r.dropdown, msg1List[1])
            end
            if r.badDropdown then
                UIDropDownMenu_SetText(r.badDropdown, "Select BAD message...")
            end
            if SSW.UI.UpdateRowPreview then SSW.UI.UpdateRowPreview(r) end
        end
    end
end)

-- None button handler
btnNone:SetScript("OnClick", function()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r:IsShown() then
            -- Reset both dropdowns
            r.msg1Index = nil
            r.badMsgIndex = nil
            UIDropDownMenu_SetText(r.dropdown, "Select GOOD message...")
            if r.badDropdown then
                UIDropDownMenu_SetText(r.badDropdown, "Select BAD message...")
            end
            if r.preview then r.preview:SetText("") end
        end
    end
end)

-- =========================================
-- Preview update
-- =========================================
function SSW.UI.UpdateRowPreview(r)
    if not r or not r:IsShown() then return end
    if not r.playerName or r.playerName == "" then
        if r.preview then r.preview:SetText("") end
        return
    end

    -- Check if BAD message is selected
    if r.badMsgIndex and r.badMsgIndex > 0 then
        -- Show BAD MODE message preview
        local badList = SSW.GetBadModePresetsWithCustom and SSW.GetBadModePresetsWithCustom() or {}
        if #badList > 0 and r.badMsgIndex <= #badList then
            local badTemplate = badList[r.badMsgIndex] or "..."
            
            -- Strip custom tag if present
            if type(badTemplate) == "string" and badTemplate:sub(1, #SSW.CUSTOM_TAG) == SSW.CUSTOM_TAG then
                badTemplate = badTemplate:sub(#SSW.CUSTOM_TAG + 1)
            end
            
            --Remove "Random" indicator and get actual message
            if badTemplate:lower():find("random", 1, true) then
                local candidates = {}
                for _, v in ipairs(badList) do
                    local raw = v
                    -- Strip custom tag for comparison
                    if type(raw) == "string" and raw:sub(1, #SSW.CUSTOM_TAG) == SSW.CUSTOM_TAG then
                        raw = raw:sub(#SSW.CUSTOM_TAG + 1)
                    end
                    if not raw:lower():find("random", 1, true) and raw:sub(1, #SSW.CUSTOM_TAG) ~= SSW.CUSTOM_TAG then
                        table.insert(candidates, raw)
                    end
                end
                if #candidates > 0 then
                    badTemplate = candidates[1]  -- Preview first option
                end
            end
            
            -- Apply placeholders
            local clean = SSW.CleanName(r.playerName)
            local badMsg = badTemplate
                :gsub("{name}", clean)
                :gsub("{role}", r.role or "DPS")
                :gsub("{spec}", r.specName or "")
            
            if r.preview then
                local ignoreText = ""
                if r.cbIgnore and r.cbIgnore:GetChecked() then
                    ignoreText = " (player will be ignored)"
                end
                r.preview:SetText("|cFFFF4444[BAD]|r Preview: " .. badMsg .. ignoreText)
            end
        end
        return
    end

    -- Check if GOOD message is selected
    if r.msg1Index and r.msg1Index > 0 then
        local includeName = false  -- Never include name (per new requirement)
        local includeSecond = r.cbBnet:GetChecked()

        -- Build meta data for the new BuildMessagesForTarget function
        local meta = {
            role = r.role or "NONE",
            specID = r.specID or 0,
            msg1Index = r.msg1Index,
        }

        -- Use the new function from Presets.lua
        local msg1, msg2 = SSW.BuildMessagesForTarget(
            r.playerName,
            includeName,
            includeSecond,
            meta
        )

        local line = msg1
        if includeSecond and msg2 ~= "" then line = line .. " | " .. msg2 end

        if r.preview then 
            r.preview:SetText("Preview: " .. line)
        end
        return
    end
    
    -- No message selected
    if r.preview then
        r.preview:SetText("")
    end
end

function SSW.UI.UpdateAllPreviews()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r and r:IsShown() then SSW.UI.UpdateRowPreview(r) end
    end
end

-- Rebuild row message dropdowns when custom messages change
function SSW.UI.RebuildRowMessageDropdowns()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r and r.dropdown then
            -- Re-initialize dropdown with updated message list
            UIDropDownMenu_Initialize(r.dropdown, function(self, level)
                local selectedIdx = r.msg1Index or 1
                local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
                for idx, txt in ipairs(msg1List) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = txt
                    info.checked = (idx == selectedIdx)
                    info.func = function()
                        r.msg1Index = idx
                        UIDropDownMenu_SetSelectedID(r.dropdown, idx)
                        UIDropDownMenu_SetText(r.dropdown, txt)
                        CloseDropDownMenus()
                        if SSW.UI.UpdateRowPreview then
                            SSW.UI.UpdateRowPreview(r)
                        end
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end)
            
            -- Update the dropdown text if it's currently showing
            if r.dropdown:IsShown() then
                local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
                local idx = r.msg1Index or 1
                if idx >= 1 and idx <= #msg1List then
                    UIDropDownMenu_SetText(r.dropdown, msg1List[idx])
                end
            end
        end
        
        -- Re-initialize BAD dropdown with updated message list
        if r and r.badDropdown and SSW.IsBadModeEnabled and SSW.IsBadModeEnabled() then
            UIDropDownMenu_Initialize(r.badDropdown, function(self, level)
                local selectedIdx = r.badMsgIndex or 1
                local badList = SSW.GetBadModePresetsWithCustom and SSW.GetBadModePresetsWithCustom() or {}
                for idx, txt in ipairs(badList) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = txt
                    info.checked = (idx == selectedIdx)
                    info.func = function()
                        r.badMsgIndex = idx
                        UIDropDownMenu_SetSelectedID(r.badDropdown, idx)
                        UIDropDownMenu_SetText(r.badDropdown, txt)
                        CloseDropDownMenus()
                        if SSW.UI.UpdateRowPreview then
                            SSW.UI.UpdateRowPreview(r)
                        end
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end)
            
            -- Update the BAD dropdown text if it's currently showing
            if r.badDropdown:IsShown() then
                local badList = SSW.GetBadModePresetsWithCustom()
                local idx = r.badMsgIndex or 1
                if idx >= 1 and idx <= #badList then
                    UIDropDownMenu_SetText(r.badDropdown, badList[idx])
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
        r.msg1Index  = 1
        r.pvpUrl     = nil
        r:Hide()
        r.cbMain:SetChecked(false)
        r.cbName:SetChecked(false)
        r.cbBnet:SetChecked(false)
        r:SetEnabledSubs(false)
        if r.preview then r.preview:SetText("") end
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
        
        -- Set up PvP check button and clickable name
        if SSW.GetCheckPvpUrl then
            r.pvpUrl = SSW.GetCheckPvpUrl(m.fullName)
            if r.pvpBtn then
                r.pvpBtn:Show()
            end
            if r.nameBtn then
                r.nameBtn:Show()
            end
        end
        
        -- Show dropdowns for this row
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
        sendWin.subText:SetText("|cFFFFFF00TEST|r: preview only. Select players and press Send.")
    elseif SSW.IsArmed() then
        sendWin.subText:SetText("|cFFFF2020LIVE|r: will whisper other players. Double-check your selection.")
    else
        sendWin.subText:SetText("|cFF00FFFFSAFE|r: preview only. Use /ssw arm to enable LIVE.")
    end

    sendWin.noteLine:SetText("Solo Shuffle: Optionally enable Message 2 (BTag) per player.")
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
        if SSW.Access and SSW.Access.ApplyToSendWindow then
            SSW.Access.ApplyToSendWindow(SSW.UI.sendWin)
        end
        return
    end

    -- Live: use existing snapshot
    PopulateFromSnapshot()
    sendWin:Show()
    SSW.UI.SetSendUIEnabled(true)
    SSW.UI.UpdateAllPreviews()
    if SSW.Access and SSW.Access.ApplyToSendWindow then
        SSW.Access.ApplyToSendWindow(SSW.UI.sendWin)
    end
end

-- Store rows for Send.lua to access
SSW.UI.rows = rows
SSW.UI.btnSend = btnSend
