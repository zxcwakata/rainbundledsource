-- Animation Inspector.
--
-- Окно со списком анимаций, которые указанный персонаж играет ПРЯМО СЕЙЧАС:
-- id ассета, имя с маркетплейса, Priority, Speed, WeightCurrent/Target,
-- Length, TimePosition. Обновление живых полей ~16 Гц.
--
-- Клик по строке кормит Timing Builder (builder:load_track) — тот самый
-- приём, ради которого окно и нужно: увидел анимацию в бою, кликнул,
-- получил id и windup в билдере, дальше Save.
--
-- Портировано из Luma-main/Features/Combat/AnimationInspector.lua. Оттуда
-- взята схема (Animator.AnimationPlayed + GetPlayingAnimationTracks как
-- сид, кап на MAX_ROWS, опрос живых полей). Fade-time через namecall-хук
-- из оригинала не переносил: это единственное, что там требует
-- перехвата __namecall, а пользы для подбора таймингов нет.
--
-- Окно на своём ScreenGui — тот же приём, что в builder.lua: на части
-- исполнителей gethui()/CoreGui скрыт, и окно просто не появляется.

local inspector = {};
inspector.on_close = nil;

local MAX_ROWS = 100;
local UPDATE_INTERVAL = 0.06

local gui, frame, list_frame, status, target_label;
local rows = {};           -- track -> { line }
local row_order = {};      -- track, в порядке появления
local running = false;
local anim_conn = nil;
local char_conn = nil;
local player_conn = nil;
local poll_started = false;
local y = 30;
local target_player = nil;

local function clear_conn(c)
    if c then pcall(function() c:Disconnect() end) end
    return nil
end

local function fmt(v)
    if type(v) ~= "number" then return tostring(v) end
    if v == math.floor(v) and math.abs(v) < 1e9 then return tostring(v) end
    return string.format("%.3f", v)
end

local function get(fn, dflt)
    local ok, v = pcall(fn);
    if not ok or v == nil then return dflt end
    return v;
end

local function anim_id_of(track)
    local anim = get(function() return track.Animation end);
    local raw = get(function() return anim.AnimationId end, "");
    return tostring(raw):match("(%d+)") or "", tostring(raw);
end

------------------------------------------------------------------ строки

local function remove_row(track)
    local row = rows[track];
    if not row then return end;
    rows[track] = nil;
    for i, t in ipairs(row_order) do
        if t == track then table.remove(row_order, i) break end;
    end;
    pcall(function() row.line:Destroy() end);
end

local function clear_rows()
    for track in pairs(rows) do
        pcall(function() rows[track].line:Destroy() end);
    end;
    table.clear(rows);
    table.clear(row_order);
end

local function refresh_row(row)
    local track = row.track;
    if get(function() return track.Parent end, nil) == nil and not get(function() return track.IsPlaying end, false) then
        remove_row(track);
        return;
    end;

    local id = row.id;
    local prio = get(function() return track.Priority.Name end, "?");
    row.line.Text = string.format(
        "%s  %s\n    prio=%s  spd=%s  wc=%s  wt=%s  len=%s  t=%s",
        id, row.name or "?",
        prio,
        fmt(get(function() return track.Speed end, 0)),
        fmt(get(function() return track.WeightCurrent end, 0)),
        fmt(get(function() return track.WeightTarget end, 0)),
        fmt(get(function() return track.Length end, 0)),
        fmt(get(function() return track.TimePosition end, 0))
    );
    row.line.TextColor3 = get(function() return track.IsPlaying end, false)
        and Color3.fromRGB(140, 220, 140)
        or Color3.fromRGB(130, 130, 140);
end

