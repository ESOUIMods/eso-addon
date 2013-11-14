-----------------------------------------
--                                     --
--     E s o h e a d   L o o t e r     --
--                                     --
--    Patch: 0.27.9.659475             --
--    E-mail: feedback@esohead.com     --
--                                     --
-----------------------------------------

Esohead = ZO_CallbackObject:Subclass()

local savedVars
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
        skyshard = {},
        npc = {},
        book = {},
        harvest = {},
        chest = {},
        fish = {},
        vendor = {},
        interactable = {},
        debug = 1,
    }
    savedVars = ZO_SavedVars:New("Esohead_SavedVariables", 1, "Esohead", defaults)

    if savedVars.debug == 1 then
        Esohead:Debug("Esohead addon initialized. Debugging is enabled.")
    else
        Esohead:Debug("Esohead addon initialized. Debugging is disabled.")
    end

    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_RETICLE_TARGET_CHANGED, function(eventCode, ...) self:OnTargetChange() end)
end

-- Logs saved variables
function Esohead:Log(nodes, ...)
    local data = {}
    local dataStr = ""
    local sv = savedVars

    for i = 1, #nodes do
        if sv[nodes[i]] == nil then
            sv[nodes[i]] = {}
        end
        sv = sv[nodes[i]]
    end

    for i = 1, select("#", ...) do
        local value = select(i, ...)
        data[i] = value
        dataStr = dataStr .. "[" .. tostring(value) .. "] "
    end

    if savedVars.debug == 1 then
        self:Debug("---")
        self:Debug("Logged data: " .. dataStr)
        self:Debug(nodes)
    end

    if #sv == 0 then
        sv[1] = data
    else
        sv[#sv+1] = data
    end
end

-- Checks if we already have an entry for the object/npc within a certain x/y distance
function Esohead:LogCheck(nodes, x, y)
    local log = true
    local sv = savedVars

    for i = 1, #nodes do
        if sv[nodes[i]] == nil then
            sv[nodes[i]] = {}
        end
        sv = sv[nodes[i]]
    end

    for i = 1, #sv do
        local item = sv[i]

        if math.abs(item[1] - x) < 0.01 and math.abs(item[2] - y) then
            log = false
        end
    end

    return log
end

-- formats a number with commas on thousands
function Esohead:NumberFormat(num)
    local formatted = num
    local k

    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end

    return formatted
end

-- Fired every frame in-game, listens for target changes since the API is insufficient
function Esohead:OnUpdate()
    local action, name, interactionBlocked, additionalInfo, context = GetGameCameraInteractableActionInfo()

    if action and name and name ~= currentTarget then
        local type = GetInteractionType()
        local active = IsPlayerInteractingWithObject()
        local x, y, a, subzone, world = self:GetUnitPosition("player")
        local targetType

        -- Use
        if type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE5) then
            currentTarget = name

            if name == "Skyshard" then
                targetType = "skyshard"

                if self:LogCheck({targetType, subzone}, x, y) then
                    self:Log({targetType, subzone}, x, y)
                end
            end

        -- Lootable
        elseif action == GetString(SI_GAMECAMERAACTIONTYPE1) then
            currentTarget = name
            targetType = "interactable"

            if self:LogCheck({targetType, subzone, name}, x, y) then
                self:Log({targetType, subzone, name}, x, y)
            end

        -- Harvesting
        elseif action == GetString(SI_GAMECAMERAACTIONTYPE3) then
            currentTarget = name
            targetType = "harvest"

            if self:LogCheck({targetType, subzone, name}, x, y) then
                self:Log({targetType, subzone, name}, x, y)
            end

        -- Chest
        elseif type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE12) then
            currentTarget = name
            targetType = "chest"
            local lockQuality = context

            if self:LogCheck({targetType, subzone, GetString("SI_LOCKQUALITY", lockQuality)}, x, y) then
                self:Log({targetType, subzone, GetString("SI_LOCKQUALITY", lockQuality)}, x, y)
            end

        -- Lore/Skill Books
        elseif active and type == INTERACTION_BOOK then
            currentTarget = name
            targetType = "book"

            if self:LogCheck({targetType, subzone, name}, x, y) then
                self:Log({targetType, subzone, name}, x, y)
            end

        -- Fishing Nodes
        elseif action == GetString(SI_GAMECAMERAACTIONTYPE16) then
            currentTarget = name
            targetType = "fish"

            if self:LogCheck({targetType, subzone}, x, y) then
                self:Log({targetType, subzone}, x, y)
            end

        -- NPC Vendor
        elseif active and type == INTERACTION_VENDOR then
            currentTarget = name
            targetType = "vendor"

            self:Debug("NYI: NPC Vendor")

        end

        if targetType ~= nil then
            self:FireCallbacks("ESOHEAD_EVENT_TARGET_CHANGED", targetType, name, x, y)
        end
    end
end

-----------------------------------------
--         Coordinate System           --
-----------------------------------------

