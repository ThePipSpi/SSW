-- Presets.lua
-- Friendly, low-drama message presets for Solo Shuffle.
-- PVP philosophy: Less talk is better, but praise over flame.
-- Kept intentionally neutral and short to avoid sarcasm or drama.
-- Custom lines are stored in SSW_Config.customLines and are NEVER included in "Random".

SSW = SSW or {}

-- Msg1 = short gg / thanks
-- Placeholders:
--   {name}   (no realm)
--   {praise} (neutral + randomized)
--   {role}   (Tank / Healer / DPS)
--   {spec}   (best effort, e.g. "Holy")
SSW.MSG1_PRESETS = {
    "gg {name}",
    "ty {name}!",
    "good games {name}!",
    "Random",
    "{praise} {name}",
    "gg {name} :)",
    "nice games!",
}

-- Msg2 = optional BTag
SSW.MSG2_PRESETS = {
    "if you wanna queue again: {btag}",
    "feel free to add me: {btag}",
    "up for more games? {btag}",
    "Random",
    "if you want to queue more: {btag}",
}

-- BAD MODE presets (only available when enabled in settings)
-- These are intentionally short and not overly toxic - just critical feedback
-- Philosophy: "Less talk is better" applies even to negative feedback
SSW.BAD_MODE_PRESETS = {
    "...",
    "learn your spec {name}",
    "you threw {name}",
    "stop tunneling {name}",
    "peel next time {name}",
    "Random",
    "watch positioning {name}",
    "check your gear {name}",
}

-- Custom lines are appended at runtime but excluded from Random selection
-- They are stored in SSW_Config.customLines = { [1] = "...", ... }

-- Build combined msg1 list (presets + non-empty custom lines)
-- Custom entries are tagged so the Random picker can skip them.
SSW.CUSTOM_TAG = "[Custom] "
local CUSTOM_TAG = SSW.CUSTOM_TAG

function SSW.GetMsg1WithCustom()
    local list = {}
    for _, v in ipairs(SSW.MSG1_PRESETS) do
        table.insert(list, v)
    end
    if SSW_Config and SSW_Config.customLines then
        for i = 1, SSW.MAX_CUSTOM_LINES do
            local line = SSW_Config.customLines[i]
            if line and strtrim(line) ~= "" then
                table.insert(list, CUSTOM_TAG .. line)
            end
        end
    end
    return list
end

-- Get BAD MODE presets (only when enabled)
function SSW.GetBadModePresets()
    if not SSW_Config or not SSW_Config.badModeEnabled then
        return {}
    end
    return SSW.BAD_MODE_PRESETS
end

-- Check if BAD MODE is enabled
function SSW.IsBadModeEnabled()
    return SSW_Config and SSW_Config.badModeEnabled or false
end

-- =========================================
-- Helpers
-- =========================================
function SSW.CleanOutgoing(s)
    s = tostring(s or "")
    s = s:gsub("\r", " ")
    s = s:gsub("\n", " ")
    if #s > (SSW.MAX_LEN or 140) then
        s = s:sub(1, SSW.MAX_LEN or 140)
    end
    return s
end