local function add_row(track)
    if rows[track] then refresh_row(rows[track]) return end;
    if not list_frame then return end;
    if #row_order >= MAX_ROWS then
        -- вытесняем самую старую строку, иначе флуд от AP-ломателя
        -- забил бы окно и заблокировал реальные анимации
        remove_row(row_order[1]);
    end;

    local id = anim_id_of(track);
    if id == "" then return end;

    -- имя берём у самого Animation-инстанса: Deepwoken именует их по муву,
    -- в отличие от MarketplaceService, который для анимаций молчит
    local anim_name = get(function() return track.Animation.Name end, nil);
    if anim_name == "" then anim_name = nil end;

    local line = Instance.new("TextButton");
    line.Name = id;
    line.Size = UDim2.new(1, -8, 0, 34);
    line.Position = UDim2.new(0, 4, 0, (#row_order) * 36);
    line.BackgroundTransparency = 1;
    line.BackgroundColor3 = Color3.fromRGB(50, 50, 62);
    line.AutoButtonColor = true;
    line.TextXAlignment = Enum.TextXAlignment.Left;
    line.TextYAlignment = Enum.TextYAlignment.Top;
    line.TextWrapped = true;
    line.TextSize = 11;
    line.Font = Enum.Font.Code;
    line.Text = id;
    line.Parent = list_frame;

    local row = { track = track, line = line, id = id, name = anim_name };

    -- клик по строке -> Timing Builder
    line.MouseButton1Click:Connect(function()
        local builder = getgenv().timing_builder;
        if not builder then
            if status then
                status.TextColor3 = Color3.fromRGB(240, 200, 120);
                status.Text = "timing builder not loaded";
            end;
            return;
        end;
        local entity = target_player and target_player.Character or local_player.character;
        pcall(function() builder:load_track(track, entity) end);
    end);

    rows[track] = row;
    table.insert(row_order, track);
    refresh_row(row);
end

------------------------------------------------------------------ привязка

local function bind_animator(animator)
    anim_conn = clear_conn(anim_conn);
    if not animator then return end;

    pcall(function()
        anim_conn = animator.AnimationPlayed:Connect(function(track)
            if running then add_row(track) end;
        end);
    end);

    -- сид: то, что уже играет
    local playing = get(function() return animator:GetPlayingAnimationTracks() end, nil);
    if type(playing) == "table" then
        for _, track in ipairs(playing) do add_row(track) end;
    end;
end

local function bind_character(character)
    clear_rows();
    if not character then
        if status then status.Text = "target has no character" end;
        return;
    end;

    local humanoid = character:FindFirstChildOfClass("Humanoid");
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator");
    if animator then
        bind_animator(animator);
        return;
    end;

    -- персонаж только что заспавнился, Animator может быть ещё нет
    task.spawn(function()
        local hum = character:WaitForChild("Humanoid", 5);
        local anim = hum and hum:WaitForChild("Animator", 5);
        if anim and running and target_player and target_player.Character == character then
            bind_animator(anim);
        end;
    end);
end

local function bind_player(player)
    target_player = player;
    char_conn = clear_conn(char_conn);
    if not player then
        clear_rows();
        return;
    end;

    if target_label then
        target_label.Text = "target: " .. tostring(player.DisplayName or player.Name);
    end;

    bind_character(player.Character);
    pcall(function()
        char_conn = player.CharacterAdded:Connect(function(c) bind_character(c) end);
    end);
end

------------------------------------------------------------------ интерфейс

local function poll()
    if not running then return end;
    for track, row in pairs(rows) do refresh_row(row) end;

    local list = get(function() return target_player.Character end, nil);
    if status then
        status.Text = string.format("%d track(s) | target: %s",
            #row_order, list and "in world" or "no character");
    end;
end

local function ensure_gui()
    if gui and gui.Parent then return end;

    gui = Instance.new("ScreenGui");
    gui.Name = "RainAnimInspectorGui";
    gui.ResetOnSpawn = false;
    gui.IgnoreGuiInset = true;
    gui.DisplayOrder = 999;
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    pcall(function() gui.Parent = game:GetService("CoreGui") end);
    if not gui.Parent then
        local ok, pg = pcall(function()
            return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
        end);
        if ok and pg then pcall(function() gui.Parent = pg end) end;
    end;

    frame = Instance.new("Frame");
    frame.Name = "RainAnimInspector";
    frame.Size = UDim2.new(0, 380, 0, 440);
    frame.Position = UDim2.new(0.5, -190, 0.3, -120);
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22);
    frame.BorderSizePixel = 0;
    frame.Visible = false;
    frame.Active = true;
    frame.Parent = gui;

    local title = Instance.new("TextLabel");
    title.Size = UDim2.new(1, 0, 0, 28);
    title.BackgroundColor3 = Color3.fromRGB(32, 32, 40);
    title.BorderSizePixel = 0;
    title.Text = "Animation Inspector   — click a row to send it to the Timing Builder";
    title.TextColor3 = Color3.fromRGB(235, 235, 235);
    title.Font = Enum.Font.GothamBold;
    title.TextSize = 11;
    title.TextXAlignment = Enum.TextXAlignment.Left;
    title.Parent = frame;

    do
        local dragging, start_pos, start_input = false, nil, nil;
        title.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; start_pos = frame.Position;
                start_input = input.Position;
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end;
                end);
            end;
        end);
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local d = input.Position - start_input;
                frame.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + d.X,
                    start_pos.Y.Scale, start_pos.Y.Offset + d.Y);
            end;
        end);
    end;

    local function button(text, xx, color, cb)
        local b = Instance.new("TextButton");
        b.Size = UDim2.new(0, 116, 0, 24);
        b.Position = UDim2.new(0, xx, 0, y);
        b.BackgroundColor3 = color;
        b.BorderSizePixel = 0;
        b.Text = text;
        b.TextColor3 = Color3.fromRGB(255, 255, 255);
        b.Font = Enum.Font.GothamBold;
        b.TextSize = 11;
        b.Parent = frame;
        b.MouseButton1Click:Connect(cb);
        return b;
    end

    target_label = Instance.new("TextLabel");
    target_label.Size = UDim2.new(1, -16, 0, 20);
    target_label.Position = UDim2.new(0, 8, 0, y);
    target_label.BackgroundTransparency = 1;
    target_label.Text = "target: -";
    target_label.TextColor3 = Color3.fromRGB(190, 190, 200);
    target_label.Font = Enum.Font.Gotham;
    target_label.TextSize = 11;
    target_label.TextXAlignment = Enum.TextXAlignment.Left;
    target_label.Parent = frame;
    y += 24;

    button("Self", 8, Color3.fromRGB(50, 70, 110), function()
        bind_player(game:GetService("Players").LocalPlayer);
    end);

    button("Nearest Enemy", 130, Color3.fromRGB(80, 60, 40), function()
        local best, best_d = nil, math.huge;
        local root = local_player and local_player.root_part;
        if not root then return end;
        for _, obj in workspace:GetDescendants() do
            if obj:IsA("Model") and obj ~= local_player.character then
                local h = obj:FindFirstChildOfClass("Humanoid");
                local r = obj:FindFirstChild("HumanoidRootPart");
                if h and r and h.Health > 0 then
                    local d = (r.Position - root.Position).Magnitude;
                    if d < best_d then
                        best_d = d;
                        best = obj;
                    end;
                end;
            end;
        end;
        if best and best:FindFirstChild("Humanoid") then
            local p = game:GetService("Players"):GetPlayerFromCharacter(best);
            if p then bind_player(p) else bind_character(best) end;
        end;
    end);

    button("Close", 252, Color3.fromRGB(110, 40, 40), function()
        inspector:set_visible(false);
        if inspector.on_close then pcall(inspector.on_close) end;
    end);

    y += 28;

    status = Instance.new("TextLabel");
    status.Size = UDim2.new(1, -16, 0, 18);
    status.Position = UDim2.new(0, 8, 0, y);
    status.BackgroundTransparency = 1;
    status.Text = "";
    status.TextColor3 = Color3.fromRGB(140, 220, 140);
    status.Font = Enum.Font.Gotham;
    status.TextSize = 11;
    status.TextXAlignment = Enum.TextXAlignment.Left;
    status.Parent = frame;
    y += 22;

    list_frame = Instance.new("ScrollingFrame");
    list_frame.Size = UDim2.new(1, -10, 1, -(y + 12));
    list_frame.Position = UDim2.new(0, 5, 0, y);
    list_frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30);
    list_frame.BorderSizePixel = 0;
    list_frame.ScrollBarThickness = 5;
    list_frame.CanvasSize = UDim2.new(0, 0, 0, 0);
    list_frame.AutomaticCanvasSize = Enum.AutomaticSize.Y;
    list_frame.Parent = frame;
end

------------------------------------------------------------------ API

function inspector:set_visible(val)
    if not val then
        running = false;
        if frame then frame.Visible = false end;
        return;
    end;

    ensure_gui();
    if not gui or not frame then return end;

    running = true;
    gui.Enabled = true;
    gui.DisplayOrder = 999;
    frame.Visible = true;

    if not target_player then
        bind_player(game:GetService("Players").LocalPlayer);
    else
        bind_character(target_player.Character);
    end;

    if not poll_started then
        poll_started = true;
        -- общий цикл на всё окно: дёшево, дергается только при running
        task.spawn(function()
            local last = 0;
            while gui and gui.Parent do
                if tick() - last >= UPDATE_INTERVAL then
                    last = tick();
                    poll();
                end;
                task.wait();
            end;
            poll_started = false;
        end);
    end;
end;

function inspector:is_visible()
    return running == true;
end

function inspector:detach()
    running = false;
    clear_rows();
    anim_conn = clear_conn(anim_conn);
    char_conn = clear_conn(char_conn);
    player_conn = clear_conn(player_conn);
    if gui then pcall(function() gui:Destroy() end) end;
    gui, frame, list_frame = nil, nil, nil;
end;

getgenv().anim_inspector = inspector
return inspector