-- Anti AP Breaker — evidence-first (server-authoritative) валидация.
--
-- ПОЧЕМУ ТАК
-- Прежняя версия была чисто реактивной: смотрела на свойства AnimationTrack
-- (Speed, Length, Priority, WeightTarget, fadetime, priority hiding). Все эти
-- свойства локальные и подделываются тривиально — достаточно выставить
-- Speed=1, Priority=Core, WeightTarget=1, и трек неотличим от «чистого».
--
-- Новый подход: мы НЕ спрашиваем у трека «похож ли он на настоящий», мы
-- спрашиваем у сервера «ждали ли мы атаку вообще». Источники истины:
--   1) Requests.ClientEffect (RemoteEvent, сервер -> клиент):
--        WeaponTrail      — оружие пошло в замах (m1 / critical / special)
--        CriticalSwirl    — точно крит
--        WeaponTrailOff   — замах отменён
--   2) атрибут персонажа StoredAction == "criticalattack" (реплицируется)
--   3) появление дочернего "Ether" — серверный спавн расхода (мантра/крит)
--
-- Ключевое свойство: легитимная атака ВСЕГДА приходит с серверным evidence.
-- У трека, пришедшего без предсказания, легитимного происхождения быть не
-- может — значит это инъекция. Breaker не может ни подавить серверный
-- RemoteEvent (тогда игра развалится у всех на клиенте), ни подделать его.
-- Единственный способ «не спалиться» — не показывать анимацию вовсе, но
-- тогда и париться нечему. Обход возможен только ценой отказа от атаки.
--
-- Старые эвристики сохранены вторым слоем (cheap-мусор они ловят быстрее),
-- всё по-прежнему гейтится флагами из меню — поведение настраиваемое то же.

local anti_ap_breaker = {}

------------------------------------------------------------------ константы
-- окна задержки (мс) между серверным evidence и появлением анимации.
-- Растягиваются на пинг: медленный пин -> широкие окна, иначе легитимные
-- атаки на быстром пинге начнут отсекаться как инъекции.
local BASE_LATENCY_MIN, BASE_LATENCY_MAX = 0, 340
local CRIT_LATENCY_MIN, CRIT_LATENCY_MAX = 0, 420
local PING_STRETCH = 1.35 -- множитель окна на пинг
local PING_CAP = 260      -- потолок растяжки, мс
local EVIDENCE_TTL_MS = 2600  -- сколько живёт неиспользованное evidence
local RESYNC_GRACE_MS = 450    -- после спавна не судим первые треки
local VERDICT_SETTLE_MS = 250  -- сколько живёт неопознанный вердикт

local FAMILY_M1 = "weapon-m1"
local FAMILY_CRIT = "weapon-critical"
local FAMILY_SPECIAL = "weapon-special"

------------------------------------------------------------------ состояние
local track_seen_at = setmetatable({}, { __mode = "k" })
local priority_cache = {}

-- защитник -> состояние доказательств
local DEFS = setmetatable({}, { __mode = "k" })
-- трек -> вердикт { auth=bool, serial=n, at=ms, grace=bool }
local VERDICT = setmetatable({}, { __mode = "k" })

------------------------------------------------------------------ утилиты
local function now_ms() return os.clock() * 1000 end

local function ping_ms()
    local p = 60
    pcall(function()
        local gg = getgenv()
        local L = gg and (gg.Latency or rawget(gg, "Latency"))
        if L and type(L.get_ping) == "function" then p = L:get_ping() * 1000 end
    end)
    return p
end

local function window(base_min, base_max)
    local stretch = math.min(ping_ms() * PING_STRETCH, PING_CAP)
    return base_min + stretch * 0.5, base_max + stretch
end

------------------------------------------------------------------ публичный API
function anti_ap_breaker:on()
    return aztup.flags.basic_validation
end

function anti_ap_breaker:compatibility()
    return aztup.flags.compatibility_mode_anti_ap_breaker
end

