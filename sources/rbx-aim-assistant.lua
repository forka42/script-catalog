--[=[
    written by forka42
    ---
    https://github.com/forka42
    universal(ish)
]=]

local fenv = getfenv()
local genv = fenv.getgenv()
local ident = function() end

pcall(genv.stop_aim_assistant or ident)

local isfile = fenv.isfile
local readfile = fenv.readfile
local writefile = fenv.writefile
local insert = table.insert
local instances = {} :: { [number]: Instance }?
local connections = {} :: { [number]: RBXScriptConnection }?

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    insert(connections, connection)
    return connection
end

local function make(class, parent)
    local obj = Instance.new(class, parent)
    insert(instances, obj)
    return obj
end

local players = game:GetService("Players")
local runservice = game:GetService('RunService')
local httpservice = game:GetService("HttpService")
local userinputservice = game:GetService("UserInputService")

local file = 'rbxaimassistant.json'
local check, blank = '✓', ''

local defaults = {
    aimbot = true,
    esp = true,
    ffa = true,
    fov = 4,
    sens = 0.2
}

local function clampnum(n, min, max, fallback)
    n = tonumber(n)
    if not n or n ~= n or n == math.huge or n == -math.huge then
        return fallback
    end
    return math.clamp(n, min, max)
end

local function sanitize(save)
    return {
        aimbot = save.aimbot == true,
        esp = save.esp == true,
        ffa = save.ffa == true,
        fov = clampnum(save.fov, 1, 360, defaults.fov),
        sens = clampnum(save.sens, 0.01, 1, defaults.sens)
    }
end

local function write_defaults()
    local ok, encoded = pcall(httpservice.JSONEncode, httpservice, defaults)
    if not ok then return false end
    local wrote = pcall(writefile, file, encoded)
    return wrote == true
end

local function loadsettings()
    if isfile(file) then
        local ok, raw = pcall(readfile, file)
        if ok and type(raw) == 'string' and #raw > 0 then
            local decoded, save = pcall(httpservice.JSONDecode, httpservice, raw)
            if decoded and type(save) == 'table' then
                return true, sanitize(save)
            end
        end
        if not write_defaults() then
            warn('aim assistant: could not regenerate malformed settings file')
        end
        return false, table.clone(defaults)
    end

    if not write_defaults() then
        warn('aim assistant: could not create settings file')
    end
    return false, table.clone(defaults)
end

local mysettings = select(2, loadsettings())
local aimbot = mysettings.aimbot
local esp = mysettings.esp
local ffa = mysettings.ffa
local fov = mysettings.fov
local sens = mysettings.sens

local function pick(v, fallback)
    if v == nil then return fallback end
    return v
end

local function trysave(overrides)
    local payload = {
        aimbot = pick(overrides.aimbot, aimbot),
        esp = pick(overrides.esp,    esp),
        ffa = pick(overrides.ffa,    ffa),
        fov = pick(overrides.fov,    fov),
        sens = pick(overrides.sens,   sens)
    }
    local ok, encoded = pcall(httpservice.JSONEncode, httpservice, payload)
    if not ok then return false end
    return (pcall(writefile, file, encoded)) and true or false
end

local pfexperiences = {292439477, 299659045}
local ignoret = type(table.find({
	unpack(pfexperiences),
	286090429
}, game.PlaceId)) == 'number'

local v2 = Vector2.new
local c3u = Color3.fromRGB
local coregui = if type(fenv.gethui) then fenv.gethui() else game:GetService('CoreGui')

local ui = make("ScreenGui")
ui.ResetOnSpawn = false
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Enabled = true
ui.Parent = coregui
insert(instances, ui)

local ui_frame = make("Frame")
ui_frame.Name = "ui_frame"
ui_frame.AnchorPoint = Vector2.new(0.5, 0)
ui_frame.BackgroundColor3 = Color3.new(0.176, 0.176, 0.176)
ui_frame.Position = UDim2.new(0.5, 0, 0, 10)
ui_frame.BorderColor3 = Color3.new(0.125, 0.125, 0.125)
ui_frame.BorderSizePixel = 3
ui_frame.Size = UDim2.new(0, 300, 0, 140)
ui_frame.Parent = ui

local ui_domainlabel = make("TextLabel")
ui_domainlabel.Name = "ui_domainlabel"
ui_domainlabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
ui_domainlabel.TextColor3 = Color3.new(1, 1, 1)
ui_domainlabel.TextTransparency = 0.8
ui_domainlabel.Text = "(c) 2022-2026 forka42"
ui_domainlabel.BackgroundColor3 = Color3.new(1, 1, 1)
ui_domainlabel.AnchorPoint = Vector2.new(0.5, 1)
ui_domainlabel.BackgroundTransparency = 1
ui_domainlabel.Position = UDim2.new(0.5, 0, 1, -5)
ui_domainlabel.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_domainlabel.TextYAlignment = Enum.TextYAlignment.Bottom
ui_domainlabel.TextSize = 17
ui_domainlabel.Size = UDim2.new(0, 125, 0, 17)
ui_domainlabel.Parent = ui_frame

