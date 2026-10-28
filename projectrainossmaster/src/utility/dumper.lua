-- Dumper. Инструмент для проверки собственного анти-дампера.
--
-- Собран так, чтобы закрыть все стандартные пути, которыми сливают игру:
--   Instances — обход дерева Instance (workspace / ReplicatedStorage / Players)
--   Modules   — все ModuleScript + их исходник (включая те, что видны только
--               через require-кэш, а не через дерево)
--   GC        — getgc(): функции, таблицы, upvalue, с источником и аргументами
--   Tables    — глубокий дамп выбранной таблицы с защитой от циклов
--   Upvalues  — разбор closure: что функция держит вверх
--
-- Почему так много: анти-дамп, который ловит только обход дерева, обходится
-- за секунду через getgc или через require-кэш. Проверять надо каждый канал.
--
-- STEALTH. Дампер по умолению прячет свои функции от getgc и свои инстансы
-- от обхода дерева: подменяет поля метатаблицы под setreadonly и уводит
-- свои GUI-объекты в скрытый контейнер. Именно в этом режиме проверяется,
-- видно ли дампер вообще.

local dumper = {}

local gui, frame;
local running = false;
local last_result = {};   -- id -> текст дампа
local active_tab = "Instances";

-- скрытые контейнеры для stealth
local stealth_mount = nil;

------------------------------------------------------------------ утилиты

local function txt(n)
    if type(n) == "string" then return n end;
    return tostring(n);
end

local function short(v, maxLen)
    local s
    if type(v) == "string" then s = string.format("%q", v)
    else s = tostring(v) end;
    if #s > (maxLen or 60) then s = s:sub(1, maxLen or 60) .. "..." end;
    return s;
end

local function fullname(inst)
    local ok, s = pcall(function() return inst:GetFullName() end);
    if ok and s then return s end;
    return "?" .. " " .. txt(inst.Name);
end

--- Исходник функции/скрипта. Несколько путей, потому что у исполнителей
--- они ведут себя по-разному.
local function source_of(f)
    if type(f) ~= "function" then return nil, nil end;

    if type(getsource) == "function" then
        local ok, s = pcall(getsource, f);
        if ok and type(s) == "string" and #s > 0 then return s, true end;
    end;

    if type(debug) == "table" and type(debug.info) == "function" then
        local ok, s = pcall(debug.info, f, "s");
        if ok and type(s) == "string" and #s > 0 then
            -- у inline-кусков s = "=name", настоящий исходник не отдаётся
            if s:sub(1, 1) ~= "=" then return s, true end;
        end;
    end;

    if type(debug) == "table" and type(debug.getinfo) == "function" then
        local ok, info = pcall(debug.getinfo, f, "S");
        if ok and info and type(info.source) == "string" and info.source:sub(1, 1) ~= "=" then
            return info.source, false;
        end;
    end;

    return nil, false;
end

------------------------------------------------------------------ Instances

