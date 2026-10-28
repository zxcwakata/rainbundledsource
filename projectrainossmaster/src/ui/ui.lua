 
local tab, _ = require("@src/utility/ui/wrapper");

return {
    initialize = function()
        local creation_order = {
            "Main",
            "Visuals",
            "Combat",
            "Automation"
        };
 
        -- restore: было pairs() по массиву — порядок вкладок в UI получался
        -- случайным (AddTab регистрирует их в порядке вызовов). ipairs даёт
        -- детерминированный порядок: Main, Visuals, Combat, Automation.
        for _, tab_name in ipairs(creation_order) do
            aztup.tabs[tab_name] = tab.new(tab_name);
        end
        for _, module in list_modules("ui/tabs/*") do
            -- restore: модуль вкладки отдаёт ДВА значения (func, { name = ... }).
            -- Раньше тут стояло "require(module)" в for-in, где лишнее значение
            -- отбрасывалось, и data.name давал nil -> вкладки оставались пустыми.
            local func, data = require(module)
            if type(func) ~= "function" or type(data) ~= "table" or not data.name then
                -- restore: лог убран — warn("[restore] ui: tab module returned no name :: " .. tostring(module))
                continue
            end
            if not aztup.tabs[data.name] then
                -- ui_only: этот модуль рисуется в UI-вкладке, отдельного слота
                -- у него нет by design — тихо пропускаем, без warn
                if not data.ui_only then
                    -- restore: лог убран — warn("[restore] ui: no tab slot for " .. tostring(data.name) .. " (" .. tostring(module) .. ")")
                end
                continue
            end
            local ok, err = xpcall(func, warn, aztup.tabs[data.name])
            if not ok then
                -- restore: лог убран — warn("[restore] ui: tab " .. tostring(data.name) .. " failed :: " .. tostring(err))
            end
        end

        local ThemeManager = require("@src/utility/librarys/managers/ThemeManager");
        local SaveManager = require("@src/utility/librarys/managers/SaveManager");
        
        aztup.tabs.UI = tab.new("UI");

        SaveManager:SetLibrary(aztup.ui)
        SaveManager:IgnoreThemeSettings() 
        ThemeManager:SetLibrary(aztup.ui);

        SaveManager:SetIgnoreIndexes({
            "fly",
            "noclip",
            "speed",
            "infinite_jump",
            "spotify_redirect_url",
            
        })
        SaveManager:SetFolder('Project Rain/Deepwoken-Config')
        ThemeManager:SetFolder('Project Rain/Deepwoken-Config')
        SaveManager:BuildConfigSection(aztup.tabs.UI.Tab);
        ThemeManager:ApplyToTab(aztup.tabs.UI.Tab);

        task.spawn(pcall, require("@src/ui/config_converter"));
        -- restore: fast-flag кнопки (часть зависит от типа исполнителя) и
        -- ally-фильтры живут внизу вкладки UI. Раньше это шло через
        -- task.spawn(xpcall, require("@src/ui/tabs/ui"), warn, aztup.tabs.UI) —
        -- в task.spawn результат require терялся, поэтому setup уходил в
        -- фон и мог отработать до готовности UI. Теперь вызов прямой и под xpcall.
        local ui_extra = require("@src/ui/tabs/ui")
        if type(ui_extra) == "function" then
            local ok, err = xpcall(ui_extra, warn, aztup.tabs.UI)
            if not ok then
                -- restore: лог убран — warn("[restore] ui: UI extras failed :: " .. tostring(err))
            end
        end

        task.spawn(function()
            aztup_toggles.mod_detector:SetValue(true);
        end);
        
        local start = tick();
        if aztup.automation:has_any() then
            task.spawn(pcall, function()
                SaveManager:LoadAutoloadConfig()
            end);
        else
            SaveManager:LoadAutoloadConfig()
        end;
        local custom_name = not LPH_OBFUSCATED and isfile("custom_name.txt") and readfile("custom_name.txt") or nil;
        Library.PRWindow:SetWindowTitle((function()
		    if custom_name then
		    	return string.format(LPH_ENCSTR("%s"), custom_name:gsub("|ACCENT", "<font color=\"#" .. Library.AccentColor:ToHex() .. "\">"))		    
end
		    return string.format(LPH_ENCSTR("pr <font color=\"#%s\">nextgen</font>"), Library.AccentColor:ToHex())
	    end)())

        aztup.auto_loaded = true;

        -- restore: clickable banner above the main window (src/ui/menu_banner.lua)
        task.spawn(xpcall, function()
            require("@src/ui/menu_banner").initialize()
        end, warn);
    end;
} 