local ui_content = make("Frame")
ui_content.Name = "ui_content"
ui_content.BackgroundTransparency = 1
ui_content.Position = UDim2.new(0, 0, 0, 25)
ui_content.BorderColor3 = Color3.new(0.176, 0.176, 0.176)
ui_content.BackgroundColor3 = Color3.new(1, 1, 1)
ui_content.Size = UDim2.new(1, 0, 1, -25)
ui_content.Parent = ui_frame

local ui_sencontroller = make("Frame")
ui_sencontroller.Name = "ui_sencontroller"
ui_sencontroller.Position = UDim2.new(0, 222, 0, 40)
ui_sencontroller.BorderColor3 = Color3.new(0.125, 0.125, 0.125)
ui_sencontroller.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
ui_sencontroller.Size = UDim2.new(0, 70, 0, 20)
ui_sencontroller.Parent = ui_content

local ui_label = make("TextLabel")
ui_label.Name = "ui_label"
ui_label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
ui_label.TextColor3 = Color3.new(1, 1, 1)
ui_label.Text = "Sensitivity"
ui_label.BackgroundColor3 = Color3.new(1, 1, 1)
ui_label.BackgroundTransparency = 1
ui_label.TextXAlignment = Enum.TextXAlignment.Right
ui_label.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_label.Position = UDim2.new(-1, -40, 0, 0)
ui_label.TextSize = 14
ui_label.Size = UDim2.new(0, 100, 1, 0)
ui_label.Parent = ui_sencontroller

local ui_senbox = make("TextBox")
ui_senbox.Name = "ui_senbox"
ui_senbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
ui_senbox.TextColor3 = Color3.new(1, 1, 1)
ui_senbox.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_senbox.Text = ""
ui_senbox.BackgroundTransparency = 1
ui_senbox.BackgroundColor3 = Color3.new(1, 1, 1)
ui_senbox.PlaceholderText = "0.2"
ui_senbox.TextSize = 14
ui_senbox.Size = UDim2.new(1, 0, 1, 0)
ui_senbox.Parent = ui_sencontroller

local ui_aimcontroller = make("Frame")
ui_aimcontroller.Name = "ui_aimcontroller"
ui_aimcontroller.BackgroundTransparency = 1
ui_aimcontroller.Position = UDim2.new(0, 10, 0, 10)
ui_aimcontroller.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_aimcontroller.BackgroundColor3 = Color3.new(1, 1, 1)
ui_aimcontroller.Size = UDim2.new(0, 20, 0, 20)
ui_aimcontroller.Parent = ui_content

local ui_label_2 = make("TextLabel")
ui_label_2.Name = "ui_label"
ui_label_2.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
ui_label_2.TextColor3 = Color3.new(1, 1, 1)
ui_label_2.Text = "Aimbot"
ui_label_2.BackgroundColor3 = Color3.new(1, 1, 1)
ui_label_2.BackgroundTransparency = 1
ui_label_2.TextXAlignment = Enum.TextXAlignment.Left
ui_label_2.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_label_2.Position = UDim2.new(1, 5, 0, 0)
ui_label_2.TextSize = 14
ui_label_2.Size = UDim2.new(0, 100, 1, 0)
ui_label_2.Parent = ui_aimcontroller

local ui_aimbutton = make("ImageButton")
ui_aimbutton.Name = "ui_aimbutton"
ui_aimbutton.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
ui_aimbutton.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
ui_aimbutton.ImageTransparency = 1
ui_aimbutton.BorderColor3 = Color3.new(0.125, 0.125, 0.125)
ui_aimbutton.Size = UDim2.new(1, 0, 1, 0)
ui_aimbutton.Parent = ui_aimcontroller

local ui_aimcheck = make("TextLabel")
ui_aimcheck.Name = "ui_aimcheck"
ui_aimcheck.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
ui_aimcheck.TextColor3 = Color3.new(1, 1, 1)
ui_aimcheck.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_aimcheck.Text = "✓"
ui_aimcheck.AnchorPoint = Vector2.new(0.5, 0.5)
ui_aimcheck.BackgroundTransparency = 1
ui_aimcheck.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_aimcheck.BackgroundColor3 = Color3.new(1, 1, 1)
ui_aimcheck.TextSize = 16
ui_aimcheck.Size = UDim2.new(1, -5, 1, -5)
ui_aimcheck.Parent = ui_aimbutton

