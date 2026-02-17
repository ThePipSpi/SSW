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
configWin:SetSize(520, 720)
configWin:SetPoint("CENTER", 0, 60)
configWin:SetMovable(true)
configWin:EnableMouse(true)
configWin:RegisterForDrag("LeftButton")
configWin:SetScript("OnDragStart", configWin.StartMoving)
configWin:SetScript("OnDragStop",  configWin.StopMovingOrSizing)
configWin:Hide()

configWin.title = configWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
configWin.title:SetPoint("TOPLEFT", 14, -10)
configWin.title:SetText("Solo Shuffle Whisperer - Settings")

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
local y = AddSectionHeader(configWin, "CUSTOM MESSAGE LINES  (excluded from Random)", -38)

local custLabel = configWin:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
custLabel:SetPoint("TOPLEFT", 18, y)
custLabel:SetWidth(480)
custLabel:SetJustifyH("LEFT")
custLabel:SetText("Write your own messages below. They appear in the send window message dropdown but are never picked by \"Random\".\nPlaceholders: {name}, {praise}, {role}, {spec}, {btag}")

local CUSTOM_BOX_H = 22
local CUSTOM_GAP   = 4
local customBoxes  = {}

for ci = 1, SSW.MAX_CUSTOM_LINES do
    local boxY = y - 32 - ((ci - 1) * (CUSTOM_BOX_H + CUSTOM_GAP))
    local numLbl = configWin:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    numLbl:SetPoint("TOPLEFT", 18, boxY - 3)
    numLbl:SetText(tostring(ci) .. ".")

    local box = CreateFrame("EditBox", "SSW_CustomBox" .. ci, configWin, "InputBoxTemplate")
    box:SetSize(440, CUSTOM_BOX_H)
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
yBehav = AddSectionHeader(configWin, "BEHAVIOR", yBehav)

-- Sezione Message 1
local section1 = CreateFrame("Frame", nil, configWin, "BackdropTemplate")
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
local section2 = CreateFrame("Frame", nil, configWin, "BackdropTemplate")
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

-- Sezione Delay
local section3 = CreateFrame("Frame", nil, configWin, "BackdropTemplate")
section3:SetPoint("TOPLEFT", 12, yBehav - 208)
section3:SetPoint("TOPRIGHT", -12, yBehav - 208)
section3:SetHeight(50)
section3:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
section3:SetBackdropColor(0.05, 0.05, 0.05, 0.5)
section3:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

local lblDelay = section3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lblDelay:SetPoint("TOPLEFT", 10, -8)
lblDelay:SetText("LIVE Mode: Delay before sending (seconds)")
lblDelay:SetTextColor(1, 0.82, 0, 1)

-- Checkboxes
local cbAutoGreet = CreateFrame("CheckButton", nil, configWin, "ChatConfigCheckButtonTemplate")
cbAutoGreet:SetPoint("TOPLEFT", 18, yBehav - 275)
cbAutoGreet.Text:ClearAllPoints()
cbAutoGreet.Text:SetPoint("LEFT", cbAutoGreet, "RIGHT", 6, 1)
cbAutoGreet.Text:SetWidth(450)
cbAutoGreet.Text:SetJustifyH("LEFT")
cbAutoGreet.Text:SetText("Auto greeting in party (accessibility)")
cbAutoGreet:SetScript("OnClick", function(self)
    SSW_Config.autoGreetEnabled = self:GetChecked() and true or false
end)

local hint = configWin:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint:SetPoint("TOPLEFT", cbAutoGreet, "BOTTOMLEFT", 0, -15)
hint:SetWidth(480)
hint:SetJustifyH("LEFT")
hint:SetText("Available placeholders: {name}, {praise}, {role}, {spec}, {btag}\nMessage 1 can be customized per-player in the send window.")
hint:SetTextColor(0.7, 0.7, 0.7, 1)

