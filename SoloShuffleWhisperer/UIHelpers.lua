-- UIHelpers.lua
-- Shared UI helper functions for class icons, spec icons, role icons

SSW = SSW or {}
SSW.UI = SSW.UI or {}

-- =========================================
-- Class icon helper
-- =========================================
local CLASS_ICON_TOKEN = {
    WARRIOR     = "Warrior",    PALADIN     = "Paladin",
    HUNTER      = "Hunter",     ROGUE       = "Rogue",
    PRIEST      = "Priest",     DEATHKNIGHT = "DeathKnight",
    SHAMAN      = "Shaman",     MAGE        = "Mage",
    WARLOCK     = "Warlock",    MONK        = "Monk",
    DRUID       = "Druid",      DEMONHUNTER = "DemonHunter",
    EVOKER      = "Evoker",
}

function SSW.UI.ClassIconTag(classFile, size)
    size = size or 16
    if not classFile then return "" end
    local token = CLASS_ICON_TOKEN[classFile]
    if not token then return "" end
    local path = "Interface\\Icons\\ClassIcon_" .. token
    return ("|T%s:%d:%d:0:0|t "):format(path, size, size)
end

function SSW.UI.SpecIconTag(specID, size)
    size   = size or 16
    specID = tonumber(specID)
    if not specID or specID <= 0     then return "" end
    if not GetSpecializationInfoByID then return "" end
    local _, _, _, icon = GetSpecializationInfoByID(specID)
    if not icon then return "" end
    return ("|T%s:%d:%d:0:0|t "):format(tostring(icon), size, size)
end

function SSW.UI.RoleIconTag(role, size)
    size = size or 14
    if not CreateAtlasMarkup then return "" end
    role = tostring(role or "")
    if role == "TANK"    then return CreateAtlasMarkup("roleicon-tiny-tank",   size, size) .. " " end
    if role == "HEALER"  then return CreateAtlasMarkup("roleicon-tiny-healer", size, size) .. " " end
    if role == "DAMAGER" then return CreateAtlasMarkup("roleicon-tiny-dps",    size, size) .. " " end
    return ""
end

function SSW.UI.RoleText(role)
    role = tostring(role or "")
    if role == "TANK"    then return "Tank"   end
    if role == "HEALER"  then return "Healer" end
    if role == "DAMAGER" then return "DPS"    end
    return "Role?"
end

function SSW.UI.GetClassColorStr(classFile)
    local c = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
           or (RAID_CLASS_COLORS and RAID_CLASS_COLORS["PRIEST"])
    return (c and c.colorStr) or "ffffffff"
end
