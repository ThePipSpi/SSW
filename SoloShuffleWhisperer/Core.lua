-- Core.lua
-- Core utilities + SavedVariables init + slash commands + armed toggle helper

SSW = SSW or {}

local ADDON_NAME = "SoloShuffleWhisperer"

SSW.MAX_ROWS = 5
SSW.SEND_DELAY = 0.35
SSW.DEFAULT_PRE_SEND_DELAY = 3.0  -- Fixed delay, no longer configurable
SSW.MAX_LEN = 140
SSW.MAX_CUSTOM_LINES = 10
SSW.MAX_CUSTOM_BAD_LINES = 10

SSW.IsTesting = false

-- Session statistics (reset on login)
SSW.SessionStats = { sent = 0 }

function SSW.GetSessionStats()
    return SSW.SessionStats
end

function SSW.IncrementSentCount()
    SSW.SessionStats.sent = (SSW.SessionStats.sent or 0) + 1
end

function SSW.Now()
    return GetTime and GetTime() or time()
end

function SSW.Print(msg)
    print("|cFF00FFAA[SSW]|r " .. tostring(msg))
end

function SSW.CleanName(fullName)
    if not fullName then return "" end
    return (tostring(fullName):gsub("%-.+", ""))
end

function SSW.GetRealm(fullName)
    if not fullName then return "" end
    local realm = tostring(fullName):match("%-(.+)")
    return realm or ""
end

function SSW.GetRegionCode()
    -- Auto-detect region using GetCurrentRegion() API
    -- Returns: "us", "eu", "kr", "tw", or "cn"
    -- GetCurrentRegion() returns: 1=US, 2=Korea, 3=EU, 4=Taiwan, 5=China
    if GetCurrentRegion then
        local regionID = GetCurrentRegion()
        if regionID == 1 then
            return "us"
        elseif regionID == 2 then
            return "kr"
        elseif regionID == 3 then
            return "eu"
        elseif regionID == 4 then
            return "tw"
        elseif regionID == 5 then
            return "cn"
        end
    end
    
    -- Fallback: try GetCVar("portal") as alternative
    if GetCVar then
        local portal = GetCVar("portal")
        if portal and portal ~= "" then
            portal = portal:lower()
            -- Return the portal value if it's valid
            if portal == "us" or portal == "eu" or portal == "kr" or portal == "tw" or portal == "cn" then
                return portal
            end
        end
    end
    
    -- Default to EU if detection fails (EU servers are used as fallback since
    -- the addon was originally developed for EU. This default works for most
    -- cases and users on other regions will have their region auto-detected.)
    return "eu"
end

function SSW.GetCheckPvpUrl(fullName)
    if not fullName or fullName == "" then return "" end
    local name = SSW.CleanName(fullName)
    local realm = SSW.GetRealm(fullName)
    
    -- If no realm in fullName, try to get current realm
    if realm == "" then
        realm = GetRealmName and GetRealmName() or ""
    end
    
    -- Convert realm to URL format: replace spaces/apostrophes with hyphens
    -- Character name preserves original capitalization (check-pvp.fr is case-sensitive)
    realm = realm:gsub("[%s']+", "-")
    
    -- Auto-detect region (no user modification needed)
    local region = SSW.GetRegionCode()
    return ("https://check-pvp.fr/%s/%s/%s"):format(region, realm, name)
end

function SSW.GetMyBattleTag()
    local success, _, btag = pcall(function() 
        if BNGetInfo then
            return BNGetInfo() 
        end
        return nil, nil
    end)
    if success and btag then
        btag = tostring(btag)
        if btag:find("#") then
            return btag
        end
    end
    return ""
end

function SSW.IsArmed()
    SSW_CharConfig = SSW_CharConfig or {}
    return not not SSW_CharConfig.isArmed
end

function SSW.ModeText(isTest)
    if isTest then return "|cFFFFFF00TEST MODE|r" end
    if SSW.IsArmed() then return "|cFFFF2020LIVE MODE|r" end
    return "|cFF00FFFFSAFE MODE|r"