local closeBtnCfg = CreateFrame("Button", nil, configWin, "UIPanelButtonTemplate")
closeBtnCfg:SetSize(140, 36)
closeBtnCfg:SetPoint("BOTTOM", 0, 15)
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

local dd1 = MakeDropdown(configWin, "SSW_DD1", 440, function() 
    return SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
end, function(i)
    SSW_Config.msg1Index = i
end)
dd1:SetPoint("TOPLEFT", section1, "TOPLEFT", -2, -32)

local dd2 = MakeDropdown(configWin, "SSW_DD2", 440, SSW.MSG2_PRESETS, function(i)
    SSW_Config.msg2Index = i
end)
dd2:SetPoint("TOPLEFT", section2, "TOPLEFT", -2, -32)

local delayBox = CreateFrame("EditBox", "SSW_DelayBox", configWin, "InputBoxTemplate")
delayBox:SetSize(80, 30)
delayBox:SetPoint("TOPLEFT", section3, "TOPLEFT", 10, -24)
delayBox:SetAutoFocus(false)
delayBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    local v = tonumber(self:GetText())
    if not v then v = SSW.DEFAULT_PRE_SEND_DELAY end
    SSW_Config.preSendDelay = math.max(0, v)
end)

configWin:SetScript("OnShow", function()
    cbAutoGreet:SetChecked(SSW_Config and SSW_Config.autoGreetEnabled)

    local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
    local i1 = tonumber(SSW_Config.msg1Index) or 1
    local i2 = tonumber(SSW_Config.msg2Index) or 1
    if i1 < 1 or i1 > #msg1List then i1 = 1 end
    if i2 < 1 or i2 > #SSW.MSG2_PRESETS then i2 = 1 end

    UIDropDownMenu_SetSelectedID(dd1, i1)
    UIDropDownMenu_SetText(dd1, msg1List[i1])
    UIDropDownMenu_SetSelectedID(dd2, i2)
    UIDropDownMenu_SetText(dd2, SSW.MSG2_PRESETS[i2])

    delayBox:SetText(tostring(SSW_Config.preSendDelay or SSW.DEFAULT_PRE_SEND_DELAY))
    
    -- Populate custom line edit boxes
    for ci = 1, SSW.MAX_CUSTOM_LINES do
        local box = customBoxes[ci]
        if box then
            local val = (SSW_Config and SSW_Config.customLines and SSW_Config.customLines[ci]) or ""
            box:SetText(val)
        end
    end
    
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
sendWin:SetPoint("CENTER")
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
h2:SetPoint("LEFT", 280, 0)
h2:SetText("Send")
h2:SetTextColor(1, 0.82, 0, 1)

local h3 = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
h3:SetPoint("LEFT", 340, 0)
h3:SetText("Name")
h3:SetTextColor(1, 0.82, 0, 1)

local h4 = headerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
h4:SetPoint("LEFT", 400, 0)
h4:SetText("BNet")
h4:SetTextColor(1, 0.82, 0, 1)

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
    
    -- PvP Check Button (clickable icon)
    r.pvpBtn = CreateFrame("Button", nil, r)
    r.pvpBtn:SetSize(16, 16)
    r.pvpBtn:SetPoint("LEFT", r.text, "RIGHT", 2, 0)
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
            GameTooltip:AddLine(r.pvpUrl, 0.5, 0.7, 1)
            GameTooltip:AddLine("Click to copy URL", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    end)
    
    r.pvpBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    r.pvpBtn:SetScript("OnClick", function(self)
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
                        self.editBox:SetText(data)
                        self.editBox:HighlightText()
                        self.editBox:SetFocus()
                    end,
                    EditBoxOnEscapePressed = function(self)
                        self:GetParent():Hide()
                    end,
                }
            end
            StaticPopup_Show("SSW_COPY_URL", nil, nil, urlToCopy)
        end
    end)
    
    r.pvpBtn:Hide() -- Hidden by default, shown when player is set

    -- Checkbox "Send" (allineata)
    r.cbMain = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbMain:SetSize(26, 26)
    r.cbMain:SetPoint("TOPLEFT", 268, -6)

    -- Checkbox "Use {name}"
    r.cbName = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbName:SetSize(26, 26)
    r.cbName:SetPoint("TOPLEFT", 328, -6)
    r.cbName:SetEnabled(false)

    -- Checkbox "+ BNet"
    r.cbBnet = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    r.cbBnet:SetSize(26, 26)
    r.cbBnet:SetPoint("TOPLEFT", 388, -6)
    r.cbBnet:SetEnabled(false)

    -- Dropdown per msg1 (seconda riga, più grande)
    r.msg1Index = 1
    r.dropdown = CreateFrame("Frame", "SSW_RowDD_" .. i, r, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(r.dropdown, 280)
    r.dropdown:SetPoint("TOPLEFT", 0, -30)
    r.dropdown:SetScale(0.9)
    UIDropDownMenu_SetText(r.dropdown, "Select message...")
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
        r.cbName:SetEnabled(enabled)
        r.cbBnet:SetEnabled(enabled)
        if enabled then
            r.dropdown:Show()
            local msg1List = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
            UIDropDownMenu_SetSelectedID(r.dropdown, r.msg1Index or 1)
            local idx = r.msg1Index or 1
            if idx >= 1 and idx <= #msg1List then
                UIDropDownMenu_SetText(r.dropdown, msg1List[idx])
            end
        else
            r.dropdown:Hide()
        end
    end

    r.cbMain:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        r:SetEnabledSubs(checked)
        if not checked then
            r.cbName:SetChecked(false)
            r.cbBnet:SetChecked(false)
        end
        if SSW.UI.UpdateRowPreview then
            SSW.UI.UpdateRowPreview(r)
        end
    end)

    r.cbName:SetScript("OnClick", function()
        if SSW.UI.UpdateRowPreview then
            SSW.UI.UpdateRowPreview(r)
        end
    end)

    r.cbBnet:SetScript("OnClick", function()
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

local btnThankAll = CreateFrame("Button", nil, sendWin, "UIPanelButtonTemplate")
btnThankAll:SetSize(140, 36)
btnThankAll:SetPoint("LEFT", btnSend, "RIGHT", 8, 0)
btnThankAll:SetText("Thank All")

local btnSettings = CreateFrame("Button", nil, sendWin, "UIPanelButtonTemplate")
btnSettings:SetSize(120, 36)
btnSettings:SetPoint("BOTTOMRIGHT", -128, 15)
btnSettings:SetText("Settings")
btnSettings:SetScript("OnClick", function()
    if SSW.ShowSettings then SSW.ShowSettings() end
end)

local btnClose = CreateFrame("Button", nil, sendWin, "UIPanelButtonTemplate")
btnClose:SetSize(100, 36)
btnClose:SetPoint("BOTTOMRIGHT", -18, 15)
btnClose:SetText("Close")
btnClose:SetScript("OnClick", function() sendWin:Hide() end)

sendWin:SetScript("OnHide", function()
    if SSW.UnlockSnapshot then
        SSW.UnlockSnapshot()
    end
end)

function SSW.UI.SetSendUIEnabled(enabled)
    btnSend:SetEnabled(enabled)
    btnAll:SetEnabled(enabled)
    btnNone:SetEnabled(enabled)
    btnThankAll:SetEnabled(enabled)
    btnClose:SetEnabled(enabled)
    btnSend:SetAlpha(enabled and 1 or 0.35)
    btnAll:SetAlpha(enabled and 1 or 0.35)
    btnNone:SetAlpha(enabled and 1 or 0.35)
    btnThankAll:SetAlpha(enabled and 1 or 0.35)
    btnClose:SetAlpha(enabled and 1 or 0.35)

    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r and r:IsShown() then
            r.cbMain:SetEnabled(enabled)
            r.cbMain:SetAlpha(enabled and 1 or 0.35)
            local subsEnabled = enabled and r.cbMain:GetChecked()
            r.cbName:SetEnabled(subsEnabled)
            r.cbBnet:SetEnabled(subsEnabled)
            r.cbName:SetAlpha(subsEnabled and 1 or 0.25)
            r.cbBnet:SetAlpha(subsEnabled and 1 or 0.25)
        end
    end
end

-- All button handler
btnAll:SetScript("OnClick", function()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r:IsShown() then
            r.cbMain:SetChecked(true)
            r:SetEnabledSubs(true)
            if SSW.UI.UpdateRowPreview then SSW.UI.UpdateRowPreview(r) end
        end
    end
end)

-- None button handler
btnNone:SetScript("OnClick", function()
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r:IsShown() then
            r.cbMain:SetChecked(false)
            r:SetEnabledSubs(false)
            if r.preview then r.preview:SetText("") end
        end
    end
end)

-- Thank all button handler
btnThankAll:SetScript("OnClick", function()
    -- Randomly select one of the MSG1_PRESETS (excluding "Random" and custom messages)
    -- Build list of preset indices in the combined list
    local combinedList = SSW.GetMsg1WithCustom and SSW.GetMsg1WithCustom() or SSW.MSG1_PRESETS
    local presetIndices = {}
    
    -- Only include indices that correspond to non-Random MSG1_PRESETS
    for idx = 1, #SSW.MSG1_PRESETS do
        local preset = SSW.MSG1_PRESETS[idx]
        if type(preset) == "string" and preset ~= "Random" then
            table.insert(presetIndices, idx)
        end
    end
    
    local selectedIdx = 1
    if #presetIndices > 0 then
        selectedIdx = presetIndices[math.random(1, #presetIndices)]
    end
    
    -- Select all visible rows and set their message to the randomly selected preset
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r:IsShown() then
            r.cbMain:SetChecked(true)
            r:SetEnabledSubs(true)
            r.msg1Index = selectedIdx
            UIDropDownMenu_SetSelectedID(r.dropdown, selectedIdx)
            if selectedIdx >= 1 and selectedIdx <= #combinedList then
                UIDropDownMenu_SetText(r.dropdown, combinedList[selectedIdx])
            end
            if SSW.UI.UpdateRowPreview then SSW.UI.UpdateRowPreview(r) end
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
    -- No preview if row not selected
    if not r.cbMain:GetChecked() then
        if r.preview then r.preview:SetText("") end
        return
    end

    local includeName = r.cbName:GetChecked()
    local includeSecond = r.cbBnet:GetChecked()

    -- Build meta data for the new BuildMessagesForTarget function
    local meta = {
        role = r.role or "NONE",
        specID = r.specID or 0,
        msg1Index = r.msg1Index or 1,
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
        
        -- Set up PvP check button
        if SSW.GetCheckPvpUrl then
            r.pvpUrl = SSW.GetCheckPvpUrl(m.fullName)
            if r.pvpBtn then
                r.pvpBtn:Show()
            end
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
            { fullName = "TestWarrior-Realm", classFile = "WARRIOR", specName = "Arms",  specID = 71,  role = "DAMAGER" },
            { fullName = "TestMage-Realm",    classFile = "MAGE",    specName = "Frost", specID = 64,  role = "DAMAGER" },
            { fullName = "TestPriest-Realm",  classFile = "PRIEST",  specName = "Disc",  specID = 256, role = "HEALER" },
            { fullName = "TestHunter-Realm",  classFile = "HUNTER",  specName = "BM",    specID = 253, role = "DAMAGER" },
            { fullName = "TestPaladin-Realm", classFile = "PALADIN", specName = "Ret",   specID = 70,  role = "DAMAGER" },
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
