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
	modHelper = FindFirstOf("ModActor_C")
    if modHelper:IsValid() then
		modHelper.ConnectionHelper:OnDisconnect()
	end
end

function Helper_OnConnected()
	modHelper = FindFirstOf("ModActor_C")
    if modHelper:IsValid() then
		modHelper.ConnectionHelper:OnConnectionSuccess()
	end
end

function DisableBasicButton(button)
	modHelper = FindFirstOf("ModActor_C")
    if modHelper:IsValid() then
		modHelper:DisableButton(button)
	end
end