local ui_ffacontroller = make("Frame")
ui_ffacontroller.Name = "ui_ffacontroller"
ui_ffacontroller.BackgroundTransparency = 1
ui_ffacontroller.Position = UDim2.new(0, 10, 0, 70)
ui_ffacontroller.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_ffacontroller.BackgroundColor3 = Color3.new(1, 1, 1)
ui_ffacontroller.Size = UDim2.new(0, 20, 0, 20)
ui_ffacontroller.Parent = ui_content

local ui_label_3 = make("TextLabel")
ui_label_3.Name = "ui_label"
ui_label_3.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
ui_label_3.TextColor3 = Color3.new(1, 1, 1)
ui_label_3.Text = "FFA"
ui_label_3.BackgroundColor3 = Color3.new(1, 1, 1)
ui_label_3.BackgroundTransparency = 1
ui_label_3.TextXAlignment = Enum.TextXAlignment.Left
ui_label_3.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_label_3.Position = UDim2.new(1, 5, 0, 0)
ui_label_3.TextSize = 14
ui_label_3.Size = UDim2.new(0, 100, 1, 0)
ui_label_3.Parent = ui_ffacontroller

local ui_ffabutton = make("ImageButton")
ui_ffabutton.Name = "ui_ffabutton"
ui_ffabutton.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
ui_ffabutton.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
ui_ffabutton.ImageTransparency = 1
ui_ffabutton.BorderColor3 = Color3.new(0.125, 0.125, 0.125)
ui_ffabutton.Size = UDim2.new(1, 0, 1, 0)
ui_ffabutton.Parent = ui_ffacontroller

local ui_ffacheck = make("TextLabel")
ui_ffacheck.Name = "ui_ffacheck"
ui_ffacheck.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
ui_ffacheck.TextColor3 = Color3.new(1, 1, 1)
ui_ffacheck.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_ffacheck.Text = "✓"
ui_ffacheck.AnchorPoint = Vector2.new(0.5, 0.5)
ui_ffacheck.BackgroundTransparency = 1
ui_ffacheck.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_ffacheck.BackgroundColor3 = Color3.new(1, 1, 1)
ui_ffacheck.TextSize = 16
ui_ffacheck.Size = UDim2.new(1, -5, 1, -5)
ui_ffacheck.Parent = ui_ffabutton

local ui_espcontroller = make("Frame")
ui_espcontroller.Name = "ui_espcontroller"
ui_espcontroller.BackgroundTransparency = 1
ui_espcontroller.Position = UDim2.new(0, 10, 0, 40)
ui_espcontroller.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_espcontroller.BackgroundColor3 = Color3.new(1, 1, 1)
ui_espcontroller.Size = UDim2.new(0, 20, 0, 20)
ui_espcontroller.Parent = ui_content

local ui_espbutton = make("ImageButton")
ui_espbutton.Name = "ui_espbutton"
ui_espbutton.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
ui_espbutton.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
ui_espbutton.ImageTransparency = 1
ui_espbutton.BorderColor3 = Color3.new(0.125, 0.125, 0.125)
ui_espbutton.Size = UDim2.new(1, 0, 1, 0)
ui_espbutton.Parent = ui_espcontroller

local ui_espcheck = make("TextLabel")
ui_espcheck.Name = "ui_espcheck"
ui_espcheck.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
ui_espcheck.TextColor3 = Color3.new(1, 1, 1)
ui_espcheck.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_espcheck.Text = "✓"
ui_espcheck.AnchorPoint = Vector2.new(0.5, 0.5)
ui_espcheck.BackgroundTransparency = 1
ui_espcheck.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_espcheck.BackgroundColor3 = Color3.new(1, 1, 1)
ui_espcheck.TextSize = 16
ui_espcheck.Size = UDim2.new(1, -5, 1, -5)
ui_espcheck.Parent = ui_espbutton

local ui_label_4 = make("TextLabel")
ui_label_4.Name = "ui_label"
ui_label_4.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
ui_label_4.TextColor3 = Color3.new(1, 1, 1)
ui_label_4.Text = "ESP"
ui_label_4.BackgroundColor3 = Color3.new(1, 1, 1)
ui_label_4.BackgroundTransparency = 1
ui_label_4.TextXAlignment = Enum.TextXAlignment.Left
ui_label_4.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_label_4.Position = UDim2.new(1, 5, 0, 0)
ui_label_4.TextSize = 14
ui_label_4.Size = UDim2.new(0, 100, 1, 0)
ui_label_4.Parent = ui_espcontroller

local ui_fovcontroller = make("Frame")
ui_fovcontroller.Name = "ui_fovcontroller"
ui_fovcontroller.Position = UDim2.new(0, 222, 0, 10)
ui_fovcontroller.BorderColor3 = Color3.new(0.125, 0.125, 0.125)
ui_fovcontroller.BackgroundColor3 = Color3.new(0.157, 0.157, 0.157)
ui_fovcontroller.Size = UDim2.new(0, 70, 0, 20)
ui_fovcontroller.Parent = ui_content

