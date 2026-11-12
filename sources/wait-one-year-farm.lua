--[=[
    written by forka42
    ---
    https://github.com/forka42
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = 'Wait For 1 Year (18406461316)',
    LoadingTitle = 'Rayfield Interface Suite',
    LoadingSubtitle = 'Sirius (UI), forka42 (Code)',
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab('Main', 4483362458)
MainTab:CreateSection('Essentials')

local AutoCompleteObby = false
MainTab:CreateToggle({
    Name = 'Auto Complete Obby',
    CurrentValue = AutoCompleteObby,
    Callback = function(x) AutoCompleteObby = x == true end
})

local WinParts = {}

for _, v in pairs(workspace:GetChildren()) do
    if v:IsA('BasePart') and v.Name == 'WinPart' then
        table.insert(WinParts, v)
    end
end

local step = 0
local interval = 0.5
local timer = 0

RunService.RenderStepped:Connect(function(deltaTime)
    timer += deltaTime

    if timer >= interval then
        timer -= interval
        if AutoCompleteObby then
            local Character = LocalPlayer.Character
            local WinPart = WinParts[(step - 1) % #WinParts + 1]

            if Character and WinPart then
                Character:PivotTo(CFrame.new(WinPart.Position + Vector3.new(0, 1, 0)))
                local Humanoid = Character:FindFirstChildWhichIsA('Humanoid')
                local RootPart = Humanoid and Humanoid.RootPart or Character:FindFirstChild('HumanoidRootPart')
                if RootPart then
                    RootPart.AssemblyLinearVelocity = Vector3.zero
                    RootPart.AssemblyAngularVelocity = Vector3.zero
                end
            end

            step += 1
        end
    end
end)