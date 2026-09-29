ZenLevels = {
    [ 0] = 'The Deep',
    [ 1] = 'Pharaoh\'s Code',
    [ 2] = 'Karma Wheel',
    [ 3] = 'Jellyfish Chorus',
    [ 4] = 'Da Vinci',
    [ 5] = 'Prayer Circles',
    [ 6] = 'Ritual Passion',
    [ 7] = 'Deserted',
    [ 8] = 'Dolphin Surf',
    [ 9] = 'Downtown Jazz',
    [10] = 'Spirit Canyon',
    [11] = 'Jewel Veil',
    [12] = 'Forest Dawn',
    [13] = 'Kaleidoscope',
    [14] = 'Turtle Dreams',
    [15] = 'Celebration',
    [16] = 'Sunset Breeze',
    [17] = 'Aurora Peak',
    [18] = 'Zen Blossoms',
    [19] = 'Ying & Yang',
    [20] = 'Hula Soul',
    [21] = 'Starfall',
    [22] = 'Balloon High',
    [23] = 'Mermaid Cove',
    [24] = 'Orbit',
    [25] = 'Stratosphere',
    [26] = 'Metamorphosis'
}

EffectLevels = {
    [ 0] = 'Marathon',
    [ 1] = 'Zone Marathon',
    [ 2] = 'Ultra',
    [ 3] = 'Sprint',
    [ 4] = 'Master',
    [ 5] = 'Classic Score Attack',
    [ 6] = 'Chill Marathon',
    [ 7] = 'Quick Play',
    [ 8] = 'Playlist (Sea)',
    [ 9] = 'Playlist (Wind)',
    [10] = 'Playlist (World)',
    [11] = 'All Clear',
    [12] = 'Combo',
    [13] = 'Target',
    [14] = 'Countdown',
    [15] = 'Purity',
    [16] = 'Mystery'
}


---@param size integer
---@param at_start? integer
---@return {[integer]: boolean}
function MakeSet(size, at_start)
    local set = {}
    start_index = 0
    if at_start ~= nil then start_index = at_start end
    for i = start_index, size, 1 do
        set[i] = false
    end
    return set
end

function PrintToGame(message)
    modHelper = FindFirstOf("ModActor_C")
    if modHelper:IsValid() then
        modHelper.StatusBoxText:PrintMessage(message)
    end
end

function PrintToAll(message)
    if message == nil or message == "" then return end
    modHelper = FindFirstOf("ModActor_C")
    if modHelper:IsValid() then
        modHelper.StatusBoxText:PrintMessage(message)
    end
    print(message)
end

function Helper_OnDisconnect()
    ExecuteInGameThread(function()
        modHelper = FindFirstOf("ModActor_C")
        if modHelper:IsValid() then
            modHelper.ConnectionHelper:OnDisconnect()
        end
    end)
end

function Helper_OnConnected()
    ExecuteInGameThread(function()
        modHelper = FindFirstOf("ModActor_C")
        if modHelper:IsValid() then
            modHelper.ConnectionHelper:OnConnectionSuccess()
        end
    end)
end

function DisableBasicButton(button)
    modHelper = FindFirstOf("ModActor_C")
    if modHelper:IsValid() then
        modHelper:DisableButton(button)
    end
end


function GetGameScore()

    ---@type ATPPuzzleManager_C
    manager = FindFirstOf("TPPuzzleManager_C")
    print(manager:type())
    if manager:IsValid() then
        print("Valid")
        result = {}
        manager:GetScore(false, result)
        for _, value in pairs(result) do
            print(tostring(value))
            return value
        end
    end
end

function QueueTrap(trap_name)
    if trap_name == "Lines Trap" then
        --Implement lines trap
    elseif trap_name == "Giant Mino Trap" then

    elseif trap_name == "Broken Mino Trap" then
    elseif trap_name == "Zone Trap" then
    elseif trap_name == "Ghost Piece Trap" then
    elseif trap_name == "Hold Trap" then
    elseif trap_name == "Queue Trap" then
    elseif trap_name == "Speed Trap" then

    end
    print("Received a trap but it's not implemented yet")
end

TrapList = {
    ["Lines trap"] = function()

    end
}

function PerformTrap()

end

