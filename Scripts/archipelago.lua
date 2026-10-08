---@diagnostic disable: lowercase-global
local APCli = require("lua-apclientpp")

require("utils")
require("ranksanity_utils")
require("area_ranksanity_utils")

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
DeathLinkType = 0
ZenStoryByAreas = false
EffectModeEnabled = false
ExcludedModes = {}
RanksanityEnabled = false
ZoneUnlocked = true
LevelsToComplete = 0
LastStage = 0
StagesCompleted = 0

local UnlockedZenLevels = MakeSet(26)
local UnlockedEffectLevels = MakeSet(16)
local UnlockedGroups = MakeSet(10)
local RequiresVerify = false

local TSpinNum = 0
local BackToBackNum = 0
local BackToBackRen = 0
local TetrisNum = 0
local IsFirstConnection = false


function APOasisIsLevelUnlocked(levelIndex)
    if not UnlockedEffectLevels[levelIndex] then
        return true
    end
    return false
end

function APZenIsAreaUnlocked(areaIndex)
    if not UnlockedGroups[areaIndex] then return false end
    return true
end

function APZenIsStageUnlocked(stageIndex)
    --print(tostring(stageIndex))
    if stageIndex == 26 then
        if StagesCompleted < LevelsToComplete and not UnlockedZenLevels[26] then return true end
        return false
    end
    if stageIndex > 26 then return true end
    return UnlockedZenLevels[stageIndex]
end

---Sends all rank locations from the given Stage based on the score given and the game's current difficulty.
---Alternatively, it sends rank locations from the effect mode index given as Stage, based on a given rank value on Score if IsEffect is set to true
---@param Score integer Either score obtained or a ScoreRankType value
---@param Stage integer Zen stage or GameResultType value
---@param Difficulty integer What difficulty is the player on. Ignored if trying to check out from Effect mode
---@param IsEffect? boolean Are we on effect mode?
function APCheckRank(Score, Stage, Difficulty, IsEffect)
    if ap == nil then return end
    if IsEffect == nil or not IsEffect then
        if Difficulty == 0 then return end
        local CurrentRank = RequestRank(Score, Stage, Difficulty)
        local StageName = ZenLevels[Stage]
        for _, value in ipairs(CurrentRank) do
            local item_name = string.format("%s: %s Rank", StageName, value)
            local item_id = ap:get_location_id(item_name)
            if item_id ~= nil then
                SendLocation(item_id)
            else PrettyPrint("Attempted to send location but it was not found. Item: " .. item_name)
            end
        end

    else
        local StageName = nil
        if Stage == 17 then -- Obtain which Playlist mode are we playing, or QuickPlay if we aren't
            ---@type ATPStageManager_C
            local StageManager = FindFirstOf("TPStageManager_C")
            if StageManager ~= nil then
                local IsQuickPlay = false

                local res = {}
                StageManager.ModeBehavior:IsQuickPlay(res)
                for _, value in ipairs(res) do IsQuickPlay = value end

                if not IsQuickPlay then StageName = EffectLevels[8 + StageManager.ModeBehavior.PlayListKind]
                else StageName = EffectLevels[7] end
            end
        else
            StageName = EffectLevels[GameResultToModeID[Stage]] -- Get the name if it's some other stage emode
        end
        PrettyPrint("Sending ranks of Effect mode " .. StageName)
        for _, value in ipairs(GetObtainedRanks(Score)) do
            local item_name = string.format("%s: %s Rank", StageName, value)
            local item_id = ap:get_location_id(item_name)
            if item_id ~= nil then
                SendLocation(item_id)
            else PrettyPrint("Attempted to send location but it was not found. Item: " .. item_name)
            end
        end
    end
    --print(CurrentRank)
end

function APSendAreaRankChecks(Score, Area, Difficulty)
    if Difficulty == 0 then return end
        for _, Rank in ipairs(RequestAreaRank(Score, Area, Difficulty)) do
            local item_name = string.format("Area %q: %s Rank", Area, Rank)
            local item_id = ap:get_location_id(item_name)
            if item_id ~= nil then
                SendLocation(item_id)
            else PrettyPrint("Attempted to send location but it was not found. Item: " .. item_name)
            end
        end
end

function APClearStage(Stage, IsEffect)
    if Stage == 26 then GameGoal() end
    if IsEffect == nil or not IsEffect then
        StageName = ZenLevels[Stage]
        item_name = string.format("%s Stage Cleared", StageName)
    else
        StageName = EffectLevels[GameResultToModeID[Stage]]
        item_name = string.format("%s Mode Cleared", StageName)
    end
    item_id = ap:get_location_id(item_name)
    if item_id ~= nil then SendLocation(item_id) else PrintToAll("Error! Couldn't send stage clear!") end
