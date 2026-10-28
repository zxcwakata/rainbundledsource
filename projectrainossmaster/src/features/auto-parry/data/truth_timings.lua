-- Тайминги из Luma-main/Timings/truth.txt, сконвертированы в формат Rain.
-- Источник: дамп таймингов игры — 712 анимационных записей.
-- Взят только пробел: id, которых НЕТ в assets/extra_data.json (455 шт.),
-- настройки Rain не перебиваются. Module-driven записи (umoa, 144 шт.) пропущены:
-- им нужен Modules/*.lua из Luma, это другая архитектура.
--
-- Формат записи идентичен base.lua: ids / action_type / run. Разница —
-- один общий build() на модуль вместо тела функции в каждой записи:
-- run всё равно получает creator, поэтому ipairs(def.actions) корректен.

local function build(def)
	return function(action)
		for _, a in ipairs(def.actions) do
			action.when = a[1];
			if a[2] ~= 0 or a[3] ~= 0 or a[4] ~= 0 then
				action.hitbox = Vector3.new(a[2], a[3], a[4]);
			end
			action.type = a[5];
			action.name = a[6];
			if a[7] then action.ignore_hitbox = true end
			action:push();
		end;
		return action;
	end
end

local T = {}

T["FireEruption"] = {
	ids = { "8378263543" },
	action_type = "Spell",
	name = "FireEruption",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.38, 41, 25, 40, "Parry", "1", false },
		{ 1.15, 41, 25, 40, "Parry", "2", false },
	},
}
T["FireEruption"].run = build(T["FireEruption"]);

T["1Inferno2"] = {
	ids = { "135226142279222" },
	action_type = "M1",
	name = "1Inferno2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 16, 14, 12, "Parry", "1", false },
	},
}
T["1Inferno2"].run = build(T["1Inferno2"]);

T["KaritaLeap"] = {
	ids = { "15420044707" },
	action_type = "Spell",
	name = "KaritaLeap",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 23, 11, 20, "Parry", "Release", false },
	},
}
T["KaritaLeap"].run = build(T["KaritaLeap"]);

T["Scythe_2"] = {
	ids = { "11493923277" },
	action_type = "M1",
	name = "Scythe_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 10, 10, 10, "Parry", "Release", false },
	},
}
T["Scythe_2"].run = build(T["Scythe_2"]);

T["FlameRepulsion"] = {
	ids = { "5778357994" },
	action_type = "Spell",
	name = "FlameRepulsion",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.1, 51, 50, 50, "Parry", "1", false },
	},
}
T["FlameRepulsion"].run = build(T["FlameRepulsion"]);

T["SquibboAxeKick"] = {
	ids = { "6922103707" },
	name = "SquibboAxeKick",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 18, 32, 33, "Parry", "1", false },
	},
}
T["SquibboAxeKick"].run = build(T["SquibboAxeKick"]);

T["2_GenericStaff2"] = {
	ids = { "86466909898596" },
	action_type = "M1",
	name = "2_GenericStaff2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericStaff2"].run = build(T["2_GenericStaff2"]);

T["2_GenericGreatsword1"] = {
	ids = { "6675698010" },
	action_type = "M1",
	name = "2_GenericGreatsword1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericGreatsword1"].run = build(T["2_GenericGreatsword1"]);

T["1_GenericSpear1"] = {
	ids = { "7626771915" },
	action_type = "M1",
	name = "1_GenericSpear1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericSpear1"].run = build(T["1_GenericSpear1"]);

T["ShadeBringer2"] = {
	ids = { "9470822568" },
	action_type = "Spell",
	name = "ShadeBringer2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.18, 36, 14, 18, "Parry", "1", false },
	},
}
T["ShadeBringer2"].run = build(T["ShadeBringer2"]);

T["1_GenericSword1"] = {
	ids = { "7600160919" },
	action_type = "M1",
	name = "1_GenericSword1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericSword1"].run = build(T["1_GenericSword1"]);

T["KaritaLeapp"] = {
	ids = { "73703637156475" },
	action_type = "Spell",
	name = "KaritaLeapp",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 14, 20, 38, "Parry", "Release", false },
	},
}
T["KaritaLeapp"].run = build(T["KaritaLeapp"]);

T["TitusVault"] = {
	ids = { "118932415770119" },
	name = "TitusVault",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 1.45, 60, 102, 60, "Dodge", "1", false },
	},
}
T["TitusVault"].run = build(T["TitusVault"]);

T["BoneBoyLeapAttack"] = {
	ids = { "9681472252" },
	name = "BoneBoyLeapAttack",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 43, 46, 43, "Jump", "1", false },
	},
}
T["BoneBoyLeapAttack"].run = build(T["BoneBoyLeapAttack"]);

T["DeepSpiderRightSwing"] = {
	ids = { "6428514850" },
	name = "DeepSpiderRightSwing",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 40, 38, 40, "Parry", "Release", false },
	},
}
T["DeepSpiderRightSwing"].run = build(T["DeepSpiderRightSwing"]);

T["1_GenericGreatAxe3"] = {
	ids = { "5067105317" },
	action_type = "M1",
	name = "1_GenericGreatAxe3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericGreatAxe3"].run = build(T["1_GenericGreatAxe3"]);

T["ScytheRunning"] = {
	ids = { "11493924588" },
	action_type = "M1",
	name = "ScytheRunning",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 12, 10, 13, "Parry", "1", false },
	},
}
T["ScytheRunning"].run = build(T["ScytheRunning"]);

T["StrongLeft"] = {
	ids = { "8085349676" },
	action_type = "Spell",
	name = "StrongLeft",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 15, 15, 15, "Parry", "Release", false },
	},
}
T["StrongLeft"].run = build(T["StrongLeft"]);

T["AraneaCrit"] = {
	ids = { "123321475025790" },
	action_type = "Critical",
	name = "AraneaCrit",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 15, 11, 20, "Parry", "1", false },
		{ 1.4, 15, 11, 20, "Parry", "3", false },
		{ 1, 15, 11, 20, "Parry", "2", false },
	},
}
T["AraneaCrit"].run = build(T["AraneaCrit"]);

T["Bonestomp"] = {
	ids = { "102109041124059" },
	name = "Bonestomp",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 25, 15, 50, "Jump", "1", false },
	},
}
T["Bonestomp"].run = build(T["Bonestomp"]);

T["IceChampion3Hit"] = {
	ids = { "100777123071173" },
	name = "IceChampion3Hit",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.51, 33, 23, 27, "Parry", "1", false },
		{ 2.36, 32, 21, 20, "Crouch", "4", false },
		{ 1.26, 32, 24, 25, "Crouch", "3", false },
		{ 1.12, 32, 21, 25, "Parry", "2", false },
	},
}
T["IceChampion3Hit"].run = build(T["IceChampion3Hit"]);

T["SquidwardEruption"] = {
	ids = { "6922310516" },
	name = "SquidwardEruption",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 10, 20, 50, "Dodge", "Release", false },
	},
}
T["SquidwardEruption"].run = build(T["SquidwardEruption"]);

T["1_GenericUntrainedFist1"] = {
	ids = { "139109176874463" },
	action_type = "M1",
	name = "1_GenericUntrainedFist1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0, 0, 0, 0, "Parry", "1", false },
	},
}
T["1_GenericUntrainedFist1"].run = build(T["1_GenericUntrainedFist1"]);

T["IceCarve"] = {
	ids = { "15713914142" },
	name = "IceCarve",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.2, 0, 0, 0, "Start Block", "1", false },
		{ 2, 0, 0, 0, "End Block", "2", false },
	},
}
T["IceCarve"].run = build(T["IceCarve"]);

T["ImperialM1_2"] = {
	ids = { "16654105888" },
	action_type = "M1",
	name = "ImperialM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 16, 11, 14, "Parry", "1", false },
	},
}
T["ImperialM1_2"].run = build(T["ImperialM1_2"]);

T["ToonsM1_1"] = {
	ids = { "102858834757078" },
	action_type = "M1",
	name = "ToonsM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["ToonsM1_1"].run = build(T["ToonsM1_1"]);

T["TitusStormboundLoop"] = {
	ids = { "113791985784867" },
	action_type = "Spell",
	name = "TitusStormboundLoop",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0, 0, 0, 0, "Parry", "1", false },
	},
}
T["TitusStormboundLoop"].run = build(T["TitusStormboundLoop"]);

T["WealnWoeM1_2"] = {
	ids = { "115757796989607" },
	action_type = "M1",
	name = "WealnWoeM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["WealnWoeM1_2"].run = build(T["WealnWoeM1_2"]);

T["CrimsonRain"] = {
	ids = { "83367609184503" },
	action_type = "Spell",
	name = "CrimsonRain",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 23, 15, 32, "Parry", "1", false },
	},
}
T["CrimsonRain"].run = build(T["CrimsonRain"]);

T["TitusGrabDodge"] = {
	ids = { "128613582420698" },
	name = "TitusGrabDodge",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 25, 21, 25, "Dodge", "1", false },
	},
}
T["TitusGrabDodge"].run = build(T["TitusGrabDodge"]);

T["MaliceM1_3"] = {
	ids = { "12138861998" },
	action_type = "M1",
	name = "MaliceM1_3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.33, 20, 14, 16, "Parry", "1", false },
	},
}
T["MaliceM1_3"].run = build(T["MaliceM1_3"]);

T["TollM1_1"] = {
	ids = { "11186652658" },
	action_type = "M1",
	name = "TollM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.275, 12, 10, 15, "Parry", "1", false },
	},
}
T["TollM1_1"].run = build(T["TollM1_1"]);

T["BloodOrb"] = {
	ids = { "137313477686049" },
	action_type = "Spell",
	name = "BloodOrb",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.52, 16, 16, 30, "Parry", "1", false },
	},
}
T["BloodOrb"].run = build(T["BloodOrb"]);

T["BurningServants"] = {
	ids = { "5769343416" },
	action_type = "Spell",
	name = "BurningServants",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.23, 40, 20, 40, "Parry", "1", false },
		{ 2, 40, 20, 40, "Parry", "2", false },
	},
}
T["BurningServants"].run = build(T["BurningServants"]);

T["TacetDropKick"] = {
	ids = { "10168663111" },
	action_type = "Spell",
	name = "TacetDropKick",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0, 0, 0, 0, "Parry", "1", false },
	},
}
T["TacetDropKick"].run = build(T["TacetDropKick"]);

T["CurvedBladeCrit"] = {
	ids = { "13290263661" },
	action_type = "Critical",
	name = "CurvedBladeCrit",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 20, 20, 20, "Parry", "1", false },
		{ 0.76, 20, 20, 20, "Parry", "2", false },
	},
}
T["CurvedBladeCrit"].run = build(T["CurvedBladeCrit"]);

T["RisingThunder"] = {
	ids = { "15214200859" },
	action_type = "Spell",
	name = "RisingThunder",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 10, 10, 15, "Parry", "Release", false },
	},
}
T["RisingThunder"].run = build(T["RisingThunder"]);

T["1_GenericKarita1"] = {
	ids = { "16372476897" },
	action_type = "M1",
	name = "1_GenericKarita1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 24, 24, 21, "Parry", "1", false },
	},
}
T["1_GenericKarita1"].run = build(T["1_GenericKarita1"]);

T["BlooudFoulerM1_3"] = {
	ids = { "74422917176963" },
	action_type = "M1",
	name = "BlooudFoulerM1_3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 10, 15, 10, "Parry", "Release", false },
	},
}
T["BlooudFoulerM1_3"].run = build(T["BlooudFoulerM1_3"]);

T["IceChampion5HitCombo"] = {
	ids = { "132499670118034" },
	name = "Ice Champion 5 Hit Combo",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.64, 33, 23, 27, "Parry", "1", false },
		{ 2.14, 32, 24, 25, "Parry", "3", false },
		{ 1.21, 32, 21, 25, "Parry", "2", false },
		{ 3.94, 31, 21, 25, "Dodge", "5", false },
		{ 2.8, 32, 21, 24, "Dodge", "4", false },
	},
}
T["IceChampion5HitCombo"].run = build(T["IceChampion5HitCombo"]);

T["WindKick"] = {
	ids = { "10357806593" },
	action_type = "Spell",
	name = "WindKick",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 16, 11, 28, "Parry", "1", false },
	},
}
T["WindKick"].run = build(T["WindKick"]);

T["TitusLariat"] = {
	ids = { "93803643628347" },
	name = "TitusLariat",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.74, 28, 29, 60, "Dodge", "1", false },
	},
}
T["TitusLariat"].run = build(T["TitusLariat"]);

T["UmbriteSwing2"] = {
	ids = { "119672037814127" },
	action_type = "M1",
	name = "UmbriteSwing2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 15, 12, 11, "Parry", "1", false },
	},
}
T["UmbriteSwing2"].run = build(T["UmbriteSwing2"]);

T["1_GenericGreatAxe1"] = {
	ids = { "5064195992" },
	action_type = "M1",
	name = "1_GenericGreatAxe1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericGreatAxe1"].run = build(T["1_GenericGreatAxe1"]);

T["2_GenericTwinblade1"] = {
	ids = { "123456225328134" },
	action_type = "M1",
	name = "2_GenericTwinblade1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericTwinblade1"].run = build(T["2_GenericTwinblade1"]);

T["PyreKeeperM1_2"] = {
	ids = { "17197704130" },
	action_type = "M1",
	name = "PyreKeeperM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 16, 12, 12, "Parry", "1", false },
	},
}
T["PyreKeeperM1_2"].run = build(T["PyreKeeperM1_2"]);

T["LightningStreamWindup"] = {
	ids = { "5968796999" },
	action_type = "Spell",
	name = "LightningStreamWindup",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0, 31, 31, 31, "Parry", "1", false },
	},
}
T["LightningStreamWindup"].run = build(T["LightningStreamWindup"]);

T["RatKingLeapSlash"] = {
	ids = { "72778500832762" },
	name = "RatKingLeapSlash",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 40, 40, 72, "Parry", "1", false },
	},
}
T["RatKingLeapSlash"].run = build(T["RatKingLeapSlash"]);

T["PurpleCloud2"] = {
	ids = { "16372422960" },
	action_type = "M1",
	name = "PurpleCloud2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.325, 15, 12, 12, "Parry", "1", false },
	},
}
T["PurpleCloud2"].run = build(T["PurpleCloud2"]);

T["WealnWoeM1_3"] = {
	ids = { "107771611881875" },
	action_type = "M1",
	name = "WealnWoeM1_3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["WealnWoeM1_3"].run = build(T["WealnWoeM1_3"]);

T["UmbriteSwing3"] = {
	ids = { "113419264758259" },
	action_type = "M1",
	name = "UmbriteSwing3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 15, 12, 11, "Parry", "1", false },
	},
}
T["UmbriteSwing3"].run = build(T["UmbriteSwing3"]);

T["LightningAssault"] = {
	ids = { "5968282214" },
	action_type = "Spell",
	name = "LightningAssault",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 29, 29, 29, "Parry", "1", false },
	},
}
T["LightningAssault"].run = build(T["LightningAssault"]);

T["PetrasCritWindup"] = {
	ids = { "12071495751" },
	action_type = "Critical",
	name = "PetrasCritWindup",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.55, 20, 20, 20, "Parry", "1", false },
	},
}
T["PetrasCritWindup"].run = build(T["PetrasCritWindup"]);

T["DeepSpiderLeftSwing"] = {
	ids = { "6428519131" },
	name = "DeepSpiderLeftSwing",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 40, 38, 40, "Parry", "Release", false },
	},
}
T["DeepSpiderLeftSwing"].run = build(T["DeepSpiderLeftSwing"]);

T["RisingStarSilentheart"] = {
	ids = { "139465383955578" },
	name = "RisingStarSilentheart",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 25, 25, 25, "Parry", "Release", false },
	},
}
T["RisingStarSilentheart"].run = build(T["RisingStarSilentheart"]);

T["2_GenericGreatsword2"] = {
	ids = { "6675703249" },
	action_type = "M1",
	name = "2_GenericGreatsword2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericGreatsword2"].run = build(T["2_GenericGreatsword2"]);

T["IceChampion4Hit"] = {
	ids = { "127741055541488" },
	name = "IceChampion4Hit",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.64, 33, 23, 27, "Parry", "1", false },
		{ 3.1, 32, 21, 24, "Dodge", "4", false },
		{ 2.04, 32, 24, 25, "Jump", "3", false },
		{ 1.34, 32, 21, 25, "Parry", "2", false },
	},
}
T["IceChampion4Hit"].run = build(T["IceChampion4Hit"]);

T["RatKingTurnDash"] = {
	ids = { "100947251441923" },
	name = "RatKingTurnDash",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 50, 50, 25, "Parry", "1", false },
	},
}
T["RatKingTurnDash"].run = build(T["RatKingTurnDash"]);

T["MirrorIllusion"] = {
	ids = { "87085678581483" },
	action_type = "Spell",
	name = "MirrorIllusion",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 50, 50, 50, "Dodge", "1", false },
	},
}
T["MirrorIllusion"].run = build(T["MirrorIllusion"]);

T["RailbladeM1_3"] = {
	ids = { "9832727905" },
	action_type = "M1",
	name = "RailbladeM1_3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 19, 13, 16, "Parry", "1", false },
	},
}
T["RailbladeM1_3"].run = build(T["RailbladeM1_3"]);

T["MaliceAerial"] = {
	ids = { "12496640760" },
	action_type = "M1",
	name = "MaliceAerial",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 14, 14, 15, "Parry", "1", false },
	},
}
T["MaliceAerial"].run = build(T["MaliceAerial"]);

T["RegentGrab"] = {
	ids = { "111647546998749" },
	name = "RegentGrab",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 300, 300, 300, "Parry", "1", false },
	},
}
T["RegentGrab"].run = build(T["RegentGrab"]);

T["MaliceM1_2"] = {
	ids = { "12138860062" },
	action_type = "M1",
	name = "MaliceM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.33, 20, 14, 16, "Parry", "1", false },
	},
}
T["MaliceM1_2"].run = build(T["MaliceM1_2"]);

T["WindCarve1"] = {
	ids = { "121771684522987" },
	action_type = "Spell",
	name = "WindCarve1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 40, 37, 43, "Start Block", "Release", false },
		{ 1.5, 40, 38, 40, "End Block", "2", false },
	},
}
T["WindCarve1"].run = build(T["WindCarve1"]);

T["IceCarveSpin"] = {
	ids = { "16337192866" },
	action_type = "Spell",
	name = "IceCarveSpin",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 0, 0, 0, "Start Block", "1", false },
		{ 3.1, 50, 50, 50, "End Block", "2", false },
	},
}
T["IceCarveSpin"].run = build(T["IceCarveSpin"]);

T["WSRoar"] = {
	ids = { "96971457742631" },
	name = "WSRoar",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 5.35, 300, 300, 300, "Parry", "1", false },
	},
}
T["WSRoar"].run = build(T["WSRoar"]);

T["1_GenericSpear2"] = {
	ids = { "7627049402" },
	action_type = "M1",
	name = "1_GenericSpear2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericSpear2"].run = build(T["1_GenericSpear2"]);

T["PetrasCritGo"] = {
	ids = { "12071557016" },
	action_type = "Critical",
	name = "PetrasCritGo",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.2, 0, 0, 0, "Parry", "1", false },
	},
}
T["PetrasCritGo"].run = build(T["PetrasCritGo"]);

T["AstralWind"] = {
	ids = { "6470684331" },
	action_type = "Spell",
	name = "AstralWind",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 24, 25, 25, "Parry", "1", false },
	},
}
T["AstralWind"].run = build(T["AstralWind"]);

T["1_GenericTwinblade2"] = {
	ids = { "100190998225588" },
	action_type = "M1",
	name = "1_GenericTwinblade2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericTwinblade2"].run = build(T["1_GenericTwinblade2"]);

T["KingCroccoSlam"] = {
	ids = { "9921853885" },
	name = "KingCroccoSlam",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 40, 50, 40, "Start Block", "Release", false },
		{ 0.9, 300, 300, 300, "End Block", "End", false },
	},
}
T["KingCroccoSlam"].run = build(T["KingCroccoSlam"]);

T["BounderLeap"] = {
	ids = { "9544206893" },
	name = "BounderLeap",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.8, 300, 300, 300, "Start Block", "Release", false },
		{ 1.2, 55, 111, 55, "End Block", "2", false },
	},
}
T["BounderLeap"].run = build(T["BounderLeap"]);

T["RailbladeM1_1"] = {
	ids = { "9832721746" },
	action_type = "M1",
	name = "RailbladeM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 19, 13, 16, "Parry", "1", false },
	},
}
T["RailbladeM1_1"].run = build(T["RailbladeM1_1"]);

T["TollM1_3"] = {
	ids = { "11186656574" },
	action_type = "M1",
	name = "TollM1_3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.275, 12, 10, 15, "Parry", "1", false },
	},
}
T["TollM1_3"].run = build(T["TollM1_3"]);

T["UmbriteSwing1"] = {
	ids = { "77160956516659" },
	action_type = "M1",
	name = "UmbriteSwing1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 15, 12, 11, "Parry", "1", false },
	},
}
T["UmbriteSwing1"].run = build(T["UmbriteSwing1"]);

T["DualCurvedBladeCrit"] = {
	ids = { "13277887570" },
	action_type = "Critical",
	name = "DualCurvedBladeCrit",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.29, 15, 16, 14, "Parry", "1", false },
	},
}
T["DualCurvedBladeCrit"].run = build(T["DualCurvedBladeCrit"]);

T["CrystalImpaleWindup"] = {
	ids = { "6054920207" },
	action_type = "Spell",
	name = "CrystalImpaleWindup",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 19, 32, 19, "Parry", "1", false },
	},
}
T["CrystalImpaleWindup"].run = build(T["CrystalImpaleWindup"]);

T["1_GenericGreatcannon2"] = {
	ids = { "122256431354649" },
	action_type = "M1",
	name = "1_GenericGreatcannon2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericGreatcannon2"].run = build(T["1_GenericGreatcannon2"]);

T["2_GenericTwinblade2"] = {
	ids = { "107653610777693" },
	action_type = "M1",
	name = "2_GenericTwinblade2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericTwinblade2"].run = build(T["2_GenericTwinblade2"]);

T["SharkoDropKick"] = {
	ids = { "9903097211" },
	name = "SharkoDropKick",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.42, 40, 68, 42, "Forced Full Dodge", "1", false },
	},
}
T["SharkoDropKick"].run = build(T["SharkoDropKick"]);

T["SpectralM1_1"] = {
	ids = { "94626092299428" },
	action_type = "M1",
	name = "SpectralM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.25, 10, 9, 14, "Parry", "1", false },
	},
}
T["SpectralM1_1"].run = build(T["SpectralM1_1"]);

T["PyreKeeperM1_3"] = {
	ids = { "17197732174" },
	action_type = "M1",
	name = "PyreKeeperM1_3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 16, 12, 12, "Parry", "1", false },
	},
}
T["PyreKeeperM1_3"].run = build(T["PyreKeeperM1_3"]);

T["SharkoBeam"] = {
	ids = { "91389074160755" },
	name = "SharkoBeam",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 2.92, 54, 87, 142, "Forced Full Dodge", "1", false },
		{ 4.85, 54, 87, 142, "Forced Full Dodge", "2", false },
	},
}
T["SharkoBeam"].run = build(T["SharkoBeam"]);

T["2_GenericSpear1"] = {
	ids = { "7627372304" },
	action_type = "M1",
	name = "2_GenericSpear1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericSpear1"].run = build(T["2_GenericSpear1"]);

T["TitusStormbound"] = {
	ids = { "82898164556000" },
	action_type = "Spell",
	name = "TitusStormbound",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.15, 62, 62, 62, "Dodge", "1", false },
	},
}
T["TitusStormbound"].run = build(T["TitusStormbound"]);

T["ElectroCarveMagnet"] = {
	ids = { "15433825224" },
	action_type = "Spell",
	name = "ElectroCarveMagnet",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 16, 16, 40, "Parry", "1", false },
	},
}
T["ElectroCarveMagnet"].run = build(T["ElectroCarveMagnet"]);

T["RapierPierce"] = {
	ids = { "100635703599003" },
	action_type = "Critical",
	name = "RapierPierce",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 20, 10, 45, "Parry", "1", false },
	},
}
T["RapierPierce"].run = build(T["RapierPierce"]);

T["VanguardAirKick"] = {
	ids = { "139898407143891" },
	action_type = "Spell",
	name = "VanguardAirKick",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 21, 41, 21, "Parry", "Release", false },
	},
}
T["VanguardAirKick"].run = build(T["VanguardAirKick"]);

T["1_GenericTwinblade1"] = {
	ids = { "138417702895229" },
	action_type = "M1",
	name = "1_GenericTwinblade1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericTwinblade1"].run = build(T["1_GenericTwinblade1"]);

T["DukeWindBlast"] = {
	ids = { "8286153000" },
	name = "DukeWindBlast",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.55, 25, 25, 25, "Parry", "Release", false },
	},
}
T["DukeWindBlast"].run = build(T["DukeWindBlast"]);

T["EnforcerSpin"] = {
	ids = { "7019018522" },
	name = "EnforcerSpin",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 100, 100, 100, "Dodge", "Release", false },
	},
}
T["EnforcerSpin"].run = build(T["EnforcerSpin"]);

T["CrabboRexBeam"] = {
	ids = { "7960934455" },
	name = "CrabboRexBeam",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.9, 40, 40, 40, "Start Block", "Release", false },
		{ 2, 72, 75, 71, "End Block", "2", false },
	},
}
T["CrabboRexBeam"].run = build(T["CrabboRexBeam"]);

T["ImperialM1_1"] = {
	ids = { "16654099937" },
	action_type = "M1",
	name = "ImperialM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 16, 11, 14, "Parry", "1", false },
	},
}
T["ImperialM1_1"].run = build(T["ImperialM1_1"]);

T["LightningSlash"] = {
	ids = { "5968288116" },
	action_type = "Spell",
	name = "LightningSlash",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 300, 300, 300, "Parry", "Release", false },
	},
}
T["LightningSlash"].run = build(T["LightningSlash"]);

T["1Inferno1"] = {
	ids = { "80513922848003" },
	action_type = "M1",
	name = "1Inferno1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 16, 14, 12, "Parry", "1", false },
	},
}
T["1Inferno1"].run = build(T["1Inferno1"]);

T["GolemSmack"] = {
	ids = { "6500704554" },
	name = "GolemSmack",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 18, 40, 25, "Dodge", "Release", false },
	},
}
T["GolemSmack"].run = build(T["GolemSmack"]);

T["ToonsM1_3"] = {
	ids = { "111781160894259" },
	action_type = "M1",
	name = "ToonsM1_3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["ToonsM1_3"].run = build(T["ToonsM1_3"]);

T["MayhemSilentheart"] = {
	ids = { "81062541535552" },
	name = "MayhemSilentheart",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.7, 0, 0, 0, "Parry", "Release", false },
	},
}
T["MayhemSilentheart"].run = build(T["MayhemSilentheart"]);

T["DukeStomp"] = {
	ids = { "8290626574" },
	name = "DukeStomp",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.75, 15, 20, 50, "Dodge", "Release", false },
	},
}
T["DukeStomp"].run = build(T["DukeStomp"]);

T["EnforcerPullHuman"] = {
	ids = { "10880473795" },
	action_type = "Spell",
	name = "EnforcerPullHuman",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.7, 103, 102, 102, "Parry", "1", false },
	},
}
T["EnforcerPullHuman"].run = build(T["EnforcerPullHuman"]);

T["IceChampionWindupSlash"] = {
	ids = { "106268260112496" },
	name = "Ice Champion Windup Slash",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 33, 23, 27, "Start Block", "1", false },
		{ 2, 33, 23, 27, "End Block", "2", false },
	},
}
T["IceChampionWindupSlash"].run = build(T["IceChampionWindupSlash"]);

T["TempestBlitz"] = {
	ids = { "15789927733" },
	action_type = "Spell",
	name = "TempestBlitz",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.05, 40, 40, 40, "Parry", "1", false },
	},
}
T["TempestBlitz"].run = build(T["TempestBlitz"]);

T["FirePalm"] = {
	ids = { "7618754583" },
	action_type = "Spell",
	name = "FirePalm",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.05, 28, 20, 43, "Parry", "1", false },
	},
}
T["FirePalm"].run = build(T["FirePalm"]);

T["2_GenericStaff3"] = {
	ids = { "119153579346494" },
	action_type = "M1",
	name = "2_GenericStaff3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericStaff3"].run = build(T["2_GenericStaff3"]);

T["EdenstaffCrit"] = {
	ids = { "15250125394" },
	action_type = "Critical",
	name = "EdenstaffCrit",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 1.5, 32, 31, 40, "Parry", "1", false },
	},
}
T["EdenstaffCrit"].run = build(T["EdenstaffCrit"]);

T["ChorusDivide"] = {
	ids = { "118532593654437" },
	action_type = "Spell",
	name = "ChorusDivide",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 1.25, 122, 15, 14, "Forced Full Dodge", "1", false },
	},
}
T["ChorusDivide"].run = build(T["ChorusDivide"]);

T["PyreKeeperM1_Aerial"] = {
	ids = { "17208601112" },
	action_type = "M1",
	name = "PyreKeeperM1_Aerial",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 16, 15, 15, "Parry", "1", false },
	},
}
T["PyreKeeperM1_Aerial"].run = build(T["PyreKeeperM1_Aerial"]);

T["AuthortyPunchFloruish"] = {
	ids = { "110164806111956" },
	name = "AuthortyPunchFloruish",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 12, 12, 12, "Parry", "1", false },
	},
}
T["AuthortyPunchFloruish"].run = build(T["AuthortyPunchFloruish"]);

T["DarkBlade"] = {
	ids = { "6038858570" },
	action_type = "Spell",
	name = "DarkBlade",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.16, 21, 15, 18, "Parry", "Release", false },
	},
}
T["DarkBlade"].run = build(T["DarkBlade"]);

T["IceChampionSpike"] = {
	ids = { "133763199472108" },
	name = "IceChampionSpike",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.87, 33, 23, 27, "Dodge", "1", false },
		{ 3.21, 32, 21, 24, "Dodge", "4", false },
		{ 2.1, 32, 24, 25, "Jump", "3", false },
		{ 1.52, 32, 21, 25, "Parry", "2", false },
	},
}
T["IceChampionSpike"].run = build(T["IceChampionSpike"]);

T["2_GenericSpear2"] = {
	ids = { "7627558238" },
	action_type = "M1",
	name = "2_GenericSpear2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericSpear2"].run = build(T["2_GenericSpear2"]);

T["MetalRush"] = {
	ids = { "13567686046" },
	action_type = "Spell",
	name = "MetalRush",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 0, 0, 0, "Parry", "Release", false },
	},
}
T["MetalRush"].run = build(T["MetalRush"]);

T["TollM1_2"] = {
	ids = { "11186654931" },
	action_type = "M1",
	name = "TollM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.275, 12, 10, 15, "Parry", "1", false },
	},
}
T["TollM1_2"].run = build(T["TollM1_2"]);

T["Windgun"] = {
	ids = { "8310877920" },
	action_type = "Spell",
	name = "Windgun",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 20, 20, 40, "Parry", "1", false },
	},
}
T["Windgun"].run = build(T["Windgun"]);

T["RegentGrapplePull"] = {
	ids = { "139770040216235" },
	name = "RegentGrapplePull",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 29, 29, 300, "Dodge", "1", false },
	},
}
T["RegentGrapplePull"].run = build(T["RegentGrapplePull"]);

T["ElderPrimaUltimateStomp"] = {
	ids = { "82315723491864" },
	name = "ElderPrimaUltimateStomp",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 2.55, 151, 252, 151, "Parry", "1", false },
	},
}
T["ElderPrimaUltimateStomp"].run = build(T["ElderPrimaUltimateStomp"]);

T["ShadowRoar"] = {
	ids = { "7620630583" },
	action_type = "Spell",
	name = "ShadowRoar",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 40, 40, 40, "Parry", "1", false },
	},
}
T["ShadowRoar"].run = build(T["ShadowRoar"]);

T["HairSpray"] = {
	ids = { "14169996512" },
	name = "HairSpray",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.2, 6, 7, 7, "Start Block", "1", false },
		{ 0.6, 50, 50, 50, "End Block", "2", false },
	},
}
T["HairSpray"].run = build(T["HairSpray"]);

T["IceGuyThrow"] = {
	ids = { "10413826409" },
	name = "IceGuyThrow",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 1.05, 31, 54, 51, "Parry", "1", false },
	},
}
T["IceGuyThrow"].run = build(T["IceGuyThrow"]);

T["PurpleCloud3"] = {
	ids = { "16372427756" },
	action_type = "M1",
	name = "PurpleCloud3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.325, 15, 12, 12, "Parry", "1", false },
	},
}
T["PurpleCloud3"].run = build(T["PurpleCloud3"]);

T["CrazyGuns"] = {
	ids = { "7007974914" },
	name = "CrazyGuns",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.1, 14, 12, 27, "Start Block", "1", false },
		{ 1.3, 18, 15, 50, "Parry", "3", false },
		{ 0.9, 53, 51, 56, "End Block", "2", false },
	},
}
T["CrazyGuns"].run = build(T["CrazyGuns"]);

T["ChainwardenPull"] = {
	ids = { "5773977536" },
	name = "Chainwarden Pull",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 31, 29, 31, "Parry", "1", false },
	},
}
T["ChainwardenPull"].run = build(T["ChainwardenPull"]);

T["EthironBeam"] = {
	ids = { "11876148070" },
	name = "EthironBeam",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 1.1, 300, 300, 300, "Parry", "1", false },
	},
}
T["EthironBeam"].run = build(T["EthironBeam"]);

T["ChaserSlam"] = {
	ids = { "14531935090" },
	name = "ChaserSlam",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 1, 300, 300, 300, "Parry", "Release", false },
	},
}
T["ChaserSlam"].run = build(T["ChaserSlam"]);

T["EnforcerPullStart"] = {
	ids = { "7271659917" },
	name = "EnforcerPullStart",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 100, 100, 100, "Dodge", "Release", false },
	},
}
T["EnforcerPullStart"].run = build(T["EnforcerPullStart"]);

T["BellSpinCresendo"] = {
	ids = { "139686454345909" },
	name = "BellSpinCresendo",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.8, 43, 21, 60, "Parry", "1", false },
	},
}
T["BellSpinCresendo"].run = build(T["BellSpinCresendo"]);

T["ShadowAssault"] = {
	ids = { "6318273143" },
	action_type = "Spell",
	name = "ShadowAssault",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 18, 10, 15, "Parry", "Release", false },
	},
}
T["ShadowAssault"].run = build(T["ShadowAssault"]);

T["GremorianLongSpearCrit"] = {
	ids = { "12883012690" },
	action_type = "Critical",
	name = "GremorianLongSpearCrit",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 21, 15, 28, "Parry", "Release", false },
	},
}
T["GremorianLongSpearCrit"].run = build(T["GremorianLongSpearCrit"]);

T["1_GenericGreatsword1"] = {
	ids = { "6607519294" },
	action_type = "M1",
	name = "1_GenericGreatsword1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Jump", "1", false },
	},
}
T["1_GenericGreatsword1"].run = build(T["1_GenericGreatsword1"]);

T["BoneBoySpikeFloor"] = {
	ids = { "9681916972" },
	name = "BoneBoySpikeFloor",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.9, 20, 25, 99, "Jump", "Release", false },
	},
}
T["BoneBoySpikeFloor"].run = build(T["BoneBoySpikeFloor"]);

T["1_GenericGreatcannon1"] = {
	ids = { "106858298622632" },
	action_type = "M1",
	name = "1_GenericGreatcannon1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericGreatcannon1"].run = build(T["1_GenericGreatcannon1"]);

T["1_GenericSword2"] = {
	ids = { "7600224169" },
	action_type = "M1",
	name = "1_GenericSword2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericSword2"].run = build(T["1_GenericSword2"]);

T["IceChampionSweep"] = {
	ids = { "80169226986818" },
	name = "Ice Champion Sweep",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.57, 33, 23, 27, "Jump", "1", false },
		{ 1.88, 32, 24, 25, "Crouch", "3", false },
		{ 0.78, 32, 21, 25, "Crouch", "2", false },
	},
}
T["IceChampionSweep"].run = build(T["IceChampionSweep"]);

T["SpectralM1_2"] = {
	ids = { "88620745767944" },
	action_type = "M1",
	name = "SpectralM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.25, 10, 9, 14, "Parry", "1", false },
	},
}
T["SpectralM1_2"].run = build(T["SpectralM1_2"]);

T["DeepSpiderDoubleStab"] = {
	ids = { "6428525211" },
	name = "DeepSpiderDoubleStab",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 40, 38, 40, "Parry", "Release", false },
	},
}
T["DeepSpiderDoubleStab"].run = build(T["DeepSpiderDoubleStab"]);

T["Lumberaxe"] = {
	ids = { "89448051861345" },
	name = "Lumberaxe",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 11, 9, 14, "Parry", "1", false },
	},
}
T["Lumberaxe"].run = build(T["Lumberaxe"]);

T["LionfishTripleBite"] = {
	ids = { "5680585677" },
	name = "LionfishTripleBite",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 40, 40, 49, "Parry", "1", false },
		{ 1.95, 40, 40, 25, "Parry", "3", false },
		{ 1.15, 40, 40, 45, "Parry", "2", false },
	},
}
T["LionfishTripleBite"].run = build(T["LionfishTripleBite"]);

T["CroccoPoison"] = {
	ids = { "9474993606" },
	name = "CroccoPoison",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 1, 15, 25, 25, "Forced Full Dodge", "Release", false },
	},
}
T["CroccoPoison"].run = build(T["CroccoPoison"]);

T["PurpleCloud1"] = {
	ids = { "16372412925" },
	action_type = "M1",
	name = "PurpleCloud1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.325, 15, 12, 12, "Parry", "1", false },
	},
}
T["PurpleCloud1"].run = build(T["PurpleCloud1"]);

T["GolemHammer"] = {
	ids = { "15382135299" },
	name = "GolemHammer",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0, 0, 0, 0, "Parry", "1", false },
	},
}
T["GolemHammer"].run = build(T["GolemHammer"]);

T["BloodFoulerM1_2"] = {
	ids = { "99450771029342" },
	action_type = "M1",
	name = "BloodFoulerM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 10, 15, 10, "Parry", "Release", false },
	},
}
T["BloodFoulerM1_2"].run = build(T["BloodFoulerM1_2"]);

T["RatKingDoubleSlashDash"] = {
	ids = { "76066030388144" },
	name = "RatKingDoubleSlashDash",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.58, 34, 32, 34, "Parry", "1", false },
		{ 2.3, 42, 42, 42, "Parry", "3", false },
		{ 1.39, 34, 32, 34, "Parry", "2", false },
	},
}
T["RatKingDoubleSlashDash"].run = build(T["RatKingDoubleSlashDash"]);

T["FireForgeWindup"] = {
	ids = { "7608480718" },
	action_type = "Spell",
	name = "FireForgeWindup",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 16, 16, 23, "Parry", "1", false },
	},
}
T["FireForgeWindup"].run = build(T["FireForgeWindup"]);

T["MaliceM1_1"] = {
	ids = { "12138857946" },
	action_type = "M1",
	name = "MaliceM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.33, 20, 14, 16, "Parry", "1", false },
	},
}
T["MaliceM1_1"].run = build(T["MaliceM1_1"]);

T["1_GenericGreatsword2"] = {
	ids = { "6607538047" },
	action_type = "M1",
	name = "1_GenericGreatsword2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericGreatsword2"].run = build(T["1_GenericGreatsword2"]);

T["KaritaDiveBomb"] = {
	ids = { "15577323908" },
	name = "KaritaDiveBomb",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0, 0, 0, 0, "Parry", "Release", false },
	},
}
T["KaritaDiveBomb"].run = build(T["KaritaDiveBomb"]);

T["ToonsM1_2"] = {
	ids = { "106608030834708" },
	action_type = "M1",
	name = "ToonsM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["ToonsM1_2"].run = build(T["ToonsM1_2"]);

T["AuthorityOppressive"] = {
	ids = { "85186188251021" },
	name = "AuthorityOppressive",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 12, 12, 12, "Parry", "1", false },
	},
}
T["AuthorityOppressive"].run = build(T["AuthorityOppressive"]);

T["BloodFoulerM1_1"] = {
	ids = { "121003629056681" },
	action_type = "M1",
	name = "BloodFoulerM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 10, 15, 10, "Parry", "Release", false },
	},
}
T["BloodFoulerM1_1"].run = build(T["BloodFoulerM1_1"]);

T["LightningBeam"] = {
	ids = { "99711177955459" },
	action_type = "Spell",
	name = "LightningBeam",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 14, 20, 55, "Parry", "Release", false },
	},
}
T["LightningBeam"].run = build(T["LightningBeam"]);

T["ImperialM1_3"] = {
	ids = { "16654113357" },
	action_type = "M1",
	name = "ImperialM1_3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.35, 16, 11, 14, "Parry", "1", false },
	},
}
T["ImperialM1_3"].run = build(T["ImperialM1_3"]);

T["MetalBall"] = {
	ids = { "14953939237" },
	action_type = "Spell",
	name = "MetalBall",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 0, 0, 0, "Start Block", "Release", false },
		{ 0, 0, 0, 0, "Parry", "2", false },
	},
}
T["MetalBall"].run = build(T["MetalBall"]);

T["PyreKeeperM1_1"] = {
	ids = { "17197593993" },
	action_type = "M1",
	name = "PyreKeeperM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 16, 12, 12, "Parry", "1", false },
	},
}
T["PyreKeeperM1_1"].run = build(T["PyreKeeperM1_1"]);

T["2_GenericStaff"] = {
	ids = { "93964938784148" },
	action_type = "M1",
	name = "2_GenericStaff",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["2_GenericStaff"].run = build(T["2_GenericStaff"]);

T["Caltrops"] = {
	ids = { "14954130177" },
	action_type = "Spell",
	name = "Caltrops",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.2, 23, 15, 23, "Parry", "1", false },
	},
}
T["Caltrops"].run = build(T["Caltrops"]);

T["SoulflareSiphon"] = {
	ids = { "14428696078" },
	action_type = "Spell",
	name = "SoulflareSiphon",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.37, 16, 16, 20, "Parry", "1", false },
	},
}
T["SoulflareSiphon"].run = build(T["SoulflareSiphon"]);

T["1_GenericGreatAxe2"] = {
	ids = { "5067090007" },
	action_type = "M1",
	name = "1_GenericGreatAxe2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericGreatAxe2"].run = build(T["1_GenericGreatAxe2"]);

T["Scythe_1"] = {
	ids = { "11493920418" },
	action_type = "M1",
	name = "Scythe_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 16, 12, 16, "Parry", "Release", false },
	},
}
T["Scythe_1"].run = build(T["Scythe_1"]);

T["1_GenericTwinblade3"] = {
	ids = { "114108670383026" },
	action_type = "M1",
	name = "1_GenericTwinblade3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["1_GenericTwinblade3"].run = build(T["1_GenericTwinblade3"]);

T["ShadowEruptionCast"] = {
	ids = { "8018953639" },
	action_type = "Spell",
	name = "ShadowEruptionCast",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.05, 25, 25, 25, "Parry", "Release", false },
	},
}
T["ShadowEruptionCast"].run = build(T["ShadowEruptionCast"]);

T["IceEruptionBoss"] = {
	ids = { "105119461600751" },
	name = "IceEruptionBoss",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.5, 20, 15, 80, "Forced Full Dodge", "1", false },
	},
}
T["IceEruptionBoss"].run = build(T["IceEruptionBoss"]);

T["1Inferno3"] = {
	ids = { "96251946143797" },
	action_type = "M1",
	name = "1Inferno3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 16, 14, 12, "Parry", "1", false },
	},
}
T["1Inferno3"].run = build(T["1Inferno3"]);

T["ContractorPull"] = {
	ids = { "11328614766" },
	action_type = "Spell",
	name = "ContractorPull",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 27, 31, 28, "Parry", "Release", false },
	},
}
T["ContractorPull"].run = build(T["ContractorPull"]);

T["MaliceRunning"] = {
	ids = { "12496646061" },
	action_type = "M1",
	name = "MaliceRunning",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.45, 14, 14, 15, "Parry", "1", false },
	},
}
T["MaliceRunning"].run = build(T["MaliceRunning"]);

T["WealnWoeM1_1"] = {
	ids = { "87039001813522" },
	action_type = "M1",
	name = "WealnWoeM1_1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.533, 16, 16, 16, "Parry", "1", false },
	},
}
T["WealnWoeM1_1"].run = build(T["WealnWoeM1_1"]);

T["RailbladeM1_2"] = {
	ids = { "9832724876" },
	action_type = "M1",
	name = "RailbladeM1_2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 19, 13, 16, "Parry", "1", false },
	},
}
T["RailbladeM1_2"].run = build(T["RailbladeM1_2"]);

T["MechaGatling"] = {
	ids = { "11638263796" },
	action_type = "Spell",
	name = "MechaGatling",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.2, 18, 15, 24, "Start Block", "1", false },
		{ 2.5, 103, 103, 100, "End Block", "2", false },
	},
}
T["MechaGatling"].run = build(T["MechaGatling"]);

T["FlameAssault"] = {
	ids = { "7543558046" },
	action_type = "Spell",
	name = "FlameAssault",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 14, 15, 15, "Parry", "1", false },
	},
}
T["FlameAssault"].run = build(T["FlameAssault"]);

T["FlameGrab"] = {
	ids = { "5750353585" },
	action_type = "Spell",
	name = "FlameGrab",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0, 23, 20, 34, "Start Block", "1", false },
		{ 0.4, 60, 60, 60, "End Block", "2", false },
	},
}
T["FlameGrab"].run = build(T["FlameGrab"]);

T["TwisterKicks"] = {
	ids = { "16394277950" },
	action_type = "Spell",
	name = "TwisterKicks",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 20, 20, 20, "Parry", "1", false },
		{ 0.55, 32, 32, 32, "Parry", "2", false },
	},
}
T["TwisterKicks"].run = build(T["TwisterKicks"]);

T["AscensionWindup"] = {
	ids = { "9461033190" },
	action_type = "Spell",
	name = "AscensionWindup",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 1.2, 41, 50, 40, "Forced Full Dodge", "1", false },
	},
}
T["AscensionWindup"].run = build(T["AscensionWindup"]);

T["DreadBreath"] = {
	ids = { "11219902982" },
	action_type = "Spell",
	name = "DreadBreath",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.55, 25, 25, 85, "Parry", "1", false },
	},
}
T["DreadBreath"].run = build(T["DreadBreath"]);

T["DeepSpiderSpit"] = {
	ids = { "6428530032" },
	name = "DeepSpiderSpit",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 40, 38, 40, "Forced Full Dodge", "Release", false },
	},
}
T["DeepSpiderSpit"].run = build(T["DeepSpiderSpit"]);

T["WindBladeCopy"] = {
	ids = { "89554403628833" },
	action_type = "Spell",
	name = "WindBlade Copy",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.3, 33, 33, 33, "Parry", "1", false },
	},
}
T["WindBladeCopy"].run = build(T["WindBladeCopy"]);

T["LightningKickCopy"] = {
	ids = { "139120102460171" },
	action_type = "Spell",
	name = "LightningKick Copy",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.55, 18, 20, 21, "Parry", "Release", false },
	},
}
T["LightningKickCopy"].run = build(T["LightningKickCopy"]);

T["FlameLeapCopy"] = {
	ids = { "78527715560798" },
	action_type = "Spell",
	name = "FlameLeap Copy",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.4, 31, 32, 31, "Parry", "1", false },
	},
}
T["FlameLeapCopy"].run = build(T["FlameLeapCopy"]);

T["FrostGrabWindupCopy"] = {
	ids = { "121952157536892" },
	action_type = "Spell",
	name = "FrostGrabWindup Copy",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.6, 28, 28, 28, "Parry", "1", false },
	},
}
T["FrostGrabWindupCopy"].run = build(T["FrostGrabWindupCopy"]);

T["FirstlightM3"] = {
	ids = { "90244051282295" },
	action_type = "M1",
	name = "FirstlightM3",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.281, 35, 39, 32, "Parry", "1", false },
	},
}
T["FirstlightM3"].run = build(T["FirstlightM3"]);

T["FirstlightM2"] = {
	ids = { "107490523807500" },
	action_type = "M1",
	name = "FirstlightM2",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.297, 35, 39, 32, "Parry", "1", false },
	},
}
T["FirstlightM2"].run = build(T["FirstlightM2"]);

T["FirstLightM1"] = {
	ids = { "74039616835372" },
	action_type = "M1",
	name = "FirstLightM1",
	default_chance = 100,
	allow_block_input = true,
	allow_parry_to_roll = true,
	allow_roll_to_parry = true,
	allow_parry_to_block = true,
	actions = {
		{ 0.297, 35, 39, 32, "Parry", "1", false },
	},
}
T["FirstLightM1"].run = build(T["FirstLightM1"]);

return T
