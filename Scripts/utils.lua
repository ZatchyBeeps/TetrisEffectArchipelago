function MakeSet(list)
    local set = {}
    for _, item in ipairs(list) do set[item] = true end
    return set
end

function PrintToGame(message)
    modHelper = FindFirstOf("ModActor_C")
    if modHelper:IsValid() then
        modHelper.StatusBoxText:PrintMessage(message)
    end
end

function PrintToAll(message)
    modHelper = FindFirstOf("ModActor_C")
    if modHelper:IsValid() then
        modHelper.StatusBoxText:PrintMessage(message)
    end
    print(message)
end

function Helper_OnDisconnect()
    modHelper.ConnectionHelper:OnDisconnect()
end

function Helper_OnConnected()
    modHelper.ConnectionHelper:OnConnectionSuccess()
end