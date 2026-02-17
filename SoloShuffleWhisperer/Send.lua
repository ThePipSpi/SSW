-- Send.lua
-- Handles the actual sending of whispers with anti-spam protection

SSW = SSW or {}

local queue = {}

local function FillPlaceholders(s, data)
    s = tostring(s or "")
    if data.useName then
        s = s:gsub("{name}", data.cleanName or "")
    else
        s = s:gsub("{name}", "")
    end
    s = s:gsub("{praise}", SSW.RandomPraise and SSW.RandomPraise() or "good job")
    
    -- Converti il ruolo in testo leggibile
    local roleText = "DPS"
    if data.role == "TANK" then
        roleText = "Tank"
    elseif data.role == "HEALER" then
        roleText = "Healer"
    elseif data.role == "DAMAGER" then
        roleText = "DPS"
    end
    
    s = s:gsub("{role}", roleText)
    s = s:gsub("{spec}", data.specName or "")
    s = s:gsub("{btag}", data.btag or "")
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

local function BuildMessagesForRow(r)
    if not r or not r.playerName then return "", "", "", "" end

    local i1 = r.msg1Index or 1 -- Usa l'indice della riga
    local i2 = tonumber(SSW_Config.msg2Index) or 1
    if i1 < 1 or i1 > #SSW.MSG1_PRESETS then i1 = 1 end
    if i2 < 1 or i2 > #SSW.MSG2_PRESETS then i2 = 1 end

    local tpl1 = SSW.MSG1_PRESETS[i1] or ""
    local tpl2 = SSW.MSG2_PRESETS[i2] or ""

    local clean = SSW.CleanName(r.playerName)
    local btag = SSW.GetMyBattleTag and SSW.GetMyBattleTag() or ""

    local msg1 = FillPlaceholders(tpl1, {
        useName = r.cbName:GetChecked(),
        cleanName = clean,
        specName = r.specName or "",
        role = r.role or "DPS",
        btag = btag,
    })

    local msg2 = FillPlaceholders(tpl2, {
        useName = r.cbName:GetChecked(),
        cleanName = clean,
        specName = r.specName or "",
        role = r.role or "DPS",
        btag = btag,
    })

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
        if r and r:IsShown() and r.cbMain:GetChecked() then
            if not r.playerName or r.playerName == "" then
                SSW.Print("Row " .. i .. " selected but has no target name.")
            else
                local msg1, msg2, clean, target = BuildMessagesForRow(r)
                local classColor = r.text:GetText() and (r.text:GetText():match("|cff(%x+)") or "ffffff") or "ffffff"

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

    -- Get delay
    local preSendDelay = tonumber(SSW_Config.preSendDelay) or SSW.DEFAULT_PRE_SEND_DELAY

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

            -- Schedule next
            if idx < #queue then
                C_Timer.After(SSW.SEND_DELAY, SendNext)
            else
                SSW.Print("Done sending whispers.")
            end
        end

        SendNext()
    end)
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