-- фильтры из меню; nil/unset = разрешено по умолчанию (не блокируем проверку)
function anti_ap_breaker:is_filter_on(flag)
    local ok, opts = pcall(function() return aztup_options.validation_filters end)
    if not ok or type(opts) ~= "table" or type(opts.Value) ~= "table" then return true end
    local v = opts.Value[flag]
    if v == nil then return true end
    return v and true or false
end

function anti_ap_breaker:is_filter_log_on(flag)
    local ok, opts = pcall(function() return aztup_options.validation_log_filters end)
    if not ok or type(opts) ~= "table" or type(opts.Value) ~= "table" then return false end
    local v = opts.Value[flag]
    if v == nil then return false end
    return v and true or false
end

function anti_ap_breaker:log(type, ...)
    local debug_on = false
    pcall(function() debug_on = aztup.flags.anti_ap_breaker_debug end)
    if not debug_on then return end
    if not self:is_filter_log_on(type) then return end
    -- args пакуем явно: "..." внутри вложенного closure валиден в Luau, но
    -- не переживает статический разбор (мешает проверке синтаксиса)
    local args = table.pack(...)
    pcall(function()
        setthreadidentity(8)
        Logger:short_notify("[Anti AP]",
            string.format(table.unpack(args, 1, args.n)))
    end)
end

------------------------------------------------------------------ доказательства
local function client_ready()
    local ok_lp, lp = pcall(function() return game:GetService("Players").LocalPlayer end)
    if not ok_lp or not lp then return false end
    if not lp:FindFirstChild("PlayerScripts") then return false end
    if not game:IsLoaded() then return false end
    return true
end

local function def_of(defender)
    if not defender then return nil end
    local d = DEFS[defender]
    if not d then
        d = {
            pending = {},       -- неиспользованные доказательства
            serial = 0,
            attached = false,
            conns = {},
            evidenceSeen = 0,
            injections = 0,
            cancel_at = nil,
            grace_until = client_ready() and (now_ms() + RESYNC_GRACE_MS) or (now_ms() + math.max(RESYNC_GRACE_MS, 700)),
        }
        DEFS[defender] = d
    end
    return d
end

local function drop_stale(d)
    local t = now_ms()
    for i = #d.pending, 1, -1 do
        if t - d.pending[i].at > EVIDENCE_TTL_MS then
            table.remove(d.pending, i)
        end
    end
end

local function record(d, kind, families, exactFamily, weaponKey, opts)
    opts = opts or {}
    d.evidenceSeen = d.evidenceSeen + 1
    local lo, hi = window(opts.latMin or BASE_LATENCY_MIN, opts.latMax or BASE_LATENCY_MAX)
    d.serial = d.serial + 1
    d.pending[#d.pending + 1] = {
        serial = d.serial,
        kind = kind,
        families = families or {},
        exactFamily = exactFamily or nil,
        bridge = opts.bridge ~= false,
        weaponKey = weaponKey or nil,
        at = now_ms(),
        lo = lo,
        hi = hi,
    }
    drop_stale(d)
end

-- Есть ли доказательство, объясняющее этот трек? Возвращает serial или nil.
local function match_evidence(d, families, weaponKey)
    local t = now_ms()
    local bestIndex, bestScore = nil, math.huge

    for i, ev in ipairs(d.pending) do
        local age = t - ev.at
        -- вне окна задержки — этот evidence не про наш трек
        if age <= ev.hi and age >= ev.lo then
            local ok = false
            if ev.exactFamily then
                for _, f in ipairs(families) do
                    if f == ev.exactFamily then
                        ok = true
                        break
                    end
                    -- крит нередко стартует с m1-подобного трека
                    if ev.bridge and f == FAMILY_M1 then
                        ok = true
                        break
                    end
                end
            else
                for _, f in ipairs(families) do
                    if ev.families[f] then
                        ok = true
                        break
                    end
                end
            end

            -- трек, сыгранный НЕ ТЕМ оружием, не проходит
            if ok and not (ev.weaponKey and weaponKey and ev.weaponKey ~= weaponKey) then
                local score = age
                if ev.exactFamily then score = score - 1000 end -- точное семейство приоритетнее
                if score < bestScore then
                    bestIndex, bestScore = i, score
                end
            end
        end
    end

    if bestIndex then
        local ev = d.pending[bestIndex]
        local serial = ev.serial
        table.remove(d.pending, bestIndex) -- evidence одноразовое
        return serial
    end
    return nil
