local APCli = require("lua-apclientpp")

require("utils")
require("ranksanity_utils")

local GameName = "Tetris Effect: Connected"
local APVersion = { 0, 6, 7 }
local modVersion = { 0, 0, 1 }
local items_handling = APCli.Permission.AUTO_ENABLED
local message_format = APCli.RenderFormat.TEXT

---@type APClient
ap = nil
---@type table
GameOptions = nil
slotData = nil
isGameCompleted = false
itemList = {}
checkedLocations = {}
LocationsToCheck = {}
server = nil
slot = nil
password = nil
isDeathLink = false
ZenStoryByAreas = false
EffectModeEnabled = false
ExcludedModes = {}
RanksanityEnabled = false
LastStage = 0

local UnlockedZenLevels = MakeSet(26)
local UnlockedEffectLevels = MakeSet(16)
local UnlockedGroups = MakeSet(10)
local RequiresVerify = false

function APCheckOasisLevelUnlocked(levelIndex)
    if not UnlockedEffectLevels[levelIndex] then
        return true
    end
    return false
end

function APZenIsAreaUnlocked(areaIndex)
    -- Change this later with actual checking
    if areaIndex == 2 then return true end
    return false
end

function APZenIsStageUnlocked(stageIndex)
    -- Change this later with actual checking
    return UnlockedZenLevels[stageIndex]
end

---comment
---@param Score any
---@param Stage any
---@param Difficulty any
---@param IsEffect? boolean
function APCheckRank(Score, Stage, Difficulty, IsEffect)
    -- Compare score to maybe a row of tables with rank info for the stage
    -- for _, ReqScore in ipairs(RankData[Stage]) do
    -- Compare and send checks
    -- Stop and return  when we're going lower than the current ReqScore
    -- end
    if ap == nil then return end
    CurrentRank = RequestRank(Score, Stage, Difficulty)
    if IsEffect == nil or not IsEffect then StageName = ZenLevels[Stage] else StageName = EffectLevels[Stage] end
    for _, value in ipairs(CurrentRank) do
        item_name = string.format("%s: %s Rank", StageName, value)
        print(item_name)
        item_id = ap:get_location_id(item_name)
        print(tostring(item_id))
        if item_id ~= nil then
            SendLocation(item_id)
        end
    end

    --print(CurrentRank)
end

function APClearStage(Stage, IsEffect)
    if IsEffect == nil or not IsEffect then
        StageName = ZenLevels[Stage]
        item_name = string.format("%s Stage Cleared", StageName)
    else
        StageName = EffectLevels[Stage]
        item_name = string.format("%s Mode Cleared", StageName)
    end
    print(item_name)
    item_id = ap:get_location_id(item_name)
    print(tostring(item_id))
    if item_id ~= nil then SendLocation(item_id) else PrintToAll("Error! Couldn't send stage clear!") end
end

