// build_luabundle.mjs -> rain_bundle.lua
//
// Собирает весь Project Rain в один файл в формате luabundle (как у Luma):
//   -- Bundled by luabundle {"version":"1.7.0"}
//   local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = <runtime>(require)
//   __bundle_register("NAME", function(require, _LOADED, __bundle_register, __bundle_modules) ... end)
//   return __bundle_require("__root")
//
// Почему не npm-пакет luabundle: его парсер (moonsharp-luaparse) не понимает
// Luau — падает на "+=" (у нас 195 таких мест, 131 continue, 27 типов).
// Наш генератор код не парсит вообще: обходит дерево и оборачивает файлы.
//
// Как решаются проблемы, которые обычно ломают бандл:
//   * "@src/..." — имя модуля в бандле совпадает со строкой require, поэтому
//     146 статических require работают без переписывания;
//   * 73 динамических require — не в бандле -> рантайм-фоллбэк на __resolve
//     лоадера (HTTP + кэш), т.е. ведут себя ровно как сейчас;
//   * 6 отсутствующих модулей (main_menu/loader и прочие) — лоадер отдаёт их
//     из таблицы STUBS, путь в бандле не находится -> фоллбэк -> STUBS;
//   * restore/rain_hooks_new.lua — тоже встроен, лоадер переключается на него.
//
// Запуск:  node build_luabundle.mjs
// Проверка: node build_luabundle.mjs --check   (только отчёт, файл не пишет)

import fs from 'fs';
import path from 'path';

const HERE = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const PROJECT = path.join(HERE, 'project-rain-oss-master');
const LOADER_PATH = path.join(HERE, 'rain_loader.lua');
const OUT_PATH = path.join(HERE, 'rain_bundle.lua');

const CHECK_ONLY = process.argv.includes('--check');

// ---------------------------------------------------------------- обход дерева
// Берём ВСЁ, а не только *.lua: лоадер отдаёт .json/.txt строкой
// (candidates = { rel..".lua", rel, rel..".json" }, для не-.lua возвращает сырой
// src), и код на это завязан — например base_esp.lua дёргает
// require("@src/utility/deepwoken/deepwoken_meshes" .. "") и ждёт JSON-строку.
function walk(dir, base = '') {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, e.name);
    const rel = base ? base + '/' + e.name : e.name;
    if (e.isDirectory()) out.push(...walk(abs, rel));
    else out.push({ abs, rel });
  }
  return out;
}

// содержимое в long-bracket строку: уровень длиннее любой последовательности "]=..."
function asLuaString(s) {
  let level = 0;
  for (const m of s.matchAll(/\]=+/g)) level = Math.max(level, m[0].length - 1);
  const eq = '='.repeat(level + 1);
  return `return [${eq}[${s}]${eq}]`;
}

const modules = new Map(); // name -> { body, kind }
const dataModules = [];

for (const f of walk(path.join(PROJECT, 'src'))) {
  const name = '@src/' + f.rel.replace(/\.[^.]+$/, '');
  if (modules.has(name)) { console.warn('! дубликат имени модуля:', name); continue; }
  const content = fs.readFileSync(f.abs, 'utf8');
  if (f.rel.endsWith('.lua')) modules.set(name, { body: content, kind: 'lua' });
  else { modules.set(name, { body: asLuaString(content), kind: 'data' }); dataModules.push(name); }
}

const hooksPath = path.join(PROJECT, 'restore', 'rain_hooks_new.lua');
if (fs.existsSync(hooksPath)) {
  // restore: вывод хуков глушится в самом файле (restore/rain_hooks_new.lua),
  // а не здесь — файл теперь правится напрямую, и трансформ только мешал бы.
  modules.set('@restore/rain_hooks_new', { body: fs.readFileSync(hooksPath, 'utf8'), kind: 'lua' });} else {
  console.warn('! restore/rain_hooks_new.lua не найден — хуки будут грузиться по HTTP');
}

// ---------------------------------------------------------------- Luma-порт
// luma/** — это файлы, портированные из Luma-main (Utility, Game,
// Features/Automation, ...). Регистрируются как @luma/<rel>, то есть
// ровно под тем путём, который Luma использует в своих require.
//
// Требуется переписывание require: в Luma модули требуют друг друга по
// путям относительно корня ("Utility/Maid", "Features/Game/Tweening"),
// а в бандле имя модуля = строка require дословно. Поэтому любой require
// вида require("A/B") в файле из luma/ переписывается в require("@luma/A/B"),
// если такой модуль есть. Если его нет — идёт по таблице алиасов на
// родные модули Rain, и только потом остаётся как есть (и попадает в
// --check как битая ссылка, чтобы не потерялось молча).
const LUMA_DIR = path.join(PROJECT, 'luma');

