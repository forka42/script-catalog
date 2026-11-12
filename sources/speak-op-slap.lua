--[=[
    written by forka42
    ---
    https://github.com/forka42
	https://www.roblox.com/games/5551771360/Speak
]=]

local ContextActionService = game:GetService('ContextActionService')

ContextActionService.LocalToolEquipped:Connect(function(toolEquipped)
	if toolEquipped.Name == 'DarkBlueGlove' then
		local power, speed, flight = toolEquipped:FIndFirstChild('Power'), toolEquipped:FindFirstChild('Speed'), toolEquipped:FindFirstChild('Flight')
		if power then power.Value = math.huge end
		if speed then speed.Value = 0 end
		if flight then flight.Value = 0 end
	end
end)