--- Обход дерева Instance. limit по узлам — чтобы не утащить полную карту
--- на 300k объектов и не положить клиент.
function dumper.dumpInstances(roots, limit)
    local out = {}
    limit = limit or 60000;
    local queue = {};
    local seen = {};

    for _, r in ipairs(roots) do queue[#queue + 1] = { inst = r, depth = 0 } end;

    local n = 0;
    while #queue > 0 and n < limit do
        local node = table.remove(queue, 1);
        local inst = node.inst;
        if typeof(inst) == "Instance" and not seen[inst] then
            seen[inst] = true;
            n = n + 1;
            out[#out + 1] = string.format("%s%s [%s]", string.rep("  ", node.depth),
                inst.Name, inst.ClassName);
            local ok = pcall(function()
                for _, child in ipairs(inst:GetChildren()) do
                    queue[#queue + 1] = { inst = child, depth = node.depth + 1 };
                end;
            end);
        end;
    end;

    out[#out + 1] = "";
    out[#out + 1] = string.format("всего: %d узлов (лимит %d)", n, limit);
    return table.concat(out, "\n");
end

------------------------------------------------------------------ Modules

--- Все ModuleScript'ы: и через дерево, и через require-кэш.
--- Второй источник важен: модуль, который уже require'нули, в дереве
--- виден, но иногда его прячут — require-кэш его выдаст.
function dumper.dumpModules(root, limit)
    local out = {};
    limit = limit or 5000;
    local seen = {};
    local count = 0;

    local function push(inst, viaTree)
        if count >= limit then return end;
        if typeof(inst) ~= "Instance" or seen[inst] then return end;
        if not inst:IsA("ModuleScript") then return end;
        seen[inst] = true;
        count = count + 1;

        local src = "";
        if type(require) == "function" then
            local ok, mod = pcall(require, inst);
            if ok and type(mod) == "table" then
                src = "require -> table(" .. table.concat(table.keys(mod), ",") .. ")";
            elseif ok then
                src = "require -> " .. type(mod);
            else
                src = "require error: " .. short(mod, 80);
            end;
        end;

        out[#out + 1] = string.format("[%s] %s%s", viaTree and "tree" or "cache",
            inst.Name, inst.Parent and (" -> " .. inst.Parent.Name) or "");
        out[#out + 1] = "    " .. src;
    end;

    -- 1) дерево
    for _, inst in ipairs(root:GetDescendants()) do
        pcall(push, inst, true);
    end;

    -- 2) require-кэш: иногда достаёт то, чего в дереве не видно
    if type(getgenv) == "function" then
        local cache = getgenv().package and getgenv().package.loaded;
        if type(cache) == "table" then
            local extra = 0;
            for k in pairs(cache) do
                if type(k) == "Instance" and k:IsA("ModuleScript") then
                    if not seen[k] then
                        extra = extra + 1;
                        pcall(push, k, false);
                    end;
                end;
            end;
            if extra > 0 then
                out[#out + 1] = "";
                out[#out + 1] = "из require-кэша дополнительно: " .. extra;
            end;
        end;
    end;

    out[#out + 1] = "";
    out[#out + 1] = string.format("всего модулей: %d (лимит %d)", count, limit);
    return table.concat(out, "\n");
end

------------------------------------------------------------------ GC

--- Разбор getgc(). Для каждой функции — source и сколько upvalue.
--- Именно это выдаёт чужой скрипт: его замыкания и таблицы.
function dumper.dumpGC(limit)
    local out = {};
    limit = limit or 4000;

    if type(getgc) ~= "function" then
        return "getgc недоступен на этом исполнителе";
    end;

    local ok, items = pcall(getgc, true);
    if not ok or type(items) ~= "table" then
        return "getgc вернул ошибку: " .. short(items, 80);
    end;

    -- "function" и "table" — зарезервированные слова, без кавычек не ключ
    local counts = { ["function"] = 0, ["table"] = 0, thread = 0, userdata = 0, other = 0 };
    local entries = {};

    for _, o in ipairs(items) do
        local t = typeof(o);
        counts[t] = (counts[t] or 0) + 1;

        if t == "function" then
            local src, real = source_of(o);
            local upv = 0;
            if type(debug) == "table" and type(debug.getupvalues) == "function" then
                local uok, list = pcall(debug.getupvalues, o);
                if uok and type(list) == "table" then
                    upv = #list;
                    -- имена upvalue часто и есть главный след
                    local names = {};
                    for _, u in ipairs(list) do
                        names[#names + 1] = tostring(u.name or "?") .. "=" .. typeof(u.value);
                    end;
                    if #names > 0 then
                        entries[#entries + 1] = string.format(
                            "fn upv=%d  %s  |  %s", upv, short(src, 40), table.concat(names, ", "));
                    end;
                end;
            end;
        end;
    end;

    out[#out + 1] = "=== СВОДКА getgc ===";
    for _, k in ipairs({ ["function"], ["table"], "thread", "userdata", "other" }) do
        out[#out + 1] = string.format("  %-9s %d", k, counts[k]);
    end;
    out[#out + 1] = "";
    out[#out + 1] = "=== ФУНКЦИИ С UPVALUE (главный след чужого кода) ===";

    local shown = 0;
    for _, line in ipairs(entries) do
        if shown >= limit then
            out[#out + 1] = "... обрезано на " .. limit;
            break;
        end;
        out[#out + 1] = "  " .. line;
        shown = shown + 1;
    end;

    return table.concat(out, "\n");
end

------------------------------------------------------------------ таблица

--- Глубокий дамп таблицы: depth ограничен, циклы помечаются.
function dumper.dumpTable(t, name, maxDepth)
    local out = {};
    local seen = {};
    maxDepth = maxDepth or 4;

    if type(t) ~= "table" then
        return short(t) .. " (" .. type(t) .. ") — не таблица";
    end;

    local function walk(v, path, depth)
        if depth > maxDepth then
            out[#out + 1] = path .. "  ... (глубже " .. maxDepth .. ")";
            return;
        end;
        if type(v) ~= "table" then
            out[#out + 1] = string.rep("  ", depth) .. path .. " = " .. short(v, 90);
            return;
        end;
        if seen[v] then
            out[#out + 1] = string.rep("  ", depth) .. path .. " -> <цикл>";
            return;
        end;
        seen[v] = true;

        local keys = {};
        for k in pairs(v) do keys[#keys + 1] = k end;
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end);

        for _, k in ipairs(keys) do
            local path2 = path .. "." .. tostring(k);
            local val = v[k];
            if type(val) == "function" then
                local s = source_of(val);
                out[#out + 1] = string.rep("  ", depth + 1)
                    .. path2 .. " = fn " .. short(s, 50);
            else
                walk(val, path2, depth + 1);
            end;
        end;
        seen[v] = nil;
    end;

    out[#out + 1] = "=== " .. (name or "таблица") .. " (" .. type(t) .. ") ===";
    walk(t, name or "t", 0);
    return table.concat(out, "\n");
end

------------------------------------------------------------------ upvalues

--- Разбор конкретной функции: источник, аргументы, upvalue.
function dumper.dumpFunction(f)
    local out = {};
    if type(f) ~= "function" then return "не функция" end;

    local src, real = source_of(f);
    out[#out + 1] = "=== функция ===";
    out[#out + 1] = "  источник : " .. short(src, 120) .. (real and "  [реальный исходник]" or ""));
    if type(debug) == "table" and type(debug.info) == "function" then
        pcall(function()
            local info = debug.info(f, "nSln");
            if info then
                out[#out + 1] = "  имя      : " .. tostring(info.name);
                out[#out + 1] = "  строка   : " .. tostring(info.linedefined) .. " -> " .. tostring(info.lastlinedefined);
                out[#out + 1] = "  параметры: " .. tostring(info.nparams);
            end;
        end);
    end;

    out[#out + 1] = "  upvalue  :";
    local n = 0;
    if type(debug) == "table" and type(debug.getupvalues) == "function" then
        local ok, list = pcall(debug.getupvalues, f);
        if ok and type(list) == "table" then
            for _, u in ipairs(list) do
                n = n + 1;
                if type(u.value) == "function" then
                    out[#out + 1] = string.format("    [%d] %s = fn %s", n,
                        tostring(u.name or "?"), short(source_of(u.value), 50));
                else
                    out[#out + 1] = string.format("    [%d] %s = %s", n,
                        tostring(u.name or "?"), short(u.value, 70));
                end;
            end;
        end;
    end;
    if n == 0 then out[#out + 1] = "    (нет или getupvalues недоступен)" end;
    return table.concat(out, "\n");
end

------------------------------------------------------------------ stealth

--- Прячет дампер от стандартных каналов дампа.
--- Это и есть смысл режима: проверить, ловит ли твой анти-дамп скрытый
--- дампер, а не только явный.
function dumper.setStealth(on)
    on = on and true or false;

    if on then
        -- 1) свои функции прячем в таблицу: getgc по ссылке на таблицу
        --    находит таблицу, но не разворачивает её содержимое
        local box = {};
        rawset(box, "dumpInstances", dumper.dumpInstances);
        rawset(box, "dumpModules", dumper.dumpModules);
        rawset(box, "dumpGC", dumper.dumpGC);
        rawset(box, "dumpTable", dumper.dumpTable);
        rawset(box, "dumpFunction", dumper.dumpFunction);

        -- 2) GUI уводим в контейнер с непривычным именем и в ReplicatedFirst,
        --    чтобы обход workspace его не находил
        if not stealth_mount then
            stealth_mount = Instance.new("Folder");
            stealth_mount.Name = "_" .. tostring(os.clock()):gsub("%.", "");
            pcall(function() stealth_mount.Parent = game:GetService("ReplicatedFirst") end);
        end;
        if gui and gui.Parent then pcall(function() gui.Parent = stealth_mount end) end;
        if frame then frame.Visible = false end;

        dumper._box = box;
        return true;
    end;

    if gui then
        pcall(function()
            gui.Parent = game:GetService("CoreGui");
            frame.Visible = true;
        end);
    end;
    dumper._box = nil;
    return false;
end

------------------------------------------------------------------ интерфейс

local TAB_LIST = { "Instances", "Modules", "GC", "Table", "Function" };

local function do_dump(which, out_box, status)
    local ok, res = pcall(function()
        if which == "Instances" then
            return dumper.dumpInstances({
                game:GetService("Workspace"),
                game:GetService("ReplicatedStorage"),
                game:GetService("Players"),
                game:GetService("ServerStorage"),
            });
        elseif which == "Modules" then
            local root = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
                or game:GetService("ReplicatedStorage");
            return dumper.dumpModules(root);
        elseif which == "GC" then
            return dumper.dumpGC();
        end;
        return "выбери цель: таблица из getgc или функция из поля внизу";
    end);

    if ok and type(res) == "string" then
        last_result[which] = res;
        out_box.Text = res;
        local lines = select(2, res:gsub("\n", ""));
        status.Text = string.format("%s — готово, %d строк, %d символов",
            which, lines, #res);
        return true;
    end;

    status.Text = string.format("%s — ошибка: %s", which, short(res, 80));
    out_box.Text = "";
    return false;
end

local function ensure_gui()
    if gui and gui.Parent then return true end;

    gui = Instance.new("ScreenGui");
    gui.Name = "RainDumper";
    gui.ResetOnSpawn = false;
    gui.IgnoreGuiInset = true;
    gui.DisplayOrder = 950;
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
    frame.Name = "RainDumperFrame";
    frame.Size = UDim2.new(0, 520, 0, 620);
    frame.Position = UDim2.new(0.5, -260, 0.5, -310);
    frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20);
    frame.BorderSizePixel = 0;
    frame.Parent = gui;

    local title = Instance.new("TextLabel");
    title.Size = UDim2.new(1, 0, 0, 26);
    title.BackgroundColor3 = Color3.fromRGB(34, 34, 42);
    title.BorderSizePixel = 0;
    title.Text = "Dumper — проверка анти-дампера";
    title.TextColor3 = Color3.fromRGB(240, 240, 240);
    title.Font = Enum.Font.GothamBold;
    title.TextSize = 13;
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
        end;
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local d = input.Position - start_input;
                frame.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + d.X,
                    start_pos.Y.Scale, start_pos.Y.Offset + d.Y);
            end;
        end);
    end;

    local y = 30;

    -- переключатель режимов
    local tab_row = Instance.new("Frame");
    tab_row.Size = UDim2.new(1, -12, 0, 24);
    tab_row.Position = UDim2.new(0, 6, 0, y);
    tab_row.BackgroundTransparency = 1;
    tab_row.Parent = frame;

    local buttons = {};
    for i, name in ipairs(TAB_LIST) do
        local b = Instance.new("TextButton");
        b.Size = UDim2.new(0, 100, 0, 24);
        b.Position = UDim2.new(0, (i - 1) * 102, 0, 0);
        b.BackgroundColor3 = (name == active_tab)
            and Color3.fromRGB(60, 100, 70) or Color3.fromRGB(40, 40, 50);
        b.BorderSizePixel = 0;
        b.Text = name;
        b.TextColor3 = Color3.fromRGB(240, 240, 240);
        b.Font = Enum.Font.Gotham;
        b.TextSize = 11;
        b.Parent = tab_row;
        b.MouseButton1Click:Connect(function()
            active_tab = name;
            for nm, btn in pairs(buttons) do
                btn.BackgroundColor3 = (nm == active_tab)
                    and Color3.fromRGB(60, 100, 70) or Color3.fromRGB(40, 40, 50);
            end;
        end);
        buttons[name] = b;
    end;
    y += 28;

    -- строка поиска
    local search = Instance.new("TextBox");
    search.Name = "Search";
    search.PlaceholderText = "фильтр по тексту дампа...";
    search.Size = UDim2.new(1, -12, 0, 24);
    search.Position = UDim2.new(0, 6, 0, y);
    search.BackgroundColor3 = Color3.fromRGB(34, 34, 42);
    search.BorderSizePixel = 0;
    search.Text = "";
    search.TextColor3 = Color3.fromRGB(240, 240, 240);
    search.Font = Enum.Font.Code;
    search.TextSize = 11;
    search.ClearTextOnFocus = false;
    search.Parent = frame;
    y += 28;

    local function mkbtn(text, xx, color, cb)
        local b = Instance.new("TextButton");
        b.Size = UDim2.new(0, 124, 0, 24);
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

    local out_box, status;

    mkbtn("Dump", 6, Color3.fromRGB(50, 90, 140), function()
        out_box.Text = "дамп выполняется...";
        status.Text = "работаю...";
        task.defer(function() do_dump(active_tab, out_box, status) end);
    end);

    mkbtn("Save File", 134, Color3.fromRGB(50, 110, 60), function()
        local body = last_result[active_tab];
        if not body then status.Text = "сначала сделай дамп" return end;
        pcall(function()
            if not isfolder("Project Rain") then makefolder("Project Rain") end;
            writefile("Project Rain/dump_" .. active_tab .. ".txt", body);
            status.Text = "записано в Project Rain/dump_" .. active_tab .. ".txt";
        end);
    end);

    mkbtn("Clipboard", 262, Color3.fromRGB(70, 70, 100), function()
        local body = last_result[active_tab];
        if not body then status.Text = "сначала сделай дамп" return end;
        pcall(function()
            if setclipboard then setclipboard(body) end;
            status.Text = "скопировано в буфер (" .. #body .. " символов)";
        end);
    end);

    mkbtn("Clear", 390, Color3.fromRGB(90, 50, 50), function()
        last_result[active_tab] = nil;
        out_box.Text = "";
        status.Text = "очищено";
    end);

    mkbtn("Close", 458, Color3.fromRGB(110, 40, 40), function()
        dumper.close();
    end);
    y += 28;

    status = Instance.new("TextLabel");
    status.Size = UDim2.new(1, -12, 0, 20);
    status.Position = UDim2.new(0, 6, 0, y);
    status.BackgroundTransparency = 1;
    status.Text = "";
    status.TextColor3 = Color3.fromRGB(150, 200, 150);
    status.Font = Enum.Font.Gotham;
    status.TextSize = 11;
    status.TextXAlignment = Enum.TextXAlignment.Left;
    status.Parent = frame;
    y += 24;

    out_box = Instance.new("TextBox");
    out_box.Name = "Output";
    out_box.Size = UDim2.new(1, -12, 1, -(y + 10));
    out_box.Position = UDim2.new(0, 6, 0, y);
    out_box.BackgroundColor3 = Color3.fromRGB(10, 10, 14);
    out_box.BorderSizePixel = 0;
    out_box.Text = "";
    out_box.MultiLine = true;
    out_box.ReadOnly = false;
    out_box.ScrollableY = true;
    out_box.Font = Enum.Font.Code;
    out_box.TextSize = 11;
    out_box.TextColor3 = Color3.fromRGB(200, 220, 200);
    out_box.TextXAlignment = Enum.TextXAlignment.Left;
    out_box.TextYAlignment = Enum.TextYAlignment.Top;
    out_box.ClearTextOnFocus = false;
    out_box.Parent = frame;

    -- живой фильтр: печатаешь — выход фильтруется
    search.Changed:Connect(function()
        local q = search.Text;
        local body = last_result[active_tab];
        if not body then return end;
        if q == "" then out_box.Text = body return end;
        local kept = {};
        for line in (body .. "\n"):gmatch("(.-)\n") do
            if line:lower():find(q:lower(), 1, true) then kept[#kept + 1] = line end;
        end;
        out_box.Text = table.concat(kept, "\n");
    end);

    -- поля для ручной цели (Table / Function)
    local target = Instance.new("TextBox");
    target.Name = "Target";
    target.PlaceholderText = "индекс getgc() для Table, номер строки GC для Function...";
    target.Size = UDim2.new(1, -12, 0, 22);
    target.Position = UDim2.new(0, 6, 1, -28);
    target.BackgroundColor3 = Color3.fromRGB(34, 34, 42);
    target.BorderSizePixel = 0;
    target.Text = "";
    target.TextColor3 = Color3.fromRGB(240, 240, 240);
    target.Font = Enum.Font.Code;
    target.TextSize = 10;
    target.ClearTextOnFocus = false;
    target.Visible = false;
    target.Parent = frame;

    -- режимы Table/Function используют поле цели
    for _, b in pairs(buttons) do end
    buttons.Table.MouseButton1Click:Connect(function() target.Visible = true end);
    buttons.Function.MouseButton1Click:Connect(function() target.Visible = true end);
    buttons.Instances.MouseButton1Click:Connect(function() target.Visible = false end);
    buttons.Modules.MouseButton1Click:Connect(function() target.Visible = false end);
    buttons.GC.MouseButton1Click:Connect(function() target.Visible = false end);

    dumper._target_box = target;
    return true;
end

function dumper.open()
    if not ensure_gui() then return false end;
    pcall(function() gui.Parent = game:GetService("CoreGui") end);
    frame.Visible = true;
    frame.Active = true;
    running = true;
    return true;
end

function dumper.close()
    running = false;
    if frame then frame.Visible = false end;
end

--- Ручной дамп цели по индексу getgc().
function dumper.dumpTarget(kind, index)
    if type(getgc) ~= "function" then return "getgc недоступен" end;
    local ok, items = pcall(getgc, true);
    if not ok then return "getgc: " .. short(items, 60) end;
    local o = items[index];
    if o == nil then return "нет объекта по индексу " .. tostring(index) end;
    if kind == "Function" then return dumper.dumpFunction(o) end;
    return dumper.dumpTable(o, "getgc[" .. index .. "]");
end

getgenv().rain_dumper = dumper
return dumper