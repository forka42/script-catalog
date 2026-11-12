local GPEService = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if RunService:IsServer() then
	return error("GPEService is a client-only module.")
end

GPEService.KeysPressed = {}

UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
	if gameProcessedEvent == true then
		return
	end
	if not table.find(GPEService.KeysPressed, inputObject.KeyCode) then
		table.insert(GPEService.KeysPressed, inputObject.KeyCode)
	end
end)

UserInputService.InputEnded:Connect(function(inputObject)
	for index,value in pairs(GPEService.KeysPressed) do
		if value == inputObject.KeyCode then
			table.remove(GPEService.KeysPressed, table.find(GPEService.KeysPressed, value))
		end
	end
end)

function GPEService:IsProcessedKeyDown(KeyCode)
	return table.find(GPEService.KeysPressed, KeyCode) ~= nil
end

return GPEService