local ui_label_5 = make("TextLabel")
ui_label_5.Name = "ui_label"
ui_label_5.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
ui_label_5.TextColor3 = Color3.new(1, 1, 1)
ui_label_5.Text = "FOV"
ui_label_5.BackgroundColor3 = Color3.new(1, 1, 1)
ui_label_5.BackgroundTransparency = 1
ui_label_5.TextXAlignment = Enum.TextXAlignment.Right
ui_label_5.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_label_5.Position = UDim2.new(-1, -40, 0, 0)
ui_label_5.TextSize = 14
ui_label_5.Size = UDim2.new(0, 100, 1, 0)
ui_label_5.Parent = ui_fovcontroller

local ui_fovbox = make("TextBox")
ui_fovbox.Name = "ui_fovbox"
ui_fovbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
ui_fovbox.TextColor3 = Color3.new(1, 1, 1)
ui_fovbox.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_fovbox.Text = ""
ui_fovbox.BackgroundTransparency = 1
ui_fovbox.BackgroundColor3 = Color3.new(1, 1, 1)
ui_fovbox.PlaceholderText = "4"
ui_fovbox.TextSize = 14
ui_fovbox.Size = UDim2.new(1, 0, 1, 0)
ui_fovbox.Parent = ui_fovcontroller

local ui_versionlabel = make("TextLabel")
ui_versionlabel.Name = "ui_versionlabel"
ui_versionlabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
ui_versionlabel.TextColor3 = Color3.new(1, 1, 1)
ui_versionlabel.TextTransparency = 0.8
ui_versionlabel.Text = "[2.0.0]"
ui_versionlabel.BackgroundColor3 = Color3.new(1, 1, 1)
ui_versionlabel.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_versionlabel.AnchorPoint = Vector2.new(1, 0)
ui_versionlabel.Position = UDim2.new(1, 0, 0, 0)
ui_versionlabel.BackgroundTransparency = 1
ui_versionlabel.TextXAlignment = Enum.TextXAlignment.Right
ui_versionlabel.TextYAlignment = Enum.TextYAlignment.Bottom
ui_versionlabel.TextSize = 14
ui_versionlabel.Size = UDim2.new(0, 100, 0, 15)
ui_versionlabel.Parent = ui_frame

local ui_topbar = make("Frame")
ui_topbar.Name = "ui_topbar"
ui_topbar.BackgroundColor3 = Color3.new(0.125, 0.125, 0.125)
ui_topbar.BorderColor3 = Color3.new(0.176, 0.176, 0.176)
ui_topbar.BorderSizePixel = 0
ui_topbar.Size = UDim2.new(1, 0, 0, 25)
ui_topbar.Parent = ui_frame

local ui_topbarlabel = make("TextLabel")
ui_topbarlabel.Name = "ui_topbarlabel"
ui_topbarlabel.FontFace = Font.new(
	"rbxasset://fonts/families/GothamSSm.json",
	Enum.FontWeight.Medium,
	Enum.FontStyle.Normal
)
ui_topbarlabel.TextColor3 = Color3.new(1, 1, 1)
ui_topbarlabel.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_topbarlabel.Text = "Aim Assistant"
ui_topbarlabel.AnchorPoint = Vector2.new(0.5, 0.5)
ui_topbarlabel.BackgroundTransparency = 1
ui_topbarlabel.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_topbarlabel.BackgroundColor3 = Color3.new(1, 1, 1)
ui_topbarlabel.TextSize = 20
ui_topbarlabel.Size = UDim2.new(1, 0, 1, 0)
ui_topbarlabel.Parent = ui_topbar

local ui_circle = make("Frame")
ui_circle.Name = "ui_circle"
ui_circle.AnchorPoint = Vector2.new(0.5, 0.5)
ui_circle.BackgroundTransparency = 0.9
ui_circle.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_circle.BackgroundColor3 = Color3.new(0.125, 0.125, 0.125)
ui_circle.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_circle.Size = UDim2.new(0, 200, 0, 200)
ui_circle.Parent = ui

local ui_circle_line = make("Frame")
ui_circle_line.Name = "ui_circle_line"
ui_circle_line.AnchorPoint = Vector2.new(0.5, 0.5)
ui_circle_line.BackgroundColor3 = Color3.new()
ui_circle_line.BackgroundTransparency = 0.8
ui_circle_line.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_circle_line.Rotation = 315
ui_circle_line.BorderSizePixel = 0
ui_circle_line.Size = UDim2.new(0, 1, 0.5, 0)
ui_circle_line.Parent = ui_circle

local ui_circle_stroke = make("UIStroke")
ui_circle_stroke.Name = "ui_circle_stroke"
ui_circle_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ui_circle_stroke.Transparency = 0.8
ui_circle_stroke.Color = Color3.new(0.125, 0.125, 0.125)
ui_circle_stroke.Thickness = 2
ui_circle_stroke.Parent = ui_circle