function Connect(_server, _slot, _password)
    server = _server
    slot = _slot
    password = _password

    function OnSocketConnected()
        print("Socket connected succesfully")
    end

    function OnSocketError(reason)
        PrintToAll("An error ocurred connecting socket: " .. tostring(reason))
    end

    function OnSocketDisconnected()
        PrintToAll("Connection to archipelago was lost. Reconnecting...")
        itemList = {}
    end

    function HandleRoomInfo()
        print("Room info")
        ap:ConnectSlot(slot, password, items_handling, { "Lua-APClientPP" }, APVersion)
    end

    function OnSlotConnect(RSlotData)
        PrintToAll("Slot succesfully connected")
        --print("Locations checked are: " .. table.concat(ap.checked_locations, ", "))
        --print("Locations missing: " .. table.concat(ap.missing_locations, ", "))
        LocationsMissing = ap.missing_locations
        GameOptions = RSlotData
        for key, value in pairs(GameOptions) do
            print(key .. ": " .. tostring(value))
        end
        print("Getting locations")
        for _, id in ipairs(ap.checked_locations) do
            CheckLocation(id)
        end


        print("Enabling DeathLink")
        if GameOptions.death_link ~= 3 then
            isDeathLink = true
            ap:ConnectUpdate(nil, { "Lua-APClientPP", "DeathLink" })
            PrintToAll("DeathLink has been enabled")
        end

        print("Getting slot info")
        ZenStoryByAreas = GameOptions.unlock_method
        EffectModeEnabled = GameOptions.is_include_effect
        ExcludedModes = GameOptions.excluded_modes
        RanksanityEnabled = GameOptions.is_ranksanity

        --ParseItemUnlocks()
        print("Done")
        Helper_OnConnected()


        -- To-do,Call for lock items here
    end

    function OnSlotRefused(reasons)
        PrintToAll("Slot has refused connection. Reason: " .. table.concat(reasons, ", "))
        Helper_OnDisconnect()
    end

    function OnReceiveItems(ItemsReceived)
        --PrintToAll("Items received: " .. #ItemsReceived)
        for _, item in ipairs(ItemsReceived) do
            ParseItem(ap:get_item_name(item.item, nil))
        end
    end

    function on_location_info(locationInfos)
        for _, info in ipairs(locationInfos) do
            local itemname = ap:get_item_name(info.item, ap:get_player_game(info.player))
            local location = ap:get_location_name(info.location, ap:get_player_game(info.player))
            PrintToAll("scouted item " .. tostring(itemname) .. " in location " .. tostring(location))
        end
    end

    function on_location_checked(locations)
        PrintToAll("Locations checked:" .. table.concat(locations, ", "))
        print("Checked locations: " .. table.concat(ap.checked_locations, ", "))
        for _, LocationID in ipairs(locations) do
            CheckLocation(LocationID)
        end
    end

    function CheckLocation(location_id)
        local name = ap:get_location_name(location_id, nil)
        if name ~= nil then
            table.insert(checkedLocations, name)
        end
    end

    function on_data_package_changed(data_package)
        print("Data package changed:")
        print(table.concat(data_package, ", "))
    end

    function on_print(msg)
        PrintToAll(msg)
    end

    function on_print_json(msg, extra)
        PrintToAll(ap:render_json(msg, message_format))
    end

    function on_bounced(bounce)
        print("Bounced:")
        for k, v in pairs(bounce) do
            print(k .. ": " .. tostring(v))
        end
    end

    function on_retrieved(map, keys, extra)
        print("Retrieved:")
        for _, key in ipairs(keys) do
            print("  " .. key .. ": " .. tostring(map[key]))
        end
        print("Extra:")
        for key, value in pairs(extra) do
            print("  " .. key .. ": " .. tostring(value))
        end
    end

    function on_set_reply(message)
        print("Set Reply:")
        for key, value in pairs(message) do
            print("  " .. key .. ": " .. tostring(value))
            if key == "value" and type(value) == "table" then
                for subkey, subvalue in pairs(value) do
                    print("    " .. subkey .. ": " .. tostring(subvalue))
                end
            end
        end
    end

    local uuid = ""
    ap = APCli(uuid, GameName, server)
    PrintToAll("Connecting to " .. server .. " as " .. slot)

    ap:set_socket_connected_handler(OnSocketConnected)
    ap:set_socket_error_handler(OnSocketError)
    ap:set_socket_disconnected_handler(OnSocketDisconnected)
    ap:set_room_info_handler(HandleRoomInfo)
    ap:set_slot_connected_handler(OnSlotConnect)
    ap:set_slot_refused_handler(OnSlotRefused)
    ap:set_items_received_handler(OnReceiveItems)
    ap:set_location_info_handler(on_location_info)
    ap:set_location_checked_handler(on_location_checked)
    ap:set_data_package_changed_handler(on_data_package_changed)
    ap:set_print_handler(on_print)
    ap:set_print_json_handler(on_print_json)
    ap:set_bounced_handler(on_bounced)
    ap:set_retrieved_handler(on_retrieved)
    ap:set_set_reply_handler(on_set_reply)
end

function connectToAp(host, slot, password)
    ExecuteAsync(function()
        Connect(host, slot, password)
    end)

    LoopAsync(400, function()
        if ap == nil then
            return true
        end
        xpcall(function()
            ap:poll()
            -- AddHint("Polling!", HintType.Info)
            if #LocationsToCheck > 0 then
                local ToSend = {}
                for _, value in ipairs(LocationsToCheck) do
                    table.insert(ToSend, value)
                    checkedLocations[value] = true
                end
                ap:LocationChecks(ToSend)
                checkedLocations = {}
            end
        end, function()
            ap:disconnect()
        end)
        return false
    end)
end

function disconnect()
    if ap == nil then return end
    checkedLocations = {}
    item_list = {}
    ap = nil
    isDeathLink = false
    collectgarbage("collect")
    PrintToAll("Disconnected from archipelago")
end

ZenLevelItems = {
    ['The Deep Unlock'] = 0,
    ['Pharaoh\'s Code Unlock'] = 1,
    ['Karma Wheel Unlock'] = 2,
    ['Jellyfish Chorus Unlock'] = 3,
    ['Da Vinci Unlock'] = 4,
    ['Prayer Circles Unlock'] = 5,
    ['Ritual Passion Unlock'] = 6,
    ['Deserted Unlock'] = 7,
    ['Dolphin Surf Unlock'] = 8,
    ['Downtown Jazz Unlock'] = 9,
    ['Spirit Canyon Unlock'] = 10,
    ['Jewel Veil Unlock'] = 11,
    ['Forest Dawn Unlock'] = 12,
    ['Kaleidoscope Unlock'] = 13,
    ['Turtle Dreams Unlock'] = 14,
    ['Celebration Unlock'] = 15,
    ['Sunset Breeze Unlock'] = 16,
    ['Aurora Peak Unlock'] = 17,
    ['Zen Blossoms Unlock'] = 18,
    ['Ying & Yang Unlock'] = 19,
    ['Hula Soul Unlock'] = 20,
    ['Starfall Unlock'] = 21,
    ['Balloon High Unlock'] = 22,
    ['Mermaid Cove Unlock'] = 23,
    ['Orbit Unlock'] = 24,
    ['Stratosphere Unlock'] = 25,
    ['Metamorphosis Unlock'] = 26
}

EffectLevelItems = {
    ['Effect: Marathon Mode Unlock'] = 0,
    ['Effect: Zone Marathon Mode Unlock'] = 1,
    ['Effect: Ultra Mode Unlock'] = 2,
    ['Effect: Sprint Mode Unlock'] = 3,
    ['Effect: Master Mode Unlock'] = 4,
    ['Effect: Classic Score Attack Mode Unlock'] = 5,
    ['Effect: Chill Marathon Mode Unlock'] = 6,
    ['Effect: Quick Play Mode Unlock'] = 7,
    ['Effect: Playlist (Sea) Mode Unlock'] = 8,
    ['Effect: Playlist (Wind) Mode Unlock'] = 9,
    ['Effect: Playlist (World) Mode Unlock'] = 10,
    ['Effect: All Clear Mode Unlock'] = 11,
    ['Effect: Combo Mode Unlock'] = 12,
    ['Effect: Target Mode Unlock'] = 13,
    ['Effect: Countdown Mode Unlock'] = 14,
    ['Effect: Purity Mode Unlock'] = 15,
    ['Effect: Mystery Mode Unlock'] = 16
}

AreaItems = {
    ['Area 1 Unlock'] = { 0, 1, 2 },
    ['Area 2 Unlock'] = { 3, 4, 5, 6 },
    ['Area 3 Unlock'] = { 7, 8, 9, 10 },
    ['Area 4 Unlock'] = { 11, 12, 13, 14, 15 },
    ['Area 5 Unlock'] = { 16, 17, 18, 19, 20 },
    ['Area 6 Unlock'] = { 21, 22, 23, 24, 25 },
    ['Metamorphosis Unlock'] = { 26 },
    ['Effect: Classic Modes Unlock'] = { 0, 1, 2, 3, 4, 5 },
    ['Effect: Relax Modes Unlock'] = { 6, 7, 8, 9, 10 },
    ['Effect: Focus Modes Unlock'] = { 11, 12, 13 },
    ['Effect: Adventurous Modes Unlock'] = { 14, 15, 16 }
}


---Validates the item name given and makes it available to the player
---@param item_name string
function ParseItem(item_name)
    if string.find(item_name, "Unlock") ~= nil then
        if ZenStoryByAreas then
            if AreaItems[item_name] ~= nil then
                InEffect = false
                if string.find(item_name, "Effect:") ~= nil then InEffect = true end
                for _, level in ipairs(AreaItems[item_name]) do
                    if not InEffect then
                        UnlockedZenLevels[level] = true
                    else
                        if not CheckIfModelIsSkipped(item_name) then UnlockedEffectLevels[level] = true end
                    end
                end
                print("Received and unlocked levels of area: " .. item_name)
                return
            end
        end
        if ZenLevelItems[item_name] ~= nil then
            UnlockedZenLevels[ZenLevelItems[item_name]] = true
            print("Received and unlocked level: " .. item_name)
            return
        end
        if EffectLevelItems[item_name] ~= nil then
            UnlockedEffectLevels[EffectLevelItems[item_name]] = true
            print("Received and unlocked mode: " .. item_name)
            return
        end
        print("Received item \"" ..
            item_name ..
            "\" but it's feature is not yet implemented or the item was not recognized. Report it to the developer")
    elseif string.find(item_name, "Trap") ~= nil then
        QueueTrap(item_name)
    else
        print("Received item \"" ..
            item_name ..
            "\" which was deemed a filler item. If the item was not recognized as an unlock or trap please report it to the developer")
    end
end

function CheckIfModelIsSkipped(effect_mode)
    for index, value in ipairs(ExcludedModes) do
        if string.find(effect_mode, value) ~= nil then
            return true
        end
        return false
    end
end

function SendLocation(ID)
    if checkedLocations[ID] then return end
    print("Attempting to send item " .. ap:get_location_name(ID, ap:get_game()))
    table.insert(LocationsToCheck, ID)
end
