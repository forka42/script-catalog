--[=[
    written by forka42
    ---
    https://github.com/forka42
	universal(ish)
]=]

math.randomseed(tick())

local fenv = getfenv()
if type(fenv.getgenv) ~= 'function' then
	return
end
local genv = fenv.getgenv()
local setclipboard = fenv.setclipboard

if type(genv) == 'table' then
	local Players = game:GetService('Players')
	local LocalPlayer = Players.LocalPlayer
	local InternalSettings = { 
		UseVariablesAlways = false, -- coding preference for serialization xd
		Development = false,
		LoadUI = true,
	}
	local httpget = fenv.httpget

	local Splix
	if InternalSettings.LoadUI then
		if InternalSettings.Development then
			Splix = require(script:WaitForChild("Splix")); genv.Splix = Splix
		else
			local http_success, http_response = pcall(httpget, 'https://raw.githubusercontent.com/matas3535/SplixPrivateDrawingLibrary/main/Library.lua')
			if http_success == true and type(http_response) == 'string' then
				local callback = select(2, pcall(loadstring, http_response))
				if type(callback) == 'function' then
					Splix = callback()
				end
			end
		end
	end

	local hasclipboard = type(fenv.setclipboard) == 'function'

	pcall(function() genv.AC6F.GlitchConnection:Disconnect() end)
	pcall(function() genv.AC6F.HackConnection:Disconnect() end)

	local AC6F = {}
	genv.AC6F = AC6F

	local find = table.find

	local function serialize(x, tab)
		if type(tab) ~= 'number' then
			tab = 1
		end
		local txt = '{'
		local counter = 0
		for i, v in pairs(x) do
			txt = txt .. '\n' .. string.rep('\t', tab)
			local i_type = typeof(i)
			local v_type = typeof(v)
			if i_type == 'string' then
				if i == '__index' then
					continue
				end
				txt = txt .. '[\"' .. tostring(i) .. '\"] = '
			end
			if v_type == 'table' and v ~= x then
				tab = tab + 1
				txt = txt .. serialize(v, tab)
				tab = tab - 1
			elseif find({'number', 'EnumItem', 'Enum'}, v_type) then
				txt = txt .. tostring(v)
			elseif v_type == 'BrickColor' then
				txt = txt .. 'BrickColor.new(\"' .. tostring(v) .. '\")'
			elseif v_type == 'Vector3' then
				local def = 'Vector3.new(' .. tostring(v.X) .. ', ' .. tostring(v.Y) .. ', ' .. tostring(v.Z) .. ')'
				if v.X == v.Y then
					if v.Y == v.Z then
						if v.X == 0 then
							txt = txt .. 'Vector3.zero'
						elseif v.X == 1 then
							txt = txt .. 'Vector3.one'
						elseif InternalSettings.UseVariablesAlways then
							txt = txt .. 'Vector3.one * ' .. tostring(v.X)
						end
					else -- some may not have 'continue'
						txt = txt .. def
					end
				else -- which is why i did this
					txt = txt .. def
				end
			elseif v_type == 'Vector2' then
				local def = 'Vector2.new(' .. tostring(v.X) .. ', ' .. tostring(v.Y) .. ')'
				if v.X == v.Y then
					if v.X == 0 then
						txt = txt .. 'Vector3.zero'
					elseif v.X == 1 then
						txt = txt .. 'Vector3.one'
					elseif InternalSettings.UseVariablesAlways then
						txt = txt .. 'Vector3.one * ' .. tostring(v.X)
					end
				else -- which is why i did this
					txt = txt .. def
				end 
			elseif v_type == 'boolean' then
				local bool = 'false'
				if v == true then
					bool = 'true'
				end
				txt = txt .. bool
			elseif v_type == 'nil' then
				txt = txt .. 'nil' -- lol
			else
				txt = txt .. '\"' .. tostring(v) .. '\"'
			end
			txt = txt .. ','
			counter = counter + 1
		end
		tab = tab - 1
		txt = txt .. '\n' .. string.rep('\t', tab) .. '}'
		return txt
	end

	local function GetSeatPart()
		local SeatPart = select(2, pcall(function()
			return LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").SeatPart
		end))
		if type(SeatPart) ~= 'string' then
			return SeatPart
		end
		return
	end

	local function GetVehicle()
		local SeatPart = GetSeatPart()
		if typeof(SeatPart) == 'Instance' and SeatPart:IsA("VehicleSeat") and SeatPart.Parent ~= workspace then
			return SeatPart.Parent
		end
		return
	end

	local function FindSurfaceType(Part, SurfaceType)
		if typeof(Part) == 'Instance' and Part:IsA("BasePart") then
			for _, NormalId in pairs(Enum.NormalId:GetEnumItems()) do
				if Part[NormalId.Name .. 'Surface'] == SurfaceType then
					return NormalId
				end
			end
		end
		return false
	end

	local function GetWheels()
		local Vehicle = GetVehicle()
		if typeof(Vehicle) == 'Instance' then
			local Wheels = {}
			for _, Wheel in pairs(Vehicle:GetDescendants()) do
				if FindSurfaceType(Wheel, 'Hinge') or Wheel:FindFirstChildWhichIsA("HingeConstraint") then
					table.insert(Wheels, Wheel)
				end
			end
			return Wheels
		end
		return
	end

	local function _GetSprings() -- unused but may be used later
		local Wheels = GetWheels() or {}
		local Springs = {}
		for _, Wheel in pairs(Wheels) do
			local SpringConstraint = Wheel:FindFirstChildWhichIsA("SpringConstraint")
			if typeof(SpringConstraint) == 'Instance' then
				table.insert(Springs, SpringConstraint)
			end
		end
		return Springs
	end

	local Pointers = Splix.pointers
	local MainWindow
	local HackConnection

	if InternalSettings.LoadUI then
		local Window = Splix:New({
			Name = 'AC6F'
		}) do
			local GeneralPage = Window:Page({
				Name = 'General'
			}) do
				local Section = GeneralPage:Section({
					Name = 'Driving (Network Universal)'
				}) do
					Section:Slider({
						Name = 'Speed Hack',

						Default = 20,
						Minimum = 0,
						Maximum = 30,

						Pointer = 'Acceleration',
					})

					Section:Slider({
						Name = 'Brake Hack',

						Default = 20,
						Minimum = 0,
						Maximum = 30,

						Pointer = 'Deceleration',
					})

					local Acceleration = Pointers.Acceleration
					local Deceleration = Pointers.Deceleration

					local UserInputService = game:GetService("UserInputService")
					local W, S = Enum.KeyCode.W, Enum.KeyCode.S
					local Heartbeat = Instance.new("BindableEvent")

					local C = 1
					local T = 0
					local F = 60
					local D = 1 / F
					local Velocity = Vector3.one

					HackConnection = game:GetService("RunService").Stepped:Connect(function(time, deltaTime)
						if 1 / deltaTime > F or time > T + D then
							Heartbeat:Fire()
							local SeatPart = GetSeatPart()
							if typeof(SeatPart) == 'Instance' and SeatPart:IsA("VehicleSeat") then
								local Acceleration = math.floor(Acceleration:Get())
								local Deceleration = math.floor(Deceleration:Get())
								if UserInputService:IsKeyDown(W) and Acceleration > 0 then
									C = 1 + (Acceleration / 10) * deltaTime
									Velocity = Vector3.one * C
									SeatPart.AssemblyLinearVelocity = SeatPart.AssemblyLinearVelocity * Velocity
								elseif UserInputService:IsKeyDown(S) and Deceleration > 0 then
									C = 1 - (Deceleration / 10) * deltaTime
									Velocity = Vector3.one * C
									SeatPart.AssemblyLinearVelocity = SeatPart.AssemblyLinearVelocity * Velocity
								end
							end
						end
					end)

					AC6F.HackConnection = HackConnection

					Section:Button({
						Name = 'Air Ricochet',
						Callback = function()
							local SeatPart = GetSeatPart()
							if typeof(SeatPart) == 'Instance' and SeatPart:IsA("VehicleSeat") then
								SeatPart.AssemblyLinearVelocity = -SeatPart.AssemblyLinearVelocity
							end
						end,
					})

					Section:Button({
						Name = 'Air Fling',
						Callback = function()
							local SeatPart = GetSeatPart()
							if typeof(SeatPart) == 'Instance' and SeatPart:IsA("VehicleSeat") then
								local X = math.random(0, 1)
								if X == 0 then
									X = -1
								else
									X = 1
								end
								local Y = 1e3 * X
								SeatPart.AssemblyLinearVelocity = Vector3.new(Y, Y, Y)
							end
						end,
					})

					Section:Toggle({
						Name = 'Glitch',
						Default = false,
						Callback = function(X)
							if X == true then
								AC6F.GlitchConnection = Heartbeat.Event:Connect(function()
									local SeatPart = GetSeatPart()
									if typeof(SeatPart) == 'Instance' and SeatPart:IsA("VehicleSeat") then
										local x = math.random(-500, 500)
										local y = math.random(-500, 500)
										local z = math.random(-500, 500)

										SeatPart.AssemblyLinearVelocity = Vector3.new(x, y, z)
									end
								end)
							else
								pcall(function() AC6F.GlitchConnection:Disconnect() end)
							end
						end,
					})
				end
			end
			local DeveloperPage = Window:Page({
				Name = 'Developer',
			}) do
				local Section = DeveloperPage:Section({
					Name = 'Splix',
				}) do
					Section:Button({
						Name = 'Unload',
						Callback = function()
							pcall(function()
								return HackConnection:Disconnect()
							end)
							return Window:Unload()
						end,
					})
				end
			end
			local HelpPage = Window:Page({
				Name = "Help (Please Read)",
			}) do
				local Section = HelpPage:Section({
					Name = 'Applying Settings',
				}) do
					Section:Label({Name = 'Some settings may require\nyou to exit and re-enter\nthe vehicle.\n\nThis is because the vehicle\nstores the values before\nactually using them.'})
				end

				local ContributingSection = HelpPage:Section({
					Name = 'Contributing',
				}) do
					ContributingSection:Label({Name = 'Feel free to contribute.' .. (function()
						if not hasclipboard then
							return '\n\nhttps://github.com/forka42/legacy-scripts'
						end
						return ''
					end)()})
					if hasclipboard then
						ContributingSection:Button({Name = 'GitHub Repository [Clipboard]', Callback = function()
							return setclipboard('https://github.com/forka42/legacy-scripts')
						end,})
					end
				end
			end
		end
		Window.uibind = Enum.KeyCode.RightShift
		MainWindow = Window
	end

	if MainWindow then
		MainWindow:Initialize()
	end
end
