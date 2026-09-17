---@meta

---@class UConectionHelper_C : UUserWidget
---@field UberGraphFrame FPointerToUberGraphFrame
---@field ConnectAPButton UButton Button pressed to call OnConnect
---@field ConnectAPText UTextBlock 
---@field PasswordInput UEditableTextBox
---@field PortInput UEditableTextBox
---@field ServerInput UEditableTextBox
---@field SlotInput UEditableTextBox
---@field IsConnected boolean
UConectionHelper_C = {}

-- Call this to let the helper know we are no longer connected, and allow the user to change the input fields
function UConectionHelper_C:OnDisconnect() end
-- When the connect button is pressed, the widget calls to this method. Intended to hook into it as internally the widget just locks the input fields and the button while the lua mod connects
---@param Server FString Will return ap!disconnect when the user wants to disconnect from the current session
---@param Port FString
---@param Slot FString
---@param Password FString
function UConectionHelper_C:OnConnect(Server, Port, Slot, Password) end
-- Call to let the helper know we connected. Makes the button display "Disconnect" and calls OnConnect("ap!disconnect", "", "", "") instead
function UConectionHelper_C:OnConnectionSuccess() end
function UConectionHelper_C:BndEvt__ConectionHelper_Button_0_K2Node_ComponentBoundEvent_0_OnButtonClickedEvent__DelegateSignature() end
---@param EntryPoint int32
function UConectionHelper_C:ExecuteUbergraph_ConectionHelper(EntryPoint) end

