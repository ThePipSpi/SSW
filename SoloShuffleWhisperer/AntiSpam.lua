-- AntiSpam.lua
-- Simple anti-spam guards for whispers + auto features:
--  - per-target cooldown (don't whisper same player too often)
--  - per-run cap (max whispers per run)
--  - prevents duplicate sending if UI opens twice

SSW = SSW or {}
SSW.AntiSpam = SSW.AntiSpam or {}

-- Defaults (safe, not annoying)
SSW.AntiSpam.DEFAULTS = {
    whisperCooldown = 60 * 20,  -- 20 min per target
    maxWhispersPerRun = 12,     -- cap per run (Msg1+Msg2 count)
    minSecondsBetweenBursts = 3 -- minimum time between two "Send" actions
}

local function EnsureCharConfig()
    SSW_CharConfig = SSW_CharConfig or {}
    SSW_CharConfig.antispam = SSW_CharConfig.antispam or {}
    local a = SSW_CharConfig.antispam
    for k, v in pairs(SSW.AntiSpam.DEFAULTS) do
        if a[k] == nil then a[k] = v end
    end
    return a
end

local function EnsureState()
    SSW_AntiSpamState = SSW_AntiSpamState or {
        lastWhisperAt = {},   -- fullName -> timestamp
        lastBurstAt = 0,
        runKey = "",
        runCount = 0,
    }
    return SSW_AntiSpamState
end

local function RunKey()
    -- Unique-ish key per run context; avoids double-send if window pops twice
    local takenAt = (SSW.PartySnapshot and SSW.PartySnapshot.takenAt) or 0
    return "SSW:" .. tostring(takenAt)
end

-- Call before sending a queue; returns (ok, reason)
function SSW.AntiSpam.CanStartBurst()
    local cfg = EnsureCharConfig()
    local st = EnsureState()

    local now = SSW.Now()
    if (now - (st.lastBurstAt or 0)) < (cfg.minSecondsBetweenBursts or 0) then
        return false, "Too soon (burst throttle)."
    end

    -- reset per-run counter if run changed
    local rk = RunKey()
    if st.runKey ~= rk then
        st.runKey = rk
        st.runCount = 0
    end

    return true
end

-- Call when a whisper is about to be sent; returns (ok, reason)
function SSW.AntiSpam.CanWhisperTarget(targetFullName)
    local cfg = EnsureCharConfig()
    local st = EnsureState()

    local now = SSW.Now()

    -- per-target cooldown
    local last = st.lastWhisperAt[targetFullName]
    if last and (now - last) < (cfg.whisperCooldown or 0) then
        return false, "Cooldown for " .. tostring(targetFullName)
    end

    -- per-run cap
    if (st.runCount or 0) >= (cfg.maxWhispersPerRun or 0) then
        return false, "Run cap reached."
    end

    return true
end

-- Call after a whisper is sent
function SSW.AntiSpam.MarkWhisper(targetFullName)
    local cfg = EnsureCharConfig()
    local st = EnsureState()

    st.lastWhisperAt[targetFullName] = SSW.Now()
    st.runCount = (st.runCount or 0) + 1
end

-- Call when a burst starts
function SSW.AntiSpam.MarkBurstStart()
    local st = EnsureState()
    st.lastBurstAt = SSW.Now()

    -- ensure run key is current
    local rk = RunKey()
    if st.runKey ~= rk then
        st.runKey = rk
        st.runCount = 0
    end
end

-- Utility: for debug
function SSW.AntiSpam.GetRunCount()
    local st = EnsureState()
    return st.runCount or 0
end
