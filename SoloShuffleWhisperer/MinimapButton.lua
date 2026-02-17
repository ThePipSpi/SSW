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
    SSW_CharConfig.minimap = SSW_CharConfig.minimap or { x = -200, y = 100 }
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

local function SetPosition(btn, x, y)
    local cfg = GetCharCfg()
    cfg.minimap.x = x or cfg.minimap.x or -200
    cfg.minimap.y = y or cfg.minimap.y or 100
    
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", UIParent, "CENTER", cfg.minimap.x, cfg.minimap.y)
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
                SSW_CharConfig.isArmed = not SSW_CharConfig.isArmed
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
        
        -- Save position relative to screen center
        local x, y = self:GetCenter()
        local px, py = UIParent:GetCenter()
        SetPosition(self, x - px, y - py)
    end)

    local cfg = GetCharCfg()
    SetPosition(btn, cfg.minimap.x, cfg.minimap.y)

    UpdateIconVisual(btn)
end

-- Create on login (safe)
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    CreateButton()
end)