local ui_circle_line_2 = make("Frame")
ui_circle_line_2.Name = "ui_circle_line"
ui_circle_line_2.AnchorPoint = Vector2.new(0.5, 0.5)
ui_circle_line_2.BackgroundTransparency = 0.8
ui_circle_line_2.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_circle_line_2.BackgroundColor3 = Color3.new()
ui_circle_line_2.BorderSizePixel = 0
ui_circle_line_2.Size = UDim2.new(0, 1, 1, 0)
ui_circle_line_2.Parent = ui_circle

local ui_circle_line_3 = make("Frame")
ui_circle_line_3.Name = "ui_circle_line"
ui_circle_line_3.AnchorPoint = Vector2.new(0.5, 0.5)
ui_circle_line_3.BackgroundTransparency = 0.8
ui_circle_line_3.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_circle_line_3.BackgroundColor3 = Color3.new()
ui_circle_line_3.BorderSizePixel = 0
ui_circle_line_3.Size = UDim2.new(1, 0, 0, 1)
ui_circle_line_3.Parent = ui_circle

local ui_circle_line_4 = make("Frame")
ui_circle_line_4.Name = "ui_circle_line"
ui_circle_line_4.AnchorPoint = Vector2.new(0.5, 0.5)
ui_circle_line_4.BackgroundColor3 = Color3.new()
ui_circle_line_4.BackgroundTransparency = 0.8
ui_circle_line_4.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_circle_line_4.Rotation = 45
ui_circle_line_4.BorderSizePixel = 0
ui_circle_line_4.Size = UDim2.new(0, 1, 0.5, 0)
ui_circle_line_4.Parent = ui_circle

local ui_circle_corner = make("UICorner")
ui_circle_corner.Name = "ui_circle_corner"
ui_circle_corner.CornerRadius = UDim.new(0.5, 0)
ui_circle_corner.Parent = ui_circle

local ui_circle_img = make("ImageLabel")
ui_circle_img.Name = "ui_circle_img"
ui_circle_img.BorderColor3 = Color3.new(0.106, 0.165, 0.208)
ui_circle_img.BackgroundColor3 = Color3.new(1, 1, 1)
ui_circle_img.AnchorPoint = Vector2.new(0.5, 0.5)
ui_circle_img.Image = "rbxassetid://7254289048"
ui_circle_img.BackgroundTransparency = 1
ui_circle_img.Position = UDim2.new(0.5, 0, 0.5, 0)
ui_circle_img.ZIndex = 2
ui_circle_img.Size = UDim2.new(0, 200, 0, 200)
ui_circle_img.Parent = ui_circle

ui_aimcheck.Text = aimbot and check or blank
ui_espcheck.Text = esp and check or blank
ui_ffacheck.Text = ffa and check or blank
ui_circle.Visible = aimbot
ui_fovbox.Text = tostring(fov)
ui_senbox.Text = tostring(sens)

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true

local function ray(origin, direction)
    return {
        origin = origin,
        direction = direction
    }
end

local function chain_raycast(worldroot, rayobject, ignorelist)
    local origin = rayobject.origin
    local direction = rayobject.direction
    local remaining = direction
    local current_origin = origin
    local ignore = type(ignorelist) == 'table' and table.clone(ignorelist) or {}
    while remaining.Magnitude > 0.05 do
        params.FilterDescendantsInstances = ignore
        local res = worldroot:Raycast(current_origin, remaining, params)
        if not res then
            return nil
        end
        local hit = res.Instance
        if ignoret and hit:IsA("BasePart") and hit.Transparency > 0 then
            table.insert(ignore, hit)
            local traveled = (res.Position - current_origin).Magnitude
            local left = math.max(remaining.Magnitude - traveled - 0.05, 0)
            if left <= 0.05 then
                return nil
            end
            current_origin = res.Position + remaining.Unit * 0.05
            remaining = remaining.Unit * left
        else
            return hit
        end
    end
    return nil
end

local color_scheme = {}
color_scheme['nearest'] = c3u(0, 172, 255)
color_scheme['valid'] = c3u(38, 255, 99)
color_scheme['invalid'] = c3u(255, 215, 37)
color_scheme['obstructed'] = c3u(255, 37, 40)

local function spawn(f, ...)
    local args = { ... }
    local thread = coroutine.create(f)
    return coroutine.resume(thread, unpack(args))
end

spawn(function()
    if genv.droppingerrors then
        return
    end
    genv.droppingerrors = true
    while true do
        for _, c in pairs({
            unpack( fenv.getconnections(game:GetService('LogService').MessageOut) ),
            unpack( fenv.getconnections(game:GetService("ScriptContext").Error) )
        }) do
            c:Disable()
        end
        task.wait(0.1)
    end
end)