end

local function families_of()
    return { FAMILY_M1, FAMILY_CRIT, FAMILY_SPECIAL }
end

-- отпечаток оружия: отсекает трек, сыгранный не тем оружием
local function weapon_key(entity)
    local ok, s = pcall(function()
        if not entity then return nil end
        local attr = entity:GetAttribute("StoredToolName")
        if type(attr) == "string" and #attr > 0 then return attr end
        local tool = entity:FindFirstChildOfClass("Tool")
        if tool and tool.Name then return tool.Name end
        return nil
    end)
    if ok then return s end
    return nil
end

-- жив ли ещё защитник (не снят ли контекст)
local function self_alive(d, defender)
    if not d or not defender then return false end
    return DEFS[defender] == d
end

------------------------------------------------------------------ сбор evidence
local function attach(defender)
    local d = def_of(defender)
    if d.attached then return d end
    d.attached = true

    local entity = defender.entity
    if not entity then return d end

    -- 1) Requests.ClientEffect* — главный серверный канал.
    -- Три канала, а не один (сверено с palantir source.lua, RangeTelegraph.init):
    --   ClientEffect       — RemoteEvent/UnreliableRemoteEvent, OnClientEvent
    --   ClientEffectLarge  — то же самое, крупные эффекты
    --   ClientEffectDirect — BindableEvent, у него .Event, а НЕ OnClientEvent
    -- Ловля только первого оставляла дыру: часть реплицируемых эффектов
    -- приходит в Large/Direct, и без них атака выглядит как инъекция.
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local requests = rs:FindFirstChild("Requests")
        if not requests then
            local t0 = os.clock()
            while os.clock() - t0 < 3 do
                requests = rs:FindFirstChild("Requests")
                if requests then break end
                task.wait()
            end
        end
        if not requests then return end

        local function on_effect(effect, data)
            if not self_alive(d, defender) then return end
            if type(effect) ~= "string" then return end
            local t = now_ms()
            if effect == "WeaponTrailOff" then
                d.pending = {}      -- отмена замаха: ожидания снимаем
                d.cancel_at = t
                return
            end
            local wk = weapon_key(entity)
            if effect == "WeaponTrail" then
                record(d, "replicated-weapon-trail",
                    { [FAMILY_M1] = true, [FAMILY_CRIT] = true, [FAMILY_SPECIAL] = true },
                    nil, wk, { latMax = BASE_LATENCY_MAX })
            elseif effect == "CriticalSwirl" then
                record(d, "replicated-critical-effect",
                    { [FAMILY_CRIT] = true }, FAMILY_CRIT, wk,
                    { latMin = CRIT_LATENCY_MIN, latMax = CRIT_LATENCY_MAX })
            end
        end

        for _, channel in ipairs({ "ClientEffect", "ClientEffectLarge" }) do
            local ev = requests:FindFirstChild(channel)
            if ev and (ev:IsA("RemoteEvent") or ev:IsA("UnreliableRemoteEvent")) then
                d.conns[#d.conns + 1] = ev.OnClientEvent:Connect(on_effect)
            end
        end

        -- Direct — BindableEvent: подписка через .Event
        local direct = requests:FindFirstChild("ClientEffectDirect")
        if direct then
            local bindable = direct:IsA("BindableEvent") and direct
                or (direct:FindFirstChild("Event") and direct:FindFirstChild("Event"))
            if bindable and bindable.Event then
                d.conns[#d.conns + 1] = bindable.Event:Connect(on_effect)
            end
        end
    end)

    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        if not lp then return end
        d.conns[#d.conns + 1] = lp.ChildAdded:Connect(function(c)
            if not self_alive(d, defender) then return end
            if c.Name == "PlayerScripts" then
                d.grace_until = math.max(d.grace_until or 0, now_ms() + 600)
            end
        end)
    end)

    -- 2) атрибуты персонажа: StoredAction == criticalattack
    pcall(function()
        d.conns[#d.conns + 1] = entity.AttributeChanged:Connect(function(name)
            if not self_alive(d, defender) then return end
            -- смена оружия инвалидирует доказательства прошлого оружия
            if name == "StoredToolName" or name == "PrimaryWeapon" or name == "Weapon" then
                d.pending = {}
                return
            end
            if name ~= "StoredAction" then return end
            local ok, v = pcall(function() return entity:GetAttribute("StoredAction") end)
            if not ok or type(v) ~= "string" or v:lower() ~= "criticalattack" then return end
            record(d, "replicated-stored-critical",
                { [FAMILY_CRIT] = true }, FAMILY_CRIT, weapon_key(entity),
                { latMin = CRIT_LATENCY_MIN, latMax = CRIT_LATENCY_MAX })
        end)
    end)

    -- 3) DescendantAdded: Ether = серверный спавн расхода
    pcall(function()
        d.conns[#d.conns + 1] = entity.DescendantAdded:Connect(function(inst)
            if not self_alive(d, defender) then return end
            if type(inst) ~= "Instance" then return end
            if inst.Name ~= "Ether" then return end
            d.last_ether = now_ms()
        end)
    end)

    -- 4) сброс на респауне
    pcall(function()
        local h = entity:FindFirstChildOfClass("Humanoid")
        if not h then return end
        d.conns[#d.conns + 1] = h.Died:Connect(function()
            d.pending = {}
            d.grace_until = now_ms() + RESYNC_GRACE_MS
        end)
    end)

    return d
