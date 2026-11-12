--[=[
    written by forka42
    ---
    https://github.com/forka42
]=]

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild('__remotes')
local CollectMoneyTS = Remotes:FindFirstChild('CollectMoneyTS', true)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = 'Penthouse Tycoon (124943244212764)',
    LoadingTitle = 'Rayfield Interface Suite',
    LoadingSubtitle = 'Sirius (UI), forka42 (Code)',
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab('Main', 4483362458)
MainTab:CreateSection('Essentials')

local function CollectMoney()
    CollectMoneyTS:FireServer()
end

local AutoCollect = false
MainTab:CreateToggle({
    Name = 'Auto Collect',
    CurrentValue = AutoCollect,
    Callback = function(x) AutoCollect = x == true end
})
local AutoBuy = false
MainTab:CreateToggle({
    Name = 'Auto Buy',
    CurrentValue = AutoBuy,
    Callback = function(x) AutoBuy = x == true end
})

local CurrentPenthouse
local CheapestButton, CheapestPrice
local Tycoons = workspace:WaitForChild('Tycoons')

local function GetTycoonOwner(tycoon)
    return tycoon.Values.Owner.Value
end

local function FetchBalance(player)
    if not player then
        player = LocalPlayer
    end
    local leaderstats = player:FindFirstChild('leaderstats')
    local money = leaderstats and leaderstats:FindFirstChild('Money')
    return money and money.Value or 0
end

task.spawn(function()
    while true do
        task.wait(2)
        if AutoCollect then
            pcall(CollectMoney)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not CurrentPenthouse then
        local PenthouseOwned = false
        for i, tycoon in pairs(Tycoons:GetChildren()) do
            local owner = select(2, pcall(GetTycoonOwner, tycoon))
            if owner == LocalPlayer then
                CurrentPenthouse = tycoon
                PenthouseOwned = true
                break
            end
        end
        if not PenthouseOwned then
            CurrentPenthouse = nil
        end
    end
    if CheapestButton and not CheapestButton:IsDescendantOf(workspace) then
        CheapestButton = nil
    end
    if not CheapestButton and CurrentPenthouse then
        CheapestPrice = math.huge
        local Tycoon = CurrentPenthouse:FindFirstChild('Tycoon')
        if Tycoon then
            for i = 1, 2, 1 do
                for _, penthouse in pairs(Tycoon:GetChildren()) do
                    local buttons = penthouse:FindFirstChild('Buttons')
                    for _, model in pairs(buttons:GetChildren()) do
                        local price = model:GetAttribute('Price')
                        if price < CheapestPrice and model ~= CheapestButton then
                            CheapestPrice = price
                            CheapestButton = model
                        end
                    end
                end
            end
        end
    end
    local HasEnoughMoney = false
    if FetchBalance() > CheapestPrice then
        HasEnoughMoney = true
    end
    if AutoBuy and CheapestButton and HasEnoughMoney then
        local pivotpos = CheapestButton:GetPivot().Position
        local character = LocalPlayer.Character
        local humanoid = character:FindFirstChildWhichIsA('Humanoid')

        if character and humanoid and not humanoid.SeatPart then
            character:PivotTo(CFrame.new(pivotpos))
        end
    end
end)

Rayfield:Notify({
    Title = 'Penthouse Tycoon UI',
    Content = 'Successfully loaded. Enjoy!',
    Duration = 6.5,
    Image = 4483362458
})