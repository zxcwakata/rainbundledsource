-- Адаптер Luma GUI/Library -> UI-библиотека Rain.
--
-- Автоматизация Luma использует из своей Library девять вещей:
-- AddToRegistry, Font, MainColor, FontColor, GetDarkerColor, OutlineColor,
-- AccentColor, MakeDraggable, Notify/NotifyWithSound/ManuallyManagedNotify.
-- Все они уже есть в UI-слое Rain, поэтому тянуть Luma-овскую библиотеку
-- (373 KB, с собственными иконками и окнами) незачем: две библиотеки
-- начали бы драться за CoreGui.
--
-- Здесь только проксирование на getgenv().Library. Если меню ещё не
-- поднято — методы безопасные no-op, чтобы фарма могла стартовать раньше UI.

local Library = {}

local function rain_lib()
    local ok, lib = pcall(function() return getgenv().Library end);
    if ok and lib then return lib end;
    return nil;
end

-- цвета/шрифты живут на самой библиотеке Rain; дефолты — на случай,
-- когда UI ещё не готов
local function prop(name, dflt)
    local lib = rain_lib();
    local v = lib and lib[name];
    if v ~= nil then return v end;
    return dflt;
end

Library.Font = prop("Font", Enum.Font.Gotham);
Library.MainColor = prop("MainColor", Color3.fromRGB(40, 32, 50));
Library.BackgroundColor = prop("BackgroundColor", Color3.fromRGB(28, 22, 36));
Library.FontColor = prop("FontColor", Color3.fromRGB(245, 238, 250));
Library.AccentColor = prop("AccentColor", Color3.fromRGB(243, 168, 214));
Library.OutlineColor = prop("OutlineColor", Color3.fromRGB(110, 86, 132));
Library.RiskColor = prop("RiskColor", Color3.fromRGB(255, 96, 128));

function Library:GetDarkerColor(color)
    local lib = rain_lib();
    if lib and type(lib.GetDarkerColor) == "function" then
        local ok, res = pcall(lib.GetDarkerColor, lib, color);
        if ok and res then return res end;
    end;
    -- тот же приём, что в Luma: масштабируем каналы, но не даём уйти в ноль
    return Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7);
end

function Library:Notify(message, duration)
    local lib = rain_lib();
    if not lib or type(lib.Notify) ~= "function" then return end;
    pcall(function() lib:Notify(message, duration or 5) end);
end

function Library:NotifyWithSound(message, duration)
    local lib = rain_lib();
    if not lib then return end;
    if type(lib.NotifyWithSound) == "function" then
        pcall(function() lib:NotifyWithSound(message, duration or 5) end);
    elseif type(lib.Notify) == "function" then
        pcall(function() lib:Notify(message, duration or 5) end);
    end;
end

function Library:ManuallyManagedNotify(message, duration)
    -- в Luma уведомление само не гасится, пока не позовут HideNotification
    local lib = rain_lib();
    if not lib then return end;
    if type(lib.ManuallyManagedNotify) == "function" then
        pcall(function() lib:ManuallyManagedNotify(message, duration) end);
    elseif type(lib.Notify) == "function" then
        pcall(function() lib:Notify(message, duration) end);
    end;
end

function Library:HideNotification()
    local lib = rain_lib();
    if lib and type(lib.HideNotification) == "function" then
        pcall(function() lib:HideNotification() end);
    end;
end

function Library:MakeDraggable(guiObject)
    local lib = rain_lib();
    if lib and type(lib.MakeDraggable) == "function" then
        local ok = pcall(function() lib:MakeDraggable(guiObject) end);
        if ok then return end;
    end;
    -- запасной вариант: перетаскивание мышью вручную
    if type(guiObject) ~= "Instance" then return end;
    local dragging, start_pos, start_input = false, nil, nil;
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true;
            start_pos = guiObject.Position;
            start_input = input.Position;
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end;
            end);
        end;
    end);
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - start_input;
            guiObject.Position = UDim2.new(
                start_pos.X.Scale, start_pos.X.Offset + d.X,
                start_pos.Y.Scale, start_pos.Y.Offset + d.Y
            );
        end;
    end);
end

function Library:AddToRegistry(...) return nil end

-- Luma-овские модули читают shared.*; в Rain этого нет — даём пустой контейнер
local shared = getgenv().Luma_shared;
if type(shared) ~= "table" then
    shared = { verbose = false };
    getgenv().Luma_shared = shared;
end

Library.shared = shared;

return Library