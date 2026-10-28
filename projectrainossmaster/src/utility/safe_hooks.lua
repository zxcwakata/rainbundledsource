-- Безопасная установка хуков метаметодов.
--
-- Часть исполнителей умеет ставить хук в параллельную фазу
-- (parallel_hooks_allowed). Часть — нет, и там вызов hookmetamethod может
-- быть отдан Actor-параллельному потоку. Это недопустимый cross-phase вызов,
-- на котором ядро паникует (Kernel panic) — то есть падает не хук, а клиент.
--
-- Поэтому: если parallel_hooks_allowed не объявлен, __newindex ставится
-- подменой поля метатаблицы под setreadonly. Это обычный table-патч, он
-- синхронный и параллельной фазе не подвержен.
--
-- Взято из Luma-main/Features/Combat/ForceAutoRotate.lua — там же на нём
-- держится установка хука на __newindex.

local safe_hooks = {}

-- true, если хук метаметода можно ставить обычным способом
function safe_hooks.can_use_hookmetamethod()
    if parallel_hooks_allowed ~= nil then
        return parallel_hooks_allowed == true
    end
    return type(hookmetamethod) == "function"
end

--- Ставит хук на метаметод.
---@param target table
---@param method string  "__index" / "__newindex" / ...
---@param hook function
---@return function|nil original  nil, если хук не поставился
function safe_hooks.set(target, method, hook)
    if type(target) ~= "table" and typeof(target) ~= "table" then
        return nil
    end

    -- обычный путь
    if safe_hooks.can_use_hookmetamethod() and type(hookmetamethod) == "function" then
        local ok, original = pcall(hookmetamethod, target, method, hook)
        if ok then return original end
    end

    -- запасной путь: патч метатаблицы под setreadonly
    local ok_mt, mt = pcall(getrawmetatable, target)
    if not ok_mt or type(mt) ~= "table" then return nil end

    local original = rawget(mt, method)

    local ok = pcall(function()
        if type(setreadonly) == "function" then setreadonly(mt, false) end
        rawset(mt, method, hook)
        if type(setreadonly) == "function" then setreadonly(mt, true) end
    end)

    -- если setreadonly/патч не сработали — не оставляем объект в грязи
    if not ok then
        pcall(function()
            if type(setreadonly) == "function" then setreadonly(mt, false) end
            rawset(mt, method, original)
            if type(setreadonly) == "function" then setreadonly(mt, true) end
        end)
        return nil
    end

    return original
end

--- Снимает хук, поставленный safe_hooks.set.
---@param target table
---@param method string
---@param original any  то, что вернул set
function safe_hooks.remove(target, method, original)
    if original == nil then return end
    if safe_hooks.can_use_hookmetamethod() and type(hookmetamethod) == "function" then
        pcall(hookmetamethod, target, method, original)
        return
    end
    local ok, mt = pcall(getrawmetatable, target)
    if ok and type(mt) == "table" then
        pcall(function()
            if type(setreadonly) == "function" then setreadonly(mt, false) end
            rawset(mt, method, original)
            if type(setreadonly) == "function" then setreadonly(mt, true) end
        end)
    end
end

return safe_hooks