-- Send.lua
-- Handles the actual sending of whispers with anti-spam protection

SSW = SSW or {}

local queue = {}

local function BuildMessagesForRow(r)
    if not r or not r.playerName then return "", "", "", "" end

    local clean = SSW.CleanName(r.playerName)

    -- Build meta data for the new BuildMessagesForTarget function
    local meta = {
        role = r.role or "NONE",
        specID = r.specID or 0,
        msg1Index = r.msg1Index or 1,
    }

    -- Use the new function from Presets.lua
    local msg1, msg2 = SSW.BuildMessagesForTarget(
        r.playerName,
        r.cbBnet:GetChecked(),  -- includeSecond
        meta
    )

    return msg1, msg2, clean, r.playerName
end

local function Enqueue(target, text)
    table.insert(queue, { target = target, text = text })
end

local function PreviewLine(colorHex, label, text)
    SSW.Print("|cff" .. colorHex .. label .. "|r " .. text)
end

-- Main send function
local function ProcessWhispers(isTest)
    queue = {}
    local selected = 0

    if not SSW.UI or not SSW.UI.rows then
        SSW.Print("UI not ready.")
        return
    end

    local rows = SSW.UI.rows

    -- Check anti-spam
    if not isTest and SSW.IsArmed() then
        local ok, reason = SSW.AntiSpam.CanStartBurst()
        if not ok then
            SSW.Print("Anti-spam: " .. tostring(reason))
            return
        end
    end

    -- Preview header
    if isTest then
        SSW.Print("================================================")
        SSW.Print("TEST MODE PREVIEW - NOTHING IS SENT")
        SSW.Print("================================================")
    elseif not SSW.IsArmed() then
        SSW.Print("SAFE MODE: preview only (no whispers sent).")
    else
        SSW.Print("LIVE MODE: sending whispers...")
    end

    -- Process each row
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        -- Check if row is shown and has either GOOD or BAD message selected
        local hasGoodMessage = r.msg1Index and r.msg1Index > 0
        local hasBadMessage = r.badMsgIndex and r.badMsgIndex > 0
        
        if r and r:IsShown() and (hasGoodMessage or hasBadMessage) then
            if not r.playerName or r.playerName == "" then
                SSW.Print("Row " .. i .. " has message selected but no target name.")
            else
                local classColor = r.text:GetText() and (r.text:GetText():match("|cff(%x+)") or "ffffff") or "ffffff"
                local clean = SSW.CleanName(r.playerName)
                local target = r.playerName

                -- Check anti-spam for this target
                local canSend = true
                if not isTest and SSW.IsArmed() then
                    local ok, reason = SSW.AntiSpam.CanWhisperTarget(target)
                    if not ok then
                        SSW.Print("Skipping " .. clean .. ": " .. tostring(reason))
                        canSend = false
                    end
                end

                if canSend then
                    if hasBadMessage and SSW.IsBadModeEnabled and SSW.IsBadModeEnabled() then
                        -- BAD MODE: send negative message
                        local meta = {
                            role = r.role or "NONE",
                            specID = r.specID or 0,
                        }
                        local badMsg = SSW.BuildBadMessage(r.playerName, r.badMsgIndex, meta)
                        
                        -- Check if should ignore after sending BAD message
                        local shouldIgnore = r.cbIgnore and r.cbIgnore:GetChecked()
                        
                        if isTest then
                            if shouldIgnore then
                                PreviewLine(classColor, "[TEST -> " .. clean .. " - BAD]", badMsg .. " (will be ignored)")
                            else
                                PreviewLine(classColor, "[TEST -> " .. clean .. " - BAD]", badMsg)
                            end
                        elseif SSW.IsArmed() then
                            if shouldIgnore then
                                table.insert(queue, { target = target, text = badMsg, addToIgnore = true })
                            else
                                Enqueue(target, badMsg)
                            end
                        else
                            if shouldIgnore then
                                PreviewLine(classColor, "[SAFE -> " .. clean .. " - BAD]", badMsg .. " (will be ignored)")
                            else
                                PreviewLine(classColor, "[SAFE -> " .. clean .. " - BAD]", badMsg)
                            end
                        end
                    elseif hasGoodMessage then
                        -- GOOD mode: send positive message
                        local msg1, msg2 = BuildMessagesForRow(r)
                        
                        if isTest then
                            PreviewLine(classColor, "[TEST -> " .. clean .. "]", msg1)
                            if r.cbBnet:GetChecked() and msg2 ~= "" then
                                PreviewLine(classColor, "[TEST -> " .. clean .. " - 2nd]", msg2)
                            end

                        elseif SSW.IsArmed() then
                            Enqueue(target, msg1)
                            if r.cbBnet:GetChecked() and msg2 ~= "" then
                                Enqueue(target, msg2)
                            end

                        else
                            PreviewLine(classColor, "[SAFE -> " .. clean .. "]", msg1)
                            if r.cbBnet:GetChecked() and msg2 ~= "" then
                                PreviewLine(classColor, "[SAFE -> " .. clean .. " - 2nd]", msg2)
                            end
                        end
                    end

                    selected = selected + 1
                end
            end
        end
    end

    if selected == 0 then
        SSW.Print("No players selected or available.")
        return
    end

    -- Close window
    if SSW.UI.sendWin then
        SSW.UI.sendWin:Hide()
    end

    -- Stop here for test/safe mode
    if isTest or not SSW.IsArmed() then
        return
    end

    -- Send whispers
    if #queue == 0 then
        SSW.Print("Queue empty (nothing to send).")
        return
    end

    -- Mark burst start for anti-spam
    if SSW.AntiSpam.MarkBurstStart then
        SSW.AntiSpam.MarkBurstStart()
    end

    -- Fixed delay of 3 seconds
    local preSendDelay = 3

    SSW.Print("Waiting " .. preSendDelay .. " seconds before sending " .. #queue .. " whisper(s)...")

    C_Timer.After(preSendDelay, function()
        local idx = 0

        local function SendNext()
            idx = idx + 1
            local item = queue[idx]
            if not item then
                SSW.Print("Done sending whispers.")
                return
            end

            -- Mark for anti-spam
            if SSW.AntiSpam.MarkWhisper then
                SSW.AntiSpam.MarkWhisper(item.target)
            end

            SendChatMessage(item.text, "WHISPER", nil, item.target)
            
            -- Add to ignore list if requested
            if item.addToIgnore then
                local success = pcall(function()
                    C_FriendList.AddIgnore(item.target)
                end)
                if not success then
                    SSW.Print("Could not add " .. item.target .. " to ignore list (may be full or invalid name)")
                end
            end
            
            -- Increment session stats
            if SSW.IncrementSentCount then
                SSW.IncrementSentCount()
            end

            -- Schedule next
            if idx < #queue then
                C_Timer.After(SSW.SEND_DELAY, SendNext)
            end
        end

        SendNext()
    end)
end

-- Send whispers immediately with no delay and add players to ignore list
-- Used by "Ty All" and "Blame All" buttons
-- messageTemplate can be:
--   - A string template (for "Blame All" with "...")
--   - "RANDOM" to send random non-custom messages (for "Ty All")
function SSW.SendImmediatelyWithIgnore(messageTemplate, skipAntiSpam)
    if not SSW.UI or not SSW.UI.rows then
        SSW.Print("UI not ready.")
        return
    end

    local rows = SSW.UI.rows
    local queue = {}
    local selected = 0

    -- Check anti-spam unless explicitly skipped
    if not skipAntiSpam and SSW.IsArmed() then
        local ok, reason = SSW.AntiSpam.CanStartBurst()
        if not ok then
            SSW.Print("Anti-spam: " .. tostring(reason))
            return
        end
    end

    -- Build queue from visible rows
    for i = 1, SSW.MAX_ROWS do
        local r = rows[i]
        if r and r:IsShown() and r.playerName and r.playerName ~= "" then
            local clean = SSW.CleanName(r.playerName)
            local target = r.playerName
            
            -- Check anti-spam for this target unless explicitly skipped
            local canSend = true
            if not skipAntiSpam and SSW.IsArmed() then
                local ok, reason = SSW.AntiSpam.CanWhisperTarget(target)
                if not ok then
                    SSW.Print("Skipping " .. clean .. ": " .. tostring(reason))
                    canSend = false
                end
            end

            if canSend then
                local finalMessage = messageTemplate
                
                -- If RANDOM, select a random non-custom preset for each player
                if messageTemplate == "RANDOM" then
                    local presetIndices = {}
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
                    
                    -- Get the template
                    local template = SSW.MSG1_PRESETS[selectedIdx] or "gg {name}"
                    
                    -- Build meta data for the message
                    local meta = {
                        role = r.role or "NONE",
                        specID = r.specID or 0,
                        msg1Index = selectedIdx,
                    }
                    
                    -- Use BuildMessagesForTarget to fill in placeholders
                    finalMessage, _ = SSW.BuildMessagesForTarget(r.playerName, false, meta)
                else
                    -- For non-random (like "..."), use the message as-is
                    finalMessage = messageTemplate
                end
                
                table.insert(queue, { target = target, text = finalMessage })
                selected = selected + 1
            end
        end
    end

    if selected == 0 then
        SSW.Print("No players available.")
        return
    end

    -- Close window
    if SSW.UI.sendWin then
        SSW.UI.sendWin:Hide()
    end

    -- Send immediately if armed
    if SSW.IsArmed() then
        -- Mark burst start for anti-spam
        if not skipAntiSpam and SSW.AntiSpam.MarkBurstStart then
            SSW.AntiSpam.MarkBurstStart()
        end

        SSW.Print("Sending " .. #queue .. " whisper(s) immediately...")

        local idx = 0
        local function SendNext()
            idx = idx + 1
            local item = queue[idx]
            if not item then
                SSW.Print("Done sending whispers.")
                return
            end

            -- Mark for anti-spam
            if not skipAntiSpam and SSW.AntiSpam.MarkWhisper then
                SSW.AntiSpam.MarkWhisper(item.target)
            end

            -- Send whisper
            SendChatMessage(item.text, "WHISPER", nil, item.target)
            
            -- Increment session stats
            if SSW.IncrementSentCount then
                SSW.IncrementSentCount()
            end

            -- Add to ignore list
            C_FriendList.AddIgnore(item.target)

            -- Schedule next
            if idx < #queue then
                C_Timer.After(SSW.SEND_DELAY, SendNext)
            else
                SSW.Print("Done sending whispers. All players added to ignore list.")
            end
        end

        SendNext()
    else
        -- Safe mode preview
        SSW.Print("SAFE MODE: Would send to " .. selected .. " player(s) and add to ignore list.")
        for _, item in ipairs(queue) do
            local clean = SSW.CleanName(item.target)
            SSW.Print("[SAFE -> " .. clean .. "] " .. item.text)
        end
    end
end

-- Hook up send button
if SSW.UI and SSW.UI.btnSend then
    SSW.UI.btnSend:SetScript("OnClick", function()
        ProcessWhispers(SSW.IsTesting and true or false)
    end)
end

-- Fallback: hook up the button once it exists (in case Send.lua loaded before UI.lua)
local hookTimer
hookTimer = C_Timer.NewTicker(0.1, function()
    if SSW.UI and SSW.UI.btnSend then
        if not SSW.UI.btnSend:GetScript("OnClick") then
            SSW.UI.btnSend:SetScript("OnClick", function()
                ProcessWhispers(SSW.IsTesting and true or false)
            end)
        end
        hookTimer:Cancel()
    end
end)
