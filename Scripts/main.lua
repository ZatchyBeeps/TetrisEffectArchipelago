print("[MyLuaMod] loaded and ready")

UEHelpers = require("UEHelpers")

require("utils")
require("archipelago")
local modHelper = nil

local ZenStoryByAreas = false
local firstRun = true


function HookFunctions()
    -- Oasis mode level selection
    RegisterHook(
        "/Game/BluePrints/Menu/Oasis/Widget/Menu_OasisSelectPlayModeVScroll_Widget.Menu_OasisSelectPlayModeVScroll_Widget_C:CreateList",
        function(self)
            OnOasisMenuOpen()
            local widget = self:get()
            --print(self:type())
            --print(widget:type())

            ExecuteWithDelay(100, function()
                local BList = widget.ScrollList.PanelList
                if BList:IsValid() then
                    BList:ForEach(function(index, elem)
                        if APCheckOasisLevelUnlocked(index) then
                            elem:get():SetIsEnabled(false)
                            elem:get().IsInitialize = false
                        else
                            print("Skipping unlocked level")
                        end
                    end)
                else
                    print("Not valid")
                end
            end)
        end)

    -- Zen story stage selection
    RegisterHook(
        "/Game/BluePrints/Menu/ZenStory/Actor/ActorMenuZenStoryStageSelect.ActorMenuZenStoryStageSelect_C:InitializeController",
        function(self)
            ExecuteWithDelay(50, function()
                ---@type AZenStoryBaseManager_C
                local ZenStoryManager = FindFirstOf("ZenStoryBaseManager_C")
                if not ZenStoryManager:IsValid() then print("Failed to get manager") end
                local thing = ZenStoryManager.ZenStoryAreaList
                if not thing:IsValid() then print("Failed to get list") end
                local ActorList = ZenStoryManager.ZenStoryAreaList[1]
                    .Stages_7_2120313848EA05A0C5D8708544FFADBA -- Do not use ZenStoryAreaList[0], seems to be data garbage
                local LastLevelUnlocked = 0
                local yeah = {}
                local tablething = { thing[1], thing[2], thing[3], thing[4], thing[5], thing[6], thing[7] }
                local stageLevels = 0
                print(tostring(thing:GetArrayNum()))
                --for i, elem in pairs(tablething) do
                thing:ForEach(function(i, elem)
                    if ZenStoryByAreas then
                        -- Zen unlocked by areas
                        if not APZenIsAreaUnlocked(i) then
                            print("Locking area " .. tostring(i))
                            elem:set(nil)
                        else
                            if i == 2 then
                                LastLevelUnlocked = 4
                            elseif i == 3 then
                                LastLevelUnlocked = 8
                            elseif i == 4 then
                                LastLevelUnlocked = 12
                            elseif i == 5 then
                                LastLevelUnlocked = 17
                            elseif i == 6 then
                                LastLevelUnlocked = 22
                            elseif i == 7 then
                                LastLevelUnlocked = 27
                            end
                        end
                    else
                        -- Zen unlocked by individual stages
                        thing[i].Stages_7_2120313848EA05A0C5D8708544FFADBA:ForEach(function(index, actor)
                            print(tostring(stageLevels))
                            if not APZenIsStageUnlocked(stageLevels) then
                                actor:get():SetActive(false, 1)
                                actor:get().bActorEnableCollision = false
                            else
                                LastLevelUnlocked = stageLevels
                            end
                            stageLevels = stageLevels + 1
                        end)
                    end
                end)
                ExecuteWithDelay(50, function()
                    ZenStoryManager:SetCursorCurrentPosition(LastLevelUnlocked)
                    ZenStoryManager.FreeCursorStageIndex = LastLevelUnlocked
                    ZenStoryManager:ResetAreaPosition(2)
                end)
            end)
        end)

    -- Zen story stage end
    RegisterHook("/Game/BluePrints/Game/Interlude/TPInterludeBG.TPInterludeBG_C:SetupMesh", function(self)
        print("Stage has ended")
        local ae = {}


        ExecuteInGameThread(function()
            -- Handle level clear location send here

            local StageIndex = {}
            local ResIndex

            FindFirstOf("TPStageManager_C"):GetCurrentStageIndex(StageIndex)
            for index, value in pairs(StageIndex) do
                print(tostring(index) .. " " .. tostring(value))
                ResIndex = value
            end
            print(tostring(ResIndex))
            if not APZenIsStageUnlocked(ResIndex + 1) then
                ExecuteWithDelay(1000, function()
                    FindFirstOf("TPGamePlayManager_C"):CreateGameResult(true)

                    ExecuteWithDelay(50, function()
                        ---@type AActorGameOver_C
                        local gameoveractor = FindFirstOf("ActorGameOver_C")
                        if gameoveractor:IsValid() then
                            gameoveractor.MenuWidget.Continue.Text:SetText(FText(
                                "RESTART (NEXT STAGE IS LOCKED BY ARCHIPELAGO)"))
                        end
                    end)
                end)
            end
        end)
    end)

    RegisterHook("/Game/BluePrints/Game/Puzzle/TPPuzzleManager.TPPuzzleManager_C:CalcLineEraseScore",
        function(self, Score)

        end)


    RegisterHook("/Game/BluePrints/Menu/MenuTop/Actor/Actor_Menu_Top.Actor_Menu_Top_C:InitializedWidget", function(self)
        print("Triggered game start")
        ExecuteInGameThread(function()
            modHelper = FindFirstOf("ModActor_C")
            print(modHelper:type())
            if modHelper:IsValid() then
                modHelper:CreateAPMenu()
            end
        end)
    end)

    ExecuteWithDelay(2000, function()
        RegisterHook("/Game/Mods/TetrisEffectArchipelago/ConectionHelper.ConectionHelper_C:OnConnect",
            function(self, server, port, slot, password)
                if server():get():ToString() == "" then return end
                connectToAp(server:get():ToString() .. ":" .. port:get():ToString(), slot:get():ToString(), password:get():ToString())
            end)

        RegisterHook("/Game/Mods/TetrisEffectArchipelago/ConectionHelper.ConectionHelper_C:OnDisconnect",
            function(self)
                disconnect()
            end)
    end)
