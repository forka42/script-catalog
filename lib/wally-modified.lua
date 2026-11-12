--[=[
	updates & optimizations by forka42
    ---
    https://github.com/forka42
]=]

--!strict
local pgui = select(2, pcall(game.GetService, game, 'CoreGui'))
local mode = 'core'
local player = game:GetService('Players').LocalPlayer
if typeof(pgui) ~= 'Instance' and typeof(player) == 'Instance' and player:IsA('Player') then
	pgui = player:FindFirstChildWhichIsA('PlayerGui')
		or player:WaitForChild('PlayerGui')
	mode = 'player'
	assert(typeof(pgui) == 'Instance' and pgui:IsA('PlayerGui'), `Invalid PlayerGui for {script.Name} ({script:GetFullName()})`)
end
local dragger, types = {}, {}
local func_identity: (...any) -> () = function() end

local TweenService = game:GetService('TweenService')
local TextService = game:GetService('TextService')
local UserInputService = game:GetService('UserInputService')

type WallyUIConfiguration = {
	topcolor: Color3;
	titlecolor: Color3;
	underlinecolor: Color3;
	bgcolor: Color3;
	boxcolor: Color3;
	btncolor: Color3;
	dropcolor: Color3;
	sectncolor: Color3;
	bordercolor: Color3;
	font: Enum.Font;
	titlefont: Enum.Font;
	fontsize: number;
	titlesize: number;
	textstroke: number;
	titlestroke: number;
	strokecolor: Color3;
	textcolor: Color3;
	titletextcolor: Color3;
	placeholdercolor: Color3;
	titlestrokecolor: Color3 }
local library: any = { 
	count = 0, 
	queue = {}, 
	callbacks = {}, 
	toggled = true, 
	binds = {} :: {
		[string]: {
			location: { [any]: any },
			callback: (...any) -> (),
		}
	} 
}
local userOptions: { [string]: any } = {}
do
	local c = Instance.new('ScreenGui')
	c.ResetOnSpawn = false
	if mode == 'core' then
		c.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end
	c.Parent = pgui
	library.container = c
end
local defaults: WallyUIConfiguration = {
	topcolor = Color3.fromRGB(30, 30, 30);
	titlecolor = Color3.fromRGB(255, 255, 255);
	underlinecolor = Color3.fromRGB(0, 255, 140);
	bgcolor = Color3.fromRGB(35, 35, 35);
	boxcolor = Color3.fromRGB(35, 35, 35);
	btncolor = Color3.fromRGB(25, 25, 25);
	dropcolor = Color3.fromRGB(25, 25, 25);
	sectncolor = Color3.fromRGB(25, 25, 25);
	bordercolor = Color3.fromRGB(60, 60, 60);
	font = Enum.Font.SourceSans;
	titlefont = Enum.Font.Code;
	fontsize = 17;
	titlesize = 18;
	textstroke = 1;
	titlestroke = 1;
	strokecolor = Color3.fromRGB(0, 0, 0);
	textcolor = Color3.fromRGB(255, 255, 255);
	titletextcolor = Color3.fromRGB(255, 255, 255);
	placeholdercolor = Color3.fromRGB(255, 255, 255);
	titlestrokecolor = Color3.fromRGB(0, 0, 0) }
local blank = ''

--[=[ dragger ]=] do
	function dragger.new(frame: GuiObject): ()
		local dragging: boolean = false
		local dragInput: InputObject? = nil
		local dragStart: Vector3? = nil
		local startPos: UDim2? = nil

		local function update(input: InputObject)
			if dragStart and startPos then
				local delta: Vector3 = input.Position - dragStart
				frame.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end

		frame.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		frame.InputChanged:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UserInputService.InputChanged:Connect(function(input: InputObject)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(key: InputObject, gpe: boolean)
		if not gpe then
			if key.KeyCode == Enum.KeyCode.RightControl then
				library.toggled = not library.toggled

				for _, data: { [any]: any } in library.queue do
					local p = rawget(data, "p") :: UDim2?
					local w = rawget(data, "w") :: Instance?
					local pos: UDim2 = UDim2.fromScale(-1, -0.5)

					if typeof(p) == "UDim2" and library.toggled then
						pos = p
					end

					if w and w:IsA("GuiObject") then
						local tweenInfo = TweenInfo.new(
							0.15,
							Enum.EasingStyle.Quad,
							if library.toggled then Enum.EasingDirection.Out else Enum.EasingDirection.In
						)
						TweenService:Create(w, tweenInfo, { Position = pos }):Play()
					end

					task.wait()
				end
			end
		end
	end)
end