local localplayer = players.LocalPlayer
local playermouse = localplayer:GetMouse()
local currentcamera = workspace.CurrentCamera

connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    currentcamera = workspace.CurrentCamera
end)

local touch = Enum.UserInputType.Touch
local mousebutton1 = Enum.UserInputType.MouseButton1
local mousebutton2 = Enum.UserInputType.MouseButton2
local mousemovement = Enum.UserInputType.MouseMovement
local mousebutton1down = false
local mousebutton2down = false
local inputbegan = userinputservice.InputBegan
local inputended = userinputservice.InputEnded
local inputendstate = Enum.UserInputState.End
local keyboard = Enum.UserInputType.Keyboard
local key = { f6 = Enum.KeyCode.F6 }

spawn(function()
    if not table.find(pfexperiences, game.PlaceId) then return end
    phantomforces = true
    fenv.run_on_thread(fenv.getactorthreads()[1], [==[
        local ri = getrenv().shared.require('ReplicationInterface')
        local operateOnAllEntries = ri.operateOnAllEntries
        game:GetService("RunService").Stepped:Connect(function()
            operateOnAllEntries(function(p, e)
                pcall(function()
                    local third = e.getThirdPersonObject and e:getThirdPersonObject()
                    if not third then return end
                    local model = (third.getCharacterModel and third:getCharacterModel()) 
                        or third._characterModel
                    if model then
                        p.Character = model
                    end
                end)
            end)
        end)
    ]==])
end)

spawn(function()
    local dragging
    local draginput
    local dragstart
    local startpos

    local function update(input)
        local delta = input.Position - dragstart
        ui_frame.Position = UDim2.new(startpos.X.Scale, startpos.X.Offset + delta.X, startpos.Y.Scale,
            startpos.Y.Offset + delta.Y)
    end

    connect(ui_topbar.InputBegan, function(input)
        if input.UserInputType == mousebutton1 or input.UserInputType == touch then
            dragging = true
            dragstart = input.Position
            startpos = ui_frame.Position

            connect(input.Changed, function()
                if input.UserInputState == inputendstate then
                    dragging = false
                end
            end)
        end
    end)

    connect(ui_topbar.InputChanged, function(input)
        if input.UserInputType == mousemovement then
            draginput = input
        end
    end)

    connect(ui_frame.InputChanged, function(input)
        if input == draginput and dragging then
            update(input)
        end
    end)

    connect(ui_topbar.InputEnded, function(input)
        if input.UserInputType == mousebutton1 or input.UserInputType == touch then
            dragging = false
        end
    end)
end)

connect(ui_fovbox.FocusLost, function(enter_pressed)
    if not enter_pressed then return end
    local number = clampnum(ui_fovbox.Text, 1, 360, fov)
    if not trysave({ fov = number }) then
        ui_fovbox.TextColor3 = Color3.new(1, 0.3, 0.3)
        task.delay(1, function() ui_fovbox.TextColor3 = Color3.new(1, 1, 1) end)
        return
    end
    fov = number
    ui_fovbox.Text = tostring(number)
end)

connect(ui_senbox.FocusLost, function(enter_pressed)
    if not enter_pressed then return end
    local number = clampnum(ui_senbox.Text, 0.01, 1, sens)
    if not trysave({ sens = number }) then
        ui_senbox.TextColor3 = Color3.new(1, 0.3, 0.3)
        task.delay(1, function() ui_senbox.TextColor3 = Color3.new(1, 1, 1) end)
        return
    end
    sens = number
    ui_senbox.Text = tostring(number)
end)

local function get_team_ident(player)
    local team = player.Team
    if team and team.Name and team.Name ~= "" then
        return team.Name
    end
    
    local teamColor = player.TeamColor
    if teamColor and teamColor.Name and teamColor.Name ~= "" then
        return teamColor.Name
    end
    
    return tostring(teamColor) or "Unknown"
end

local function can_track(player, character)
    if typeof(player) == 'Instance' and player:IsA('Model') then
        character = player
        player = players:GetPlayerFromCharacter(character)
    end
    
    if not player or player == localplayer then
        return false
    end
    
    return ffa or get_team_ident(player) ~= get_team_ident(localplayer)
end

local content = {} :: { [any]: any }
local highlight = {}
highlight.__index = highlight

function highlight.new(player)
    if content[player] then
        return content[player]
    end
    local self = setmetatable({}, highlight)
    self.player = player
    local highlight = make("Highlight")
    highlight.Enabled = can_track(player)
    highlight.FillColor = color_scheme['invalid']
    highlight.OutlineColor = color_scheme['invalid']
    highlight.Parent = ui
    connect(player.CharacterAdded, function(character)
        self.character = character
        highlight.Adornee = character
        highlight.Enabled = can_track(player)
    end)
    if player.Character then
        self.character = player.Character
        highlight.Adornee = player.Character
        highlight.Enabled = can_track(player)
    end
    connect(player:GetPropertyChangedSignal("Team"), function()
        highlight.Enabled = can_track(player)
    end)
    self.highlight = highlight
    content[player] = self
    return self
