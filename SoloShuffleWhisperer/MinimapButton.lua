-- MinimapButton.lua - Draggable button (outside minimap) for quick access
-- Left: open window | Right: settings | Shift+Left: toggle SAFE/LIVE

SSW = SSW or {}
local BTN_NAME, ICON_TEX = "SSW_MinimapButton", "Interface\\Icons\\achievement_bg_killflagcarriers_grabflag_capit"

local function GetCfg()
    SSW_CharConfig = SSW_CharConfig or {}
    SSW_CharConfig.minimap = SSW_CharConfig.minimap or { x = -200, y = 100 }
    return SSW_CharConfig.minimap
end

local function UpdateColor(btn)
    if btn and btn.icon then
        btn.icon:SetVertexColor((SSW.IsArmed and SSW.IsArmed()) and 1 or 0.25, 0.25, (SSW.IsArmed and SSW.IsArmed()) and 0.25 or 1)
    end
end

local function SetPos(btn, x, y)
    local cfg = GetCfg()
    cfg.x, cfg.y = x or cfg.x, y or cfg.y
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", UIParent, "CENTER", cfg.x, cfg.y)
end

local function CreateButton()
    if _G[BTN_NAME] then UpdateColor(_G[BTN_NAME]) return end
    
    local btn = CreateFrame("Button", BTN_NAME, UIParent)
    btn:SetClampedToScreen(true) btn:SetSize(32, 32) btn:SetFrameStrata("MEDIUM") btn:SetFrameLevel(8)
    btn:SetMovable(true) btn:EnableMouse(true) btn:RegisterForClicks("LeftButtonUp", "RightButtonUp") btn:RegisterForDrag("LeftButton")
    
    btn.icon = btn:CreateTexture(nil, "BACKGROUND")
    btn.icon:SetTexture(ICON_TEX) btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) btn.icon:SetPoint("CENTER", 0, 1) btn.icon:SetSize(20, 20)
    
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder") btn.border:SetSize(53, 53) btn.border:SetPoint("TOPLEFT")
    
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT") GameTooltip:AddLine("Solo Shuffle Whisperer")
        GameTooltip:AddLine("Left click: open window", 0.9, 0.9, 0.9) GameTooltip:AddLine("Right click: settings", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Shift+Left: toggle SAFE/LIVE", 0.9, 0.9, 0.9) GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    btn:SetScript("OnClick", function(self, button)
        if IsShiftKeyDown() and button == "LeftButton" then
            if SSW.ToggleArmed then SSW.ToggleArmed() elseif SSW_CharConfig then SSW_CharConfig.isArmed = not SSW_CharConfig.isArmed end
            UpdateColor(self)
            if SSW.Print then SSW.Print("Mode: " .. (SSW.IsArmed() and "|cffff2020LIVE|r" or "|cff00ffffSAFE|r")) end
            return
        end
        if button == "RightButton" then if SSW.ShowSettings then SSW.ShowSettings() end
        else if SSW.ShowWhisperWindow then SSW.ShowWhisperWindow(false) end end
    end)
    
    btn:SetScript("OnDragStart", function(self) self:StartMoving() self.isDragging = true end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing() self.isDragging = false
        local x, y = self:GetCenter() local px, py = UIParent:GetCenter()
        SetPos(self, x - px, y - py)
    end)
    
    local cfg = GetCfg()
    SetPos(btn, cfg.x, cfg.y)
    UpdateColor(btn)
end

CreateFrame("Frame"):RegisterEvent("PLAYER_LOGIN"):SetScript("OnEvent", CreateButton)
