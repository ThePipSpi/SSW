-- Core.lua
-- Core utilities + SavedVariables init + slash commands + armed toggle helper

SSW = SSW or {}

local ADDON_NAME = "SoloShuffleWhisperer"

SSW.MAX_ROWS = 5
SSW.SEND_DELAY = 0.35
SSW.DEFAULT_PRE_SEND_DELAY = 3.5
SSW.MAX_LEN = 140

SSW.IsTesting = false

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

function SSW.GetMyBattleTag()
    local ok, _, btag = pcall(function() return BNGetInfo() end)
    if ok then
        btag = tostring(btag or "")
        if btag:find("#") then return btag end
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
            msg2Index = 1,
            preSendDelay = SSW.DEFAULT_PRE_SEND_DELAY,
            autoPartyThanksOnReward = false,
            autoGreetEnabled = false,
        }
    end
    -- Migrations: fill in keys missing from older saved configs
    if SSW_Config.autoPartyThanksOnReward == nil then
        SSW_Config.autoPartyThanksOnReward = false
    end
    if SSW_Config.autoGreetEnabled == nil then
        SSW_Config.autoGreetEnabled = false
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
