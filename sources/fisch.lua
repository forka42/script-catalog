--[=[
    written by forka42
    ---
    https://github.com/forka42
    https://www.roblox.com/games/16732694052
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")

local Starlight = (loadstring :: any)((game :: any):HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Starlight-Interface-Suite/master/Source.lua"))()

local LocalPlayer = Players.LocalPlayer

local ok_rc, ReelController = pcall(function()
    return require((ReplicatedStorage :: any).client.legacyControllers.ReelController)
end)
if not ok_rc or type(ReelController) ~= 'table' then
    warn('[fish] failed to require ReelController: ' .. tostring(ReelController))
end

local config = {
    enabled = false,
    cast_hold = 0.35,
    lookahead = 0.15,
    reel_speed = 3.0,
}

local active_rod = nil
local running = false
local generation = 0
local cast_loop_active = false
local holding = false
local shaking = false

local Net = require((ReplicatedStorage :: any).packages.Net)
local EquipBaitRemote = Net:RemoteEvent("Bait/Equip", -1)

local function equip_bait(bait_name)
    pcall(function()
        EquipBaitRemote:FireServer(bait_name or "None")
    end)
end

local function get_best_bait()
    local ok, DataController = pcall(function()
        return require((ReplicatedStorage :: any).client.legacyControllers.DataController)
    end)
    if not ok then return "None" end
    
    local PlayerDataReplicator = DataController.PlayerDataReplicator
    PlayerDataReplicator:WaitForLoaded()
    
    local ok2, legacyLocalPlayerData = pcall(function()
        return require((ReplicatedStorage :: any).client.modules.legacyLocalPlayerData)
    end)
    if not ok2 then return "None" end
    
    local player_data = legacyLocalPlayerData.fetch()
    local stats = player_data:WaitForChild("Stats", 5)
    if not stats then return "None" end
    
    local bait_folder = stats:WaitForChild("bait", 5)
    if not bait_folder then return "None" end

    local bait_priority = {
        "Magnet",
        "Truffle Worm",
        "Squid",
        "Flakes",
        "Mystery Bait",
        "Worm",
        "Maggot",
        "None"
    }

    for _, bait_name in ipairs(bait_priority) do
        local bait_child = bait_folder:FindFirstChild("bait_" .. bait_name)
        if bait_child and bait_child:IsA("NumberValue") and bait_child.Value > 0 then
            return bait_name
        end
    end

    return "None"
end

local function setheld(state)
    if state == holding then return end
    holding = state
end

local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')
local SHAKE_INTERVAL = 0.26

local function find_shake_button()
    local gui = PlayerGui:FindFirstChild('shakeui', true)
    if not (gui and gui:IsA('ScreenGui') and gui.Enabled) then return nil end
    local safe = gui:FindFirstChild('safezone')
    if not safe then return nil end
    for _, c in ipairs(safe:GetChildren()) do
        if c:IsA('GuiButton') then return c end
        if c:FindFirstChild('consoleStroke') then return c end
    end
    return nil
end

local function shake_ui_active()
    return find_shake_button() ~= nil
end

local function shake_start()
    if shaking then return end
    shaking = true
    task.spawn(function()
        while shaking do
            local btn = find_shake_button()
            if btn then
                local ok = pcall(function() btn:Activate() end)
                if not ok then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                end
            end
            task.wait(SHAKE_INTERVAL)
        end
    end)
end

local function shake_stop() 
    shaking = false 
end

local function is_rod(tool)
    return tool ~= nil and tool:IsA('Tool')
        and tool:FindFirstChild('rodClient') ~= nil
        and tool:FindFirstChild('values') ~= nil
end

local ROD_STATE_EQUIPPED = 3
local ROD_STATE_SEARCHING = 5
local ROD_STATE_LURING = 6
local ROD_STATE_PRE_REEL = 7

local function get_values(tool)
    return tool and tool:FindFirstChild('values')
end

local function is_green_zone(tool)
    local values = get_values(tool)
    if not values then return false end
    local zone = values:FindFirstChild('bobberzone')
    return zone ~= nil and zone.Value == true
end

local function has_bobber(tool)
    return tool ~= nil and tool:FindFirstChild('bobber') ~= nil
end

local FishingRodClient = require(
    (ReplicatedStorage :: any).client.legacyControllers.FishingRodController.FishingRodClient
)

local function wait_until_castable(tool, gen, timeout)
    local rod = FishingRodClient.Active
    local deadline = tick() + (timeout or 60)

    while config.enabled and running and generation == gen and tick() < deadline do
        if tool.Parent == nil then return false end
        if ReelController.ActiveReel ~= nil then return false end

        rod = FishingRodClient.Active
        local state
        if rod and rod.Tool == tool then
            state = rod.State
        else
            local values = get_values(tool)
            local sv = values and values:FindFirstChild('state')
            state = sv and sv.Value
        end
        if state == nil then task.wait(0.05); continue end

        if state >= ROD_STATE_PRE_REEL then
            task.wait(0.1)
            continue
        end

        if not has_bobber(tool) then
            if state == ROD_STATE_EQUIPPED or state == ROD_STATE_LURING then
                return true
            end
        else
            if (state == ROD_STATE_SEARCHING or state == ROD_STATE_LURING) and is_green_zone(tool) then
                return true
            end
        end

        task.wait(0.05)
    end
    return false
end

local function wait_for_rod_init(tool, timeout)
    local deadline = tick() + (timeout or 2)
    while tick() < deadline do
        if tool.Parent == nil then return false end
        if tool:FindFirstChild('events') and tool:FindFirstChild('values') then
            return true
        end
        task.wait(0.05)
    end
    return false
end

local function start_cast_loop(gen)
    if cast_loop_active then return end
    cast_loop_active = true

    task.spawn(function()
        while config.enabled and running and generation == gen do
            while ReelController.ActiveReel ~= nil and generation == gen do task.wait(0.1) end
            if generation ~= gen then break end

            task.wait(0.2)
            if generation ~= gen then break end

            if not wait_until_castable(active_rod, gen, 60) then
                if generation ~= gen or not config.enabled then break end
                task.wait(0.5)
                continue
            end

            local CastRemote = Net:RemoteFunction("FishingRod/Cast", -1)
            task.wait(0.1)
            
            local success = CastRemote:InvokeServer(95, true)
            if not success then
                warn("[fish] cast rejected by server")
            end
            
            if generation ~= gen then break end

            local deadline = tick() + 30
            while tick() < deadline and generation == gen do
                if ReelController.ActiveReel ~= nil then break end
                if shake_ui_active() then
                    while shake_ui_active() and tick() < deadline and generation == gen do
                        task.wait(0.1)
                    end
                    break
                end
                task.wait(0.1)
            end
            if generation ~= gen then break end

            while ReelController.ActiveReel == nil and tick() < deadline and generation == gen do task.wait(0.1) end
            if generation ~= gen then break end
            while ReelController.ActiveReel ~= nil and generation == gen do task.wait(0.1) end
            if generation ~= gen then break end

            task.wait(1)
        end
        cast_loop_active = false
    end)
end

local function begin_rod(tool)
    if not is_rod(tool) then return end
    if active_rod == tool then return end
    active_rod = tool
    generation += 1
    local gen = generation

    local best_bait = get_best_bait()
    equip_bait(best_bait)
    print("[fish] auto-equipped best available bait: " .. best_bait)

    task.delay(0.3, function()
        if not config.enabled then return end
        if generation ~= gen or active_rod ~= tool or tool.Parent == nil then return end
        if not wait_for_rod_init(tool, 2) then
            warn('[fish] rod did not initialize in time')
            return
        end
        if generation ~= gen then return end
        running = true
        start_cast_loop(gen)
    end)
end

local equip_conn, unequip_conn

local function enable()
    if config.enabled then return end
    config.enabled = true

    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    for _, t in Character:GetChildren() do
        if is_rod(t) then begin_rod(t); break end
    end

    equip_conn = ContextActionService.LocalToolEquipped:Connect(begin_rod)
    unequip_conn = ContextActionService.LocalToolUnequipped:Connect(function(tool)
        if active_rod ~= tool then return end
        active_rod = nil
        running = false
        generation += 1
        setheld(false)
        shake_stop()
    end)
end

local function disable()
    if not config.enabled then return end
    config.enabled = false
    running = false
    active_rod = nil
    generation += 1
    shake_stop()
    if equip_conn then equip_conn:Disconnect(); equip_conn = nil end
    if unequip_conn then unequip_conn:Disconnect(); unequip_conn = nil end
end

PlayerGui.DescendantAdded:Connect(function(d)
    if d.Name == 'shakeui' and d:IsA('ScreenGui') then shake_start() end
end)
PlayerGui.DescendantRemoving:Connect(function(d)
    if d.Name == 'shakeui' and d:IsA('ScreenGui') then shake_stop() end
end)

RunService.RenderStepped:Connect(function()
    if not (config.enabled and running) then
        if shaking then shake_stop() end
        return
    end
    if shaking and not shake_ui_active() then shake_stop() end
end)

RunService.RenderStepped:Connect(function(dt)
    if not (config.enabled and running) then return end
    local reel = ReelController.ActiveReel
    
    if not reel or not reel.ready or not reel.active then return end

    local fishc = reel.core and reel.core.fish
    if fishc then
        local fish = reel.fishPosition
        local fishv = fishc.CurrentVelocity or 0
        local pf = math.clamp(fish + fishv * config.lookahead, 0, 1)
        reel.barPosition = pf
        reel.onbar = true
    end

    if not reel.progressLocked then
        local base_gain = 35 * dt 
        reel.progress = math.min(reel.progress + (base_gain * config.reel_speed), 100)
    end
end)

LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

local function create_highlight(chest)
    if not chest:GetAttribute("TreasureESP") then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 215, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = chest
        chest:SetAttribute("TreasureESP", true)
        return highlight
    end
    return
end

task.spawn(function()
    while true do
        task.wait(1)
        local chests = CollectionService:GetTagged("TreasureChest")
        for _, chest in ipairs(chests) do
            create_highlight(chest)
        end
    end
end)

local function teleport_to_nearest_chest()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local chests = CollectionService:GetTagged("TreasureChest")
    local nearest_chest = nil
    local shortest_dist = math.huge

    for _, chest in ipairs(chests) do
        local dist = (chest:GetPivot().Position - hrp.Position).Magnitude
        if dist < shortest_dist then
            shortest_dist = dist
            nearest_chest = chest
        end
    end

    if nearest_chest then
        local target_pos = nearest_chest:GetPivot().Position + Vector3.new(0, 5, 0)
        hrp.CFrame = CFrame.new(target_pos)
        print("[fish] Teleported to nearest treasure chest!")
    else
        print("[fish] No treasure chests found nearby.")
    end
end

local Window = Starlight:CreateWindow({
    Name = "Fisch Auto",
    Subtitle = "by forka42",
})

local TabSection = Window:CreateTabSection("Main")

local Tab = TabSection:CreateTab({
    Name = "Fishing",
    Columns = 2,
}, "fisch_config")

local ControlsGroupbox = Tab:CreateGroupbox({
    Name = "Controls",
    Column = 1,
}, "fisch_config")

ControlsGroupbox:CreateButton({
    Name = "Teleport to Treasure",
    Callback = function()
        teleport_to_nearest_chest()
    end,
}, "fisch_config")

ControlsGroupbox:CreateToggle({
    Name = "Fishing Auto",
    CurrentValue = config.enabled,
    Style = 1,
    Callback = function(state)
        if state then
            enable()
            print('[fish] enabled')
        else
            disable()
            print('[fish] disabled')
        end
    end,
}, "fisch_config")

local TuningGroupbox = Tab:CreateGroupbox({
    Name = "Tuning",
    Column = 2,
}, "fisch_config")

TuningGroupbox:CreateSlider({
    Name = "Reel Speed Multiplier",
    Range = {1.0, 10.0},
    Increment = 0.5,
    CurrentValue = config.reel_speed,
    Callback = function(v)
        config.reel_speed = v
    end,
}, "fisch_config")

TuningGroupbox:CreateSlider({
    Name = "Reel Lead",
    Range = {0.00, 0.50},
    Increment = 0.01,
    CurrentValue = config.lookahead,
    Callback = function(v)
        config.lookahead = v
    end,
}, "fisch_config")