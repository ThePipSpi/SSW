-- MinimapButton.lua
-- Minimap icon with preset logo (WoW texture) + quick controls
-- Left click: /ssw show
-- Right click: settings
-- Shift + Left click: toggle SAFE/LIVE

SSW = SSW or {}

local ICON_TEX = "Interface\\Icons\\achievement_bg_killflagcarriers_grabflag_capit" -- PvP icon
local BTN_NAME = "SSW_MinimapButton"

-- Saved per character (optional position)
local function GetCharCfg()
    SSW_CharConfig = SSW_CharConfig or {}
    SSW_CharConfig.minimap = SSW_CharConfig.minimap or { angle = 220 }
    return SSW_CharConfig
end

local function UpdateIconVisual(btn)
    if not btn or not btn.icon then return end
    local armed = SSW.IsArmed and SSW.IsArmed() or false
    -- simple "glow" via vertex color
    if armed then
        btn.icon:SetVertexColor(1, 0.25, 0.25) -- reddish = LIVE
    else
        btn.icon:SetVertexColor(0.25, 1, 1) -- cyan-ish = SAFE
    end
end

local function SetAngle(btn, angle)
    local cfg = GetCharCfg()
    cfg.minimap.angle = angle

    local rad = math.rad(angle)
    local x = math.cos(rad) * 80  -- Reduced from 90 to better center on minimap border
    local y = math.sin(rad) * 80

    -- IMPORTANT: prevent anchor-family errors
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateButton()
    if _G[BTN_NAME] then
        UpdateIconVisual(_G[BTN_NAME])
        return
    end

    local btn = CreateFrame("Button", BTN_NAME, UIParent)
    btn:SetClampedToScreen(true)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Icon texture (rendered behind border, so it appears inside)
    btn.icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.icon:SetTexture(ICON_TEX)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon:SetPoint("CENTER", 0, 1)
    btn.icon:SetSize(20, 20)

    -- Circular border (overlay to mask icon edges)
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border:SetSize(53, 53)
    btn.border:SetPoint("TOPLEFT")

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Solo Shuffle Whisperer")
        GameTooltip:AddLine("Left click: open window", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Right click: settings", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Shift+Left: toggle SAFE/LIVE", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self, button)
        if IsShiftKeyDown() and button == "LeftButton" then
            -- toggle armed
            if SSW.ToggleArmed then
                SSW.ToggleArmed()
            elseif SSW_CharConfig then
                SSW_CharConfig.isArmed = not not (not SSW_CharConfig.isArmed)
            end
            UpdateIconVisual(self)
            if SSW.Print then
                SSW.Print("Mode: " .. (SSW.IsArmed() and "|cffff2020LIVE|r" or "|cff00ffffSAFE|r"))
            end
            return
        end

        if button == "RightButton" then
            if SSW.ShowSettings then SSW.ShowSettings() end
        else
            if SSW.ShowWhisperWindow then
                SSW.ShowWhisperWindow(false)
            end
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self.isDragging = true
    end)

    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.isDragging = false

        -- save angle based on current cursor position around minimap
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetScale()
        cx, cy = cx / scale, cy / scale

        local dx, dy = cx - mx, cy - my
        if dx == 0 and dy == 0 then return end -- avoid atan2(0,0)
        local angle = math.deg(math.atan2(dy, dx))
        SetAngle(self, angle)
    end)

    local cfg = GetCharCfg()
    SetAngle(btn, cfg.minimap.angle or 220)

    UpdateIconVisual(btn)
end

-- Create on login (safe)
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    CreateButton()
end)
