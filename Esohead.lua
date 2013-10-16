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

    if savedVars[key] == nil then
        savedVars[key] = {}
        savedVars[key][1] = data
    else
        savedVars[key][#savedVars[key]+1] = data
    end
end

-----------------------------------------
--            API Helpers              --
-----------------------------------------

function Esohead:GetPosition()
    return GetMapPlayerPosition("player")
end

function Esohead:GetMap()
    return GetMapName()
end

-----------------------------------------
--          Event Management           --
-----------------------------------------

function OnEventInit(eventCode, addOnName)
    if(addOnName == "Esohead") then
        EHLog("Esohead Looter Loaded - Thanks!")
        savedVars = ZO_SavedVars:New("Esohead_SavedVariables", 1, "EHDATA", {})
    end
end

function OnEventSkyshard(eventCode, pointsOld, pointsNew, isSkyShard)
    if isSkyShard then
        local x, y, a = Esohead:GetPosition()
        local map = Esohead:GetMap()

        Esohead:Store("skyshard", map, x, y)

        if debug then
            EHLog(string.format("[SKYSHARD] map=%s x=%s, y=%s", map, tostring(x), tostring(y)))
        end
    end
end

EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_ADD_ON_LOADED, OnEventInit)
EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_SKILL_POINTS_CHANGED, OnEventSkyshard)