function Esohead:UpdateCoordinates()
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl();

    if (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer) then

        local currentOffsetX = ZO_WorldMapContainer:GetLeft()
        local currentOffsetY = ZO_WorldMapContainer:GetTop()
        local parentOffsetX = ZO_WorldMap:GetLeft()
        local parentOffsetY = ZO_WorldMap:GetTop()
        local mouseX, mouseY = GetUIMousePosition()
        local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
        local parentWidth, parentHeight = ZO_WorldMap:GetDimensions()

        local normalizedX = math.floor((((mouseX - currentOffsetX) / mapWidth) * 100) + 0.5);
        local normalizedY = math.floor((((mouseY - currentOffsetY) / mapHeight) * 100) + 0.5);

        EsoheadCoordinates:SetAlpha(0.8)
        EsoheadCoordinates:SetDrawLayer(ZO_WorldMap:GetDrawLayer() + 1)
        EsoheadCoordinates:SetAnchor(TOPLEFT, nil, TOPLEFT, parentOffsetX + 130, parentOffsetY + parentHeight - 33)
        EsoheadCoordinatesValue:SetText(normalizedX .. ", " .. normalizedY)
    else
        EsoheadCoordinates:SetAlpha(0)
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

        if self:LogCheck({"npc", subzone, name}, x, y) then
            self:Log({"npc", subzone, name}, x, y, level)
        end

        self:FireCallbacks("ESOHEAD_EVENT_TARGET_CHANGED", "npc", name, x, y, level)
    end
end

-----------------------------------------
--           Debug Logger              --
-----------------------------------------

local function EmitMessage(text)
    if(CHAT_SYSTEM)
    then
        if(text == "")
        then
            text = "[Empty String]"
        end

        CHAT_SYSTEM:AddMessage(text)
    end
end

local function EmitTable(t, indent, tableHistory)
    indent          = indent or "."
    tableHistory    = tableHistory or {}

    for k, v in pairs(t)
    do
        local vType = type(v)

        EmitMessage(indent.."("..vType.."): "..tostring(k).." = "..tostring(v))

        if(vType == "table")
        then
            if(tableHistory[v])
            then
                EmitMessage(indent.."Avoiding cycle on table...")
            else
                tableHistory[v] = true
                EmitTable(v, indent.."  ", tableHistory)
            end
        end
    end
end

function Esohead:Debug(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if(type(value) == "table")
        then
            EmitTable(value)
        else
            EmitMessage(tostring (value))
        end
    end
end

-----------------------------------------
--           Slash Command             --
-----------------------------------------

SLASH_COMMANDS["/esohead"] = function (cmd)
    local commands = {}
    local index = 1
    for i in string.gmatch(cmd, "%S+") do
        if (i ~= nil and i ~= "") then
            commands[index] = i
            index = index + 1
        end
    end

    if #commands == 0 then
        return Esohead:Debug("Please enter a valid command")
    end

    if #commands == 2 and commands[1] == "debug" then
        if commands[2] == "on" then
            Esohead:Debug("Esohead debugger toggled on")
            savedVars.debug = 1
        elseif commands[2] == "off" then
            Esohead:Debug("Esohead debugger toggled off")
            savedVars.debug = 0
        end

    elseif commands[1] == "reset" then
        savedVars.skyshard = {}
        savedVars.npc = {}
        savedVars.book = {}
        savedVars.harvest = {}
        savedVars.interactable = {}
        savedVars.chest = {}
        savedVars.fish = {}
        savedVars.vendor = {}

        Esohead:Debug("Saved data has been completely reset")

    elseif commands[1] == "datalog" then
        Esohead:Debug("---")
        Esohead:Debug("Complete list of gathered data:")
        Esohead:Debug("---")

        local skyshard = 0
        local npc = 0
        local harvest = 0
        local chest = 0
        local interactable = 0
        local fish = 0
        local book = 0

        for zone, t1 in pairs(savedVars.skyshard) do
            skyshard = skyshard + #savedVars.skyshard[zone]
        end

        for zone, t1 in pairs(savedVars.npc) do
            for data, t2 in pairs(savedVars.npc[zone]) do
                npc = npc + #savedVars.npc[zone][data]
            end
        end

        for zone, t1 in pairs(savedVars.harvest) do
            for data, t2 in pairs(savedVars.harvest[zone]) do
                harvest = harvest + #savedVars.harvest[zone][data]
            end
        end

        for zone, t1 in pairs(savedVars.chest) do
            for data, t2 in pairs(savedVars.chest[zone]) do
                chest = chest + #savedVars.chest[zone][data]
            end
        end

        for zone, t1 in pairs(savedVars.interactable) do
            for data, t2 in pairs(savedVars.interactable[zone]) do
                interactable = interactable + #savedVars.interactable[zone][data]
            end
        end

        for zone, t1 in pairs(savedVars.fish) do
            for data, t2 in pairs(savedVars.fish[zone]) do
                fish = fish + #savedVars.fish[zone][data]
            end
        end

        for zone, t1 in pairs(savedVars.book) do
            for data, t2 in pairs(savedVars.book[zone]) do
                book = book + #savedVars.book[zone][data]
            end
        end

        Esohead:Debug("Skyshards: "        .. Esohead:NumberFormat(skyshard))
        Esohead:Debug("Monster/NPCs: "     .. Esohead:NumberFormat(npc))
        Esohead:Debug("Lore/Skill Books: " .. Esohead:NumberFormat(book))
        Esohead:Debug("Harvest Nodes: "    .. Esohead:NumberFormat(harvest))
        Esohead:Debug("Treasure Chests: "  .. Esohead:NumberFormat(chest))
        Esohead:Debug("Lootable Nodes: "   .. Esohead:NumberFormat(interactable))
        Esohead:Debug("Fishing Pools: "    .. Esohead:NumberFormat(fish))

        Esohead:Debug("---")
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