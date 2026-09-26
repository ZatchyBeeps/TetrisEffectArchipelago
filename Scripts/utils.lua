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
