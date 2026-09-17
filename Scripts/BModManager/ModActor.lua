-- Stuff here comes from the mod helper blueprint
-- A lot of the variables are unused as I used them for debugging purposes
-- This file will be updated if I change the blueprint (or you can generate lua types, which will also pull files like these)




---@meta

---@class AModActor_C : AActor
---@field UberGraphFrame FPointerToUberGraphFrame
---@field DefaultSceneRoot USceneComponent
---@field TestTextBox UWBP_Test_C "Debugging User Widget. Unused"
---@field ['Out Actors'] TArray<AActor> 
---@field UnlockedLevels TArray<int32> "Unused"
---@field ['Found Widgets'] TArray<UUserWidget>
---@field WIndex int32
---@field TempINdex int32
---@field Children_0 TArray<USceneComponent>
---@field A AActorMenuOasisSelectPlayModeVScroll_C
---@field StreamLevelManager ATPStreamLevelLoader_C "The stream level manager contains info to track which level is loaded right now. Used to keep track of when to hide the connection helper"
---@field NewVar_1 TArray<UActorComponent>
---@field UnlockedOasisPlayModes TArray<int32> "Unused"
---@field OasisMenuManager AActorMenuOasisSelectPlayModeVScroll_C
---@field NewVar_0 UGameplayTasksComponent
---@field Oasis_ActualLevelList TArray<int32> "Unused"
---@field Oasis_LookAtIndex int32
---@field StatusBoxText UStatusBox_C "User widget that contains the text box for archipelago logs"
---@field ConnectionHelper UConectionHelper_C "User widget for connecting to archipelago. We hook to it for connection, the widget manages itself for when to hide and when to appear"
AModActor_C = {}

-- Hides the ConnectionHelper when called
function AModActor_C:DisappearAPMenu() end
-- This function clears the LocationBoxs map property from the given button. UE4SS doesn't support MapProperty's, so this exists to help
---@param Button UMenuButtonWidgetBase_C MenuButtonWidgetBase to remove it's LocationBoxs
function AModActor_C:RemoveLoactionBoxs(Button) end
-- Shows the ConnectionHelper when called. Creates it if it doesn't exist
function AModActor_C:CreateAPMenu() end

-- Debug
function AModActor_C:ModifyOasisList() end
-- Debug
function AModActor_C:PerformTestAction() end
-- Debug
AModActor_C['Disable Widget'] = function() end
-- Debug
---@param Add boolean
function AModActor_C:FindWidget(Add) end
-- Debug
function AModActor_C:GetWidgets() end
-- Debug
function AModActor_C:DisableSelected() end
-- Debug

function AModActor_C:TestExecute() end
function AModActor_C:ReceiveBeginPlay() end
---@param DeltaSeconds float
function AModActor_C:ReceiveTick(DeltaSeconds) end
function AModActor_C:PreBeginPlay() end
function AModActor_C:PostBeginPlay() end
---@param Message FString
function AModActor_C:PrintToModLoader(Message) end
---@param EntryPoint int32
function AModActor_C:ExecuteUbergraph_ModActor(EntryPoint) end