end

RegisterKeyBind(Key.F7, function()
    ExecuteInGameThread(function()
        modHelper = FindFirstOf("ModActor_C")
        if modHelper:IsValid() then
            print("Mod helper hooked and loaded")
            print(modHelper:type())
            modHelper:CreateAPMenu()
        else
            print("Error getting mod helper! Some functions won't work")
        end
    end)
end)

RegisterKeyBind(Key.F8, function()
    HookFunctions()
end)

RegisterKeyBind(Key.F9, function()
    disconnect()
end)


function OnOasisMenuOpen()
    print("Oasis menu opened")
end

function MainMenuStart()
    print("Main menu has been detected")
end

function OnZenMenuOpen()
    print("Zen menu has been opened")
end

RegisterInitGameStatePostHook(function(Context)
    if not firstRun then
        HookFunctions()
        ExecuteWithDelay(1000, function()
            ExecuteInGameThread(function()
                modHelper = FindObject(nil, "ModActor_C", EObjectFlags.RF_NoFlags, EObjectFlags.RF_NoFlags)
                if modHelper:IsValid() then
                    print("Mod helper hooked and loaded")
                else
                    print("Error getting mod helper! Some functions won't work")
                end
            end)
        end)
    else
        firstRun = false
    end
end)



--RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)

--RegisterHook("/Game/main/mainGamemode.mainGamemode_C:Load Primitives", function(self, in_canLoad, in_isSubData, in_loadingSubLevel)
--HookFunctions()
--end)
--end)