--[=[ types ]=] do
	types.__index = types;
	function types.window(name: string, config: WallyUIConfiguration)
		library.count += 1
		local newWindow = library:Create('Frame', {
			Name = name;
			Size = UDim2.new(0, 190, 0, 30);
			BackgroundColor3 = config.topcolor;
			BorderSizePixel = 0;
			Parent = library.container;
			Position = UDim2.new(0, (15 + (200 * library.count) - 200), 0, 0);
			ZIndex = 3;
			library:Create('TextLabel', {
				Text = name;
				Size = UDim2.new(1, -10, 1, 0);
				Position = UDim2.new(0, 5, 0, 0);
				BackgroundTransparency = 1;
				TextSize = config.titlesize;
				Font = config.titlefont;
				TextColor3 = config.titletextcolor;
				TextStrokeTransparency = library.options.titlestroke;
				TextStrokeColor3 = library.options.titlestrokecolor;
				ZIndex = 3 }),
			library:Create('TextButton', {
				Size = UDim2.new(0, 30, 0, 30);
				Position = UDim2.new(1, -35, 0, 0);
				BackgroundTransparency = 1;
				Text = '-';
				TextSize = config.titlesize;
				Font = config.titlefont;
				Name = 'window_toggle';
				TextColor3 = config.titletextcolor;
				TextStrokeTransparency = library.options.titlestroke;
				TextStrokeColor3 = library.options.titlestrokecolor;
				ZIndex = 3 }),
			library:Create('Frame', {
				Name = 'Underline',
				Size = UDim2.new(1, 0, 0, 2),
				Position = UDim2.new(0, 0, 1, -2),
				BackgroundColor3 = config.underlinecolor,
				BorderSizePixel = 0,
				ZIndex = 3 }),
			library:Create('Frame', {
				Name = 'container',
				Position = UDim2.new(0, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, 0),
				BorderSizePixel = 0,
				BackgroundColor3 = config.bgcolor,
				ClipsDescendants = false,
				library:Create('UIListLayout', {
					Name = 'List';
					SortOrder = Enum.SortOrder.LayoutOrder })
			})
		})

		local window = setmetatable({
			count = 0;
			object = newWindow;
			container = newWindow.container;
			toggled = true;
			flags   = {};

		}, types)

		table.insert(library.queue, {
			w = window.object;
			p = window.object.Position;
		})

		newWindow:FindFirstChild('window_toggle').MouseButton1Click:Connect(function()
			window.toggled = not window.toggled;
			newWindow:FindFirstChild('window_toggle').Text = (window.toggled and '+' or '-')
			if (not window.toggled) then
				window.container.ClipsDescendants = true;
			end
			task.wait();
			local y = 0;
			for i, v in next, window.container:GetChildren() do
				if (not v:IsA('UIListLayout')) then
					y = y + v.AbsoluteSize.Y;
				end
			end 

			local targetSize = if window.toggled then UDim2.new(1, 0, 0, y + 5) else UDim2.new(1, 0, 0, 0)
			local targetDirection = if window.toggled then Enum.EasingDirection.In else Enum.EasingDirection.Out

			TweenService:Create(
				window.container,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, targetDirection),
				{ Size = targetSize }
			):Play()
			task.wait(0.15)
			if window.toggled then
				window.container.ClipsDescendants = false;
			end
		end)

		return window;
	end

	function types.Resize(self: any)
		local y = 0;
		for i, v in next, self.container:GetChildren() do
			if (not v:IsA('UIListLayout')) then
				y = y + v.AbsoluteSize.Y;
			end
		end 
		self.container.Size = UDim2.new(1, 0, 0, y+5)
	end

	function types.GetOrder(self: any) 
		local c = 0;
		for i, v in next, self.container:GetChildren() do
			if (not v:IsA('UIListLayout')) then
				c = c + 1
			end
		end
		return c
	end

	function types.Label(self: any, text: string, rich: boolean)
		local label = library:Create('TextLabel', {
			Size = UDim2.new(1, 0, 1, 0);
			Position = UDim2.new(0, 10, 0, 0);
			LayoutOrder = self:GetOrder();
			Text = text,
			TextSize = 18,
			RichText = rich == true,
			Font = Enum.Font.SourceSans;
			TextColor3 = Color3.fromRGB(255, 255, 255);
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextWrapped = true })
		local textsize = TextService:GetTextSize(text, label.TextSize, label.Font, Vector2.one * math.huge)
		local content = library:Create('Frame', {
			Size = UDim2.new(1, 0, 0, textsize.Y + 5);
			BackgroundTransparency  = 1;
			Parent = self.container })
		label.Parent = content
		self:Resize();
	end

	function types.Toggle(self: any, name: string, config: { [string]: any }, func: ((...any) -> ())?)
		local default = config.default or false;
		local location = config.location or self.flags;
		local flag = config.flag or blank;
		local callback = func or func_identity
		rawset(location, flag, default)

		local check = library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 25);
			LayoutOrder = self:GetOrder();
			library:Create('TextLabel', {
				Name = name;
				Text = '\r' .. name;
				BackgroundTransparency = 1;
				TextColor3 = library.options.textcolor;
				Position = UDim2.new(0, 5, 0, 0);
				Size     = UDim2.new(1, -5, 1, 0);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = library.options.font;
				TextSize = library.options.fontsize;
				TextStrokeTransparency = library.options.textstroke;
				TextStrokeColor3 = library.options.strokecolor;
				library:Create('TextButton', {
					Text = (location[flag] and utf8.char(10003) or blank);
					Font = library.options.font;
					TextSize = library.options.fontsize;
					Name = 'Checkmark';
					Size = UDim2.new(0, 20, 0, 20);
					Position = UDim2.new(1, -25, 0, 4);
					TextColor3 = library.options.textcolor;
					BackgroundColor3 = library.options.bgcolor;
					BorderColor3 = library.options.bordercolor;
					TextStrokeTransparency = library.options.textstroke;
					TextStrokeColor3 = library.options.strokecolor }) }),
			Parent = self.container;
		});

		local function click(t)
			location[flag] = not location[flag]
			local x = location[flag]; callback(x)
			check:FindFirstChild(name).Checkmark.Text = x and utf8.char(10003) or blank
		end

		local Button = check:FindFirstChild(name)
		local Connection = Button.Checkmark.MouseButton1Click:Connect(click)
		library.callbacks[flag] = click;

		if location[flag] == true then
			callback(location[flag])
		end

		self:Resize();
		return {
			['SetCallback'] = function(self, value)
				local __function = (typeof(self) == 'function' and self) or value
				pcall(function() Connection:Disconnect(); Connection = nil end)
				callback = __function
				Connection = Button.MouseButton1Click:Connect(callback)
			end,
			['GetInstance'] = function(self, value)
				return Button
			end,
			Set = function(self, b)
				location[flag] = b;
				callback(location[flag])
				check:FindFirstChild(name).Checkmark.Text = location[flag] and utf8.char(10003) or blank;
			end,
		}
	end

	function types.Button(self: any, name: string, func: ((...any) -> ())?)
		local callback: (...any) -> ...any = func or func_identity
		local check = library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 25);
			LayoutOrder = self:GetOrder();
			library:Create('TextButton', {
				Name = name;
				Text = name;
				BackgroundColor3 = library.options.btncolor;
				BorderColor3 = library.options.bordercolor;
				TextStrokeTransparency = library.options.textstroke;
				TextStrokeColor3 = library.options.strokecolor;
				TextColor3 = library.options.textcolor;
				Position = UDim2.new(0, 5, 0, 5);
				Size     = UDim2.new(1, -10, 0, 20);
				Font = library.options.font;
				TextSize = library.options.fontsize;
			});
			Parent = self.container;
		});
		local Button = check:FindFirstChild(name)
		local Connection = Button.MouseButton1Click:Connect(callback)
		self:Resize()
		local index = {
			SetCallback = function(self, value)
				local __function = (typeof(self) == 'function' and self) or value
				pcall(function() Connection:Disconnect(); Connection = nil end)
				callback = __function
				Connection = Button.MouseButton1Click:Connect(callback)
			end,
			GetInstance = function(self, value)
				return Button
			end,
			Fire = function()
				return pcall(callback)
			end }
		return index
	end

	function types.Box(self: any, name: string, config: { [string]: any }, func: ((...any) -> ())?)
		local boxType = config.type or blank
		local default = config.default or blank
		local location = config.location or self.flags
		local flag = config.flag or blank
		local callback = func or func_identity
		local min = config.min or 0
		local max = config.max or 9e9

		if boxType == 'number' and (not tonumber(default)) then
			location[flag] = default;
		else
			location[flag] = blank;
			default = blank;
		end

		local check = library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 25);
			LayoutOrder = self:GetOrder();
			library:Create('TextLabel', {
				Name = name;
				Text = '\r' .. name;
				BackgroundTransparency = 1;
				TextColor3 = library.options.textcolor;
				TextStrokeTransparency = library.options.textstroke;
				TextStrokeColor3 = library.options.strokecolor;
				Position = UDim2.new(0, 5, 0, 0);
				Size     = UDim2.new(1, -5, 1, 0);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = library.options.font;
				TextSize = library.options.fontsize;
				library:Create('TextBox', {
					TextStrokeTransparency = library.options.textstroke;
					TextStrokeColor3 = library.options.strokecolor;
					Text = tostring(default);
					Font = library.options.font;
					TextSize = library.options.fontsize;
					Name = 'Box';
					Size = UDim2.new(0, 60, 0, 20);
					Position = UDim2.new(1, -65, 0, 3);
					TextColor3 = library.options.textcolor;
					BackgroundColor3 = library.options.boxcolor;
					BorderColor3 = library.options.bordercolor;
					PlaceholderColor3 = library.options.placeholdercolor }) }),
			Parent = self.container
		});

		local box = check:FindFirstChild(name):FindFirstChild('Box');
		box.FocusLost:Connect(function(e)
			local old = location[flag];
			if boxType == 'number' then
				local num = tonumber(box.Text)
				if (not num) then
					box.Text = tostring(location[flag])
				else
					location[flag] = math.clamp(num, min, max)
					box.Text = tostring(location[flag])
				end
			else
				location[flag] = tostring(box.Text)
			end

			callback(location[flag], old, e)
		end)

		if boxType == 'number' then
			box:GetPropertyChangedSignal('Text'):Connect(function()
				box.Text = (string.gsub(box.Text, '[%a+]', blank))
			end)
		end

		self:Resize()
		return box
	end

	function types.Bind(self: any, name: string, config: { [string]: any }, func: ((...any) -> ())?)
		local location = config.location or self.flags
		local keyboardOnly = config.kbonly or false
		local flag = config.flag or blank
		local callback = func or func_identity
		local default = config.default
		local passed = true

		if keyboardOnly and (tostring(default):find('MouseButton')) then passed = false end
		if passed then location[flag] = default end

		local banned = {
			Return = true;
			Space = true;
			Tab = true;
			Unknown = true;
		}

		local shortNames = {
			RightControl = 'RightCtrl';
			LeftControl = 'LeftCtrl';
			LeftShift = 'LShift';
			RightShift = 'RShift';
			MouseButton1 = 'Mouse1';
			MouseButton2 = 'Mouse2';
		}

		local allowed = {
			MouseButton1 = true;
			MouseButton2 = true;
		}      

		local nm = (default and (shortNames[default.Name] or default.Name) or 'None');
		local check = library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 30);
			LayoutOrder = self:GetOrder();
			library:Create('TextLabel', {
				Name = name;
				Text = '\r' .. name;
				BackgroundTransparency = 1;
				TextColor3 = library.options.textcolor;
				Position = UDim2.new(0, 5, 0, 0);
				Size     = UDim2.new(1, -5, 1, 0);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = library.options.font;
				TextSize = library.options.fontsize;
				TextStrokeTransparency = library.options.textstroke;
				TextStrokeColor3 = library.options.strokecolor;
				BorderColor3     = library.options.bordercolor;
				BorderSizePixel  = 1;
				library:Create('TextButton', {
					Name = 'Keybind';
					Text = nm;
					TextStrokeTransparency = library.options.textstroke;
					TextStrokeColor3 = library.options.strokecolor;
					Font = library.options.font;
					TextSize = library.options.fontsize;
					Size = UDim2.new(0, 60, 0, 20);
					Position = UDim2.new(1, -65, 0, 5);
					TextColor3 = library.options.textcolor;
					BackgroundColor3 = library.options.bgcolor;
					BorderColor3 = library.options.bordercolor;
					BorderSizePixel = 1;
				})
			});
			Parent = self.container;
		});

		local button = check:FindFirstChild(name).Keybind;
		button.MouseButton1Click:Connect(function()
			library.binding = true
			button.Text = '...'
			local a = UserInputService.InputBegan:Wait();
			if (a.UserInputType ~= Enum.UserInputType.Keyboard and (allowed[a.UserInputType.Name]) and (not keyboardOnly)) or (a.KeyCode and (not banned[a.KeyCode.Name])) then
				local name = (a.UserInputType ~= Enum.UserInputType.Keyboard and a.UserInputType.Name or a.KeyCode.Name);
				location[flag] = (a);
				button.Text = shortNames[name] or name;
			elseif (location[flag]) then
				if (not pcall(function()
						return location[flag].UserInputType
					end)) then
					local name = tostring(location[flag])
					button.Text = shortNames[name] or name
				else
					local name = (location[flag].UserInputType ~= Enum.UserInputType.Keyboard and location[flag].UserInputType.Name or location[flag].KeyCode.Name);
					button.Text = shortNames[name] or name;
				end
			end
			task.wait(0.1)  
			library.binding = false;
		end)

		if location[flag] then
			button.Text = shortNames[tostring(location[flag].Name)] or tostring(location[flag].Name)
		end

		library.binds[flag] = {
			location = location;
			callback = callback;
		};

		self:Resize();
	end

	function types.Section(self: any, name: string)
		local order = self:GetOrder();
		local determinedSize = UDim2.new(1, 0, 0, 25)
		local determinedPos = UDim2.new(0, 0, 0, 4);
		local secondarySize: UDim2? = UDim2.new(1, 0, 0, 20);

		if order == 0 then
			determinedSize = UDim2.new(1, 0, 0, 21)
			determinedPos = UDim2.new(0, 0, 0, -1);
			secondarySize = nil
		end

		local check = library:Create('Frame', {
			Name = 'Section';
			BackgroundTransparency = 1;
			Size = determinedSize;
			BackgroundColor3 = library.options.sectncolor;
			BorderSizePixel = 0;
			LayoutOrder = order;
			library:Create('TextLabel', {
				Name = 'section_lbl';
				Text = name;
				BackgroundTransparency = 0;
				BorderSizePixel = 0;
				BackgroundColor3 = library.options.sectncolor;
				TextColor3 = library.options.textcolor;
				Position = determinedPos;
				Size = (secondarySize or UDim2.new(1, 0, 1, 0));
				Font = library.options.font;
				TextSize = library.options.fontsize;
				TextStrokeTransparency = library.options.textstroke;
				TextStrokeColor3 = library.options.strokecolor;
			});
			Parent = self.container;
		});

		self:Resize();
		return check
	end

	function types.Slider(self: any, name: string, config: { [string]: any }?, func: ((...any) -> ())?)
		local cfg: { [string]: any } = config or {}

		local min: number = cfg.min or 0
		local max: number = cfg.max or 1
		local default: number = cfg.default or min
		local location: { [any]: any } = cfg.location or self.flags
		local precise: boolean = cfg.precise == true
		local flag: string = cfg.flag or blank
		local callback: (...any) -> () = func or func_identity

		location[flag] = default

		local check = library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 25);
			LayoutOrder = self:GetOrder();
			library:Create('TextLabel', {
				Name = name;
				TextStrokeTransparency = library.options.textstroke;
				TextStrokeColor3 = library.options.strokecolor;
				Text = '\r' .. name;
				BackgroundTransparency = 1;
				TextColor3 = library.options.textcolor;
				Position = UDim2.new(0, 5, 0, 2);
				Size     = UDim2.new(1, -5, 1, 0);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = library.options.font;
				TextSize = library.options.fontsize;
				library:Create('Frame', {
					Name = 'Container';
					Size = UDim2.new(0, 60, 0, 20);
					Position = UDim2.new(1, -65, 0, 3);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					library:Create('TextLabel', {
						Name = 'ValueLabel';
						Text = tostring(default);
						BackgroundTransparency = 1;
						TextColor3 = library.options.textcolor;
						Position = UDim2.new(0, -10, 0, 0);
						Size     = UDim2.new(0, 1, 1, 0);
						TextXAlignment = Enum.TextXAlignment.Right;
						Font = library.options.font;
						TextSize = library.options.fontsize;
						TextStrokeTransparency = library.options.textstroke;
						TextStrokeColor3 = library.options.strokecolor;
					});
					library:Create('TextButton', {
						Name = 'Button';
						Size = UDim2.new(0, 5, 1, -2);
						Position = UDim2.new(0, 0, 0, 1);
						AutoButtonColor = false;
						Text = blank;
						BackgroundColor3 = Color3.fromRGB(20, 20, 20);
						BorderSizePixel = 0;
						ZIndex = 2;
						TextStrokeTransparency = library.options.textstroke;
						TextStrokeColor3 = library.options.strokecolor;
					});
					library:Create('Frame', {
						Name = 'Line';
						BackgroundTransparency = 0;
						Position = UDim2.new(0, 0, 0.5, 0);
						Size     = UDim2.new(1, 0, 0, 1);
						BackgroundColor3 = Color3.fromRGB(255, 255, 255);
						BorderSizePixel = 0;
					});
				})
			});
			Parent = self.container;
		})

		local container = (check:FindFirstChild(name) :: any):FindFirstChild('Container') :: any
		assert(container, 'Slider: missing Container')

		local sliderButton = container.Button :: TextButton
		local valueLabel = container.ValueLabel :: TextLabel

		local function round2(n: number): number
			return math.round(n * 100) / 100
		end

		local function toValue(n: number): number
			local rounded = round2(n)
			return if precise then rounded else math.floor(rounded)
		end

		-- Moves the knob and label to match `value` (no callback)
		local function render(value: number)
			local range = max - min
			local percent = if range ~= 0 then 1 - ((max - value) / range) else 0
			sliderButton.Position = UDim2.new(math.clamp(percent, 0, 0.99), 0, 0, 1)
			valueLabel.Text = tostring(value)
		end

		local renderSteppedConnection: RBXScriptConnection? = nil
		local inputBeganConnection: RBXScriptConnection? = nil
		local inputEndedConnection: RBXScriptConnection? = nil
		local mouseDownConnection: RBXScriptConnection? = nil
		local mouseUpConnection: RBXScriptConnection? = nil

		local function update()
			if renderSteppedConnection then renderSteppedConnection:Disconnect() end
			renderSteppedConnection = game:GetService('RunService').RenderStepped:Connect(function()
				local width = container.AbsoluteSize.X
				if width <= 0 then return end

				local mouse = UserInputService:GetMouseLocation()
				local percent = math.clamp((mouse.X - container.AbsolutePosition.X) / width, 0, 1)
				percent = round2(percent)

				sliderButton.Position = UDim2.new(math.clamp(percent, 0, 0.99), 0, 0, 1)

				local value = toValue(min + (max - min) * percent)
				valueLabel.Text = tostring(value)
				location[flag] = value
				callback(value)
			end)
		end

		local function disconnect()
			if renderSteppedConnection then 
				renderSteppedConnection:Disconnect() 
				renderSteppedConnection = nil 
			end
			if inputBeganConnection then 
				inputBeganConnection:Disconnect() 
				inputBeganConnection = nil 
			end
			if inputEndedConnection then 
				inputEndedConnection:Disconnect() 
				inputEndedConnection = nil 
			end
			if mouseDownConnection then 
				mouseDownConnection:Disconnect() 
				mouseDownConnection = nil 
			end
			if mouseUpConnection then 
				mouseUpConnection:Disconnect() 
				mouseUpConnection = nil 
			end
		end

		container.MouseEnter:Connect(function()
			disconnect() -- clear leftovers from a previous hover so connections don't stack

			inputBeganConnection = container.InputBegan:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then update() end
			end)
			inputEndedConnection = container.InputEnded:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then disconnect() end
			end)
			mouseDownConnection = sliderButton.MouseButton1Down:Connect(update)
			mouseUpConnection = UserInputService.InputEnded:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					and mouseDownConnection and mouseDownConnection.Connected then
					disconnect()
				end
			end)
		end)

		if default ~= min then
			render(toValue(default))
		end

		self:Resize()

		return {
			Set = function(_self: any, value: number)
				local number = toValue(value)
				render(number)
				location[flag] = number
				callback(number)
			end,
		}
	end

	function types.SearchBox(self: any, text: string, config: { [string]: any }, func: ((...any) -> ())?)
		local list = config.list or {};
		local flag = config.flag or blank;
		local location = config.location or self.flags;
		local callback = func or func_identity;

		local busy = false;
		local box = library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 25);
			LayoutOrder = self:GetOrder();
			library:Create('TextBox', {
				Text = blank;
				PlaceholderText = text;
				PlaceholderColor3 = Color3.fromRGB(60, 60, 60);
				Font = library.options.font;
				TextSize = library.options.fontsize;
				Name = 'Box';
				Size = UDim2.new(1, -10, 0, 20);
				Position = UDim2.new(0, 5, 0, 4);
				TextColor3 = library.options.textcolor;
				BackgroundColor3 = library.options.dropcolor;
				BorderColor3 = library.options.bordercolor;
				TextStrokeTransparency = library.options.textstroke;
				TextStrokeColor3 = library.options.strokecolor;
				library:Create('ScrollingFrame', {
					Position = UDim2.new(0, 0, 1, 1);
					Name = 'Container';
					BackgroundColor3 = library.options.btncolor;
					ScrollBarThickness = 0;
					BorderSizePixel = 0;
					BorderColor3 = library.options.bordercolor;
					Size = UDim2.new(1, 0, 0, 0);
					library:Create('UIListLayout', {
						Name = 'ListLayout';
						SortOrder = Enum.SortOrder.LayoutOrder;
					});
					ZIndex = 2;
				});
			});
			Parent = self.container;
		})

		local textBox = box:FindFirstChild('Box') :: TextBox
		local dropList = textBox:FindFirstChild('Container') :: ScrollingFrame
		assert(textBox and dropList, 'SearchBox: missing Box/Container')

		local ROW_HEIGHT = 20
		local MAX_HEIGHT = 100
		local currentTween: Tween? = nil

		local function tweenListSize(height: number)
			if currentTween then
				currentTween:Cancel()
			end
			local tween = TweenService:Create(
				dropList,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(1, 0, 0, height) }
			)
			currentTween = tween
			tween:Play()
		end

		local function clearList()
			dropList.ScrollBarThickness = 0
			for _, child in dropList:GetChildren() do
				if not child:IsA('UIListLayout') then
					child:Destroy()
				end
			end
		end

		local function rebuild(query: string)
			if not dropList.Parent then return end -- gui was destroyed

			clearList()

			local count = 0
			local lowerQuery = string.lower(query)

			if #query > 0 then
				for i, v in list do
					local item = tostring(v)
					if string.sub(string.lower(item), 1, #lowerQuery) == lowerQuery then
						count += 1

						local button: TextButton = library:Create('TextButton', {
							Text = item;
							Font = library.options.font;
							TextSize = library.options.fontsize;
							TextColor3 = library.options.textcolor;
							BorderColor3 = library.options.bordercolor;
							TextStrokeTransparency = library.options.textstroke;
							TextStrokeColor3 = library.options.strokecolor;
							Parent = dropList;
							Size = UDim2.new(1, 0, 0, ROW_HEIGHT);
							LayoutOrder = i;
							BackgroundColor3 = library.options.btncolor;
							ZIndex = 2;
						})

						button.MouseButton1Click:Connect(function()
							busy = true
							textBox.Text = item
							task.wait()
							busy = false

							location[flag] = item
							callback(item)

							clearList()
							tweenListSize(0)
						end)
					end
				end
			end

			local contentHeight = ROW_HEIGHT * count
			dropList.ScrollBarThickness = if contentHeight > MAX_HEIGHT then 5 else 0
			dropList.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
			tweenListSize(math.min(contentHeight, MAX_HEIGHT))
		end

		textBox:GetPropertyChangedSignal('Text'):Connect(function()
			if not busy then
				rebuild(textBox.Text)
			end
		end)

		local function reload(new_list)
			list = new_list;
			rebuild(blank)
		end
			
		self:Resize()
		return reload, textBox
	end

	function types.Dropdown(self: any, name: string, config: { [string]: any }, func: ((...any) -> ())?)
		if type(config) ~= 'table' then config = {} end
		local location = config.location or self.flags;
		local flag = config.flag or blank;
		local callback = func or func_identity
		local list = config.list or {};

		location[flag] = list[1]
		local check = library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 25);
			BackgroundColor3 = Color3.fromRGB(25, 25, 25);
			BorderSizePixel = 0;
			LayoutOrder = self:GetOrder();
			library:Create('Frame', {
				Name = 'dropdown_lbl';
				BackgroundTransparency = 0;
				BackgroundColor3 = library.options.dropcolor;
				Position = UDim2.new(0, 5, 0, 4);
				BorderColor3 = library.options.bordercolor;
				Size     = UDim2.new(1, -10, 0, 20);
				library:Create('TextLabel', {
					Name = 'Selection';
					Size = UDim2.new(1, 0, 1, 0);
					Text = list[1];
					TextColor3 = library.options.textcolor;
					BackgroundTransparency = 1;
					Font = library.options.font;
					TextSize = library.options.fontsize;
					TextStrokeTransparency = library.options.textstroke;
					TextStrokeColor3 = library.options.strokecolor;
				});
				library:Create('TextButton', {
					Name = 'drop';
					BackgroundTransparency = 1;
					Size = UDim2.new(0, 20, 1, 0);
					Position = UDim2.new(1, -25, 0, 0);
					Text = 'v';
					TextColor3 = library.options.textcolor;
					Font = library.options.font;
					TextSize = library.options.fontsize;
					TextStrokeTransparency = library.options.textstroke;
					TextStrokeColor3 = library.options.strokecolor;
				})
			});
			Parent = self.container;
		});

		local button = check:FindFirstChild('dropdown_lbl').drop;
		local container: ScrollingFrame? = nil
		local input: RBXScriptConnection? = nil

		local function closeDrop()
			if input then
				input:Disconnect()
				input = nil
			end
			if container then
				container:Destroy()
				container = nil
			end
		end

		button.MouseButton1Click:Connect(function()
			if (input and input.Connected) then
				return
			end 

			check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = Color3.fromRGB(60, 60, 60);
			check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text = name;
			local c = 0;
			for i, v in next, list do
				c = c + 20;
			end

			local size = UDim2.new(1, 0, 0, c)

			local clampedSize: UDim2?
			local scrollSize = 0;
			if size.Y.Offset > 100 then
				clampedSize = UDim2.new(1, 0, 0, 100)
				scrollSize = 5;
			end

			local goSize = (clampedSize ~= nil and clampedSize) or size;    
			container = library:Create('ScrollingFrame', {
				TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
				BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
				Name = 'DropContainer';
				Parent = check:FindFirstChild('dropdown_lbl');
				Size = UDim2.new(1, 0, 0, 0);
				BackgroundColor3 = library.options.bgcolor;
				BorderColor3 = library.options.bordercolor;
				Position = UDim2.new(0, 0, 1, 0);
				ScrollBarThickness = scrollSize;
				CanvasSize = UDim2.new(0, 0, 0, size.Y.Offset);
				ZIndex = 5;
				ClipsDescendants = true;
				library:Create('UIListLayout', {
					Name = 'List';
					SortOrder = Enum.SortOrder.LayoutOrder
				})
			})

			for i, v in next, list do
				local btn = library:Create('TextButton', {
					Size = UDim2.new(1, 0, 0, 20);
					BackgroundColor3 = library.options.btncolor;
					BorderColor3 = library.options.bordercolor;
					Text = v;
					Font = library.options.font;
					TextSize = library.options.fontsize;
					LayoutOrder = i;
					Parent = container;
					ZIndex = 5;
					TextColor3 = library.options.textcolor;
					TextStrokeTransparency = library.options.textstroke;
					TextStrokeColor3 = library.options.strokecolor;
				})

				btn.MouseButton1Click:Connect(function()
					check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
					check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text = btn.Text;

					location[flag] = tostring(btn.Text)
					callback(location[flag])
					closeDrop()

					if typeof(input) == 'RBXScriptConnection' and input.Connected then
						input:Disconnect()
					end
				end)
			end

			if typeof(container) == 'Instance' and container:IsA('ScrollingFrame') then
				TweenService:Create(container, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { Size = goSize }):Play()
			end

			local function isInGui(frame: GuiObject?)
				if typeof(frame) == 'Instance' and frame:IsA('GuiObject') then
					local mloc = UserInputService:GetMouseLocation()
					local mouse = Vector2.new(mloc.X, mloc.Y - 36)

					local x1, x2 = frame.AbsolutePosition.X, frame.AbsolutePosition.X + frame.AbsoluteSize.X
					local y1, y2 = frame.AbsolutePosition.Y, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y

					return (mouse.X >= x1 and mouse.X <= x2) and (mouse.Y >= y1 and mouse.Y <= y2)
				end
				return false
			end

			input = UserInputService.InputBegan:Connect(function(a: InputObject)
				if a.UserInputType == Enum.UserInputType.MouseButton1 and container and not isInGui(container) then
					local selection = check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection') :: TextLabel
					selection.TextColor3 = library.options.textcolor
					selection.Text = location[flag]

					local closeTween = TweenService:Create(
						container,
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Size = UDim2.new(1, 0, 0, 0) }
					)
					closeTween:Play()
					closeTween.Completed:Wait()

					closeDrop()
				end
			end)
		end)

		self:Resize();
		local function reload(_self: any, array: { string })
			list = array
			location[flag] = array[1]
			closeDrop()
			local selection = check:WaitForChild('dropdown_lbl').Selection :: TextLabel
			selection.Text = location[flag]
			selection.TextColor3 = library.options.textcolor
		end

		return {
			Refresh = reload;
		}
	end