end

function highlight:destroy()
    self.highlight:Destroy()
end

function highlight:valid()
    return can_track(self.player)
end

function highlight:color(color)
    self.highlight.FillColor = color
    self.highlight.OutlineColor = color
end

function highlight:enabled(enabled)
    self.highlight.Enabled = enabled
end

local function get_enemy_players()
    local enemy_players = {}
    local localTeamId = get_team_ident(localplayer)
    
    for _, potential_enemy in pairs(players:GetPlayers()) do
        if potential_enemy ~= localplayer then
            local local_entry = content[potential_enemy]
            if not local_entry then
                highlight.new(potential_enemy)
                local_entry = content[potential_enemy]
            end
            local_entry:enabled(esp and can_track(local_entry.player))
            
            local is_enemy = false
            if ffa then
                is_enemy = true
            else
                local enemyTeamId = get_team_ident(potential_enemy)
                if localTeamId ~= enemyTeamId then
                    is_enemy = true
                end
            end
            
            if is_enemy then
                table.insert(enemy_players, potential_enemy)
            end
        end
    end
    return enemy_players
end

local function get_enemy_characters()
    local enemy_characters = {}
    for _, enemy_player in pairs(get_enemy_players()) do
        local enemy_character = enemy_player.Character
        local enemy_humanoid = typeof(enemy_character) == 'Instance' and enemy_character:FindFirstChildOfClass('Humanoid')
        if (enemy_humanoid and enemy_humanoid.Health > 0) or not enemy_humanoid then
            insert(enemy_characters, enemy_character)
        end
    end
    return enemy_characters
end

local function get_nearest_character(current_target)
    local nearest_character, nearest_screenpoint
    local closest_distance = 2048
    local camera_position = currentcamera.CFrame.Position
    for _, character in pairs(get_enemy_characters()) do
        local local_entry
        local local_color_selection = color_scheme['invalid']
        for _, entry in pairs(content) do
            if entry.character == character then
                local_entry = entry
                break
            end
        end
        local head = character:FindFirstChild('Head') :: BasePart?
        if phantomforces then
            for _, p in pairs(character:GetChildren()) do
                if p:IsA('BasePart') then
                    local m = p:FindFirstChildOfClass('SpecialMesh')
                    if m and m.MeshId == 'rbxassetid://6179256256' then
                        head = p
                        break
                    end
                end
            end
        end
        if typeof(head) == 'Instance' and head:IsA('BasePart') then
            local screen_position, on_screen = currentcamera:WorldToScreenPoint(head.Position)
            local screen_distance = (v2(playermouse.X, playermouse.Y) - v2(screen_position.X, screen_position.Y))
                .Magnitude
            if on_screen then
                local_entry:enabled(can_track(local_entry.player))
                local hit = chain_raycast(
                    workspace,
                    ray(camera_position, (head.Position - camera_position).Unit * 2048),
                    { currentcamera, localplayer.Character }
                )
                if typeof(hit) == 'Instance' and hit:IsDescendantOf(character) then
                    if screen_distance < closest_distance and screen_distance <= currentcamera.ViewportSize.X / (90 / fov) then
                        nearest_character = character
                        nearest_screenpoint = screen_position
                        closest_distance = screen_distance
                        local_color_selection = color_scheme['valid']
                    else
                        local_color_selection = color_scheme['invalid']
                    end
                else
                    local_color_selection = color_scheme['obstructed']
                end
            else
                local_color_selection = color_scheme['obstructed']
                local_entry:enabled(false)
            end
        end
        local_entry:color(local_color_selection)
    end
    return nearest_character, nearest_screenpoint
end

connect(inputbegan, function(input)
    if userinputservice:GetFocusedTextBox() then
        return
    end
    if input.UserInputType == mousebutton1 then
        mousebutton1down = true
    elseif input.UserInputType == mousebutton2 then
        mousebutton2down = true
    elseif input.UserInputType == keyboard then
        if input.KeyCode == key.f6 then
            ui.Enabled = not ui.Enabled
        end
    end
end)

connect(inputended, function(input)
    if userinputservice:GetFocusedTextBox() then
        return
    end
    if input.UserInputType == mousebutton1 then
        mousebutton1down = false
    elseif input.UserInputType == mousebutton2 then
        mousebutton2down = false
    end
end)

