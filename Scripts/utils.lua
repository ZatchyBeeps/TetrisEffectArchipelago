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
    if manager:IsValid() then
        print("Valid")
        local result = {}
        manager:GetScore(false, result)
        for _, value in pairs(result) do
            --print(tostring(value))
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

-- Use to represent and get a string with the obtained rank like an EScoreRankType enumerator. Yes, B rank is at the end of the enum for some reason
ScoreRankType = {
    [0] = "E",
    [1] = "D",
    [2] = "C",
    [3] = "B",
    [4] = "A",
    [5] = "S",
    [6] = "SS"
}

function GetObtainedRanks(ScoreRankTypeIndex)
    local ResultRanks = {}
    for index, rank in pairs(ScoreRankType) do
        table.insert(ResultRanks, rank)
        if index >= ScoreRankTypeIndex then return ResultRanks end
    end
    return ResultRanks
end

-- Use to represent and identify the oasis mode played like an EScoreRankType enumerator. Values are
GameResultType = {
    --[0] = GameOver
    [2] = "Sprint",
    [1] = "Marathon",
    [3] = "Ultra",
    [4] = "Victory", --ZenStoryAllClear
    [5] = "", --OasisClear . Idk what this is
    [6] = "Area Clear", -- ZenStoryAreaClear . The name says it
    [7] = "Mood Story", --Unknown
    [8] = "Mood Synthe", --Unknown
    [9] = "Countdown",
    [10] = "Combo",
    [11] = "All Clear",
    [13] = "Adventorous", -- Mystery
    [18] = "Pause Mode", --Unknown
    [12] = "Target",
    [14] = "Purify",
    [15] = "Master",
    [16] = "Relax Marathon",
    [17] = "Relax Playlist", --This seems to be all playlists and quick play
    [19] = "Zone Marathon",
    [20] = "Classic Score Attack"
}

GameResultToModeID =
{
    [1] = 0,
    [2] = 3,
    [3] = 2,
    [4] = -1,
    [5] = -1,
    [6] = -1,
    [7] = -1,
    [8] = -1,
    [9] = 14,
    [10] = 12,
    [11] = 11,
    [13] = 16,
    [18] = -1,
    [12] = 13,
    [14] = 15,
    [15] = 4,
    [16] = 6,
    [17] = 7, --This seems to be all playlists and quick play
    [19] = 1,
    [20] = 5
}