end

--[=[ library ]=] do
	function library:Create(class: string, data: { [any]: any }): any
		local obj = Instance.new(class)
		for i, v in data do
			if i ~= 'Parent' then
				if typeof(v) == 'Instance' then
					v.Parent = obj
				else
					(obj :: any)[i] = v
				end
			end
		end
		obj.Parent = data.Parent
		return obj
	end

	function library:CreateWindow(name: string, options: { [string]: any }?)
		if options then
			for k, v in options do
				userOptions[k] = v
			end
		end
		local window = types.window(name, library.options)
		dragger.new(window.object)
		return window
	end

	library.options = setmetatable({}, {
		__index = function(_, i: string)
			local option = rawget(userOptions, i)
			local default = (defaults :: any)[i]
			if typeof(option) == typeof(default) then return option end
			return default
		end,
	})

	local function isreallypressed(bind: any, inp: InputObject): boolean
		if typeof(bind) == 'Instance' then
			local inst = bind :: Instance
			if inst:IsA('InputObject') then
				local bound = inst :: InputObject
				if bound.UserInputType == Enum.UserInputType.Keyboard then
					return inp.KeyCode == bound.KeyCode
				elseif string.find(bound.UserInputType.Name, 'MouseButton', 1, true) ~= nil then
					return inp.UserInputType == bound.UserInputType
				end
			end
			return false
		end

		if string.find(tostring(bind), 'MouseButton1', 1, true) ~= nil then
			return bind == inp.UserInputType
		end
		return bind == inp.KeyCode
	end

	UserInputService.InputBegan:Connect(function(input: InputObject)
		if library.binding then return end
		for flag, bind in library.binds do
			local realBinding = bind.location[flag]
			if realBinding and isreallypressed(realBinding, input) then
				bind.callback()
			end
		end
	end)
end

return library