coroutine.resume(coroutine.create(function(dragging, drag_input, drag_start, start_position)
    local function update(input)
        local delta = input.Position - drag_start
        ui_frame.Position = UDim2.new(start_position.X.Scale, start_position.X.Offset + delta.X, start_position.Y.Scale,
            start_position.Y.Offset + delta.Y)
    end
    connect(ui_frame.InputBegan, function(input)
        if input.UserInputType == mousebutton1 or input.UserInputType == touch then
            dragging, drag_start, start_position = true, input.Position, ui_frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == inputendstate then
                    dragging = false
                end
            end)
        end
    end)
    connect(ui_frame.InputChanged, function(input)
        if input.UserInputType == mousemovement or input.UserInputType == touch then
            drag_input = input
        end
    end)
    connect(userinputservice.InputChanged, function(input)
        if input == drag_input and dragging then
            update(input)
        end
    end)
    connect(ui_frame.InputEnded, function(input)
        if input.UserInputType == mousebutton1 or input.UserInputType == touch then
            dragging = false
        end
    end)
end))

local function load_player(player)
    if player ~= localplayer then
        highlight.new(player)
    end
end

for _, player in pairs(players:GetPlayers()) do
    load_player(player)
end

connect(players.PlayerAdded, load_player)
connect(players.PlayerRemoving, function(player)
    if player ~= localplayer then
        local entry = content[player]
        if entry then
            entry:destroy()
            content[player] = nil
        end
    end
end)

local function update_mouse()
    if currentcamera then
        local viewport_size = currentcamera.ViewportSize * 2
        local x, y = playermouse.X, playermouse.Y
        ui_circle.Position = UDim2.fromOffset(x, y)
        ui_circle.Size = UDim2.fromOffset(viewport_size.X / (90 / fov), viewport_size.X / (90 / fov))
    end
end

connect(playermouse.Move, update_mouse)
connect(userinputservice:GetPropertyChangedSignal("MouseBehavior"), update_mouse)

local current_target
local nearest_player
local nearest_character
local nearest_screenpoint
local last_time = 0
local frame_rate = 60
local frame_delta = 1 / frame_rate
local mousemoverel = genv.mousemoverel

connect(ui_ffabutton.MouseButton1Up, function()
    local newvalue = not ffa
    if not trysave({ ffa = newvalue }) then
        ui_ffacheck.TextColor3 = Color3.new(1, 0.3, 0.3)
        task.delay(1, function() ui_ffacheck.TextColor3 = Color3.new(1, 1, 1) end)
        return
    end
    ffa = newvalue
    ui_ffacheck.Text = ffa and check or blank
    for _, entry in pairs(content) do
        entry:enabled(can_track(entry.player))
    end
end)

connect(ui_espbutton.MouseButton1Up, function()
    local newvalue = not esp
    if not trysave({ esp = newvalue }) then
        ui_espcheck.TextColor3 = Color3.new(1, 0.3, 0.3)
        task.delay(1, function() ui_espcheck.TextColor3 = Color3.new(1, 1, 1) end)
        return
    end
    esp = newvalue
    ui_espcheck.Text = esp and check or blank
    for _, entry in pairs(content) do
        entry:enabled(can_track(entry.player))
    end
end)

connect(ui_aimbutton.MouseButton1Up, function()
    local newvalue = not aimbot
    if not trysave({ aimbot = newvalue }) then
        ui_aimcheck.TextColor3 = Color3.new(1, 0.3, 0.3)
        task.delay(1, function() ui_aimcheck.TextColor3 = Color3.new(1, 1, 1) end)
        return
    end
    aimbot = newvalue
    ui_aimcheck.Text = aimbot and check or blank
    ui_circle.Visible = aimbot
end)

connect(runservice.Stepped, function(time, delta_time)
    current_target = nearest_character
    nearest_character, nearest_screenpoint = get_nearest_character(current_target)
    if aimbot and (mousebutton1down or mousebutton2down) and nearest_character and nearest_screenpoint and
        (time > last_time + frame_delta or delta_time > frame_delta) then
        last_time = time
        nearest_player = players:GetPlayerFromCharacter(nearest_character)
        if nearest_player then
            content[nearest_player]:color(color_scheme['nearest'])
        end
        mousemoverel((nearest_screenpoint.X - playermouse.X) * sens, (nearest_screenpoint.Y - playermouse.Y) * sens)
        ui_circle.Position = UDim2.fromOffset(nearest_screenpoint.X, nearest_screenpoint.Y)
    end
end)

genv.stop_aim_assistant = function()
    for _, connection in pairs(connections) do
        if typeof(connection) == 'RBXScriptConnection' and connection.Connected then
            pcall(connection.Disconnect, connection)
        end
    end
    for _, instance in pairs(instances) do
        if typeof(instance) == 'Instance' then
            pcall(instance.Destroy, instance)
        end
    end
    for _, entry in pairs(content) do
        if type(entry) == 'table' then
            pcall(entry.destroy, entry)
        end
    end
    content = nil
    connections = nil
    instances = nil
end