end

function APDoTrickChecks(LinesCleared, TSpinType, ComboAmount, WasB2B, WasAllClear)
    if LinesCleared == 4 then TetrisNum = TetrisNum + 1 end
    if TSpinType ~= 0 then TSpinNum = TSpinNum + 1 end
    if ComboAmount == 8 then SendNext(ap:get_location_id("Made an 8 line combo 1 times")) end
    if WasB2B then BackToBackNum = BackToBackNum + 1 end
    if WasAllClear then SendNext(ap:get_location_id("Made 1 all clear")) end
    if WasB2B and ComboAmount ~= 0 then BackToBackRen = BackToBackRen + 1 else BackToBackRen = 0 end
    if TSpinType == 2 and LinesCleared == 3 then SendNext(ap:get_location_id("Made 1 T-spin triple")) end
    

    if TetrisNum >= 15 then
        SendNext(ap:get_location_id("Made 15 Tetris line clears"))
        TetrisNum = 0
    end
    if TSpinNum >= 10 then
        SendNext(ap:get_location_id("Made 10 T-Spins"))
        TSpinNum = 0
    end
    if BackToBackNum >= 10 then
        SendNext(ap:get_location_id("Made 10 back-to-backs"))
        BackToBackNum = 0
    end
    if BackToBackRen >= 4 then
        SendNext(ap:get_location_id("Made a 4-combo back-to-back 1 times"))
        BackToBackRen = 0
    end
end

function APSendZoneChecks(LinesCleared)
    if LinesCleared >= 8 and LinesCleared < 12 then SendNext(ap:get_location_id("Made 1 octotris"))
    elseif LinesCleared >= 12 and LinesCleared < 16 then SendNext(ap:get_location_id("Made 1 dodecatris"))
    elseif LinesCleared >= 16 and LinesCleared < 18 then SendNext(ap:get_location_id("Made 1 decahexatris"))
    elseif LinesCleared >= 18 and LinesCleared < 20 then SendNext(ap:get_location_id("Made 1 perfectris"))
    elseif LinesCleared == 20 then SendNext(ap:get_location_id("Made 1 ultimatris"))
    elseif LinesCleared >= 21 then SendNext(ap:get_location_id("Made 1 kirbtris"))
    end
end

function APSendDeathLink()
    if ap ~= nil and isDeathLink then
        --PrintToAll("You topped out! Sending death link...")
        ap:Bounce({ cause = "", source = slot, time = os.time(os.date("!*t")) }, nil, nil, {"DeathLink"})
    end
end

