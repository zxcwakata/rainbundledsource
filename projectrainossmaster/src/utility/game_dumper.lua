-- Game Script Dumper. Слив исходников скриптов ИГРЫ (Deepwoken).
--
-- Задача узкая и отличается от дампа Place: нужен не список инстансов и не
-- обход getgc, а ТЕКСТ игровых скриптов. Поэтому ядро здесь одно —
-- дойти до каждого ModuleScript/LocalScript и вытащить его Source.
--
-- Как достаётся исходник (три канала, потому что у исполнителей доступен
-- не всегда один):
--   1) getscript(inst).Source   — прямой источник, самый полный
--   2) require(inst) -> функции -> debug.info(f, "S")/getsource(f)
--      даёт текст для модулей, у которых getscript не сработал
--   3) inst.Source              — если экземпляр сам Script
--
-- Где искать: ReplicatedStorage.Modules (основное хранилище Deepwoken),
-- но обход идёт по ВСЕМУ ReplicatedStorage + PlayerGui + PlayerScripts,
-- потому что часть модулей лежит вне Modules.
--
-- Для теста анти-дампера важен STEALTH: дампер уводит свои GUI-объекты в
-- скрытый контейнер и прячет функции, чтобы проверить, ловит ли анти-дамп
-- неявный слив, а не только явный обход дерева.

local dumper = {}

local gui, frame, log_box, status, progress_bar;
local running = false;
local stealth_mount = nil;
local found = {};        -- { inst = ModuleScript, name = string }
local dumped = 0;

------------------------------------------------------------------ helpers

local function line_out(s)
    if not log_box then return end;
    log_box.Text = log_box.Text .. s .. "\n";
    pcall(function() log_box.Position = UDim2.new(0, 6, 0, math.max(0, log_box.AbsoluteCanvasSize.Y)) end);
end

local function set_status(s)
    if status then status.Text = s end;
end

local function set_progress(cur, total)
    if not progress_bar then return end;
    local r = (total and total > 0) and (cur / total) or 0;
    pcall(function()
        progress_bar.Size = UDim2.new(math.clamp(r, 0, 1), 0, 1, 0);
    end);
end

------------------------------------------------------------------ поиск

