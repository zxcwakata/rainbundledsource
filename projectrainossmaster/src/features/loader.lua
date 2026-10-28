-- Restored features/loader (was stripped upstream).
-- Lazy-loads feature files on first enable (boot stays side-effect free),
-- then supervises flags -> enable/update/disable.
-- Toggle flag ids map 1:1 to feature .id in most cases; exceptions below.
-- restore: подробный лог фич (+connected / +enabled / -disabled, ~30 строк
-- на каждый запуск) убран. Включается по запросу:
--     getgenv().RAIN_VERBOSE = true
local __rain_verbose = false
pcall(function() __rain_verbose = getgenv().RAIN_VERBOSE == true end)

local FLAGMAP = {
    ["movement/tick_rate"] = "tickrate",
    ["misc/proximity_list"] = "show_list",
}

return { initialize = function(FEATS)
    FEATS = FEATS or {}
    -- background eager fill for cross-module refs (aztup.features.X),
    -- batched to dodge raw rate-limits. Delayed start: boot fetches go first,
    -- otherwise this storm competes with them for HttpGet throughput.
    task.spawn(function()
        task.wait(8)
        if getgenv().RAIN_RESTORED_DEAD then return end
        local batch = 0
        for id, path in pairs(FEATS) do
            if aztup.features[id] == nil then
                task.spawn(function()
                    local ok, mod = pcall(require, path)
                    if ok and type(mod) == "table" then
                        aztup.features[id] = mod
                        if type(mod.id) == "string" then
                            aztup.features[mod.id] = mod
                        end
                    end
                end)
                batch += 1
                if batch % 12 == 0 then task.wait(0.2) end
            end
        end
    end)
    -- supervisor + physics wedge watchdog (tick_rate does Pause/Step/Run per frame)
    task.spawn(function()
        local last_watchdog = 0
        while true do
            task.wait(0.15)
            if getgenv().RAIN_RESTORED_DEAD then break end
            local now = tick()
            if now - last_watchdog > 1 then
                last_watchdog = now
                local paused_ok, paused = pcall(function() return services.RunService.Paused end)
                if paused_ok and paused then
                    pcall(function() services.RunService:Run() end)
                    -- restore: лог убран — warn("[restore] physics was left paused, resumed (tick_rate wedge?)")
                end
            end
            for id, path in pairs(FEATS) do
                local wantflag = FLAGMAP[id] or id:match("([^/]+)$")
                if aztup.flags[wantflag] == true then
                    local f = aztup.features[id]
                    if f == nil then
                        local ok, mod = pcall(require, path)
                        if not ok then
                            -- restore: лог убран — warn("[restore] feature load failed: " .. id .. " :: " .. tostring(mod))
                        elseif type(mod) == "table" then
                            f = mod
                            aztup.features[id] = mod
                            if type(mod.id) == "string" then
                                aztup.features[mod.id] = mod
                            end
                        end
                    end
                    if type(f) == "table" then
                        if type(f.update) == "function" and f.conn then
                            if not f._c then
                                -- restore: построчная выгрузка фич (~30 строк
                                -- "��connected x") засоряла консоль на каждом
                                -- запуске. Включается флагом RAIN_VERBOSE.
                                if __rain_verbose then warn("[restore] +connected " .. id) end
                                pcall(function() f:enable() end)
                                local ok, c = pcall(function()
                                    return f.conn:Connect(function(...) pcall(f.update, ...) end)
                                end)
                                if ok then f._c = c end
                            end
                        elseif not f._on then
                            if __rain_verbose then warn("[restore] +enabled " .. id) end
                            f._on = true
                            pcall(function() f:enable() end)
                        end
                    end
                else
                    local f = aztup.features[id]
                    if type(f) == "table" and (f._c or f._on) then
                        if __rain_verbose then warn("[restore] -disabled " .. id) end
                        if f._c then pcall(function() f._c:Disconnect() end) f._c = nil end
                        f._on = nil
                        pcall(function() f:disable() end)
                    end
                end
            end
        end
    end)
end }
