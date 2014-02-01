-----------------------------------------
--                                     --
--     E s o h e a d   L o o t e r     --
--                                     --
--    Patch: eso.live.1.0.0.708405     --
--    E-mail: feedback@esohead.com     --
--                                     --
-----------------------------------------

Esohead = ZO_CallbackObject:Subclass()

local savedVars = {}
local savedVarsVersion = 1
local debugDefault = 0
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
    local dataDefault = {
        data = {}
    }

    savedVars = {
        ["internal"]     = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "internal", { debug = debugDefault }),
        ["skyshard"]     = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "skyshard", dataDefault),
        ["book"]         = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "book", dataDefault),
        ["harvest"]      = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "harvest", dataDefault),
        ["chest"]        = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "chest", dataDefault),
        ["fish"]         = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "fish", dataDefault),
        ["npc"]          = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "npc", dataDefault),
        ["vendor"]       = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "vendor", dataDefault),
        ["interactable"] = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "interactable", dataDefault),
        ["rune"]         = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "rune", dataDefault),
        ["quest"]        = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", savedVarsVersion, "quest", dataDefault),
    }

    if savedVars["internal"].debug == 1 then
        Esohead:Debug("Esohead addon initialized. Debugging is enabled.")
    else
        Esohead:Debug("Esohead addon initialized. Debugging is disabled.")
    end

    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_RETICLE_TARGET_CHANGED, function(eventCode, ...) self:OnTargetChange() end)
end

