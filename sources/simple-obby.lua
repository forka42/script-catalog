--[=[
    written by forka42
    ---
    https://github.com/forka42
    https://www.roblox.com/games/1523801080
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local StageInt = LocalPlayer:WaitForChild('StageInt')
local Spawns = workspace:WaitForChild('Spawns')

local fenv = getfenv()
local getgenv = fenv.getgenv
local genv = if type(getgenv) == 'function' then getgenv() else nil
local httpget = fenv.httpget
local wally

if type(httpget) == 'function' then
    if genv then
        local v = genv.ObbyScriptWindow
        if v ~= nil then v.object:Destroy() end 
        if genv.WallyUI ~= nil then wally = genv.WallyUI end
    else
        local s, r = pcall(httpget, 'https://raw.githubusercontent.com/forka42/script-catalog/refs/heads/main/lib/wally-modified.lua')
        local f = if s then loadstring(r) else nil
        if type(f) == 'function' then
            wally = f()
            if genv then
                genv.WallyUI = wally
            end
        end
    end
end

local hui
local gethui = fenv.gethui
if type(gethui) == 'function' then hui = gethui() else hui = game:GetService('CoreGui') end
if type(wally) ~= 'table' then return error('wally is missing or has moved') end

local window = wally:CreateWindow('A Simple Obby', { Parent = hui })
window:Label('<b>Essentials</b>', true)

local AutoSkipStages = false
window:Toggle('Auto Skip Stages', {
	flag = AutoSkipStages
}, function(v)
	AutoSkipStages = v
end)

local runstep; runstep = RunService.RenderStepped:Connect(function()
	if typeof(window.object) ~= 'Instance' then
		return runstep:Disconnect()
	end

	if AutoSkipStages then
		local NextStage = Spawns:FindFirstChild(tostring(StageInt.Value + 1))
		local Character = LocalPlayer.Character

		if Character and typeof(NextStage) == 'Instance' and NextStage:IsA('BasePart') then
			Character:PivotTo(CFrame.new(NextStage.Position + Vector3.new(0, 1, 0)))
			local Humanoid = Character:FindFirstChildWhichIsA('Humanoid')
			local RootPart = Humanoid and Humanoid.RootPart or Character:FindFirstChild('HumanoidRootPart')
			if RootPart then
				RootPart.AssemblyLinearVelocity = Vector3.zero
				RootPart.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	return
end)

if genv then
	genv.ObbyScriptWindow = window
end