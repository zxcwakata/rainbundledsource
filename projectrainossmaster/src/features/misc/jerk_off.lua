-- Jerk Off.
--
-- Взят из "Jerk OFF.lua": туул "Jerk Off" кладётся в рюкзак, при экипировке
-- грузятся две анимации, и на каждом кадре RenderStepped они перематываются на
-- заданную позицию — так цикл не даёт им прерваться.
--
-- Отличия от оригинала:
--   * Priority = Action4 + AdjustWeight(1). Оригинал полагался только на
--     повторный Play(), из-за чего анимации персонажа всё равно могли
--     перебить трек. Action4 — максимальный приоритет.
--   * выключение тумблера снимает туул (и из рюкзака, и из руки), гасит
--     треки и рвёт все соединения;
--   * туул пересоздаётся после респавна.
--
-- ВАЖНО: экземпляр Animation не уничтожается после LoadAnimation. Оригинал
-- его тоже не трогает, а вариант с Destroy() рвёт трек — анимация перестаёт
-- играть.

local feat;
local equipped = false;
local active = false;
local anims = {};      -- экземпляры Animation: держим живыми, пока нужен трек
local tracks = {};
local anim_conns = {};
local conns = {};

-- Диагностика: warn() молчит в консоль, но пишет в RAIN_ERRORS.
-- Смотри getgenv().RAIN_ERRDUMP() -> rain_errors.txt.
local function dbg(...)
	local n = select("#", ...)
	if n == 0 then return end
	local parts = {}
	for i = 1, n do
		local ok, s = pcall(tostring, (select(i, ...)))
		parts[#parts + 1] = ok and s or "?"
	end
	warn("[jerk] " .. table.concat(parts, " "));
end

local function clear(list)
	for i = #list, 1, -1 do
		local c = list[i];
		pcall(function() c:Disconnect() end);
		list[i] = nil;
	end;
end

local function player()
	local ok, p = pcall(function() return local_player.instance end);
	if ok and p then return p end;
	return game:GetService("Players").LocalPlayer;
end

local function stop_anims()
	equipped = false;
	clear(anim_conns);
	for i = #tracks, 1, -1 do
		local t = tracks[i];
		pcall(function()
			t:Stop();
			t:Destroy();
		end);
		tracks[i] = nil;
	end;
	for i = #anims, 1, -1 do
		pcall(function() anims[i]:Destroy() end);
		anims[i] = nil;
	end;
end

-- Один трек: грузим анимацию, даём максимальный приоритет и на каждом кадре
-- возвращаем её на time_pos, если доиграла до threshold.
local function add_track(anim_id, time_pos, threshold)
	local character = local_player.character;
	local humanoid = character and character:FindFirstChildOfClass("Humanoid");
	if not humanoid then
		dbg("нет Humanoid, character=", tostring(character));
		return;
	end;

	local anim = Instance.new("Animation");
	anim.AnimationId = "rbxassetid://" .. anim_id;
	table.insert(anims, anim);          -- держим живым, трек ссылается на него

	local track;
	local ok, err = pcall(function() track = humanoid:LoadAnimation(anim) end);
	if not ok or not track then
		dbg("LoadAnimation не удался id=" .. anim_id, tostring(err));
		return;
	end;

	pcall(function()
		track.Priority = Enum.AnimationPriority.Action4;
		track:AdjustWeight(1);
	end);

	tracks[#tracks + 1] = track;
	dbg("трек загружен id=" .. anim_id,
		"playing=" .. tostring(track.IsPlaying),
		"len=" .. string.format("%.3f", track.Length),
		"prio=" .. tostring(track.Priority));

	table.insert(anim_conns, services.RunService.RenderStepped:Connect(function()
		pcall(function()
			if not equipped then
				track:Stop();
			elseif track.TimePosition >= threshold or track.IsPlaying == false then
				track:Play(0);
				track.TimePosition = time_pos;
			end;
		end);
	end));

	pcall(function()
		track:Play(0);
		track.TimePosition = time_pos;
	end);

	-- отложенный отчёт: сразу после Play() состояние ещё не устоялось
	task.defer(function()
		if track and track.Parent == nil and not track.IsPlaying then
			dbg("трек id=" .. anim_id .. " не играет после запуска, len=" ..
				string.format("%.3f", track.Length));
		end;
	end);
end

local function start_anims()
	stop_anims();
	equipped = true;
	dbg("экипирован, старт анимаций");
	add_track("72042024", 0.5, 0.9);
	add_track("168268306", 1, 1.001);
end

local function remove_tool()
	-- туул живёт в рюкзаке, пока не экипирован, и в персонаже, пока экипирован
	for _, holder in ipairs({
		player():FindFirstChildOfClass("Backpack"),
		local_player.character,
	}) do
		if holder then
			local t = holder:FindFirstChild("Jerk Off");
			if t then pcall(function() t:Destroy() end) end;
		end;
	end;
end

local function give_tool()
	remove_tool();

	local bp = player():FindFirstChildOfClass("Backpack");
	if not bp then
		local ok, b = pcall(function() return player():WaitForChild("Backpack", 5) end);
		if ok then bp = b end;
	end;
	if not bp then
		dbg("нет Backpack");
		return;
	end;

	local t = Instance.new("Tool");
	t.Name = "Jerk Off";
	t.RequiresHandle = false;
	t.ToolTip = "Loops the Jerk animation over anything else.";
	t.Parent = bp;

	table.insert(conns, t.Equipped:Connect(function() start_anims() end));
	table.insert(conns, t.Unequipped:Connect(function()
		dbg("снят с руки");
		stop_anims();
	end));

	dbg("тул выдан, backpack=" .. tostring(bp:GetFullName()));
end

feat = Feature:new("jerk_off", services.RunService.Heartbeat, function() end);

function feat:enable()
	active = true;
	stop_anims();
	clear(conns);
	give_tool();

	-- после респавна персонажа прежние треки мертвы, всё собираем заново.
	-- Рюкзак и туул появляются не в тот же кадр, поэтому отложенный вызов.
	table.insert(conns, local_player.instance.CharacterAdded:Connect(function()
		if not active then return end;
		dbg("респавн");
		stop_anims();
		task.defer(function()
			if active then give_tool() end;
		end);
	end));
end;

function feat:disable()
	active = false;
	dbg("тумблер выключен, забираем тул");
	stop_anims();
	clear(conns);
	remove_tool();
end;

return feat