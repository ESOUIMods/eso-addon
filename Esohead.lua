-----------------------------------------
--                                     --
--     E s o h e a d   L o o t e r     --
--                                     --
--    Patch: eso.live.1.0.0.708405     --
--    E-mail: feedback@esohead.com     --
--                                     --
-----------------------------------------

EH = {}

EH.savedVars = {}
EH.debugDefault = 0
EH.dataDefault = {
    data = {}
}
EH.currentTarget = ""
EH.currentConversation = {
    npcName = "",
    npcLevel = 0,
    x = 0,
    y = 0,
    subzone = ""
}

-----------------------------------------
--           Core Functions            --
-----------------------------------------

function EH.InitSavedVariables()
    EH.savedVars = {
        ["internal"]     = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 1, "internal", { debug = EH.debugDefault }),
        ["skyshard"]     = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 2, "skyshard", EH.dataDefault),
        ["book"]         = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 2, "book", EH.dataDefault),
        ["harvest"]      = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 4, "harvest", EH.dataDefault),
        ["provisioning"] = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 4, "provisioning", EH.dataDefault),
        ["chest"]        = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 2, "chest", EH.dataDefault),
        ["fish"]         = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 2, "fish", EH.dataDefault),
        ["npc"]          = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 2, "npc", EH.dataDefault),
        ["vendor"]       = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 2, "vendor", EH.dataDefault),
        ["quest"]        = ZO_SavedVars:NewAccountWide("Esohead_SavedVariables", 2, "quest", EH.dataDefault),
    }

    if EH.savedVars["internal"].debug == 1 then
        EH.Debug("Esohead addon initialized. Debugging is enabled.")
    else
        EH.Debug("Esohead addon initialized. Debugging is disabled.")
    end
end

