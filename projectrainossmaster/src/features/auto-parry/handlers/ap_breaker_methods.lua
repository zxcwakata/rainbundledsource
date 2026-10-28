-- AP Breaker: переносимые из Palantir методы ломания.
--
-- Palantir (palantir source.lua, Features/Combat/APBreakerCore) держит три
-- метода и даёт выбор в дропдауне. Все три перенесены сюда как отдельные
-- методы — они принципиально разные и по-разному ведут себя на сервере,
-- поэтому выбор за пользователем.
--
--   Method 1 — Flood / mask.
--     Шесть анимаций-масок грузятся на Animator цели и держатся на
--     Enum.AnimationPriority.Action4. На каждый AnimationPlayed маска
--     переигрывается. Настоящая анимация формально не исчезает, но её
--     вес выдавливает более высокий приоритет. Сервер при этом видит
--     всё как обычно — маска клиентская.
--
--   Method 2 — Priority demotion + Core hold.
--     На AnimationPlayed атакующего трека: все играющие треки кроме
--     Idle/Movement снимаются в Core, сам трек тоже ставится в Core,
--     через core_hold_ms приоритеты возвращаются как были. Это то, что в
--     Palantir названо "Method 2 Fake Anim Time" (ползунок 5..200 мс).
--
--   Method 3 — Method 1 + Method 2 одновременно (в Palantir это Method 3,
--     который зовёт f1266 + f1257 + f1279).
--
-- Про общее ограничение см. шапку anti-ap-breaker.lua: ломание не отменяет
-- серверный RemoteEvent — оно лишь убирает анимацию, то есть фактически
-- отказывается от пари. Методы дают разную цену этому, но не дают большего.

local ap_methods = {}

-- Анимации-маски. Список из Palantir APBreakerCore.
ap_methods.MASK_IDS = {
    "rbxassetid://9149348937",
    "rbxassetid://10880473795",
    "rbxassetid://5778357994",
    "rbxassetid://16873988732",
    "rbxassetid://7620630583",
    "rbxassetid://8378263543",
}

local now_ms = (tick and function() return math.floor(tick() * 1000) end)
    or os.clock
local function now() return now_ms() end

------------------------------------------------------------------ Method 1

--- Flood: маски на Action4, переигрывание на каждой анимации.
---@param humanoid Instance
---@param opts table
---@return function cleanup
function ap_methods.flood(humanoid, opts)
    opts = opts or {};
    local animator = humanoid:FindFirstChildOfClass("Animator");
    if not animator then
        animator = Instance.new("Animator");
        pcall(function() animator.Parent = humanoid end);
    end
    if not animator then return function() end end;

    local tracks = {}          -- mask track -> animation id
    local by_id = {}           -- animation id -> true
    local holding = false

    for _, id in ipairs(ap_methods.MASK_IDS) do
        local anim = Instance.new("Animation");
        anim.AnimationId = id;
        anim.Name = "RAIN_AP_MASK";
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end);
        -- сам Animation не уничтожаем: AnimationTrack на него ссылается,
        -- Destroy() рвёт трек
        if ok and track then
            pcall(function() track.Priority = Enum.AnimationPriority.Action4 end);
            tracks[#tracks + 1] = track;
            by_id[id] = true;
        end
    end

    -- intensity: минимальный интервал между переигрываниями, мс
    local min_interval = math.floor(1000 / math.max(1, opts.intensity or 500))
    local last = 0

    local conn = animator.AnimationPlayed:Connect(function()
        if holding then return end
        local t = now()
        if t - last < min_interval then return end
        last = t;
        holding = true;
        for _, track in ipairs(tracks) do
            pcall(function()
                track:Play(0);
                track.TimePosition = 0;
            end);
        end;
        task.delay(math.max(0.01, (opts.core_hold_ms or 40) / 1000), function()
            holding = false;
        end);
    end)

    return function()
        pcall(function() conn:Disconnect() end);
        for _, track in ipairs(tracks) do
            pcall(function() track:Stop(); track:Destroy() end);
        end;
        table.clear(tracks);
        table.clear(by_id);
    end;
end

------------------------------------------------------------------ Method 2

--- Priority demotion: снять чужие треки в Core, подержать, вернуть.
---@param humanoid Instance
---@param opts table  intensity, core_hold_ms, should_break(track) -> bool
---@return function cleanup
function ap_methods.demote(humanoid, opts)
    opts = opts or {};
    local animator = humanoid:FindFirstChildOfClass("Animator");
    if not animator then return function() end end;

    local holding = false
    local hold_ms = opts.core_hold_ms or 40

    -- intensity ограничивает частоту срабатываний
    local min_interval = math.floor(1000 / math.max(1, opts.intensity or 500))
    local last = 0

    local function apply(track)
        if holding then return end

        -- треки, которые мы сами и так опустили
        if track.Priority == Enum.AnimationPriority.Core then return end
        -- Idle/Movement не трогаем: это перемещение, его демонтаж ломает
        -- визуал персонажа без выигрыша
        if track.Priority == Enum.AnimationPriority.Idle then return end

        -- вызывающий может отфильтровать по тегу/таймингу
        if opts.should_break and not opts.should_break(track) then return end

        local t = now()
        if t - last < min_interval then return end
        last = t;
        holding = true;

        local saved = {}
        for _, other in ipairs(animator:GetPlayingAnimationTracks()) do
            if other ~= track
                and other.Priority ~= Enum.AnimationPriority.Movement
                and other.Priority ~= Enum.AnimationPriority.Idle then
                saved[other] = other.Priority;
                pcall(function() other.Priority = Enum.AnimationPriority.Core end);
            end
        end;

        local own = track.Priority;
        pcall(function() track.Priority = Enum.AnimationPriority.Core end);

        task.delay(hold_ms / 1000, function()
            -- восстанавливаем только то, что ещё играет и не было снято
            for other, prio in pairs(saved) do
                if other.IsPlaying then
                    pcall(function() other.Priority = prio end);
                end
            end
            if track.IsPlaying then
                pcall(function() track.Priority = own end);
            end
            holding = false;
        end);
    end

    local conn = animator.AnimationPlayed:Connect(function(track) apply(track) end);

    return function()
        pcall(function() conn:Disconnect() end);
    end;
end

------------------------------------------------------------------ Method 3

--- Flood + demotion одновременно (Method 3 из Palantir).
function ap_methods.combined(humanoid, opts)
    local a = ap_methods.flood(humanoid, opts);
    local b = ap_methods.demote(humanoid, opts);
    return function()
        a();
        b();
    end;
end

------------------------------------------------------------------ реестр

ap_methods.METHODS = {
    ["Flood (Mask)"] = ap_methods.flood,
    ["Priority Demotion"] = ap_methods.demote,
    ["Flood + Demotion"] = ap_methods.combined,
}

return ap_methods