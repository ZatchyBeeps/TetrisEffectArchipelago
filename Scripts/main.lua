print("TE:A is loading")

UEHelpers = require("UEHelpers")

require("utils")
require("archipelago")
local modHelper = nil
local ModVersion = "V0.2.0"

local ZenStoryByAreas = false
local firstRun = true
local Ready = false
local CurrentScore = 0
local AccumulatedScore = 0
local AccumulatedAreaScore = 0
local CurrentStage = 0
local LastStageAreaIndex = -1
local LastPlayedStage = -1
local CurrentDifficulty = 0
local OnEffectMode = false
local ShouldRecheckZone = true
local GameOveredByBlockage = false
local PlayedLevels = {}


function HookFunctions()
    -- Tetris Effect uses a single Level for everything called PersistentLevel, loading others as streamed levels so we don't have to worry about hooking multiple times.
    -- We just need to prevent the hooking when booting of the game as it is another level (StartUp) before going to PersistentLevel
    -- However, going into multiplayer does load another level. I need to add checks to prevent hooking if the player goes into multiplayer (and for when I implement connected mode)

    -- Oasis mode level selection
    RegisterHook(
        "/Game/BluePrints/Menu/Oasis/Widget/Menu_OasisSelectPlayModeVScroll_Widget.Menu_OasisSelectPlayModeVScroll_Widget_C:CreateList",
        function(self)
            OnOasisMenuOpen()
            if ap == nil then PrintToAll("Warning! You haven't connected to archipelago yet! All stages are locked by default, so go back to the main menu and connect to a multiworld") end

            OnEffectMode = true
            local widget = self:get()
            --print(self:type())
            --print(widget:type())

            -- Could be changed to InGameThread, haven't tested it
            ExecuteInGameThread(function()
                local BList = widget.ScrollList.PanelList                                -- The list is already ordered the same way as in the item table
                if BList:IsValid() then
                    BList:ForEach(function(index, elem)
                        if APOasisIsLevelUnlocked(index-1) then
                            elem:get():SetIsEnabled(false)
                            elem:get().IsInitialize = false
                        else
                            PrettyPrint("Skipping unlocked level")
                        end
                    end)
                else
                    PrettyPrint("Not valid")
                end
            end)
        end)

    -- Zen story stage selection
    RegisterHook(
        "/Game/BluePrints/Menu/ZenStory/Actor/ActorMenuZenStoryStageSelect.ActorMenuZenStoryStageSelect_C:InitializeController",
        function(self)
            PrettyPrint("Zen menu has been opened")
            if ap == nil then PrintToAll("Warning! You haven't connected to archipelago yet! All stages are locked by default, so go back to the main menu and connect to a multiworld") end
            CurrentStage = -1
            -- Unlike Oasis, we don't wanna be too fast as the game will be activating the stage actors after selecting a difficulty
            -- 50ms seems to be the sweet spot
            ExecuteWithDelay(50, function()
                ---@type AZenStoryBaseManager_C
                local ZenStoryManager = FindFirstOf("ZenStoryBaseManager_C")
                if not ZenStoryManager:IsValid() then
                    PrettyPrint(
                    "Failed to get manager, unobtained levels cannot be locked. Please report this error (ZenManager was not present)")
                    return
                end
                local AreaList = ZenStoryManager.ZenStoryAreaList
                if not AreaList:IsValid() then
                    PrintToAll(
                    "Failed to get area list. Unobtained levels cannot be locked. Please report this error (AreaList returned not valid)")
                    return
                end
                local LastLevelUnlocked = 0
                local stageLevels = 0
                --print(tostring(thing:GetArrayNum()))
                --for i, elem in pairs(tablething) do
                AreaList:ForEach(function(i, elem)
                    if ZenStoryByAreas then
                        -- Zen unlocked by areas
                        -- This whole thing is untested and I'm pretty sure it doesn't even work. Will work on it later
                        if not APZenIsAreaUnlocked(i) then
                            PrettyPrint("Locking area " .. tostring(i))
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
                ExecuteWithDelay(100, function()
                    ZenStoryManager:SetCursorCurrentPosition(LastLevelUnlocked)
                    ZenStoryManager.FreeCursorStageIndex = LastLevelUnlocked
                    ZenStoryManager:ResetAreaPosition(StageIndexToAreaIndex(LastLevelUnlocked) or 4)
                    ZenStoryManager:UpdateStagePosition(LastLevelUnlocked, false, true, true, true)
                end)
            end)
        end)

    -- Zen story stage end
    -- This is maybe not the best method to hook to for when the stage ends, but it's the only one I could reliably use and it does the job well
    RegisterHook("/Game/BluePrints/Game/Interlude/TPInterludeBG.TPInterludeBG_C:SetupMesh", function(self)
        PrettyPrint("Stage has ended")
        if ap == nil or OnEffectMode then return end
        local ae = {}

        ExecuteInGameThread(function()
            local StageIndex = {}
            local ResIndex

            FindFirstOf("TPStageManager_C"):GetCurrentStageIndex(StageIndex)
            for index, value in pairs(StageIndex) do
                --PrettyPrint(tostring(index) .. " " .. tostring(value))
                ResIndex = value
            end
            AccumulatedScore = GetGameScore() + AccumulatedAreaScore
            table.insert(PlayedLevels, ResIndex)
            LastStageAreaIndex = StageIndexToAreaIndex(ResIndex)
            APClearStage(ResIndex, false)
            --PrettyPrint(tostring(ResIndex))
            if not APZenIsStageUnlocked(ResIndex + 1) then
                GameOveredByBlockage = true

                -- We wait a bit, but not too much!, so it's not an abrupt game over
                ExecuteWithDelay(1500, function()
                    FindFirstOf("TPGamePlayManager_C"):CreateGameResult(true)

                    -- Just to tell the user why they're geting this screen
                    ExecuteWithDelay(75, function()
                        ---@type AActorGameOver_C
                        local gameoveractor = FindFirstOf("ActorGameOver_C")
                        if gameoveractor:IsValid() then
                            gameoveractor.MenuWidget.Continue.Text:SetText(FText("RESTART (NEXT STAGE IS LOCKED BY ARCHIPELAGO)")) -- Aparently most text boxes just have text in uppercase, which is like idk 80% of the game? lol
                        end
                    end)
                end)
            else
                -- Reset the current score counter and set that we are on a diffent stage    
                CurrentScore = 0
                CurrentStage = ResIndex + 1            
                if StageIndexToAreaIndex(CurrentStage) ~= StageIndexToAreaIndex(CurrentStage + 1) then
                    AccumulatedScore = 0
                    PrettyPrint("Next stage does not belong to the next area. Accumulated Score reset")
                end
                
            end
            
            -- Save current game score. Will be used later if the player goes to a different stage of this area or resets it otherwise (or replaying the same level)
            table.insert(PlayedLevels, CurrentStage)
            PrettyPrint("Saving accumulated total score with value: " .. tostring(AccumulatedScore))
            
        end)
    end)


    -- On area ending or oasis mode completed
    RegisterHook("/Game/BluePrints/Menu/Result/Actor/ActorResultScore.ActorResultScore_C:OnShowRank",
    function(self)
        PrettyPrint("Ended Oasis mode")
        ---@type AActorResultScore_C
        ResultActor = self:get()
        ObtainedRank = ResultActor.RankType
        GameMode = ResultActor.GameResultType
        if GameMode == 6 then return end
        APCheckRank(ObtainedRank, GameMode, nil, true)
        if ObtainedRank >= 2 then -- The player must get at least a C rank to clear the mode
            APClearStage(GameMode, true)
        end
    end)

    NotifyOnNewObject("/Game/BluePrints/Game/TPGamePlayerPawn.TPGamePlayerPawn_C", function ()
        PrettyPrint("========================================")
        PrettyPrint("Begin stage")
        LockZone()
        CurrentStage = -1 -- Prevents score stacking if the player retries/tops out
        
    end)

    -- On drop any tetrimino
    RegisterHook("/Game/BluePrints/Game/Puzzle/TPPuzzleManager.TPPuzzleManager_C:CalcLineEraseScore",
        ---This function is called everytime a mino is placed in the board (either by hard or soft drop)
        ---@param self UObject
        ---@param ErasedLineNumber any | integer Amount of lines cleared. 0 if none
        ---@param TSpinRank any | integer Tspin kind if a tspin was done. 0 otherwise
        ---@param Ren any | integer Combo amount
        ---@param B2B any | boolean Was the line cleared a back to back?
        ---@param AllClear any | boolean Was an all clear achieved after this line clear?
        ---@param XLScaleFactor any | integer Unknown. Seems to always be 1
        ---@param Score any | integer Returned value. Total score added from the calculation. Does not include hard/soft drop bonues, so it remains 0 if no lines were cleared
        function(self, ErasedLineNumber, TSpinRank, Ren, B2B, AllClear, XLScaleFactor, Score)
            if OnEffectMode or ap == nil then return end
            if ShouldRecheckZone then
                LockZone()
                ShouldRecheckZone = false
            end
            if CurrentStage == -1 then
                local StageIndex = {}
                FindFirstOf("TPStageManager_C"):GetCurrentStageIndex(StageIndex)
                for _, value in pairs(StageIndex) do
                    CurrentStage = value
                end
                ---@type ATPStageManager_C
                local StageManager = FindFirstOf("TPStageManager_C")
                if StageManager ~= nil then
                    CurrentDifficulty = StageManager.ModeBehavior.Difficulty
                    if CurrentDifficulty == 0 then CurrentDifficulty = 1 end
                end
                PrettyPrint("Loading values from new level and difficulty " .. tostring(CurrentStage) .. ":" .. tostring(CurrentDifficulty))
                
                if IsLevelPlayed(CurrentStage) or LastStageAreaIndex ~= StageIndexToAreaIndex(CurrentStage) then
                    PrettyPrint("Reset to accumulated score. Score was " .. tostring(AccumulatedScore))
                    AccumulatedScore = 0
                    PlayedLevels = {}
                else
                    AccumulatedAreaScore = AccumulatedScore
                    AccumulatedScore = 0
                    PrettyPrint("Adding score of last stage since we are on the same area. Current total score is " .. tostring(AccumulatedAreaScore))
                    PrintToGame("Previous stage score is being considered for area ranks. Your current total area score is " .. tostring(AccumulatedAreaScore))
                end
                LockZone()
            end
            -- To-do: calculate per-stage rank requirements. The score here does not return with hard/soft bonus so idk maybe use TPPuzzleManager_C:AddScore(Add) instead?
            -- Also check what are we on when doing this
            CurrentScore = GetGameScore() - AccumulatedScore
            APCheckRank(CurrentScore, CurrentStage, CurrentDifficulty)
            if CurrentStage ~= 26 then APSendAreaRankChecks(GetGameScore() + AccumulatedAreaScore, StageIndexToAreaIndex(CurrentStage), CurrentDifficulty) end
            APDoTrickChecks(ErasedLineNumber:get(), TSpinRank:get(), Ren:get(), B2B:get(), AllClear:get())
            PerformTrap()
        end)

    
    -- On zone ended
    RegisterHook("/Game/BluePrints/Game/Puzzle/TPPuzzleManager.TPPuzzleManager_C:FinishZenMode",
        function(self, ErasedLineNum)
            APSendZoneChecks(ErasedLineNum:get())
        end)

    
    -- On main menu open
    -- Starts the ConnectionHelper widget
    RegisterHook("/Game/BluePrints/Menu/MenuTop/Actor/Actor_Menu_Top.Actor_Menu_Top_C:InitializedWidget", function(self)
        PrettyPrint("Triggered game start")
        OnEffectMode = false

        ExecuteInGameThread(function()
            modHelper = FindFirstOf("ModActor_C")
            if modHelper:IsValid() then
                modHelper:CreateAPMenu()
                modHelper:SetModVersion(ModVersion)
            end
        end)
        --ExecuteWithDelay(5000, function ()        -- To-do: Remove the button from the array UserWidget.ButtonBases
        --    self:get().UserWidget.Multiplay.LocationBoxs = nil
        --end)
    end)


    -- On game over
    RegisterHook("/Game/BluePrints/Game/TPGamePlayManager.TPGamePlayManager_C:CreateGameResult", function (self, GameOver)
        if GameOver:get() and not GameOveredByBlockage then APSendDeathLink() ShouldRecheckZone = true
        elseif GameOveredByBlockage then GameOveredByBlockage = false end
    end)


    RegisterHook("/Game/BluePrints/Menu/Option/Actor/ActorMenuOptionGame.ActorMenuOptionGame_C:InitializeWidget",
    function (self)
        ---@type UMenu_OptionGameWidget_C
        local opt_widget = self:get().UserWidget
        opt_widget.IndexRowMax = 16
    end)

    -- Because the blueprint mod is loaded later, we wait for it to get loaded or UE4SS will not find it. Since we are on a single consistent Streamed Level, we don't have to worry about hooking things multiple times
    ExecuteWithDelay(2000, function()
        RegisterHook("/Game/Mods/TetrisEffectArchipelago/ConectionHelper.ConectionHelper_C:OnConnect",
            function(self, server, port, slot, password)
                if server:get():ToString() == "" then return end
                connectToAp(server:get():ToString() .. ":" .. port:get():ToString(), slot:get():ToString(),
                    password:get():ToString())
            end)

        RegisterHook("/Game/Mods/TetrisEffectArchipelago/ConectionHelper.ConectionHelper_C:OnDisconnect",
            function(self)
                disconnect()
            end)
    end)

    Ready = true
end

-- Used for general testing
RegisterKeyBind(Key.F7, function()
	debug_GiveAll()
    ---@type ATPPuzzleManager_C
    local PManager = FindFirstOf("TPPuzzleManager_C")
    if PManager == nil or not PManager:IsValid() then return end
    PManager:ZenLevelUp()
end)


-- For later funnies
-- TPPuzzleManager_C:AddScore(Add)
-- TPPuzzleManager_C:InvertFieldH()


RegisterKeyBind(Key.F5, function ()
    ---@type AModActor_C
    modHelper = FindFirstOf("ModActor_C")
    if modHelper ~= nil and modHelper:IsValid() then
        modHelper.StatusBoxText:ToggleHide()
    end
end)


RegisterKeyBind(Key.F8, function() -- Debug
    HookFunctions()
end)

RegisterKeyBind(Key.F9, function() -- Debug
    ExecuteInGameThread(function()
        ---@type AModActor_C
        modHelper = FindFirstOf("ModActor_C")
        if modHelper ~= nil and modHelper:IsValid() then
            modHelper.ConnectionHelper:OnDisconnect()
        end
        disconnect()
    end)
end)


function OnOasisMenuOpen()
    PrettyPrint("Oasis menu opened")
end

function MainMenuStart()
    PrettyPrint("Main menu has been detected")
end

function OnZenMenuOpen()
    PrettyPrint("Zen menu has been opened")
end

function IsLevelPlayed(stage)
    for index, value in ipairs(PlayedLevels) do
        if stage == value then return true end
    end
    return false
end

RegisterInitGameStatePostHook(function(Context)
    if not firstRun and not Ready then
        HookFunctions()
        -- Probably gonna get rid of this, as finding the actor itself is more reliable (trying to call modHelper has a low chance to cause crashes for some reason)
        ExecuteWithDelay(1000, function()
            ExecuteInGameThread(function()
                modHelper = FindObject(nil, "ModActor_C", EObjectFlags.RF_NoFlags, EObjectFlags.RF_NoFlags)
                if modHelper:IsValid() then
                    PrettyPrint("Mod helper hooked and loaded")
                else
                    PrettyPrint("Error getting mod helper! Some functions won't work")
                end
            end)
        end)
    else
        firstRun = false
    end
end)

PrettyPrint("TE:A loaded and ready!")

--RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)

--RegisterHook("/Game/main/mainGamemode.mainGamemode_C:Load Primitives", function(self, in_canLoad, in_isSubData, in_loadingSubLevel)
--HookFunctions()
--end)
--end)