end

------------------------------------------------------------------ проверка
function anti_ap_breaker:initial_check(defender, track)
    if not defender or not self:on() then return false end
    if not defender.is_player then return false end

    local d = attach(defender)
    if not d then return false end

    -- ---- слой 1: серверное evidence. Каждый трек проверяем один раз.
    if VERDICT[track] == nil then
        local t = now_ms()
        if not client_ready() and t < (d.grace_until or 0) + 200 then
            if (d.grace_until or 0) < t + 500 then
                d.grace_until = t + 500
            end
        end
        local wk = weapon_key(defender.entity)
        local serial = match_evidence(d, families_of(), wk)

        if serial then
            VERDICT[track] = { auth = true, serial = serial, at = t }
        elseif t < (d.grace_until or 0) then
            -- первые мс после спавна: данных ещё нет, не рубим
            VERDICT[track] = { auth = true, serial = 0, at = t, grace = true }
        else
            -- Серверного evidence нет. У настоящей атаки оно обязано быть.
            VERDICT[track] = { auth = false, at = t }
            d.injections = d.injections + 1
            self:log("No Evidence", "Track without server evidence (injections: %d)", d.injections)
        end
    end

    -- ---- слой 2: эвристики (cheap-мусор ловится ими быстрее всего)
    if track.Speed >= aztup.flags.anti_ap_breaker_max_speed
        and self:is_filter_on("S >= X (S = Speed)") then
        self:log("S >= X (S = Speed)", "Speed is too high, Speed: %.1f", track.Speed)
        return true
    end

    if track.Length / track.Speed <= (aztup.flags.anti_ap_breaker_length_ms / 1000)
        and self:is_filter_on("Length <= Xms") then
        self:log("Length <= Xms", "Length is too short, Length: %.1f", track.Length)
        return true
    end

    if track.Priority == Enum.AnimationPriority.Core and self:is_filter_on("Core Priority") then
        self:log("Core Priority", "Track is core priority")
        return true
    end

    if track.Priority == Enum.AnimationPriority.Idle and self:is_filter_on("Idle Priority") then
        self:log("Idle Priority", "Track is idle priority")
        return true
    end

    if track.Speed == 0 and self:is_filter_on("Speed == 0") then
        return self:log("Speed == 0", "Track is frozen")
    end

    track_seen_at[track] = tick()
    priority_cache[track] = track.Priority

    task.delay(30, function()
        priority_cache[track] = nil
        VERDICT[track] = nil
    end)

    return false
end

function anti_ap_breaker:clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function anti_ap_breaker:handle_fadetime(track)
    return track.WeightCurrent < self:clamp(
        self:clamp(track.WeightTarget / 2, 1 / 120, tick() - (track_seen_at[track] or 0)), 0, 0.2)
