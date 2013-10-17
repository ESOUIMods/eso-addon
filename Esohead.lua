-----------------------------------------
--                                     --
--     E s o h e a d   L o o t e r     --
--                                     --
--    Patch: 0.27.8.646907             --
--    E-mail: feedback@esohead.com     --
--                                     --
-----------------------------------------

Esohead = {}

local savedVars
local debug = true

-----------------------------------------
--            Data Storage             --
-----------------------------------------

function Esohead:Store(key, ...)
    local data = {}

    for i = 1, select("#", ...) do
        local value = select(i, ...)
        data[i] = value
    end

    if key == nil then
        key = {}
        key[1] = data
    else
        key[#key+1] = data
    end
end

-----------------------------------------
--            API Helpers              --
-----------------------------------------

function Esohead:GetMap()
    return GetMapName()
end

function Esohead:GetUnitPosition(tag)
    return GetMapPlayerPosition(tag)
end

function Esohead:GetUnitName(tag)
    return GetUnitName(tag)
end

function Esohead:GetUnitLevel(tag)
    return GetUnitLevel(tag)
end

function Esohead:GetUnitZone(tag)
    return GetUnitZone(tag)
end

-----------------------------------------
--          Event Management           --
-----------------------------------------

function OnEventInit(eventCode, addOnName)
    if addOnName == "Esohead" then
        EHLog("Esohead Looter Loaded - Thanks!")
        local defaults = {
            skyshards = {},
            monsters = {},
            npcs = {},
        }
        savedVars = ZO_SavedVars:New("Esohead_SavedVariables", 1, "EHDATA", defaults)
    end
end

-- Fired when the reticle hovers a new target
function OnEventTargetChange(eventCode)
    local tag = "reticleover"
    local type = GetUnitType(tag)

    -- ensure the unit that the reticle is hovering is a non-playing character
    if type == 2 then
        local name = Esohead:GetUnitName(tag)
        local x, y, a = Esohead:GetUnitPosition(tag)
        local level = Esohead:GetUnitLevel(tag)
        local map = Esohead:GetMap()

        -- create saved variable entry for the creature and map if they don't exist
        if savedVars.monsters[map] == nil then
            savedVars.monsters[map] = {}
        end

        if savedVars.monsters[map][name] == nil then
            savedVars.monsters[map][name] = {}
        end

        -- we don't want to log multiple entries for same-named creatures that are very close to each other
        local log = true

        for i = 1, #savedVars.monsters[map][name] do
            local item = savedVars.monsters[map][name][i]
            if math.abs(item[2] - x) < 0.01 and math.abs(item[3] - y) < 0.01 then
                log = false
            end
        end

        if log then
            Esohead:Store(savedVars.monsters[map][name], level, x, y)
        end
    end
end

function OnEventSkyshard(eventCode, pointsOld, pointsNew, isSkyshard)
    if isSkyshard then
        local x, y, a = Esohead:GetUnitPosition("player")
        local map = Esohead:GetMap()

        Esohead:Store(savedVars.skyshards, map, x, y)

        if debug then
            EHLog(string.format("[SKYSHARD] map=%s x=%s, y=%s", map, x, y))
        end
    end
end

EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_RETICLE_TARGET_CHANGED, OnEventTargetChange)
EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_ADD_ON_LOADED, OnEventInit)
EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_SKILL_POINTS_CHANGED, OnEventSkyshard)