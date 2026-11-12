--[=[
    written by forka42
    ---
    https://github.com/forka42
]=]

---@diagnostic disable: undefined-global
math.randomseed(tick())

local fenv = getfenv()
if type(fenv.getgenv) ~= 'function' then
	return
end

local GlobalEnvironment = fenv.getgenv()
local Players = game:GetService("Players")

if type(GlobalEnvironment) == 'table' then
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
			Splix = require(script:WaitForChild("Splix")); GlobalEnvironment.Splix = Splix
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

	pcall(function() GlobalEnvironment.AC6F.GlitchConnection:Disconnect() end)
	pcall(function() GlobalEnvironment.AC6F.HackConnection:Disconnect() end)
	local AC6F = {}
	if GlobalEnvironment.FireServer and type(fenv.hookfunction) == 'function' then
		fenv.hookfunction(Instance.new("RemoteEvent").FireServer, GlobalEnvironment.FireServer)
	end
	GlobalEnvironment.FireServer = Instance.new("RemoteEvent").FireServer
	GlobalEnvironment.AC6F = AC6F

	local function rawgetall(a, t)
		for i, v in pairs(t) do
			if not rawget(a, v) then
				return false
			end
		end
		return true
	end

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
				if i_type == '__index' then
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

	local Drive
	local function GetDrive()
		for i, v in pairs(getscripts()) do
			if v.Name == 'Drive' and v:FindFirstAncestorWhichIsA("PlayerGui") then
				Drive = v
				return v
			end
		end
	end
	local function GetDriveRegistry()
		local r = {}
		local drive = GetDrive()
		for _, v in pairs(debug.getregistry()) do
			if type(v) == 'function' then
				local script = getfenv(v)['script']
				if script == drive and script:FindFirstAncestorWhichIsA("PlayerGui") then
					table.insert(r, v)
				end
			end
		end
		return r
	end
	local function GetDriveUpvalues()
		local uvs = {}
		for _, f in pairs(GetDriveRegistry()) do
			for i, v in pairs(debug.getupvalues(f)) do
				if not table.find(uvs, v) then
					uvs[#uvs + 1] = v
				end
			end
		end
		return uvs
	end
	local function GetDriveContent()
		local c = {}
		for _, t in pairs(GetDriveUpvalues()) do
			if type(t) == 'table' then
				c[#c + 1] = t
			end
		end
		return c
	end

	local MemoryConfiguration = {}

	local function GetDriveConfiguration()
		local c = select(2, pcall(GetDriveContent))
		if type(c) == 'table' then
			for _, t in pairs(GetDriveContent()) do
				if rawgetall(t, {'PeakRPM', 'SusEnabled', 'Weight'}) then
					return t
				end
			end
		end
		return MemoryConfiguration
	end

	local function GetSeatPart()
		local SeatPart = select(2, pcall(function()
			return LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").SeatPart
		end))
		if type(SeatPart) ~= 'string' then
			return SeatPart
		end
	end

	local function GetVehicle()
		local SeatPart = GetSeatPart()
		if typeof(SeatPart) == 'Instance' and SeatPart:IsA("VehicleSeat") and SeatPart.Parent ~= workspace then
			return SeatPart.Parent
		end
	end

	local MemorySprings = {}

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
	end

	local function GetSprings()
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

	local function GetSoundRemote()
		local Vehicle = GetVehicle()
		if typeof(Vehicle) == 'Instance' and Vehicle:IsA("Model") then
			local AC6_FE_Sounds = Vehicle:FindFirstChild("AC6_FE_Sounds")
			if typeof(AC6_FE_Sounds) == 'Instance' and AC6_FE_Sounds:IsA("RemoteEvent") then
				return AC6_FE_Sounds
			end
		end
	end

	local Pointers = Splix.pointers
	local MainWindow
	local HackConnection

	if InternalSettings.LoadUI then
		local Window = Splix:New({
			Name = 'AC6F'
		}) do
			local Page = Window:Page({
				Name = 'General'
			}) do
				local Section = Page:Section({
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
				local Section = Page:Section({
					Name = 'Steering (AC6 Basic)',
				}) do
					Section:Slider({
						Name = 'Speed',

						Default = .07,
						Minimum = 0,
						Maximum = .1,
						Decimals = .005,

						Callback = function(X)
							GetDriveConfiguration().SteerSpeed = X
						end,
					})

					Section:Slider({
						Name = 'Max Torque',

						Default = 5e4,
						Minimum = 0,
						Maximum = 1e5,

						Callback = function(X)
							GetDriveConfiguration().SteerMaxTorque = X
						end,
					})

					Section:Slider({
						Name = 'P',

						Default = 1e5,
						Minimum = 0,
						Maximum = 4e5,

						Callback = function(X)
							GetDriveConfiguration().SteerP = X
						end,
					})

					Section:Slider({
						Name = 'D',

						Default = 1e3,
						Minimum = 0,
						Maximum = 4e3,

						Callback = function(X)
							GetDriveConfiguration().SteerD = X
						end,
					})

					Section:Slider({
						Name = 'Inner',

						Default = 45,
						Minimum = 0,
						Maximum = 90,

						Callback = function(X)
							GetDriveConfiguration().SteerInner = X
						end,
					})

					Section:Slider({
						Name = 'Outer',

						Default = 38,
						Minimum = 0,
						Maximum = 90,

						Callback = function(X)
							GetDriveConfiguration().SteerOuter = X
						end,
					})

					Section:Slider({
						Name = 'Min',

						Default = 10,
						Minimum = 0,
						Maximum = 30,

						Callback = function(X)
							GetDriveConfiguration().MinSteer = X
						end,
					})
				end
			end
			local Page = Window:Page({
				Name = 'Developer',
			}) do
				local Section = Page:Section({
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
				local Section = Page:Section({
					Name = 'Debugging',
				}) do
					if hasclipboard then
						Section:Button({
							Name = 'Drive Configuration',
							Callback = function()
								setclipboard(serialize(GetDriveConfiguration()))
							end
						})
					end
				end
			end
			local Page = Window:Page({
				Name = "Help (Please Read)",
			}) do
				local Section = Page:Section({
					Name = 'Applying Settings',
				}) do
					Section:Label({Name = 'Some settings may require\nyou to exit and re-enter\nthe vehicle.\n\nThis is because the vehicle\nstores the values before\nactually using them.'})
				end

				local Section = Page:Section({
					Name = 'Contributing',
				}) do
					Section:Label({Name = 'Feel free to contribute.' .. (function()
						if not hasclipboard then
							return '\n\nhttps://github.com/forka42/legacy-scripts'
						end
						return ''
					end)()})
					if hasclipboard then
						Section:Button({Name = 'GitHub Repository [Clipboard]', Callback = function()
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

	--- Searches the PlayerGui for the Drive script. If the script is found, it is returned.
	function AC6F:GetDrive()
		return GetDrive()
	end

	--- Retrieve all tables used for maintaining active vehicle.
	function AC6F:GetDriveContent()
		return GetDriveContent()
	end

	--- Get all functions used by Drive.
	function AC6F:GetDriveRegistry()
		return GetDriveRegistry()
	end

	--- Get all up-values in Drive registry.
	function AC6F:GetDriveUpvalues()
		return GetDriveUpvalues()
	end

	--- Get the configuration of the current vehicle.
	function AC6F:GetDriveConfiguration()
		return GetDriveConfiguration()
	end

	--- Create a new Sound object. If another sound with the same name is found, it is destroyed.
	function AC6F:CreateSound(Name, Parent, SoundId, PlaybackSpeed, Volume, Looped)
		local RemoteEvent = GetSoundRemote()
		if typeof(RemoteEvent) == 'Instance' and RemoteEvent:IsA("RemoteEvent") then
			return RemoteEvent:FireServer("newSound", Name, Parent, SoundId, PlaybackSpeed, Volume, Looped)
		end
	end

	--- Play an existing sound.
	function AC6F:PlaySound(Name)
		local RemoteEvent = GetSoundRemote()
		if typeof(RemoteEvent) == 'Instance' and RemoteEvent:IsA("RemoteEvent") then
			return RemoteEvent:FireServer("playSound", Name)
		end
	end

	--- Stop an existing sound.
	--- @type function
	--- @return nil
	function AC6F:StopSound(Name)
		local RemoteEvent = GetSoundRemote()
		if typeof(RemoteEvent) == 'Instance' and RemoteEvent:IsA("RemoteEvent") then
			return RemoteEvent:FireServer("stopSound", Name)
		end
	end
end