end

function SSW.ToggleArmed()
    SSW_CharConfig = SSW_CharConfig or {}
    SSW_CharConfig.isArmed = not SSW.IsArmed()

    SSW.Print("Mode: " .. (SSW.IsArmed() and "|cffff2020LIVE|r" or "|cff00ffffSAFE|r"))

    -- update minimap color immediately if button exists
    local btn = _G["SSW_MinimapButton"]
    if btn and btn.icon then
        if SSW.IsArmed() then
            btn.icon:SetVertexColor(1, 0.25, 0.25) -- LIVE
        else
            btn.icon:SetVertexColor(0.25, 1, 1) -- SAFE
        end
    end
end

-- =========================================
-- ADDON_LOADED init
-- =========================================

local core = CreateFrame("Frame")
core:RegisterEvent("ADDON_LOADED")

local function ClampIndex(i, list)
    i = tonumber(i) or 1
    if i < 1 or i > #list then i = 1 end
    return i
end

core:SetScript("OnEvent", function(self, event, arg1)
    if event ~= "ADDON_LOADED" or arg1 ~= ADDON_NAME then return end

    -- Account-wide config
    if not SSW_Config then
        SSW_Config = {
            msg1Index = 1,
            preSendDelay = SSW.DEFAULT_PRE_SEND_DELAY,
            autoPartyThanksOnReward = false,
            customLines = {},
            customBadLines = {},
            badModeEnabled = false,  -- BAD MODE locked by default
        }
    end
    -- Migrations: fill in keys missing from older saved configs
    if SSW_Config.autoPartyThanksOnReward == nil then
        SSW_Config.autoPartyThanksOnReward = false
    end
    if not SSW_Config.customLines then
        SSW_Config.customLines = {}
    end
    if not SSW_Config.customBadLines then
        SSW_Config.customBadLines = {}
    end
    if SSW_Config.badModeEnabled == nil then
        SSW_Config.badModeEnabled = false
    end

    -- Per-character config (LIVE default ON)
    if not SSW_CharConfig then
        SSW_CharConfig = {
            isArmed = true,
            minimap = { angle = 220 },
            access = {},
            antispam = {},
        }
    end
    if SSW_CharConfig.isArmed == nil then
        SSW_CharConfig.isArmed = true
    end

    -- Clamp dropdown indices if presets already loaded
    if SSW.MSG1_PRESETS then SSW_Config.msg1Index = ClampIndex(SSW_Config.msg1Index, SSW.MSG1_PRESETS) end
    if SSW.MSG2_PRESETS then SSW_Config.msg2Index = ClampIndex(SSW_Config.msg2Index, SSW.MSG2_PRESETS) end

    -- Seed RNG safely
    if math and type(math.randomseed) == "function" then
        math.randomseed(time())
        if type(math.random) == "function" then
            math.random(); math.random(); math.random()
        end
    end

    SSW.Print("Loaded. Mode: " .. (SSW.IsArmed() and "|cffff2020LIVE|r" or "|cff00ffffSAFE|r"))
    SSW.Print("Commands: /ssw (settings)  /ssw show  /ssw test  /ssw arm")
end)

-- =========================================
-- Slash commands
-- =========================================
SLASH_SSW1 = "/ssw"
SlashCmdList["SSW"] = function(msg)
    msg = msg or ""
    local cmd = strtrim(string.lower(msg))

    if cmd == "test" then
        SSW.IsTesting = true
        if SSW.ShowWhisperWindow then SSW.ShowWhisperWindow(true) end
        return
    end

    if cmd == "show" then
        SSW.IsTesting = false
        if SSW.ShowWhisperWindow then SSW.ShowWhisperWindow(false) end
        return
    end

    if cmd == "arm" then
        SSW.ToggleArmed()
        return
    end

    if SSW.ShowSettings then
        SSW.ShowSettings()
    end
end
