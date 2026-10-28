local Settings = {
	folder = "Project Rain/Dump",
	stealth = false,
	keepGoing = true,
	writeManifest = true,
	skipIfUnchanged = true,
	chunkCap = 200000,
	stopOnFirstError = false,
	hookLoad = true,
	hookGetgenvLoadstring = true,
	hookRequireString = true,
};

local state = {
	index = 0,
	entries = {},
	busy = false,
	dead = false,
};

local safeWrite = function(path, body)
	local ok, err = pcall(writefile, path, body);
	return ok, err;
end

local ensureFolder = function()
	local ok = pcall(function()
		if not isfolder(Settings.folder) then
			makefolder(Settings.folder);
		end;
	end);
	return ok;
end

local sanitize = function(s)
	s = tostring(s or "");
	s = s:gsub("[^%w_%-%. ]", "_");
	if #s == 0 then return "chunk" end;
	if #s > 80 then s = s:sub(1, 80) end;
	return s;
end

local hashOf = function(s)
	local h = 5381;
	local step = math.max(1, math.floor(#s / 512));
	local i = 1;
	local n = #s;
	while i <= n do
		h = (h * 33 + s:byte(i)) % 0xFFFFFFFF;
		i = i + step;
	end;
	return string.format("%08x", h);
end

local lastHash = {};

local extractName = function(chunk, nameArg)
	local candidate = nameArg;
	if type(candidate) ~= "string" or candidate == "" then
		local m = string.match(chunk, "%-%-%s*@module%s*%(?([^%)]+)%)?") or string.match(chunk, "%-%-%-%s*%[([^%]]+)%]");
		if m and m ~= "" then candidate = m end;
	end;
	if type(candidate) ~= "string" or candidate == "" then
		candidate = state.entries[#state.entries + 1] and state.entries[#state.entries].name or "chunk";
	end;
	return sanitize(candidate:gsub("^=", ""));
end

local record = function(chunk, nameArg, vector)
	if state.busy then return end;
	if type(chunk) ~= "string" then return end;
	if #chunk == 0 then return end;
	if #chunk > Settings.chunkCap then return end;
	if #chunk < 4 then return end;

	state.busy = true;
	pcall(function()
		state.index = state.index + 1;
		local id = state.index;
		local name = extractName(chunk, nameArg);
		local hash = hashOf(chunk);

		local entry = {
			i = id,
			name = name,
			len = #chunk,
			hash = hash,
			via = vector,
			file = nil,
		};

		if Settings.skipIfUnchanged and lastHash[hash] then
			entry.file = lastHash[hash];
			entry.dup = true;
		else
			ensureFolder();
			local fname = string.format("%04d_%s_%s.lua", id, name, hash);
			local path = Settings.folder .. "/" .. fname;
			local ok, err = safeWrite(path, chunk);
			if ok then
				entry.file = path;
				lastHash[hash] = path;
			else
				entry.err = tostring(err);
			end;
		end;

		state.entries[#state.entries + 1] = entry;

		if Settings.writeManifest then
			local lines = {};
			for _, e in ipairs(state.entries) do
				lines[#lines + 1] = string.format(
					"%04d  %-9s %-34s %-28s %s%s",
					e.i,
					tostring(e.len),
					e.name,
					tostring(e.via),
					tostring(e.file or ("ERR:" .. tostring(e.err))),
					e.dup and "  [dup]" or ""
				);
			end;
			safeWrite(Settings.folder .. "/_manifest.txt", table.concat(lines, "\n"));
		end;
	end);
	state.busy = false;
end

local makeHook = function(original, vector)
	return function(chunk, ...)
		local nameArg = select(2, ...);
		record(chunk, nameArg, vector);
		return original(chunk, ...);
	end;
end

local wrap = function(fn, vector)
	if type(fn) ~= "function" then return nil end;
	local proxy = makeHook(fn, vector);
	if type(newcclosure) == "function" then
		local ok, wrapped = pcall(newcclosure, proxy);
		if ok and type(wrapped) == "function" then return wrapped end;
	end;
	return proxy;
end;

local env = getgenv();
local saved = {
	loadstring = rawget(env, "loadstring"),
	load = rawget(env, "load"),
	require = type(require) == "function" and require or nil,
};

local installed = {};

local install = function(name, target, key)
	local original = rawget(env, name);
	if type(original) ~= "function" then return end;
	local wrapped = wrap(original, name);
	if not wrapped then return end;
	rawset(env, name, wrapped);
	installed[name] = { key = key, original = original };
end

install("loadstring", env, "loadstring");

if Settings.hookLoad and type(rawget(env, "load")) == "function" then
	install("load", env, "load");
end;

if Settings.hookGetgenvLoadstring then
	install("loadstring", env, "loadstring");
end;

if Settings.hookRequireString then
	local originalRequire = saved.require;
	if type(originalRequire) == "function" then
		local wrapped = wrap(originalRequire, "require");
		if wrapped then
			env.require = wrapped;
			installed.require = { key = "require", original = originalRequire };
		end;
	end;
end;

local Control = {};

function Control.stats()
	local total, bytes, dups = 0, 0, 0;
	for _, e in ipairs(state.entries) do
		total = total + 1;
		bytes = bytes + e.len;
		if e.dup then dups = dups + 1 end;
	end;
	return { total = total, bytes = bytes, dups = dups };
end

function Control.entries()
	return state.entries;
end

function Control.reset()
	state.entries = {};
	state.index = 0;
	lastHash = {};
end

function Control.stop()
	for name, data in pairs(installed) do
		pcall(function() rawset(env, name, data.original) end);
	end;
	installed = {};
	state.dead = true;
	return true;
end

function Control.resume()
	if not state.dead then return false end;
	state.dead = false;
	install("loadstring", env, "loadstring");
	if Settings.hookLoad then install("load", env, "load") end;
	if Settings.hookRequireString and saved.require then
		local wrapped = wrap(saved.require, "require");
		if wrapped then
			env.require = wrapped;
			installed.require = { key = "require", original = saved.require };
		end;
	end;
	return true;
end

function Control.settings()
	return Settings;
end

function Control.set(key, value)
	if Settings[key] == nil then return false end;
	Settings[key] = value;
	if key == "stealth" and value and getgenv().Library then
		pcall(function() getgenv().Library:Notify("Dump: stealth on", 3) end);
	end;
	return true;
end

function Control.manifest()
	ensureFolder();
	local lines = {};
	for _, e in ipairs(state.entries) do
		lines[#lines + 1] = string.format(
			"%04d  %-9s %-34s %-12s %s%s",
			e.i, tostring(e.len), e.name, tostring(e.via),
			tostring(e.file or ("ERR:" .. tostring(e.err))), e.dup and "  [dup]" or "");
	end;
	safeWrite(Settings.folder .. "/_manifest.txt", table.concat(lines, "\n"));
	return #lines;
end

env.RainDump = Control;

return Control