end

local asset_id = require("@src/utility/asset_id")

function anti_ap_breaker:handle_priority_hiding(defender, track)
    local humanoid = defender.entity:FindFirstChild("Humanoid")
    if not humanoid then return false end
    local highest_priority = 1000

    for _, other_track in humanoid:GetPlayingAnimationTracks() do
        if track == other_track then continue end
        if other_track.Priority.Value == 1000 then continue end
        if track.Priority.Value >= other_track.Priority.Value then continue end
        if other_track.WeightCurrent <= track.WeightCurrent / 2 then continue end
        if other_track.WeightTarget <= 0.3 then continue end
        if other_track.Speed == 0 and other_track.TimePosition >= track.Length - 0.01
            or other_track.TimePosition <= 0.01 then continue end
        if not asset_id.get_id(other_track.Animation.AnimationId) then continue end
        if self:final_check(defender, other_track, true) then continue end
        -- учитываем только треки, прошедшие аутентификацию
        local v = VERDICT[other_track]
        if v == nil or v.auth then
            highest_priority = math.min(highest_priority, other_track.Priority.Value)
        end
    end

    return highest_priority ~= 1000 and highest_priority > track.Priority.Value
end

function anti_ap_breaker:final_check(defender, track, skip)
    if not self:on() then return false end

    local alive = self:is_playing(track, defender.entity)

    -- ---- слой 1: серверное evidence
    local v = VERDICT[track]
    if v and not v.auth and not v.grace and not skip and alive then
        -- неопознанный трек, переживший settle-окно, — это инъекция:
        -- сервер об атаке не сообщал, значит атаки не было
        if (now_ms() - v.at) > VERDICT_SETTLE_MS then
            self:log("No Evidence", "Unauthenticated track survived settle window")
            return true
        end
    end

    -- ---- слой 2: эвристики
    if alive and self:handle_fadetime(track) and self:is_filter_on("Fadetime") then
        if not skip then
            self:log("Fadetime", "Track is faded", track.WeightCurrent)
        end
        return true
    end

    if track.WeightTarget <= (aztup.flags.anti_ap_breaker_minimum_wt / 100)
        and self:is_filter_on("WT <= X (WT = WeightTarget)") then
        if track.WeightCurrent < (aztup.flags.anti_ap_breaker_minimum_wt / 100) or not alive then
            if not skip then
                self:log("WT <= X (WT = WeightTarget)",
                    "Track is too lightweight. WT - %.2f, WC - %.2f",
                    track.WeightTarget, track.WeightCurrent)
            end
            return true
        end
    end

    if self:is_filter_on("Priority Hiding") and not skip
        and self:handle_priority_hiding(defender, track) then
        if not skip then
            self:log("Priority Hiding", "Track is hidden behind another anims priority.")
        end
        return true
    end

    return false
end

function anti_ap_breaker:is_fully_dead(track, entity)
    local ok, res = pcall(function()
        return not table.find(entity:FindFirstChild("Humanoid"):GetPlayingAnimationTracks(), track)
    end)
    if ok then return res end
    return false
end

function anti_ap_breaker:is_playing(track, entity)
    if track.IsPlaying then return true end
    local ok, res = pcall(function()
        return table.find(entity:FindFirstChild("Humanoid"):GetPlayingAnimationTracks(), track)
    end)
    if ok then return res end
    return false
end

------------------------------------------------------------------ диагностика
-- Сколько evidence пришло, сколько инъекций отбито.
-- print(getgenv().RAIN_ANTI_AP_STATS())
function anti_ap_breaker:stats()
    local out = {}
    for _, d in pairs(DEFS) do
        out[#out + 1] = ("evidence=%d injections=%d pending=%d")
            :format(d.evidenceSeen, d.injections, #d.pending)
    end
    if #out == 0 then return "anti-ap: нет активных защитников" end
    return "anti-ap: " .. table.concat(out, " | ")
end

_G.RAIN_ANTI_AP_STATS = function()
    return anti_ap_breaker:stats()
end

return anti_ap_breaker
