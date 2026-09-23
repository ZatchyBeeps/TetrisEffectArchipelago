print("TEA loaded")

UEHelpers = require("UEHelpers")

require("utils")
require("archipelago")
local modHelper = nil

local ZenStoryByAreas = false
local firstRun = true
local CurrentScore = 0
local AccumulatedScore = 0
local CurrentStage = 0


function HookFunctions()
    -- Tetris Effect uses a single Level for everything called PersistentLevel, loading others as streamed levels so we don't have to worry about hooking multiple times.
    -- We just need to prevent the hooking when booting of the game as it is another level (StartUp) before going to PersistentLevel
    -- However, going into multiplayer does load another level. I need to add checks to prevent hooking if the player goes into multiplayer (and for when I implement connected mode) 

    -- Oasis mode level selection
    RegisterHook(
        "/Game/BluePrints/Menu/Oasis/Widget/Menu_OasisSelectPlayModeVScroll_Widget.Menu_OasisSelectPlayModeVScroll_Widget_C:CreateList",
        function(self)
            OnOasisMenuOpen()
            local widget = self:get()
            --print(self:type())
            --print(widget:type())
            
            -- Could be changed to InGameThread, haven't tested it
            ExecuteWithDelay(100, function()
                local BList = widget.ScrollList.PanelList -- The list is already ordered the same way as in the item table
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
            -- Unlike Oasis, we don't wanna be too fast as the game will be activating the stage actors after selecting a difficulty
            -- 50ms seems to be the sweet spot
            ExecuteWithDelay(50, function()
                ---@type AZenStoryBaseManager_C
                local ZenStoryManager = FindFirstOf("ZenStoryBaseManager_C")
                if not ZenStoryManager:IsValid() then print("Failed to get manager, unobtained levels cannot be locked. Please report this error (ZenManager was not present)") return end
                local AreaList = ZenStoryManager.ZenStoryAreaList
                if not AreaList:IsValid() then PrintToAll("Failed to get area list. Unobtained levels cannot be locked. Please report this error (AreaList returned not valid)") return end
                local LastLevelUnlocked = 0
                local stageLevels = 0
                --print(tostring(thing:GetArrayNum()))
                --for i, elem in pairs(tablething) do
                AreaList:ForEach(function(i, elem)
                    if ZenStoryByAreas then
                        -- Zen unlocked by areas
                        -- This whole thing is untested and I'm pretty sure it doesn't even work. Will work on it later
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
                        AreaList[i].Stages_7_2120313848EA05A0C5D8708544FFADBA:ForEach(function(index, actor)
                            --print(tostring(stageLevels))
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
                -- Somewhat prevents weird behaviours with the cursor thing being off screen breaking the stage selection until you'd went back to the difficulty select
                ExecuteWithDelay(50, function()
                    ZenStoryManager:SetCursorCurrentPosition(LastLevelUnlocked)
                    ZenStoryManager.FreeCursorStageIndex = LastLevelUnlocked
                    ZenStoryManager:ResetAreaPosition(2)
                end)
            end)
        end)

    -- Zen story stage end
    -- This is maybe not the best method to hook to for when the stage ends, but it's the only one I could reliably use and it does the job well
    RegisterHook("/Game/BluePrints/Game/Interlude/TPInterludeBG.TPInterludeBG_C:SetupMesh", function(self)
        --print("Stage has ended")
        local ae = {}


        ExecuteInGameThread(function()
            -- Handle level clear location send here


            -- The following prevents the player from continuing if the next stage is not unlocked.
            -- To-do: prevent this from running if we are on effect mode (specifically the Playlist mode which uses the stage chenging tube thing, which is what this is hooked to)
            local StageIndex = {}
            local ResIndex

            FindFirstOf("TPStageManager_C"):GetCurrentStageIndex(StageIndex)
            for index, value in pairs(StageIndex) do -- Idk why StageIndex[0] doesn't work
                print(tostring(index) .. " " .. tostring(value))
                ResIndex = value
            end
            --print(tostring(ResIndex))
            if not APZenIsStageUnlocked(ResIndex + 1) then
                -- We wait a bit, but not too much!, so it's not an abrupt game over
                ExecuteWithDelay(1500, function()
                    FindFirstOf("TPGamePlayManager_C"):CreateGameResult(true)

                    -- Just to tell the user why they're geting this screen
                    ExecuteWithDelay(50, function()
                        ---@type AActorGameOver_C
                        local gameoveractor = FindFirstOf("ActorGameOver_C")
                        if gameoveractor:IsValid() then
                            gameoveractor.MenuWidget.Continue.Text:SetText(FText(
                                "RESTART (NEXT STAGE IS LOCKED BY ARCHIPELAGO)")) -- Aparently most text boxes just have text in uppercase, which is like idk 80% of the game? lol
                        end
                    end)
                end)
            else
                AccumulatedScore = CurrentScore
                CurrentScore = 0
                CurrentStage = ResIndex + 1
            end
        end)
    end)

    -- This gets called almost every time score gets added, despite it's name. Returns current total score which includes previous stages, so it need to be substracted for rank calc
    RegisterHook("/Game/BluePrints/Game/Puzzle/TPPuzzleManager.TPPuzzleManager_C:CalcLineEraseScore",
        function(self, Score)
            -- To-do: calculate per-stage rank requirements
            -- Also check what are we on when doing this
            CurrentScore = Score - AccumulatedScore
            -- APCheckRank(CurrentScore, CurrentStage)
        end)


    -- I once had a hook for the results screen which would have been helpful to get the area score and send checks but either:
    -- A) I call the result manager to calculate the rank and get it on the hook above, to send checks mid game; or,
    -- B) I find that method again and make a hook for it
    -- Option a is best tho since the player will not get to the result manager unless it's the last stage of the area, apart of the game over preventing it if they don't have the first stage of the next area

    
    --TPPuzzleManager_C:SpawnTetrimino


    --TPPuzzleManager_C:CheckB2B


    -- Starts the ConnectionHelper widget
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

    -- Because the blueprint mod is loaded later, we wait for it to get loaded or UE4SS will not find it. Since we are on a single consistent Streamed Level, we don't have to worry about hooking things multiple times
    ExecuteWithDelay(2000, function()
        RegisterHook("/Game/Mods/TetrisEffectArchipelago/ConectionHelper.ConectionHelper_C:OnConnect",
            function(self, server, port, slot, password)
                if server:get():ToString() == "" then return end
                connectToAp(server:get():ToString() .. ":" .. port:get():ToString(), slot:get():ToString(), password:get():ToString())
            end)

        RegisterHook("/Game/Mods/TetrisEffectArchipelago/ConectionHelper.ConectionHelper_C:OnDisconnect",
            function(self)
                disconnect()
            end)
    end)
end

-- Used for general testing
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


-- For later funnies
-- TPPuzzleManager_C:SetBrokenMinoEnable(Enable, MixingRate)
-- TPPuzzleManager_C:ForbidHold(Yes)
-- TPPuzzleManager_C:AddScore(Add)
-- TPPuzzleManager_C:InvertFieldH()
-- TPPuzzleManager_C:AddGarbageLine(EmptyGridX)
-- TPPuzzleManager_C:TriggerZenMode()



RegisterKeyBind(Key.F8, function() -- Debug
    HookFunctions()
end)

RegisterKeyBind(Key.F9, function() -- Debug
    ExecuteInGameThread(function()
        modHelper = FindFirstOf("ModActor_C")
        modHelper.ConnectionHelper:OnDisconnect()
    end)
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
        -- Probably gonna get rid of this, as finding the actor itself is more reliable (trying to call modHelper has a low chance to cause crashes for some reason)
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
