-- AP Breaker: применение выбранного метода (см. ap_breaker_methods.lua).
--
-- Методы вешаются на Animator каждого персонажа в игре: свои треки видны
-- клиенту только у них, и демонтировать/накрывать анимацию можно только
-- там. Переподключается на респавне и появлении новых NPC.
--
-- Настройки приходят из UI (aztup_options), читаются на каждый вызов
-- apply(), чтобы смена дропдауна подхватывалась без перезапуска скрипта.

local ap_controller = {}

local methods = require("@src/features/auto-parry/handlers/ap_breaker_methods");
local asset_id = require("@src/utility/asset_id");

local installed = {}      -- humanoid -> cleanup
local conns = {}
local enabled = false

local function opts()
    local o = aztup_options or {};
    local method = "Flood (Mask)";
    if type(o.ap_breaker_method) == "table" and o.ap_breaker_method.Value then
        method = o.ap_breaker_method.Value;
    end
    local intensity, hold;
    if type(o.ap_breaker_intensity) == "table" then
        intensity = tonumber(o.ap_breaker_intensity.Value);
    end
    if type(o.ap_breaker_core_hold_ms) == "table" then
        hold = tonumber(o.ap_breaker_core_hold_ms.Value);
    end
    return methods.METHODS[method], {
        method = method,
        intensity = intensity or 500,
        core_hold_ms = hold or 40,
    };
end

--- Ставит метод на один humanoid.
local function bind_humanoid(humanoid)
    if installed[humanoid] then return end

    -- для demotion полезно знать, что анимация вообще атакующая:
    -- без фильтра он снимал бы в Core любую анимацию, включая свои же
    -- маски, и они бы дрались между собой
    local o = {}
    local fn, settings = opts();
    if not fn then return end;

    if settings.method ~= "Flood (Mask)" then
        local filter = ap_controller.animation_filter;
        o.should_break = filter;
    end

    local ok, cleanup = pcall(fn, humanoid, {
        intensity = settings.intensity,
        core_hold_ms = settings.core_hold_ms,
        should_break = o.should_break,
    });

    if ok and type(cleanup) == "function" then
        installed[humanoid] = cleanup;
    end
end

--- Разрешает анимацию: вернуть true, если это атака врага.
--- Заполняется в anti-ap-breaker, у которого есть таблица таймингов.
ap_controller.animation_filter = nil

function ap_controller:rebind_all()
    self:detach_all();
    if not enabled then return end;
    self:bind_all();
end

function ap_controller:bind_all()
    local players = game:GetService("Players");

    for _, plr in ipairs(players:GetPlayers()) do
        local function bind_char(character)
            if not character then return end
            local hum = character:FindFirstChildOfClass("Humanoid");
            if hum then bind_humanoid(hum) end
        end
        bind_char(plr.Character);
        conns[#conns + 1] = plr.CharacterAdded:Connect(bind_char);
    end;

    -- NPC: персонажи без игрока
    local function bind_model(model)
        if not model:IsA("Model") then return end
        if players:GetPlayerFromCharacter(model) then return end
        local hum = model:FindFirstChildOfClass("Humanoid");
        if hum then bind_humanoid(hum) end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function() bind_model(obj) end);
    end

    conns[#conns + 1] = workspace.DescendantAdded:Connect(function(obj)
        pcall(function() bind_model(obj) end);
    end);
end

function ap_controller:detach_all()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end;
    table.clear(conns);
    for humanoid, cleanup in pairs(installed) do
        pcall(function() cleanup() end);
        installed[humanoid] = nil;
    end
end

function ap_controller:set_enabled(val)
    val = val and true or false;
    if val == enabled then return end;
    enabled = val;
    if enabled then self:bind_all() else self:detach_all() end;
end

function ap_controller:is_enabled()
    return enabled;
end

return ap_controller