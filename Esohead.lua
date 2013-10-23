-----------------------------------------
--                                     --
--     E s o h e a d   L o o t e r     --
--                                     --
--    Patch: 0.27.8.646907             --
--    E-mail: feedback@esohead.com     --
--                                     --
-----------------------------------------

Esohead = ZO_CallbackObject:Subclass()

local savedVars
local debug = true
local currentTarget

-----------------------------------------
--           Core Functions            --
-----------------------------------------

function Esohead:New()
    local esoInit = ZO_CallbackObject.New(self)
    esoInit:Initialize()

    return esoInit
end

function Esohead:Initialize()
    local defaults = {
        skyshards = {},
        monsters = {},
        books = {},
        harvests = {},
        chests = {},
        pools = {},
        vendors = {},
    }
    savedVars = ZO_SavedVars:New("Esohead_SavedVariables", 1, "Esohead", defaults)

    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_RETICLE_TARGET_CHANGED, function(eventCode, ...) self:OnTargetChange() end)
    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_SKILL_POINTS_CHANGED, function(eventCode, ...) self:OnSkillUp() end)
end

-- Logs saved variables
function Esohead:Log(obj, keys, ...)
    local data = {}
    local dataStr = ""

    for i = 1, #keys do
        if obj[keys[i]] == nil then
            obj[keys[i]] = {}
        end
        obj = obj[keys[i]]
    end

    for i = 1, select("#", ...) do
        local value = select(i, ...)
        data[i] = value
        dataStr = dataStr .. "[" .. tostring(value) .. "] "
    end

    if debug then
        EHLog("Logged data: " .. dataStr)
    end

    if #obj == 0 then
        obj[1] = data
    else
        obj[#obj+1] = data
    end
end

-- Checks if we already have an entry for the object/npc within a certain x/y distance
function Esohead:LogCheck(obj, keys, x, y)
    local log = true

    for i = 1, #keys do
        if obj[keys[i]] == nil then
            obj[keys[i]] = {}
        end
        obj = obj[keys[i]]
    end

    for i = 1, #obj do
        local item = obj[i]
        if (math.abs(item[2] - x) < 0.01 or math.abs(item[3] - x) < 0.01) and (math.abs(item[3] - y) < 0.01 or math.abs(item[2] - y) < 0.01) then
            log = false
        end
    end

    return log
end

function Esohead:OnUpdate()
    local action, name, interactionBlocked, additionalInfo, context = GetGameCameraInteractableActionInfo()

    if action and name and name ~= currentTarget then
        local type = GetInteractionType()
        local active = IsPlayerInteractingWithObject()
        local x, y, a, subzone, world = self:GetUnitPosition("player")
        local targetType = nil

        -- Use
        if type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE5) then
            currentTarget = name

            EHLog("NYI: On-Use -- " .. name)

        -- Harvesting
        elseif type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE5) then
            currentTarget = name
            targetType = "harvest"

            if self:LogCheck(savedVars.harvests, {subzone, name}, x, y) then
                self:Log(savedVars.harvests, {subzone, name}, x, y)
            end

        -- Chest
        elseif type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE12) then
            currentTarget = name
            targetType = "chest"
            local lockQuality = context

            if self:LogCheck(savedVars.chests, {subzone, GetString("SI_LOCKQUALITY", lockQuality)}, x, y) then
                self:Log(savedVars.chests, {subzone, GetString("SI_LOCKQUALITY", lockQuality)}, x, y)
            end

        -- Lore/Skill Books
        elseif active and type == INTERACTION_BOOK then
            currentTarget = name
            targetType = "book"

            if self:LogCheck(savedVars.books, {subzone, name}, x, y) then
                self:Log(savedVars.books, {subzone, name}, x, y)
            end

        -- Fishing Nodes
        elseif type == INTERACTION_FISH then
            currentTarget = name
            targetType = "fish"

            if self:LogCheck(savedVars.pools, {subzone}, x, y) then
                self:Log(savedVars.pools, {subzone}, x, y)
            end

        -- NPC Vendor
        elseif active and type == INTERACTION_VENDOR then
            currentTarget = name
            targetType = "vendor"

            EHLog("NYI: NPC Vendor")

        end

        if targetType ~= nil then
            self:FireCallbacks("ESOHEAD_EVENT_TARGET_CHANGED", targetType, name, x, y)
        end
    end
end

-----------------------------------------
--            API Helpers              --
-----------------------------------------

function Esohead:GetUnitPosition(tag)
    local x, y, a = GetMapPlayerPosition(tag)
    local subzone = GetMapName()
    local world = GetUnitZone(tag)

    return x, y, a, subzone, world
end

function Esohead:GetUnitName(tag)
    return GetUnitName(tag)
end

function Esohead:GetUnitLevel(tag)
    return GetUnitLevel(tag)
end

-----------------------------------------
--        API Event Management         --
-----------------------------------------

-- Fired when the reticle hovers a new target
function Esohead:OnTargetChange(eventCode)
    local tag = "reticleover"
    local type = GetUnitType(tag)

    -- ensure the unit that the reticle is hovering is a non-playing character
    if type == 2 then
        local name = self:GetUnitName(tag)
        local x, y, a, subzone, world = self:GetUnitPosition(tag)
        local level = self:GetUnitLevel(tag)

        if self:LogCheck(savedVars.monsters, {subzone, name}, x, y) then
            self:Log(savedVars.monsters, {subzone, name}, level, x, y)
        end

        self:FireCallbacks("ESOHEAD_EVENT_TARGET_CHANGED", "npc", name, x, y, level)
    end
end

-- fired when the player levels up OR collects a skyshard
function Esohead:OnSkillUp(eventCode, pointsOld, pointsNew, isSkyshard)
    if isSkyshard then
        local x, y, a, subzone, subzone = Esohead:GetUnitPosition("player")

        self:Log(savedVars.skyshards, {subzone}, x, y)
    end
end

-----------------------------------------
--        Addon Initialization         --
-----------------------------------------

local function OnAddOnLoaded(eventCode, addOnName)
    if(addOnName == "Esohead") then
        Esohead:New()
    end
end

EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_ADD_ON_LOADED, OnAddOnLoaded)