// алиасы: путь из Luma -> модуль Rain (когда в портированном дереве нет)
const LUMA_ALIASES = {
  'Utility/Maid': '@src/utility/maid',
  'Utility/Signal': '@src/utility/signal',
  'Utility/Logger': '@src/utility/logger',
  'Utility/PersistentData': '@src/utility/persistent_data',
  'Utility/JSON': '@src/utility/json',
  'Utility/Table': '@src/utility/table_utils',
  'Utility/Attributes': '@src/utility/attributes',
  'Utility/Throttle': '@src/utility/throttle',
};

const lumaAvailable = new Set();
if (fs.existsSync(LUMA_DIR)) {
  for (const f of walk(LUMA_DIR)) {
    lumaAvailable.add(f.rel.replace(/\.[^.]+$/, ''));
  }
}

function rewriteLumaRequires(src) {
  return src.replace(/require\s*\(\s*(["'])([^"']+)\1\s*\)/g, (m, q, spec) => {
    // @-пути и относительные (./ ../) не трогаем
    if (spec.startsWith('@') || spec.startsWith('.')) return m;
    const asLuma = '@luma/' + spec;
    if (lumaAvailable.has(spec)) return `require(${q}${asLuma}${q})`;
    if (LUMA_ALIASES[spec]) return `require(${q}${LUMA_ALIASES[spec]}${q})`;
    return m; // останется битым — --check покажет
  });
}

let lumaCount = 0;
if (fs.existsSync(LUMA_DIR)) {
  for (const f of walk(LUMA_DIR)) {
    const name = '@luma/' + f.rel.replace(/\.[^.]+$/, '');
    if (modules.has(name)) { console.warn('! дубликат имени модуля:', name); continue; }
    modules.set(name, { body: rewriteLumaRequires(fs.readFileSync(f.abs, 'utf8')), kind: 'lua' });
    lumaCount++;
  }
  console.log(`модули Luma-порта: ${lumaCount}`);
}

// assets/*.json кладём в бандл как @assets/<rel>. Нужно потому, что
// inline_asset_b96() идёт в game:HttpGet, а под установленным хуками
// __namecall (rain_hooks_new onNameCall) вызов game:HttpGet перехватывается и
// падает с "argument #1 expects a string, but Instance was passed" на
// oldNameCall. Хуки трогать нельзя, поэтому убираем сам поход в сеть:
// JSON лежит в бандле и отдаётся мгновенно.
// Бинарники (ttf/mp3/png) так не встроить — они остаются на HTTP.
const assetsDir = path.join(PROJECT, 'assets');
if (fs.existsSync(assetsDir)) {
  for (const f of walk(assetsDir)) {
    if (f.rel.endsWith('.json')) {
      const name = '@assets/' + f.rel;
      modules.set(name, { body: asLuaString(fs.readFileSync(f.abs, 'utf8')), kind: 'data' });
      dataModules.push(name);
    }
  }
}

// ---------------------------------------------------------------- правки лоадера
let loader = fs.readFileSync(LOADER_PATH, 'utf8');

// 1) bundle-first резолв. Вставляется сразу после определения __resolve,
//    чтобы STUBS/apply_patches/__cache были уже в области видимости.
//    ВАЖНО: здесь нельзя кэшировать в __bundle_loaded — эту таблицу
//    использует сам рантайм бандла (упакованные {n=...} значения), и
//    запись сырого результата ломает require для всех, кто грузится после.
const ANCHOR_RESOLVE = 'local __real_require = require';
const SHIM = `-- >>> rain-bundle: bundle-first resolution (вставлено build_luabundle.mjs)
do
    local __bm, __breq = __bundle_modules, __bundle_require
    local __inner = __resolve
    __resolve = function(path)
        if __bm[path] ~= nil then
            return __breq(path)
        end
        return __inner(path)
    end
    -- то, чего нет в бандле (динамические require + STUBS), идёт в лоадер
    __bundle_fallback = __inner
end
`;
if (!loader.includes(ANCHOR_RESOLVE)) {
  throw new Error('якорь не найден в лоадере: ' + ANCHOR_RESOLVE);
}
loader = loader.replace(ANCHOR_RESOLVE, SHIM + ANCHOR_RESOLVE);

// 2) assets: сначала бандл, HTTP только для бинарников (ttf/mp3/png), которые
//    встроить в Lua-исходник нельзя. Тот же механизм, что и для require.
const ASSET_OLD = `function inline_asset_b96(path)
    local rel = path:gsub("^@assets/", "assets/")
    return game:HttpGet(BASE_URL .. rel)
end`;
const ASSET_NEW = `function inline_asset_b96(path)
    -- restore: json-ассеты лежат прямо в бандле (@assets/*.json). Раньше любой
    -- вызов уходил в game:HttpGet, но под хуками __namecall из
    -- restore/rain_hooks_new перехватывался и ронял вызов на oldNameCall
    -- ("argument #1 expects a string, but Instance was passed"), из-за чего
    -- auto-parry не поднимался. Сами хуки не трогаем — убираем поход в сеть.
    local bundled = __bundle_modules[path]
    if bundled ~= nil then
        local ok, res = pcall(__bundle_require, path)
        if ok and type(res) == "string" and #res > 0 then return res end
    end
    local rel = path:gsub("^@assets/", "assets/")
    return game:HttpGet(BASE_URL .. rel)
end`;
if (loader.includes(ASSET_OLD)) {
  loader = loader.replace(ASSET_OLD, ASSET_NEW);
  console.log('  ассеты: json переключён на бандл, бинарники остались на HTTP');
} else if (loader.includes(ASSET_NEW)) {
  console.log('  ассеты: уже на бандле');
} else {
  console.warn('! inline_asset_b96 не распознан — оставлен как есть (HTTP)');
}

// 3) хуки: сначала бандл, HTTP только как фоллбэк
const HOOK_OLD = `        local src = game:HttpGet(BASE_URL .. "restore/rain_hooks_new.lua")
        local fn = assert(loadstring(src, "=rain_hooks_new"))`;
const HOOK_NEW = `        local fn = __bundle_require("@restore/rain_hooks_new")
        if type(fn) ~= "function" then
            local src = game:HttpGet(BASE_URL .. "restore/rain_hooks_new.lua")
            fn = assert(loadstring(src, "=rain_hooks_new"))
        end`;
if (loader.includes(HOOK_OLD)) {
  loader = loader.replace(HOOK_OLD, HOOK_NEW);
  console.log('  хуки: переключены на бандл');
} else if (loader.includes(HOOK_NEW)) {
  console.log('  хуки: уже на бандле');
} else {
  console.warn('! блок загрузки хуков не распознан — оставлен как есть (HTTP)');
}

// ---------------------------------------------------------------- отчёт
// require("x" .. "") и вообще любой require, где аргумент начинается со строки —
// такой раньше не попадал в разбор и молча ломал бандл. Регулярка берёт первый
// строковый литерал независимо от того, что идёт после него.
const REQUIRE_LIT = /require\s*\(\s*"([^"]+)"/g;
const staticReq = new Map();
const dynamicReq = [];
const scan = (src, tag) => {
  const statics = [];
  for (const m of src.matchAll(REQUIRE_LIT)) statics.push(m[1]);
  for (const m of src.matchAll(/require\s*\(\s*([^"\s)][^)]*)\)/g)) dynamicReq.push([tag, m[1].trim()]);
  return statics;
};

for (const [name, mod] of modules) {
  if (mod.kind !== 'lua') continue;
  staticReq.set(name, scan(mod.body, name));
}
staticReq.set('__root', scan(loader, '__root'));

const bundleNames = new Set(modules.keys());
const STUB_OK = new Set([
  '@src/luarmor_init_script', '@src/security/user_service', '@src/utility/setup_auto_load',
  '@src/main_menu/loader', '@src/features/buttons/refresh', '@src/features/misc/spotify_widget',
]);
const missing = new Set();
for (const reqs of staticReq.values()) {
  for (const r of reqs) {
    if (typeof r !== 'string' || !r.startsWith('@')) continue;
    if (!bundleNames.has(r)) missing.add(r);
  }
}
const broken = [...missing].filter(r => !STUB_OK.has(r)).sort();

console.log('модулей в бандле      :', bundleNames.size, `(${bundleNames.size - dataModules.length} lua + ${dataModules.length} data)`);
console.log('статических require   :', [...staticReq.values()].reduce((n, a) => n + a.length, 0));
console.log('динамических require  :', dynamicReq.length);
for (const m of dataModules) console.log('   data:', m);
console.log('стабы лоадера (STUBS) :', missing.size - broken.length);
if (broken.length) {
  console.log('!! БИТЫЕ ССЫЛКИ (нет ни в бандле, ни в STUBS):');
  for (const b of broken) console.log('   ->', b);
} else {
  console.log('битых ссылок          : нет');
}

if (CHECK_ONLY) process.exit(broken.length ? 1 : 0);

// ---------------------------------------------------------------- эмиссия
const RUNTIME = `local loadingPlaceholder = {[{}] = true}
local register, modules, loaded, done, reentrant = {}, {}, {}, {}, {}
local require
local unpack = table.unpack or unpack
local function pack(...) return { n = select('#', ...), ... } end
register = function(name, body)
    if not modules[name] then modules[name] = body end
end
require = function(name)
    -- ВАЖНО: модули возвращают НЕСКОЛЬКО значений (return func, { name = "Visuals" }),
    -- поэтому результат пакуется и отдаётся через unpack. Наивный
    -- "return loaded[name]" срезает всё после первого — из-за этого в ui/ui.lua
    -- терялся { name = ... }, цикл вкладок падал и они оставались пустыми.
    if done[name] then
        local cached = loaded[name]
        -- Циклический/вложенный require: модуль ещё исполняется, поэтому
        -- loaded[name] == nil. Официальный luabundle возвращал здесь nil,
        -- и его рантайм падал бы на том же месте — отдаём nil явно.
        if cached == nil then return nil end
        return unpack(cached, 1, cached.n)
    end
    local body = modules[name]
    if not body then
        if __bundle_fallback then return __bundle_fallback(name) end
        error('rain_bundle: no such module ' .. tostring(name))
    end
    done[name] = loadingPlaceholder
    reentrant[name] = (reentrant[name] or 0) + 1
    local res = pack(body(require, loaded, register, modules))
    -- Диагностика вложенных require: модуль, который потребовали изнутри
    -- другого модуля (а не из корня), получает nil по контракту цикла.
    -- Пишем один раз, чтобы не засорять консоль.
    if reentrant[name] > 1 then
        getgenv().RAIN_BUNDLE_REENTRY = getgenv().RAIN_BUNDLE_REENTRY or {}
        local log = getgenv().RAIN_BUNDLE_REENTRY
        if not log[name] then
            local okc, info = pcall(function()
                return debug.getinfo(2, "Sl") and debug.getinfo(2, "S").source
                    .. " line " .. tostring(debug.getinfo(2, "l"))
            end)
            log[name] = okc and tostring(info) or "?"
        end
    end
    reentrant[name] = nil
    loaded[name] = res
    done[name] = true
    return unpack(res, 1, res.n)
end
return require, loaded, register, modules`;

const parts = [];
parts.push('-- Bundled by luabundle {"version":"1.7.0"}');
parts.push(`-- Project Rain: ${bundleNames.size} modules, generated by build_luabundle.mjs`);
// ВАЖНО: __bundle_fallback объявлен во внешней области — шим из лоадера пишет
// в него как в upvalue. Если объявить его внутри фабрики, присваивание станет
// глобальным и рантайм никогда не увидит фоллбэк (81 динамический require).
parts.push('local __bundle_fallback = nil');
parts.push(`local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)\n${RUNTIME}\nend)(require)`);

// корень: параметр НЕ называется require, иначе "function require(path)" в лоадере
// попал бы в локал модуля и не переопределил бы глобальный require
parts.push(`__bundle_register("__root", function(__br, _LOADED, __bundle_register, __bundle_modules)\n${loader}\nend)`);

for (const [name, mod] of modules) {
  parts.push(`__bundle_register(${JSON.stringify(name)}, function(require, _LOADED, __bundle_register, __bundle_modules)\n${mod.body}\nend)`);
}
parts.push('return __bundle_require("__root")');

const out = parts.join('\n');
fs.writeFileSync(OUT_PATH, out, 'utf8');

console.log('');
console.log('записано:', OUT_PATH);
console.log('размер  :', (Buffer.byteLength(out) / 1024 / 1024).toFixed(2), 'MB');
console.log('запуск  : loadstring(readfile("rain_bundle.lua"))()');
