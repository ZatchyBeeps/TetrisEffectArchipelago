local APCli = require("lua-apclientpp")

require("utils")

local GameName = "ULTRAKILL"
local APVersion = { 0, 6, 7 }
local modVersion = { 0, 0, 1 }
local items_handling = APCli.Permission.AUTO_ENABLED
local message_format = APCli.RenderFormat.TEXT

---@type APClient
ap = nil

options = nil
slotData = nil
isGameCompleted = false
itemList = {}
checkedLocations = {}
server = nil
slot = nil
password = nil
isDeathLink = false

local OasisLevels = MakeSet({ 2, 5 }) -- 5 = master

function APCheckOasisLevelUnlocked(levelIndex)
    if not OasisLevels[levelIndex] then
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
    if stageIndex == 6 or stageIndex == 7 or stageIndex == 8 then return true end
    return false
end

function Connect(_server, _slot, _password)
    server = _server
    slot = _slot
    password = _password

    function OnSocketConnected()
        PrintToAll("Socket connected succesfully")
    end

    function OnSocketError(reason)
        PrintToAll("An error ocurred connecting socket: " .. tostring(reason))
    end

    function OnSocketDisconnected()
        PrintToAll("Socket was disconnected")
        itemList = {}
    end

    function HandleRoomInfo()
        print("Room info")
        ap:ConnectSlot(slot, password, items_handling, { "Lua-APClientPP" }, APVersion)
    end

    function OnSlotConnect(RSlotData)
        PrintToAll("Slot succesfully connected")
        print("Locations checked are: " .. table.concat(ap.checked_locations, ", "))
        print("Locations missing: " .. table.concat(ap.missing_locations, ", "))
        LocationsMissing = ap.missing_locations
        slotData = RSlotData
        options = slotData.options

        for _, id in ipairs(ap.checked_locations) do
            CheckLocation(id)
        end

        if slotData.Version then
            if slotData.Version[1] ~= modVersion[1] and slotData.Version[2] ~= modVersion[2] and slotData.Version[3] ~= modVersion[3] then
                PrintToAll("Warning. Mod has different version from the one provided in the slot data (ModV: " ..
                table.concat(modVersion, ".") .. ", SlotDataV: " .. table.concat(slotData.Version, ".") .. ")")
            end
        end

        if options.DeathLink == 1 then
            isDeathLink = true
            ap:ConnectUpdate(nil, { "Lua-APClientPP", "DeathLink" })
            PrintToAll("DeathLink has been enabled")
        end

        -- To-do: Call for lock items here
    end

    function OnSlotRefused(reasons)
        PrintToAll("Slot has refused connection. Reason: " .. table.concat(reasons, ", "))
    end

    function OnReceiveItems(ItemsReceived)
        PrintToAll("Items received: " .. #ItemsReceived)
        for _, item in ipairs(ItemsReceived) do
            print(ap:get_location_name(item.item, nil))
        end
    end

    function on_location_info(locationInfos)
        PrintToAll("Locations scouted: " .. table.concat(locationInfos, ", "))
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

    LoopAsync(200, function()
        if ap == nil then
            return true
        end
        xpcall(function()
            ap:poll()
            --print("polling")
        end, 
		function()
            ap:disconnect()
        end)
        return false
    end)
end

function disconnect()
    if ap == nil then return end
    CheckedLocations = {}
    item_list = {}
    ap = nil
    isDeathLink = false
    collectgarbage("collect")
    PrintToAll("Disconnected from archipelago")
end