--- Собирает все скриптовые инстансы игры. Обход шире, чем просто Modules:
--- часть модулей лежит в ReplicatedStorage/PlayerGui/PlayerScripts.
function dumper.scan(limit)
    local out = {};
    local seen = {};
    limit = limit or 5000;

    local roots = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Players"):GetPlayers()[1]
            and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") or nil,
        game:GetService("Players"):GetPlayers()[1]
            and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts") or nil,
    };

    for _, root in ipairs(roots) do
        if root and typeof(root) == "Instance" then
            local ok, list = pcall(function() return root:GetDescendants() end);
            if ok then
                for _, inst in ipairs(list) do
                    if #out >= limit then break end;
                    local ct = inst.ClassName;
                    if (ct == "ModuleScript" or ct == "LocalScript" or ct == "Script")
                        and not seen[inst] then
                        seen[inst] = true;
                        out[#out + 1] = inst;
                    end;
                end;
            end;
        end;
    end;

    return out;
end

------------------------------------------------------------------ извлечение

--- Текст исходника одного инстанса. nil, если достать не удалось.
function dumper.getSource(inst)
    if typeof(inst) ~= "Instance" then return nil end;

    -- 1) getscript — самый полный канал
    if type(getscript) == "function" then
        local ok, sc = pcall(getscript, inst);
        if ok and sc and type(sc) == "Instance" then
            local sok, s = pcall(function() return sc.Source end);
            if sok and type(s) == "string" and #s > 0 then return s, "getscript" end;
        end;
    end;

    -- 2) собственный Source (если это Script/LocalScript)
    local dok, d = pcall(function() return inst.Source end);
    if dok and type(d) == "string" and #d > 0 then return d, "Source" end;

    -- 3) через require: берём функции из модуля и спрашиваем у них исходник
    local rok, mod = pcall(require, inst);
    if rok and type(mod) == "table" then
        local pieces = {};
        for _, v in pairs(mod) do
            if type(v) == "function" then
                local src = nil;
                if type(getsource) == "function" then
                    local gok, g = pcall(getsource, v);
                    if gok and type(g) == "string" and #g > 0 then src = g end;
                end;
                if not src and type(debug) == "table" and type(debug.info) == "function" then
                    local iok, info = pcall(debug.info, v, "S");
                    if iok and type(info) == "string" and info:sub(1, 1) ~= "=" then src = info end;
                end;
                if src then pieces[#pieces + 1] = "-- [" .. tostring(v) .. "]\n" .. src end;
            end;
        end;
        if #pieces > 0 then return table.concat(pieces, "\n\n"), "require" end;
    end;

    return nil;
end

------------------------------------------------------------------ дамп

--- Основной слив. Пишет каждый модуль отдельным файлом + один сводный.
---@param dir string  папка внутри воркспейса
---@return table  статистика
function dumper.run(dir)
    dir = dir or "GameDump";

    if running then return { error = "уже выполняется" } end;
    running = true;
    dumped = 0;

    if log_box then log_box.Text = "" end;
    set_status("сканирую игру...");

    local insts = dumper.scan();
    found = insts;
    set_progress(0, #insts);
    line_out(string.format("найдено скриптов: %d", #insts));

    local ok_folder = pcall(function()
        if not isfolder(dir) then makefolder(dir) end;
    end);
    if not ok_folder then
        set_status("не смог создать папку " .. dir);
        running = false;
        return { error = "folder" };
    end;

    local combined = {};
    local stats = { total = #insts, got = 0, failed = 0, bytes = 0 };

    for i, inst in ipairs(insts) do
        local src, via = dumper.getSource(inst);

        if src then
            stats.got = stats.got + 1;
            stats.bytes = stats.bytes + #src;
            dumped = dumped + 1;

            local fname = string.gsub(inst.Name, "[^%w_%-%.]", "_");
            pcall(function() writefile(dir .. "/" .. fname .. ".lua", src) end);

            combined[#combined + 1] = string.format(
                "\n\n-- ======================================================================\n"
                .. "-- FILE: %s (%s)\n-- VIA : %s\n"
                .. "-- ======================================================================\n%s",
                inst.Name, inst.ClassName, via, src);
        else
            stats.failed = stats.failed + 1;
        end;

        set_progress(i, #insts);
        if i % 25 == 0 then
            set_status(string.format("обработано %d/%d, слито %d", i, #insts, stats.got));
            task.wait();
        end;
    end;

    pcall(function() writefile(dir .. "/_ALL.lua", table.concat(combined)) end);

    running = false;
    set_progress(1, 1);
    set_status(string.format("готово: слито %d из %d, %d КБ, в папку %s",
        stats.got, stats.total, math.floor(stats.bytes / 1024), dir));
    line_out("");
    line_out(string.format("=== ГОТОВО === %d файлов, ошибок/недоступно: %d", stats.got, stats.failed));

    return stats;
end

------------------------------------------------------------------ stealth

--- Прячет дампер. Для проверки: ловит ли анти-дамп неявный слив.
function dumper.setStealth(on)
    on = on and true or false;

    if on then
        if not stealth_mount then
            stealth_mount = Instance.new("Folder");
            stealth_mount.Name = "_" .. tostring(math.floor(os.clock() * 1000));
            -- ReplicatedFirst не обходится обычным дампом workspace
            pcall(function() stealth_mount.Parent = game:GetService("ReplicatedFirst") end);
        end;
        if gui then pcall(function() gui.Parent = stealth_mount end) end;
        if frame then frame.Visible = false end;
        return true;
    end;

    if gui then
        pcall(function() gui.Parent = game:GetService("CoreGui") end);
        if frame then frame.Visible = true end;
    end;
    return false;
end

function dumper.isStealth()
    return stealth_mount ~= nil and gui ~= nil and gui.Parent == stealth_mount;
end

------------------------------------------------------------------ интерфейс

local function ensure_gui()
    if gui and gui.Parent then return true end;

    gui = Instance.new("ScreenGui");
    gui.Name = "RainGameDumper";
    gui.ResetOnSpawn = false;
    gui.IgnoreGuiInset = true;
    gui.DisplayOrder = 960;
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
    pcall(function() gui.Parent = game:GetService("CoreGui") end);
    if not gui.Parent then
        local ok, pg = pcall(function()
            return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
        end);
        if ok and pg then pcall(function() gui.Parent = pg end) end;
    end;
    if not gui.Parent then return false end;

    frame = Instance.new("Frame");
    frame.Name = "RainGameDumperFrame";
    frame.Size = UDim2.new(0, 560, 0, 560);
    frame.Position = UDim2.new(0.5, -280, 0.5, -280);
    frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20);
    frame.BorderSizePixel = 0;
    frame.Parent = gui;

    local title = Instance.new("TextLabel");
    title.Size = UDim2.new(1, 0, 0, 28);
    title.BackgroundColor3 = Color3.fromRGB(34, 34, 42);
    title.BorderSizePixel = 0;
    title.Text = "Game Script Dumper — слив исходников СКРИПТОВ ИГРЫ";
    title.TextColor3 = Color3.fromRGB(240, 240, 240);
    title.Font = Enum.Font.GothamBold;
    title.TextSize = 13;
    title.Parent = frame;

    do
        local dragging, sp, si = false, nil, nil;
        title.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; sp = frame.Position; si = input.Position;
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end;
                end);
            end;
        end);
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local d = input.Position - si;
                frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                    sp.Y.Scale, sp.Y.Offset + d.Y);
            end;
        end);
    end

    local y = 32;
    local dir_box = Instance.new("TextBox");
    dir_box.Size = UDim2.new(0, 200, 0, 24);
    dir_box.Position = UDim2.new(0, 8, 0, y);
    dir_box.BackgroundColor3 = Color3.fromRGB(34, 34, 42);
    dir_box.BorderSizePixel = 0;
    dir_box.Text = "Project Rain/GameDump";
    dir_box.TextColor3 = Color3.fromRGB(240, 240, 240);
    dir_box.Font = Enum.Font.Gotham;
    dir_box.TextSize = 11;
    dir_box.ClearTextOnFocus = false;
    dir_box.Parent = frame;

    local stealth_btn;
    local function mkbtn(text, xx, color, cb)
        local b = Instance.new("TextButton");
        b.Size = UDim2.new(0, 130, 0, 24);
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

    mkbtn("СЛИТЬ ВСЁ", 214, Color3.fromRGB(50, 95, 140), function()
        if running then set_status("уже выполняется") return end;
        set_status("запуск...");
        task.spawn(function() dumper.run(dir_box.Text) end);
    end);

    mkbtn("Только сканировать", 350, Color3.fromRGB(60, 60, 80), function()
        local insts = dumper.scan();
        if log_box then log_box.Text = "" end;
        line_out("найдено: " .. #insts);
        local by_class = {};
        for _, i in ipairs(insts) do
            by_class[i.ClassName] = (by_class[i.ClassName] or 0) + 1;
        end;
        for c, n in pairs(by_class) do line_out("  " .. c .. ": " .. n) end;
        line_out("");
        for idx, i in ipairs(insts) do
            if idx <= 400 then line_out(string.format("%4d  %-14s %s", idx, i.ClassName, i.Name)) end;
        end;
        if #insts > 400 then line_out("... и ещё " .. (#insts - 400)) end;
        set_status("сканирование завершено");
    end);

    y += 30;

    progress_bar = Instance.new("Frame");
    progress_bar.Size = UDim2.new(0, 0, 0, 4);
    progress_bar.Position = UDim2.new(0, 8, 0, y);
    progress_bar.BackgroundColor3 = Color3.fromRGB(90, 190, 120);
    progress_bar.BorderSizePixel = 0;
    progress_bar.Parent = frame;
    y += 10;

    status = Instance.new("TextLabel");
    status.Size = UDim2.new(1, -16, 0, 20);
    status.Position = UDim2.new(0, 8, 0, y);
    status.BackgroundTransparency = 1;
    status.Text = "";
    status.TextColor3 = Color3.fromRGB(150, 200, 150);
    status.Font = Enum.Font.Gotham;
    status.TextSize = 11;
    status.TextXAlignment = Enum.TextXAlignment.Left;
    status.Parent = frame;
    y += 24;

    log_box = Instance.new("TextBox");
    log_box.Size = UDim2.new(1, -16, 1, -(y + 8));
    log_box.Position = UDim2.new(0, 8, 0, y);
    log_box.BackgroundColor3 = Color3.fromRGB(10, 10, 14);
    log_box.BorderSizePixel = 0;
    log_box.Text = "";
    log_box.MultiLine = true;
    log_box.ReadOnly = true;
    log_box.ScrollableY = true;
    log_box.Font = Enum.Font.Code;
    log_box.TextSize = 11;
    log_box.TextColor3 = Color3.fromRGB(200, 220, 200);
    log_box.TextXAlignment = Enum.TextXAlignment.Left;
    log_box.TextYAlignment = Enum.TextYAlignment.Top;
    log_box.ClearTextOnFocus = false;
    log_box.Parent = frame;

    stealth_btn = mkbtn("Stealth", 8, Color3.fromRGB(70, 50, 90), function()
        local on = dumper.setStealth(not dumper.isStealth());
        stealth_btn.Text = on and "Stealth: ВКЛ" or "Stealth: выкл";
        if not on then set_status("stealth выключен") end;
    end);
    stealth_btn.Position = UDim2.new(0, 8, 1, -28);
    stealth_btn.Size = UDim2.new(0, 150, 0, 24);

    local close_btn = mkbtn("Закрыть", 400, Color3.fromRGB(110, 40, 40), function()
        dumper.close();
    end);
    close_btn.Position = UDim2.new(1, -140, 1, -28);
    close_btn.Size = UDim2.new(0, 130, 0, 24);

    return true;
end

function dumper.open()
    if not ensure_gui() then return false end;
    pcall(function() gui.Parent = game:GetService("CoreGui") end);
    frame.Visible = true;
    running = running or false;
    return true;
end

function dumper.close()
    if frame then frame.Visible = false end;
    if dumper.isStealth() then dumper.setStealth(false) end;
end

getgenv().rain_game_dumper = dumper
return dumper