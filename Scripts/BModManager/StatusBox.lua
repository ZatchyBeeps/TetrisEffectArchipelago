---@meta

---@class UStatusBox_C : UUserWidget
---@field APTextBox UTextBlock
UStatusBox_C = {}

-- Unused. Would fade the text box to a lower opacity so it's less obtrusive
function UStatusBox_C:FadeOut() end
-- Self explanatory
function UStatusBox_C:ClearBox() end
-- Adds the given message to the status box
---@param IncomingMessage FString Message to display
function UStatusBox_C:PrintMessage(IncomingMessage) end


