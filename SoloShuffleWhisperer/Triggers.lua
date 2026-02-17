-- Triggers.lua
-- Handles match completion events and auto-opens whisper window

SSW = SSW or {}
SSW.Triggers = SSW.Triggers or {}

local lastMatchComplete = 0
local MATCH_COOLDOWN = 5 -- Prevent duplicate triggers within 5 seconds

-- Handle match completion
local function OnMatchComplete()
    local now = SSW.Now()
    if (now - lastMatchComplete) < MATCH_COOLDOWN then
        return
    end
    lastMatchComplete = now
    
    -- Capture snapshot
    local success = false
    local tries = 0
    
    local function TryCapture()
        tries = tries + 1
        success = SSW.SnapshotScoreboard and SSW.SnapshotScoreboard() or false
        
        if success then
            SSW.LockSnapshot() -- Lock snapshot so it doesn't change
            
            -- Wait a moment for scoreboard to fully load, then show window
            C_Timer.After(1.5, function()
                if SSW.ShowWhisperWindow then
                    SSW.ShowWhisperWindow(false)
                end
            end)
            return
        end
        
        -- Retry up to 10 times
        if tries < 10 then
            C_Timer.After(1, TryCapture)
        else
            SSW.Print("Could not capture scoreboard. Use /ssw show to open manually.")
        end
    end
    
    -- Start capture after a short delay
    C_Timer.After(0.5, TryCapture)
end

-- Watch for match completion
local f = CreateFrame("Frame")
f:RegisterEvent("PVP_MATCH_COMPLETE")
f:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- Alternative trigger

local arenaPrepsThisMatch = 0

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PVP_MATCH_COMPLETE" then
        -- Main trigger: match is complete
        OnMatchComplete()
        arenaPrepsThisMatch = 0
        
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        -- Reset counter when entering new arena instance
        local _, instanceType = IsInInstance()
        if instanceType == "arena" and arenaPrepsThisMatch >= 6 then
            arenaPrepsThisMatch = 0
        end
        
        -- Count arena preps to detect end of 6-round shuffle
        arenaPrepsThisMatch = arenaPrepsThisMatch + 1
        
        -- Solo Shuffle has 6 rounds
        -- After 6th round ends, this might not fire PVP_MATCH_COMPLETE immediately
        -- So we watch for completion of 6 preps
        if arenaPrepsThisMatch >= 6 then
            C_Timer.After(3, function()
                -- Check if we're still in arena
                local _, instanceType = IsInInstance()
                if instanceType ~= "arena" then
                    OnMatchComplete()
                    arenaPrepsThisMatch = 0
                end
            end)
        end
    end
end)
