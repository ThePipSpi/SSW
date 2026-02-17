-- Snapshot.lua
-- Captures and manages player data from Solo Shuffle scoreboard

SSW = SSW or {}

SSW.PartySnapshot = SSW.PartySnapshot or {
    takenAt = 0,
    members = {},
    valid = false,
    locked = false,
}

-- Helper: get role from spec name (best effort via known spec IDs 1-500)
local function GetSpecInfo(specName)
    if not specName or specName == "" then return nil, "DAMAGER" end
    if not GetSpecializationInfoByID then return nil, "DAMAGER" end
    for id = 1, 500 do
        local ok, specID, name, _, _, role = pcall(GetSpecializationInfoByID, id)
        if ok and name and name:lower() == specName:lower() then
            return id, (role or "DAMAGER")
        end
    end
    return nil, "DAMAGER"
end

-- Capture snapshot from scoreboard
function SSW.SnapshotScoreboard()
    RequestBattlefieldScoreData()
    
    local numScores = GetNumBattlefieldScores()
    if not numScores or numScores <= 0 then
        return false
    end
    
    local members = {}
    local myName = UnitName("player")
    
    for i = 1, numScores do
        local name, _, _, _, _, _, _, _, _, classFile, _, _, _, _, _, specName = GetBattlefieldScore(i)
        if name and name ~= myName then
            local specID, role = GetSpecInfo(specName)
            
            table.insert(members, {
                fullName = name,
                classFile = classFile or "WARRIOR",
                specName = specName or "Unknown",
                specID = specID,
                guid = UnitGUID(name) or "",
                role = role or "DAMAGER",
            })
        end
    end
    
    if #members == 0 then
        return false
    end
    
    SSW.PartySnapshot = {
        takenAt = SSW.Now(),
        members = members,
        valid = true,
        locked = false,
    }
    
    return true
end

-- Lock snapshot (prevent updates)
function SSW.LockSnapshot()
    if SSW.PartySnapshot then
        SSW.PartySnapshot.locked = true
    end
end

-- Unlock snapshot
function SSW.UnlockSnapshot()
    if SSW.PartySnapshot then
        SSW.PartySnapshot.locked = false
    end
end

-- Clear snapshot
function SSW.ClearSnapshot()
    SSW.PartySnapshot = {
        takenAt = 0,
        members = {},
        valid = false,
        locked = false,
    }
end