function Connect(_server, _slot, _password)
    server = _server
    slot = _slot
    password = _password

    function OnSocketConnected()
        PrettyPrint("[Archipelago] Socket connected succesfully")
    end

    function OnSocketError(reason)
        PrintToAll("[Archipelago] An error ocurred connecting socket: " .. tostring(reason))
    end

    function OnSocketDisconnected()
        PrintToAll("[Archipelago] Connection to archipelago was lost. Reconnecting...")
        itemList = {}
    end

    function HandleRoomInfo()
        PrettyPrint("[Archipelago] Room info step begin")
        ap:ConnectSlot(slot, password, items_handling, { "Lua-APClientPP" }, APVersion)
    end

    function OnSlotConnect(RSlotData)
        PrintToAll("[Archipelago] Slot succesfully connected")
        IsFirstConnection = true
        --print("Locations checked are: " .. table.concat(ap.checked_locations, ", "))
        --print("Locations missing: " .. table.concat(ap.missing_locations, ", "))
        LocationsMissing = ap.missing_locations
        GameOptions = RSlotData
        for key, value in pairs(GameOptions) do
            PrettyPrint("[Archipelago] [Room Info] " .. key .. ": " .. tostring(value))
        end
        PrettyPrint("[Archipelago] [Room Info] Getting locations")
        for _, id in ipairs(ap.checked_locations) do
            CheckLocation(id)
        end


        PrettyPrint("[Archipelago] [Room Info] Enabling DeathLink")
        if GameOptions.death_link ~= 3 then
            isDeathLink = true
            DeathLinkType = GameOptions.death_link
            ap:ConnectUpdate(nil, { "Lua-APClientPP", "DeathLink" })
            PrintToAll("DeathLink has been enabled with type " .. tostring(DeathLinkType))
        end

        PrettyPrint("[Archipelago] [Room Info] Getting slot info")
        ZenStoryByAreas = GameOptions.unlock_method
        EffectModeEnabled = GameOptions.is_include_effect
        ExcludedModes = GameOptions.excluded_modes
        RanksanityEnabled = GameOptions.is_ranksanity
        ZoneUnlocked = GameOptions.is_start_zone
        LevelsToComplete = GameOptions.stages_required
        PrettyPrint("[Archipelago] [Room Info] Requiring amount of stages: " .. tostring(LevelsToComplete))

        --ParseItemUnlocks()
        PrettyPrint("[Archipelago] [Room Info] Done")
        Helper_OnConnected()

        -- To-do,Call for lock items here
    end

    function OnSlotRefused(reasons)
        PrintToAll("Slot has refused connection. Reason: " .. table.concat(reasons, ", "))
        Helper_OnDisconnect()
    end

    ---@param ItemsReceived NetworkItem[]
    function OnReceiveItems(ItemsReceived)
        --PrintToAll("Items received: " .. #ItemsReceived)
        for _, item in ipairs(ItemsReceived) do
            ParseItem(ap:get_item_name(item.item, nil))
        end
        if IsFirstConnection then IsFirstConnection = false end
    end

    function on_location_info(locationInfos)
        for _, info in ipairs(locationInfos) do
            local itemname = ap:get_item_name(info.item, ap:get_player_game(info.player))
            local location = ap:get_location_name(info.location, ap:get_player_game(info.player))
            PrettyPrint("[Archipelago] Scouted item " .. tostring(itemname) .. " in location " .. tostring(location))
        end
    end

    function on_location_checked(locations)
        --PrintToAll("Locations checked:" .. table.concat(locations, ", "))
        --print("Checked locations: " .. table.concat(ap.checked_locations, ", "))
        for _, LocationID in ipairs(locations) do
            CheckLocation(LocationID)
        end
    end

    function CheckLocation(location_id)
        local name = ap:get_location_name(location_id, nil)
        if name ~= nil then
            checkedLocations[location_id] = true
            if string.find(name, "Cleared") then
                StagesCompleted = StagesCompleted + 1
                PrettyPrint("Level has been cleared! Adding to the count...")
            end
        end
    end

    function on_data_package_changed(data_package)
        PrettyPrint("[Archipelago] Data package changed:")
        if IsFirstConnection then PrintToAll("WARNING: Data package has changed on first connection. If this is the first time you've connected to the server please reconnect or restart your game as your starting items might not have been loaded correctly.") end
        PrettyPrint(table.concat(data_package, ", "))
    end

    function on_print(msg)
        PrintToAll(msg)
    end

    function on_print_json(msg, extra)
        PrintToAll(ap:render_json(msg, message_format))
    end

    function on_bounced(bounce)
        PrettyPrint("[Archipelago] Bounced:")
        for k, v in pairs(bounce) do
            PrettyPrint(k .. ": " .. tostring(v))
        end
        if bounce.tags and isDeathLink then
            for _, tag in ipairs(bounce.tags) do
                if tag == "DeathLink" then
                    local cause = #bounce.data.cause > 0 and bounce.data.cause or (bounce.data.source .. " has died...")
                    PrintToAll(cause)
                    DeathLinkPlayer()
                end
            end
        end
    end

    function on_retrieved(map, keys, extra)
        PrettyPrint("[Archipelago] Retrieved:")
        for _, key in ipairs(keys) do
            PrettyPrint("  " .. key .. ": " .. tostring(map[key]))
        end
        PrettyPrint("[Archipelago] Extra:")
        for key, value in pairs(extra) do
            PrettyPrint("  " .. key .. ": " .. tostring(value))
        end
    end

    function on_set_reply(message)
        PrettyPrint("[Archipelago] Set Reply:")
        for key, value in pairs(message) do
            PrettyPrint("  " .. key .. ": " .. tostring(value))
            if key == "value" and type(value) == "table" then
                for subkey, subvalue in pairs(value) do
                    PrettyPrint("    " .. subkey .. ": " .. tostring(subvalue))
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
                    PrettyPrint("Sending location id " .. tostring(value))
                    table.insert(ToSend, value)
                    checkedLocations[value] = true
                end
                ap:LocationChecks(ToSend)
                LocationsToCheck = {}
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
    UnlockedZenLevels = {}
    UnlockedEffectLevels = {}
    UnlockedGroups = {}
    IsFirstConnection = true
    TSpinNum = 0
    TetrisNum = 0
    BackToBackNum = 0
    BackToBackRen = 0
    StagesCompleted = 0
    LevelsToComplete = 0
    item_list = {}
    ap = nil
    isDeathLink = false
    collectgarbage("collect")
    PrintToAll("Disconnected from archipelago")
end

function debug_GiveAll()
    for key, _ in pairs(UnlockedZenLevels) do
        UnlockedZenLevels[key] = true
    end
    for key, _ in pairs(UnlockedEffectLevels) do
        UnlockedEffectLevels[key] = true
    end
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
    ['Effect: Purify Mode Unlock'] = 15,
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
                PrettyPrint("[Item Parsing] Received and unlocked levels of area: " .. item_name)
                return
            end
        end
        if ZenLevelItems[item_name] ~= nil then
            UnlockedZenLevels[ZenLevelItems[item_name]] = true
            PrettyPrint("[Item Parsing] Received and unlocked level: " .. item_name)
            return
        end
        if EffectLevelItems[item_name] ~= nil then
            UnlockedEffectLevels[EffectLevelItems[item_name]] = true
            PrettyPrint("[Item Parsing] Received and unlocked mode: " .. item_name)
            return
        end
        if item_name == "Zone Unlock" and not ZoneUnlocked then
            ZoneUnlocked = true
            PrintToAll("[Item Parsing] You got your Zone!")
            LockZone() -- Should enable it back mid game
        end
        PrettyPrint("[Item Parsing] Received item " ..item_name .." but it's feature is not yet implemented or the item was not recognized. Report it to the developer")
    elseif string.find(item_name, "Trap") ~= nil and not IsFirstConnection then
        QueueTrap(item_name)
        PrettyPrint("[Item Parsing] The trap " .. item_name .. " has been queued.")
    else
        PrettyPrint("[Item Parsing] Received item " .. item_name .. " which was deemed a filler item. If the item was not recognized as an unlock or trap please report it to the developer")
    end
end

---Checks if the given mode is excluded in the multiworld
---@param effect_mode string
---@return boolean
function CheckIfModelIsSkipped(effect_mode)
    for index, value in ipairs(ExcludedModes) do
        if string.find(effect_mode, value) ~= nil then
            return true
        end
        return false
    end
end

---Tells the multiworld to send the given location id
---@param ID integer
function SendLocation(ID)
    if ID == nil or checkedLocations[ID] or ap == nil then return end
    if ap:get_location_name(ID, ap:get_game()) == "Unknown" then PrettyPrint("[Warning] Catched unknown location. ID: " .. tostring(ID)) return end
    PrettyPrint("Attempting to send item " .. ap:get_location_name(ID, ap:get_game()))
    table.insert(LocationsToCheck, ID)
end

---Sends the next location available from the given location ID as a base. Intended for the trick locations
---@param BaseLocationID integer
function SendNext(BaseLocationID)
    PrettyPrint("Sending next location from the given base ID: " .. BaseLocationID)
    if BaseLocationID == nil then
        PrettyPrint("We got a null value for send next!")
        return
    end
    for i = 0, 49, 1 do
        if checkedLocations[BaseLocationID + i] == nil or not checkedLocations[BaseLocationID + i] then
            SendLocation(BaseLocationID + i)
            break
        end
    end
end

function DeathLinkPlayer()
    PrettyPrint("Trying to deathlink player")
    isDeathLink = false
    if DeathLinkType == 0 then
        ---@type ATPPuzzleManager_C
        local Mana = FindFirstOf("TPPuzzleManager_C")
        if Mana ~= nil and Mana:IsValid() then
            Mana:SetGameOver({})
        end
    elseif DeathLinkType == 1 then
        ExecuteWithDelay(100, function ()
            local PManager = FindFirstOf("TPPuzzleManager_C")
            if PManager == nil or not PManager:IsValid() then return end
            for i = 1, 10, 1 do
                PManager:AddGarbageLine({})
            end
        end)
    elseif DeathLinkType == 2 then
        local PManager = FindFirstOf("TPPuzzleManager_C")
        if PManager == nil or not PManager:IsValid() then return end -- I guess to keep it consistent, we won't queue the death link if on menus
        QueuedDeathLink = true
    end
    ExecuteWithDelay(15000, function ()
        isDeathLink = true
    end)
end

function LockZone()
    local PManager = FindFirstOf("TPPuzzleManager_C")
    if PManager == nil or not PManager:IsValid() then return end
    PManager:EnableZenLevel(ZoneUnlocked)
end

function GameGoal()
    LoopAsync(1000, function ()
        PrettyPrint("Attempting to make player goal")
        return ap:StatusUpdate(ap.ClientStatus.GOAL)
    end)
end