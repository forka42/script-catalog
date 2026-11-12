--[=[
    written by forka42
    ---
    https://github.com/forka42
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local StageInt = LocalPlayer:WaitForChild('StageInt')
local Spawns = workspace:WaitForChild('Spawns')

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = 'Crazy Fun Obby (1523801080)',
    LoadingTitle = 'Rayfield Interface Suite',
    LoadingSubtitle = 'Sirius (UI), forka42 (Code)',
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab('Main', 4483362458)
MainTab:CreateSection('Essentials')

local AutoSkipStages = false
MainTab:CreateToggle({
    Name = 'Auto Skip Stages',
    CurrentValue = AutoSkipStages,
    Callback = function(x) AutoSkipStages = x == true end
})

RunService.RenderStepped:Connect(function()
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
end)