-- Logs saved variables
function Esohead:Log(type, nodes, ...)
    local data = {}
    local dataStr = ""
    local sv

    if savedVars[type] == nil or savedVars[type].data == nil then
        Esohead:Debug("Attempted to log unknown type: " .. type)
        return
    else
        sv = savedVars[type].data
    end

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

    if savedVars["internal"].debug == 1 then
        self:Debug("Logged [" .. type .. "] data: " .. dataStr)
    end

    if #sv == 0 then
        sv[1] = data
    else
        sv[#sv+1] = data
    end
end

-- Checks if we already have an entry for the object/npc within a certain x/y distance
function Esohead:LogCheck(type, nodes, x, y)
    local log = true
    local sv

    if savedVars[type] == nil or savedVars[type].data == nil then
        return true
    else
        sv = savedVars[type].data
    end

    for i = 1, #nodes do
        if sv[nodes[i]] == nil then
            sv[nodes[i]] = {}
        end
        sv = sv[nodes[i]]
    end

    for i = 1, #sv do
        local item = sv[i]

        if math.abs(item[1] - x) < 0.01 and math.abs(item[2] - y) < 0.01 then
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

    if action ~= nil and name ~= nil and name ~= currentTarget then
        local type = GetInteractionType()
        local active = IsPlayerInteractingWithObject()
        local x, y, a, subzone, world = self:GetUnitPosition("player")
        local targetType

        -- Use
        if type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE5) then
            currentTarget = name
            targetType = "skyshard"

            if name == "Skyshard" then
                if self:LogCheck(targetType, {subzone}, x, y) then
                    self:Log(targetType, {subzone}, x, y)
                end
            end

        -- Harvesting
        elseif active and type == INTERACTION_HARVEST then
            currentTarget = name

            if (string.find(name,"Rune")) then
                targetType = "rune"
            else
                targetType = "harvest"
            end

            if self:LogCheck(targetType, {subzone, name}, x, y) then
                self:Log(targetType, {subzone, name}, x, y)
            end

        -- Chest
        elseif type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE12) then
            currentTarget = name
            targetType = "chest"
            local lockQuality = context

            if GetString("SI_LOCKQUALITY", lockQuality) ~= "" then
                if self:LogCheck(targetType, {subzone, GetString("SI_LOCKQUALITY", lockQuality)}, x, y) then
                    self:Log(targetType, {subzone, GetString("SI_LOCKQUALITY", lockQuality)}, x, y)
                end
            end

        -- Fishing Nodes
        elseif action == GetString(SI_GAMECAMERAACTIONTYPE16) then
            currentTarget = name
            targetType = "fish"

            if self:LogCheck(targetType, {subzone}, x, y) then
                self:Log(targetType, {subzone}, x, y)
            end

        -- NPC Vendor
        elseif active and type == INTERACTION_VENDOR then
            currentTarget = name
            targetType = "vendor"

            local storeItems = {}

            if self:LogCheck(targetType, {subzone, name}, x, y) then
                for entryIndex = 1, GetNumStoreItems() do
                    local icon, name, stack, price, sellPrice, meetsRequirementsToBuy, meetsRequirementsToEquip, quality, questNameColor, currencyType1, currencyId1, currencyQuantity1, currencyIcon1,
                    currencyName1, currencyType2, currencyId2, currencyQuantity2, currencyIcon2, currencyName2 = GetStoreEntryInfo(entryIndex)

                    if(stack > 0) then
                        local itemData =
                        {
                            icon,
                            name,
                            stack,
                            price,
                            sellPrice,
                            quality,
                            questNameColor,
                            currencyName1,
                            currencyType1,
                            currencyId1,
                            currencyQuantity1,
                            currencyName2,
                            currencyType2,
                            currencyId2,
                            currencyQuantity2,
                            { GetStoreEntryTypeInfo(entryIndex) },
                            GetStoreEntryStatValue(entryIndex),
                        }

                        storeItems[#storeItems + 1] = itemData
                    end
                end

                self:Log(targetType, {subzone, name}, x, y, storeItems)
            end
        end

        if targetType ~= nil then
            self:FireCallbacks("ESOHEAD_EVENT_TARGET_CHANGED", targetType, name, x, y)
        end
    end
end

-----------------------------------------
--        Loot Tracking (NYI)          --
-----------------------------------------

local function OnLootReceived(eventCode, receivedBy, objectName, stackCount, soundCategory, lootType, lootedBySelf)

end

-----------------------------------------
--         Lore Book Tracking          --
-----------------------------------------

local function OnShowBook(eventCode, title, body, medium, showTitle)
    local x, y, a, subzone, world = Esohead:GetUnitPosition("player")

    local targetType = "book"

    if Esohead:LogCheck(targetType, {subzone, title}, x, y) then
        Esohead:Log(targetType, {subzone, title}, x, y)
    end
end

-----------------------------------------
--           Quest Tracking            --
-----------------------------------------

local function OnQuestAdded(_, questIndex)
    local questName = GetJournalQuestInfo(questIndex)
    local action, name, interactionBlocked, additionalInfo, context = GetGameCameraInteractableActionInfo()
    local x, y, a, subzone, world = Esohead:GetUnitPosition("player")

    local level = GetJournalQuestLevel(questIndex)

    local targetType = "quest"

    if Esohead:LogCheck(targetType, {subzone, questName}, x, y) then
        Esohead:Log(targetType, {subzone, questName}, x, y, level, name)
    end
end

-----------------------------------------
--         Coordinate System           --
-----------------------------------------

function Esohead:UpdateCoordinates()

    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()

    if (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer) then
        local currentOffsetX = ZO_WorldMapContainer:GetLeft()
        local currentOffsetY = ZO_WorldMapContainer:GetTop()
        local parentOffsetX = ZO_WorldMap:GetLeft()
        local parentOffsetY = ZO_WorldMap:GetTop()
        local mouseX, mouseY = GetUIMousePosition()
        local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
        local parentWidth, parentHeight = ZO_WorldMap:GetDimensions()

        local normalizedX = math.floor((((mouseX - currentOffsetX) / mapWidth) * 100) + 0.5)
        local normalizedY = math.floor((((mouseY - currentOffsetY) / mapHeight) * 100) + 0.5)

        EsoheadCoordinates:SetAlpha(0.8)
        EsoheadCoordinates:SetDrawLayer(ZO_WorldMap:GetDrawLayer() + 1)
        EsoheadCoordinates:SetAnchor(TOPLEFT, nil, TOPLEFT, parentOffsetX + 0, parentOffsetY + parentHeight)
        EsoheadCoordinatesValue:SetText("Coordinates: " .. normalizedX .. ", " .. normalizedY)
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

function Esohead:GetLootEntry(index)
    return GetLootItemInfo(index)
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

        if self:LogCheck("npc", {subzone, name}, x, y) then
            self:Log("npc", {subzone, name}, x, y, level)
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
            savedVars["internal"].debug = 1
        elseif commands[2] == "off" then
            Esohead:Debug("Esohead debugger toggled off")
            savedVars["internal"].debug = 0
        end

    elseif commands[1] == "reset" then
        for type,sv in pairs(savedVars) do
            if type ~= "internal" then
                savedVars[type].data = {}
            end
        end

        Esohead:Debug("Saved data has been completely reset")

    elseif commands[1] == "datalog" then
        Esohead:Debug("---")
        Esohead:Debug("Complete list of gathered data:")
        Esohead:Debug("---")

        local counter = {
            ["skyshard"] = 0,
            ["npc"] = 0,
            ["harvest"] = 0,
            ["chest"] = 0,
            ["interactable"] = 0,
            ["fish"] = 0,
            ["book"] = 0,
            ["vendor"] = 0,
            ["rune"] = 0,
            ["quest"] = 0,
        }

        for type,sv in pairs(savedVars) do
            if type ~= "internal" and type == "skyshard" then
                for zone, t1 in pairs(savedVars[type].data) do
                    counter[type] = counter[type] + #savedVars[type].data[zone]
                end
            elseif type ~= "internal" then
                for zone, t1 in pairs(savedVars[type].data) do
                    for data, t2 in pairs(savedVars[type].data[zone]) do
                        counter[type] = counter[type] + #savedVars[type].data[zone][data]
                    end
                end
            end
        end

        Esohead:Debug("Skyshards: "        .. Esohead:NumberFormat(counter["skyshard"]))
        Esohead:Debug("Monster/NPCs: "     .. Esohead:NumberFormat(counter["npc"]))
        Esohead:Debug("Lore/Skill Books: " .. Esohead:NumberFormat(counter["book"]))
        Esohead:Debug("Harvest Nodes: "    .. Esohead:NumberFormat(counter["harvest"]))
        Esohead:Debug("Treasure Chests: "  .. Esohead:NumberFormat(counter["skyshard"]))
        Esohead:Debug("Lootable Nodes: "   .. Esohead:NumberFormat(counter["interactable"]))
        Esohead:Debug("Fishing Pools: "    .. Esohead:NumberFormat(counter["fish"]))
        Esohead:Debug("Runes: "            .. Esohead:NumberFormat(counter["rune"]))
        Esohead:Debug("Quests: "           .. Esohead:NumberFormat(counter["quest"]))

        Esohead:Debug("---")
    end
end

SLASH_COMMANDS["/rl"] = function(txt)
    ReloadUI("ingame")
end

-----------------------------------------
--        Addon Initialization         --
-----------------------------------------

local function OnAddOnLoaded(eventCode, addOnName)
    if(addOnName == "Esohead") then
        Esohead:New()
    end
end

EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_LOOT_RECEIVED, OnLootReceived)
EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_SHOW_BOOK, OnShowBook)
EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_QUEST_ADDED, OnQuestAdded)
EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_ADD_ON_LOADED, OnAddOnLoaded)