-- Logs saved variables
function EH.Log(type, nodes, ...)
    local data = {}
    local dataStr = ""
    local sv

    if EH.savedVars[type] == nil or EH.savedVars[type].data == nil then
        EH.Debug("Attempted to log unknown type: " .. type)
        return
    else
        sv = EH.savedVars[type].data
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

    if EH.savedVars["internal"].debug == 1 then
        EH.Debug("Logged [" .. type .. "] data: " .. dataStr)
    end

    if #sv == 0 then
        sv[1] = data
    else
        sv[#sv+1] = data
    end
end

-- Checks if we already have an entry for the object/npc within a certain x/y distance
function EH.LogCheck(type, nodes, x, y)
    local log = true
    local sv

    if x <= 0 or y <= 0 then
        return false
    end

    if EH.savedVars[type] == nil or EH.savedVars[type].data == nil then
        return true
    else
        sv = EH.savedVars[type].data
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
function EH.NumberFormat(num)
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

-- Listens for anything that is not event driven by the API but needs to be tracked
function EH.OnUpdate()
    local action, name, interactionBlocked, additionalInfo, context = GetGameCameraInteractableActionInfo()

    if action == nil or name == nil or name == "" or name == EH.currentTarget then
        return
    end

    local type = GetInteractionType()
    local active = IsPlayerInteractingWithObject()
    local x, y, a, subzone, world = EH.GetUnitPosition("player")
    local targetType

    -- Skyshard
    if type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE5) then
        EH.currentTarget = name
        targetType = "skyshard"

        if name == "Skyshard" then
            if EH.LogCheck(targetType, {subzone}, x, y) then
                EH.Log(targetType, {subzone}, x, y)
            end
        end

    -- Chest
    elseif type == INTERACTION_NONE and action == GetString(SI_GAMECAMERAACTIONTYPE12) then
        EH.currentTarget = name
        targetType = "chest"

        if EH.LogCheck(targetType, {subzone}, x, y) then
            EH.Log(targetType, {subzone}, x, y)
        end

    -- Fishing Nodes
    elseif action == GetString(SI_GAMECAMERAACTIONTYPE16) then
        EH.currentTarget = name
        targetType = "fish"

        if EH.LogCheck(targetType, {subzone}, x, y) then
            EH.Log(targetType, {subzone}, x, y)
        end

    -- NPC Vendor
    elseif active and type == INTERACTION_VENDOR then
        EH.currentTarget = name
        targetType = "vendor"

        local storeItems = {}

        if EH.LogCheck(targetType, {subzone, name}, x, y) then
            for entryIndex = 1, GetNumStoreItems() do
                local icon, name, stack, price, sellPrice, meetsRequirementsToBuy, meetsRequirementsToEquip, quality, questNameColor, currencyType1, currencyId1, currencyQuantity1, currencyIcon1,
                currencyName1, currencyType2, currencyId2, currencyQuantity2, currencyIcon2, currencyName2 = GetStoreEntryInfo(entryIndex)

                if(stack > 0) then
                    local itemData =
                    {
                        name,
                        stack,
                        price,
                        quality,
                        questNameColor,
                        currencyType1,
                        currencyQuantity1,
                        currencyType2,
                        currencyQuantity2,
                        { GetStoreEntryTypeInfo(entryIndex) },
                        GetStoreEntryStatValue(entryIndex),
                    }

                    storeItems[#storeItems + 1] = itemData
                end
            end

            EH.Log(targetType, {subzone, name}, x, y, storeItems)
        end
    end
end

-----------------------------------------
--         Coordinate System           --
-----------------------------------------

function EH.UpdateCoordinates()
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

function EH.GetUnitPosition(tag)
    local x, y, a = GetMapPlayerPosition(tag)
    local subzone = GetMapName()
    local world = GetUnitZone(tag)

    return x, y, a, subzone, world
end

function EH.GetUnitName(tag)
    return GetUnitName(tag)
end

function EH.GetUnitLevel(tag)
    return GetUnitLevel(tag)
end

function EH.GetLootEntry(index)
    return GetLootItemInfo(index)
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

function EH.Debug(...)
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
--        Loot Tracking (NYI)          --
-----------------------------------------

function EH.ItemLinkParse(link)
    local matches = {}
    i = 1

    for match in string.gmatch(link, ":(%w+)") do
        matches[i] = match
        i = i + 1
    end

    if #matches < 20 then
        return {
            type = false,
            id = false,
            quality = false
        }
    end

    return {
        type = matches[1],
        id = tonumber(matches[2]),
        quality = matches[3]
    }
end

function EH.OnLootReceived(eventCode, receivedBy, objectName, stackCount, soundCategory, lootType, lootedBySelf)

end

function EH.OnLootUpdated(eventCode)
    local action = GetGameCameraInteractableActionInfo()
    local name, targetType, actionName = GetLootTargetInfo()
    local x, y, a, subzone, world = EH.GetUnitPosition("player")

    if not IsPlayerInteractingWithObject() and targetType ~= 5 then
        return
    end

    local numLootItems = GetNumLootItems()
    for i = 1, numLootItems do
        local lootId, itemName, icon, count, quality, value, isQuest = GetLootItemInfo(i)
        local link = EH.ItemLinkParse(GetLootItemLink(lootId))

        if link.type == "item" then
            local material = EH.GetTradeskillByMaterial(link.id)

            if not material then
                return
            end

            if targetType == 5 then
                if EH.LogCheck("provisioning", {subzone, material, link.id}, x, y) then
                    EH.Log("provisioning", {subzone, material, link.id}, x, y, count, name)
                end
            else
                if EH.LogCheck("harvest", {subzone, material}, x, y) then
                    EH.Log("harvest", {subzone, material}, x, y, count, name, link.id)
                end
            end
        end
    end
end

-----------------------------------------
--         Lore Book Tracking          --
-----------------------------------------

function EH.OnShowBook(eventCode, title, body, medium, showTitle)
    local x, y, a, subzone, world = EH.GetUnitPosition("player")

    local targetType = "book"

    if EH.LogCheck(targetType, {subzone, title}, x, y) then
        EH.Log(targetType, {subzone, title}, x, y)
    end
end

-----------------------------------------
--           Quest Tracking            --
-----------------------------------------

function EH.OnQuestAdded(_, questIndex)
    local questName = GetJournalQuestInfo(questIndex)
    local questLevel = GetJournalQuestLevel(questIndex)

    local targetType = "quest"

    if EH.LogCheck(targetType, {EH.currentConversation.subzone, questName}, EH.currentConversation.x, EH.currentConversation.y) then
        EH.Log(
            targetType,
            {
                EH.currentConversation.subzone,
                questName
            },
            EH.currentConversation.x,
            EH.currentConversation.y,
            questLevel,
            EH.currentConversation.npcName,
            EH.currentConversation.npcLevel
        )
    end
end

-----------------------------------------
--        Conversation Tracking        --
-----------------------------------------

function EH.OnChatterBegin()
    local action, name, interactionBlocked, additionalInfo, context = GetGameCameraInteractableActionInfo()
    local x, y, a, subzone, world = EH.GetUnitPosition("player")
    local npcLevel = EH.GetUnitLevel("interact")

    EH.currentConversation.npcName = name
    EH.currentConversation.npcLevel = npcLevel
    EH.currentConversation.x = x
    EH.currentConversation.y = y
    EH.currentConversation.subzone = subzone
end

-----------------------------------------
--        Better NPC Tracking          --
-----------------------------------------

-- Fired when the reticle hovers a new target
function EH.OnTargetChange(eventCode)
    local tag = "reticleover"
    local type = GetUnitType(tag)

    -- ensure the unit that the reticle is hovering is a non-playing character
    if type == 2 then
        local name = EH.GetUnitName(tag)
        local x, y, a, subzone, world = EH.GetUnitPosition(tag)

        if name == nil or name == "" or x <= 0 or y <= 0 then
            return
        end

        local level = EH.GetUnitLevel(tag)

        if EH.LogCheck("npc", {subzone, name}, x, y) then
            EH.Log("npc", {subzone, name}, x, y, level)
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
        return EH.Debug("Please enter a valid command")
    end

    if #commands == 2 and commands[1] == "debug" then
        if commands[2] == "on" then
            EH.Debug("Esohead debugger toggled on")
            EH.savedVars["internal"].debug = 1
        elseif commands[2] == "off" then
            EH.Debug("Esohead debugger toggled off")
            EH.savedVars["internal"].debug = 0
        end

    elseif commands[1] == "reset" then
        for type,sv in pairs(EH.savedVars) do
            if type ~= "internal" then
                EH.savedVars[type].data = {}
            end
        end

        EH.Debug("Saved data has been completely reset")

    elseif commands[1] == "datalog" then
        EH.Debug("---")
        EH.Debug("Complete list of gathered data:")
        EH.Debug("---")

        local counter = {
            ["skyshard"] = 0,
            ["npc"] = 0,
            ["harvest"] = 0,
            ["provisioning"] = 0,
            ["chest"] = 0,
            ["fish"] = 0,
            ["book"] = 0,
            ["vendor"] = 0,
            ["quest"] = 0,
        }

        for type,sv in pairs(EH.savedVars) do
            if type ~= "internal" and (type == "skyshard" or type == "chest" or type == "fish") then
                for zone, t1 in pairs(EH.savedVars[type].data) do
                    counter[type] = counter[type] + #EH.savedVars[type].data[zone]
                end
            elseif type ~= "internal" and type == "provisioning" then
                for zone, t1 in pairs(EH.savedVars[type].data) do
                    for item, t2 in pairs(EH.savedVars[type].data[zone]) do
                        for data, t3 in pairs(EH.savedVars[type].data[zone][item]) do
                            counter[type] = counter[type] + #EH.savedVars[type].data[zone][item][data]
                        end
                    end
                end
            elseif type ~= "internal" then
                for zone, t1 in pairs(EH.savedVars[type].data) do
                    for data, t2 in pairs(EH.savedVars[type].data[zone]) do
                        counter[type] = counter[type] + #EH.savedVars[type].data[zone][data]
                    end
                end
            end
        end

        EH.Debug("Skyshards: "        .. EH.NumberFormat(counter["skyshard"]))
        EH.Debug("Monster/NPCs: "     .. EH.NumberFormat(counter["npc"]))
        EH.Debug("Lore/Skill Books: " .. EH.NumberFormat(counter["book"]))
        EH.Debug("Harvest: "          .. EH.NumberFormat(counter["harvest"]))
        EH.Debug("Provisioning: "     .. EH.NumberFormat(counter["provisioning"]))
        EH.Debug("Treasure Chests: "  .. EH.NumberFormat(counter["skyshard"]))
        EH.Debug("Fishing Pools: "    .. EH.NumberFormat(counter["fish"]))
        EH.Debug("Quests: "           .. EH.NumberFormat(counter["quest"]))
        EH.Debug("Vendor Lists: "     .. EH.NumberFormat(counter["vendor"]))

        EH.Debug("---")
    end
end

SLASH_COMMANDS["/rl"] = function()
    ReloadUI("ingame")
end

SLASH_COMMANDS["/reload"] = function()
    ReloadUI("ingame")
end

-----------------------------------------
--        Addon Initialization         --
-----------------------------------------

function EH.OnLoad(eventCode, addOnName)
    if addOnName ~= "Esohead" then
        return
    end

    EH.InitSavedVariables()
    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_RETICLE_TARGET_CHANGED, EH.OnTargetChange)
    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_CHATTER_BEGIN, EH.OnChatterBegin)
    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_SHOW_BOOK, EH.OnShowBook)
    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_QUEST_ADDED, EH.OnQuestAdded)
    EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_LOOT_UPDATED, EH.OnLootUpdated)
end

EVENT_MANAGER:RegisterForEvent("Esohead", EVENT_ADD_ON_LOADED, EH.OnLoad)