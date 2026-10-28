-- restore: содержимое возвращено, но целится в UI-вкладку, а не в отдельную
-- "Config". Раньше эти функции (fast-flag переключатели, зависящие от типа
-- исполнителя, и настройки ally-системы) вызывались из src/ui/ui.lua:61 через
-- task.spawn(xpcall, require("@src/ui/tabs/ui"), warn, aztup.tabs.UI) —
-- то есть рисовались внизу вкладки UI.
--
-- Отдельной вкладки Config больше нет: её слот удалён из creation_order,
-- и этот модуль больше не числится самостоятельной вкладкой. Он экспортирует
-- setup(tab), который ui/ui.lua зовёт уже после создания UI-вкладки.
--
-- ВАЖНО: имя в TABS-манифесте лоадера остаётся ("@src/ui/tabs/ui"), поэтому
-- файл должен существовать — иначе require упадёт. Поэтому здесь возвращается
-- func, который ui/ui.lua вызывает сам, а цикл вкладок этот модуль пропустит
-- как не имеющий собственного слота.

local tabs = {}

function tabs:create_fast_flags(tab)
    local groupbox = tab:newGroupBox("Script Toggles", false)
    groupbox:newLabel("ALL FEATURES HERE REQUIRE A REJOIN!")

    -- restore: часть кнопок зависит от типа исполнителя
    if identifyexecutor() == "Synapse Z" then
        groupbox:newButton("[syn z] faster limited esp", function()
            fflags:set("faster_limited_esp", not fflags:get("faster_limited_esp"))
            Logger:long_notify_sound("now set to:", fflags:get("faster_limited_esp"))
        end)
    end

    groupbox:newButton("new task scheduler", function()
        fflags:set("new_task_scheduler", not fflags:get("new_task_scheduler"))
        Logger:long_notify_sound("now set to:", fflags:get("new_task_scheduler"))
    end)

    groupbox:newButton("silent mode load notif", function()
        fflags:set("dont_notify_on_first_exec", not fflags:get("dont_notify_on_first_exec"))
        Logger:long_notify_sound("silent mode load notif now set to:", fflags:get("dont_notify_on_first_exec"))
    end)

    groupbox:newButton("disable auto showing ui", function()
        fflags:set("dont_auto_show_ui", not fflags:get("dont_auto_show_ui"))
        Logger:long_notify_sound("auto show ui now set to:", not fflags:get("dont_auto_show_ui"))
    end)

    groupbox:newButton("auto load", function()
        fflags:set("auto_load", not fflags:get("auto_load"))
        Logger:long_notify_sound("auto load now set to:", fflags:get("auto_load"))
    end)
end

function tabs:create_ally_system(tab)
    local groupbox = tab:newGroupBox("Ally Filtering", true)

    groupbox:newToggle("ally_system", "Enable Ally Filtering", false,
        "Allows you to designate players as allies, preventing certain interactions with them.", function() end)

    local ally_system_dependency_box = groupbox:newDependencyBox("ally_system")
    ally_system_dependency_box:newDropdown('ally_settings', 'Ally Filters', {
        "Deepwoken Allys",
        "Roblox Friends",
        "Custom Players",
        "Custom Guilds",
        "Same Guild",
    }, {}, true, "Targets to desginate as allies.", function() end, true)

    local ally_players_dependency, raw_ap = groupbox:newDependencyBox()
    ally_players_dependency:newTextbox('ally_players_input', 'Ally Players', false, '', nil,
        '(semicolon separated list of player names to designate as allies) Ex: "Player1;Player2;Player3"')
    raw_ap:SetupDependencies({
        { aztup_toggles.ally_system, true },
        { aztup_options.ally_settings, "Custom Players" }
    })

    local ally_guilds_dependency, raw_ag = groupbox:newDependencyBox()
    ally_guilds_dependency:newTextbox('ally_guilds_input', 'Ally Guilds', false, '', nil,
        '(semicolon separated list of guild names to designate as allies) Ex: "Guild1;Guild2;Guild3"')
    raw_ag:SetupDependencies({
        { aztup_toggles.ally_system, true },
        { aztup_options.ally_settings, "Custom Guilds" }
    })
end

-- setup(tab): вызывается из ui/ui.lua уже после создания вкладки UI
local setup = function(tab)
    tabs:create_fast_flags(tab)
    tabs:create_ally_system(tab)
end

-- Отдаём и функцию, и таблицу-метку. Метка нужна только чтобы цикл вкладок
-- в ui/ui.lua корректно её пропустил: слота "Config" больше не существует.
return setup, {
    name = "Config",
    ui_only = true,
}
