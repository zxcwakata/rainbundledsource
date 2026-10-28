-- Timing Builder.
--
-- Отдельное окно поверх меню. Включается тумблером "Show Timing Builder"
-- в Combat -> Timing Builder.
--
-- Как работает:
--   * Timing Logger смотрит анимации и клик по записи кормит сюда трек
--     (builder:load_track) — id и длину подставляет сам, windup = 55% длины;
--   * либо id вбивается руками;
--   * Save пишет rw_timings/<Name>.lua и перезагружает тайминги;
--   * чтением rw_timings занимается getgenv().load_timings() в animator-handler.
--
-- Окно сделано на собственном ScreenGui, а не на gethui()/CoreGui: на части
-- исполнителей тот контейнер скрыт или перезатирается, и окно просто не
-- показывалось. Свой ScreenGui с ResetOnSpawn = false и высоким DisplayOrder
-- показывается всегда.

local builder = {};
builder.on_close = nil;

local gui, frame;
local y = 34;
local boxes = {};

-- имя файла: только буквы/цифры/_/-, иначе получим мусорный путь
local function sanitize(s)
	return tostring(s or ""):gsub("[^%w_%-]", ""):sub(1, 40)
end

local function ensure_gui()
	if gui and gui.Parent then return gui end;

	gui = Instance.new("ScreenGui");
	gui.Name = "RainTimingBuilderGui";
	gui.ResetOnSpawn = false;
	gui.IgnoreGuiInset = true;
	gui.DisplayOrder = 1000;
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	-- pcall: ScreenGui не во всех окружениях принимает ZIndexBehavior/IgnoreGuiInset
	pcall(function() gui.Parent = game:GetService("CoreGui") end);
	if not gui.Parent then
		local ok, pg = pcall(function()
			return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
		end);
		if ok and pg then pcall(function() gui.Parent = pg end) end;
	end;

	frame = Instance.new("Frame");
	frame.Name = "RainTimingBuilder";
	frame.Size = UDim2.new(0, 320, 0, 300);
	frame.Position = UDim2.new(0.5, -160, 0.35, -140);
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24);
	frame.BorderSizePixel = 0;
	frame.Visible = false;
	frame.Active = true;
	frame.Parent = gui;

	local shadow = Instance.new("ImageLabel");
	shadow.Name = "Shadow";
	shadow.Size = UDim2.new(1, 24, 1, 24);
	shadow.Position = UDim2.new(0, -12, 0, -12);
	shadow.BackgroundTransparency = 1;
	shadow.Image = "rbxasset://textures/ui/Controls/Background/SimpleShadow.png";
	shadow.ImageColor3 = Color3.new(0, 0, 0);
	shadow.ImageTransparency = 0.55;
	shadow.ScaleType = Enum.ScaleType.Slice;
	shadow.SliceCenter = Rect.new(23, 23, 277, 277);
	shadow.ZIndex = -1;
	shadow.Parent = frame;

	local title = Instance.new("TextLabel");
	title.Size = UDim2.new(1, 0, 0, 28);
	title.BackgroundColor3 = Color3.fromRGB(32, 32, 40);
	title.BorderSizePixel = 0;
	title.Text = "Timing Builder"
		.. "        (toggle in Combat -> Timing Builder)";
	title.TextColor3 = Color3.fromRGB(235, 235, 235);
	title.Font = Enum.Font.GothamBold;
	title.TextSize = 12;
	title.TextXAlignment = Enum.TextXAlignment.Left;
	title.Parent = frame;

	-- перетаскивание за заголовок
	do
		local dragging, start_pos, start_input = false, nil, nil;
		title.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true;
				start_pos = frame.Position;
				start_input = input.Position;
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		game:GetService("UserInputService").InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local d = input.Position - start_input;
				frame.Position = UDim2.new(
					start_pos.X.Scale, start_pos.X.Offset + d.X,
					start_pos.Y.Scale, start_pos.Y.Offset + d.Y
				)
			end
		end)
	end

	local function label(text, yy)
		local lab = Instance.new("TextLabel");
		lab.Size = UDim2.new(0, 108, 0, 24);
		lab.Position = UDim2.new(0, 10, 0, yy);
		lab.BackgroundTransparency = 1;
		lab.Text = text;
		lab.TextColor3 = Color3.fromRGB(200, 200, 200);
		lab.Font = Enum.Font.Gotham;
		lab.TextSize = 12;
		lab.TextXAlignment = Enum.TextXAlignment.Left;
		lab.Parent = frame;
		return lab;
	end

	local function add_row(text, initial)
		local yy = y;
		label(text, yy);
		local box = Instance.new("TextBox");
		box.Name = text;
		box.Size = UDim2.new(0, 182, 0, 24);
		box.Position = UDim2.new(0, 124, 0, yy);
		box.BackgroundColor3 = Color3.fromRGB(40, 40, 48);
		box.BorderSizePixel = 0;
		box.Text = tostring(initial or "");
		box.TextColor3 = Color3.fromRGB(255, 255, 255);
		box.Font = Enum.Font.Gotham;
		box.TextSize = 12;
		box.ClearTextOnFocus = false;
		box.Parent = frame;
		boxes[text] = box;
		y += 27;
		return box;
	end

	add_row("Anim ID", "");
	add_row("Name", "CustomM1");
	add_row("Windup (s)", "0.35");
	add_row("Hitbox XYZ", "14,20,14");
	add_row("Action Type", "M1");
	-- action_type из extra_data.json: M1 / Spell / Critical
	add_row("Chance %", "100");

	local type_btn;
	do
		local yy = y;
		label("Defend Type", yy);
		type_btn = Instance.new("TextButton");
		type_btn.Size = UDim2.new(0, 182, 0, 24);
		type_btn.Position = UDim2.new(0, 124, 0, yy);
		type_btn.BackgroundColor3 = Color3.fromRGB(50, 90, 50);
		type_btn.BorderSizePixel = 0;
		type_btn.Text = "Parry";
		type_btn.TextColor3 = Color3.fromRGB(255, 255, 255);
		type_btn.Font = Enum.Font.GothamBold;
		type_btn.TextSize = 12;
		type_btn.Parent = frame;
		type_btn.MouseButton1Click:Connect(function()
			type_btn.Text = (type_btn.Text == "Parry") and "Dodge" or "Parry";
		end);
		y += 27;
	end

	local status = Instance.new("TextLabel");
	status.Size = UDim2.new(1, -20, 0, 34);
	status.Position = UDim2.new(0, 10, 0, y);
	status.BackgroundTransparency = 1;
	status.Text = "";
	status.TextColor3 = Color3.fromRGB(140, 220, 140);
	status.Font = Enum.Font.Gotham;
	status.TextSize = 11;
	status.TextWrapped = true;
	status.TextXAlignment = Enum.TextXAlignment.Left;
	status.TextYAlignment = Enum.TextYAlignment.Top;
	status.Parent = frame;
	y += 36;

	local function button(text, xx, color, cb)
		local b = Instance.new("TextButton");
		b.Size = UDim2.new(0, 96, 0, 28);
		b.Position = UDim2.new(0, xx, 0, y);
		b.BackgroundColor3 = color;
		b.BorderSizePixel = 0;
		b.Text = text;
		b.TextColor3 = Color3.fromRGB(255, 255, 255);
		b.Font = Enum.Font.GothamBold;
		b.TextSize = 12;
		b.Parent = frame;
		b.MouseButton1Click:Connect(cb);
		return b;
	end

	local function reload_timings()
		local fn = getgenv().load_timings;
		if type(fn) ~= "function" then
			return false, "auto-parry not loaded yet"
		end;
		local ok, err = pcall(fn);
		return ok, (not ok) and tostring(err) or nil;
	end

	button("Save", 10, Color3.fromRGB(40, 110, 60), function()
		local raw_id = tostring(boxes["Anim ID"].Text or "");
		local id = raw_id:match("%d+");
		local name = sanitize(boxes["Name"].Text or "");
		if not id or #name == 0 then
			status.TextColor3 = Color3.fromRGB(230, 140, 140);
			status.Text = "need a numeric Anim ID and a Name";
			return;
		end;

		local windup = tonumber(boxes["Windup (s)"].Text) or 0.35;
		local hx, hy, hz = tostring(boxes["Hitbox XYZ"].Text or "")
			:match("([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)");
		hx, hy, hz = tonumber(hx) or 14, tonumber(hy) or 20, tonumber(hz) or 14;
		local atype = tostring(boxes["Action Type"].Text or "M1");
		if atype ~= "M1" and atype ~= "Spell" and atype ~= "Critical" then atype = "M1" end;
		local chance = tonumber(boxes["Chance %"].Text) or 100;
		local dtype = (type_btn.Text == "Dodge") and "Dodge" or "Parry";

		-- формат 1-в-1 с настоящими таймингами (base.lua, напр. tbl['ArcBeam'])
		local src = string.format(
			"return {\n    ids = { %q },\n    default_chance = %d,\n"
			.. "    allow_block_input = true,\n    allow_parry_to_roll = true,\n"
			.. "    allow_roll_to_parry = true,\n    allow_parry_to_block = true,\n"
			.. "    action_type = %q,\n    name = %q,\n"
			.. "    run = function(action)\n"
			.. "        action.when = %.3f;\n"
			.. "        action.offset = CFrame.new(0, 0, -5);\n"
			.. "        action.hitbox = Vector3.new(%.1f, %.1f, %.1f);\n"
			.. "        action.type = %q;\n"
			.. "        action:push();\n"
			.. "        return action;\n"
			.. "    end\n}\n",
			id, chance, atype, name, windup, hx, hy, hz, dtype);

		-- запись и перезагрузка — раздельно, иначе ошибка перезагрузки
		-- выглядит в статусе как ошибка записи
		local ok, err = pcall(function()
			if not isfolder("rw_timings") then makefolder("rw_timings") end;
			writefile("rw_timings/" .. name .. ".lua", src);
		end);

		if not ok then
			status.TextColor3 = Color3.fromRGB(230, 140, 140);
			status.Text = "write failed: " .. tostring(err):sub(1, 70);
			return;
		end;

		local rok, rerr = reload_timings();
		if rok then
			status.TextColor3 = Color3.fromRGB(140, 220, 140);
			status.Text = "saved " .. name .. " / id " .. id .. " — timings reloaded";
		else
			status.TextColor3 = Color3.fromRGB(240, 200, 120);
			status.Text = "saved " .. name .. ", but reload failed: " .. tostring(rerr):sub(1, 60);
		end;
	end);

	button("Reload", 112, Color3.fromRGB(50, 70, 110), function()
		local ok, err = reload_timings();
		status.TextColor3 = ok
			and Color3.fromRGB(140, 220, 140)
			or Color3.fromRGB(230, 140, 140);
		status.Text = ok and "timings reloaded from rw_timings"
			or ("reload failed: " .. tostring(err):sub(1, 70));
	end);

	button("Close", 214, Color3.fromRGB(110, 40, 40), function()
		builder:set_visible(false);
		if builder.on_close then pcall(builder.on_close) end;
	end);

	frame.Size = UDim2.new(0, 320, 0, y + 38);
	frame.ClipsDescendants = false;

	builder._status = status;
	return gui;
end

function builder:set_visible(val)
	if not val then
		if frame then frame.Visible = false end;
		return;
	end;

	ensure_gui();
	if not gui or not frame then return end;

	-- окно должно быть поверх всего, иначе его перекрывает меню
	gui.Enabled = true;
	gui.DisplayOrder = 1000;
	frame.Visible = true;
	frame.Active = true;
end;

-- Timing Logger отдаёт сюда живой трек: подставляем id, windup и имя цели.
function builder:load_track(track, entity)
	ensure_gui();
	if not boxes["Anim ID"] then return end;

	pcall(function()
		local aid = track and track.Animation
			and tostring(track.Animation.AnimationId or ""):match("%d+");
		if aid then boxes["Anim ID"].Text = aid end;
		local len = track and track.Length;
		if typeof(len) == "number" and len > 0 then
			boxes["Windup (s)"].Text = string.format("%.3f", len * 0.55);
		end;
		local en = entity and entity.Name or "";
		if en ~= "" then boxes["Name"].Text = sanitize(en):sub(1, 24) end;
		if builder._status then builder._status.Text = "track loaded — adjust and Save" end;
	end);

	self:set_visible(true);
end

getgenv().timing_builder = builder
return builder