local function PresetByIndex(list, idx)
    idx = tonumber(idx) or 1
    if idx < 1 or idx > #list then idx = 1 end

    local current = list[idx]

    -- Strip the custom tag to get the raw template
    if type(current) == "string" and current:sub(1, #CUSTOM_TAG) == CUSTOM_TAG then
        current = current:sub(#CUSTOM_TAG + 1)
    end

    local isRandom = (type(current) == "string") and current:lower():find("random", 1, true) ~= nil

    if isRandom then
        -- Pick from all non-"Random" and non-custom presets in the list
        local candidates = {}
        for _, v in ipairs(list) do
            if type(v) == "string"
               and v:lower():find("random", 1, true) == nil
               and v:sub(1, #CUSTOM_TAG) ~= CUSTOM_TAG then
                table.insert(candidates, v)
            end
        end

        if #candidates == 0 then
            return tostring(list[1] or ""), idx
        end

        local r = (type(math.random) == "function") and math.random(1, #candidates) or 1
        return candidates[r], idx
    end

    return current, idx
end

local function GetSafeTemplate(list, idx, fallbackIdx)
    local tpl
    tpl, idx = PresetByIndex(list, idx)
    tpl = SSW.CleanOutgoing(tpl)

    -- For combined lists, also accept raw custom entries
    local allowed = false
    for _, v in ipairs(list) do
        local raw = v
        if type(raw) == "string" and raw:sub(1, #CUSTOM_TAG) == CUSTOM_TAG then
            raw = raw:sub(#CUSTOM_TAG + 1)
        end
        if tpl == SSW.CleanOutgoing(raw) then
            allowed = true
            break
        end
    end

    if not allowed then
        tpl, _ = PresetByIndex(list, fallbackIdx or 1)
        tpl = SSW.CleanOutgoing(tpl)
    end
    return tpl
end

local function RoleText(role)
    role = tostring(role or "")
    if role == "TANK" then return "Tank" end
    if role == "HEALER" then return "Healer" end
    if role == "DAMAGER" then return "DPS" end
    return "" -- unknown
end

local function InferRoleFromSpecID(specID)
    if not specID or specID <= 0 then return nil end
    if not GetSpecializationInfoByID then return nil end
    local _, _, _, _, specRole = GetSpecializationInfoByID(specID)
    if specRole == "TANK" or specRole == "HEALER" or specRole == "DAMAGER" then
        return specRole
    end
    return nil
end

local function SpecNameFromID(specID)
    if not specID or specID <= 0 then return "" end
    if not GetSpecializationInfoByID then return "" end
    local _, specName = GetSpecializationInfoByID(specID)
    return tostring(specName or "")
end

local function PraiseForRole(role)
    -- Keep this intentionally neutral: role/performance comments can be read as sarcasm in PVP.
    -- PVP philosophy: Less talk is better, keep it simple and positive.
    local pool = {
        "gg!",
        "ty!",
        "wp!",
        "good games!",
        "cheers!",
    }
    if type(math.random) == "function" then
        return pool[math.random(1, #pool)]
    end
    return pool[1]
end

local function CleanupArtifacts(s)
    -- Remove dashes ("-") entirely so messages don't look templated/addon-y
    -- Examples: "gg x - ty" -> "gg x ty" ; "word-word" -> "word word"
    s = s:gsub("%s*%-%s*", " ")

    -- Remove leftover double spaces
    s = s:gsub("%s%s+", " ")

    -- If name is empty: "Thanks !" -> "Thanks!" ; "GG ," -> "GG"
    s = s:gsub("%s+!", "!")
    s = s:gsub("%s+,", ",")
    s = s:gsub(",%s*%.", ".")

    -- Remove trailing commas/spaces
    s = s:gsub("%s*,%s*$", "")

    -- Trim
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

-- =========================================
-- Build final messages
-- meta:
--   meta.role   = "TANK"|"HEALER"|"DAMAGER"|"NONE"
--   meta.specID = number
--   meta.msg1Index = number (optional override for message 1 selection)
-- =========================================
function SSW.BuildMessagesForTarget(targetFullName, includeName, includeSecond, meta)
    meta = meta or {}

    local clean = SSW.CleanName(targetFullName)
    local namePart = includeName and clean or ""

    local role = meta.role
    if role == "NONE" or role == "" or role == nil then
        role = InferRoleFromSpecID(tonumber(meta.specID) or 0) or role
    end

    local roleTxt = RoleText(role)
    local praise = PraiseForRole(role)
    local specName = SpecNameFromID(tonumber(meta.specID) or 0)

    -- Use combined list (presets + custom lines) for msg1
    local msg1List = SSW.GetMsg1WithCustom()
    local msg1Idx = meta.msg1Index or 1
    
    local tpl1 = GetSafeTemplate(msg1List, msg1Idx, 1)
    local tpl2 = GetSafeTemplate(SSW.MSG2_PRESETS, SSW_Config and SSW_Config.msg2Index, 1)

    local myBtag = SSW.GetMyBattleTag()

    local msg1 = SSW.CleanOutgoing(
        tpl1
            :gsub("{name}", namePart)
            :gsub("{btag}", myBtag)
            :gsub("{praise}", praise)
            :gsub("{role}", roleTxt)
            :gsub("{spec}", specName)
    )
    msg1 = CleanupArtifacts(msg1)

    local msg2 = ""
    if includeSecond then
        msg2 = SSW.CleanOutgoing(
            tpl2
                :gsub("{name}", namePart)
                :gsub("{btag}", myBtag)
                :gsub("{praise}", praise)
                :gsub("{role}", roleTxt)
                :gsub("{spec}", specName)
        )
        msg2 = CleanupArtifacts(msg2)

        if myBtag == "" then
            msg2 = ""
        end
    end

    return msg1, msg2
end

-- Build BAD MODE message (negative/critical feedback)
function SSW.BuildBadMessage(targetFullName, badMsgIndex, meta)
    if not SSW.IsBadModeEnabled() then
        return "..."  -- Fallback if BAD MODE somehow called when disabled
    end
    
    meta = meta or {}
    
    local clean = SSW.CleanName(targetFullName)
    local role = meta.role
    if role == "NONE" or role == "" or role == nil then
        role = InferRoleFromSpecID(tonumber(meta.specID) or 0) or role
    end
    
    local roleTxt = RoleText(role)
    local specName = SpecNameFromID(tonumber(meta.specID) or 0)
    
    -- Get BAD MODE presets
    local badList = SSW.GetBadModePresets()
    if #badList == 0 then
        return "..."  -- Fallback
    end
    
    -- Get template (handle Random selection)
    local badIdx = tonumber(badMsgIndex) or 1
    if badIdx < 1 or badIdx > #badList then badIdx = 1 end
    
    local badTemplate = badList[badIdx]
    
    -- Handle "Random" selection
    if type(badTemplate) == "string" and badTemplate:lower():find("random", 1, true) then
        local candidates = {}
        for _, v in ipairs(badList) do
            if type(v) == "string" and not v:lower():find("random", 1, true) then
                table.insert(candidates, v)
            end
        end
        if #candidates > 0 then
            local r = (type(math.random) == "function") and math.random(1, #candidates) or 1
            badTemplate = candidates[r]
        else
            badTemplate = "..."
        end
    end
    
    -- Apply placeholders
    local badMsg = SSW.CleanOutgoing(
        badTemplate
            :gsub("{name}", clean)
            :gsub("{role}", roleTxt)
            :gsub("{spec}", specName)
    )
    badMsg = CleanupArtifacts(badMsg)
    
    return badMsg
end
