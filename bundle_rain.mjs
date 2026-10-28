// Rain single-file bundler (Node port of build_bundle.ps1, inspired by
// cutegirlnkcw/project-rain-oss bundle_project_rain.mjs).
// Embeds src/**/*.lua|json + code assets + restore hooks + games hubs into
// rain_loader.lua as a Lua string table (runtime require reads EMBED first).
// Needs only Node builtins. Usage: node bundle_rain.mjs
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, 'project-rain-oss-master');
const LOADER = path.join(__dirname, 'rain_loader.lua');
const OUT = path.join(__dirname, 'rain_bundle.lua');

function luaString(text) {
  let level = 0;
  while (true) {
    const eq = '='.repeat(level);
    const close = ']' + eq + ']';
    if (!text.includes(close)) return '[' + eq + '[' + text + close;
    level++;
    if (level > 10) throw new Error('cannot bracket-escape content');
  }
}

function collect(dir, relBase, exts) {
  const out = [];
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const full = path.join(d, e.name);
      if (e.isDirectory()) { walk(full); continue; }
      if (!e.isFile()) continue;
      if (exts && !exts.includes(path.extname(e.name))) continue;
      const rel = relBase + '/' + path.relative(dir, full).split(path.sep).join('/');
      out.push([rel, full]);
    }
  };
  walk(dir);
  out.sort((a, b) => (a[0] < b[0] ? -1 : 1));
  return out;
}

const entries = [];
for (const [rel, full] of collect(path.join(ROOT, 'src'), 'src', ['.lua', '.json']))
  entries.push([rel, fs.readFileSync(full, 'utf8')]);
for (const a of ['assets/base.json', 'assets/extra_data.json', 'assets/hopper.lua']) {
  const full = path.join(ROOT, ...a.split('/'));
  if (fs.existsSync(full)) entries.push([a, fs.readFileSync(full, 'utf8')]);
}
entries.push(['restore/rain_hooks_new.lua',
  fs.readFileSync(path.join(ROOT, 'restore', 'rain_hooks_new.lua'), 'utf8')]);
const gamesDir = path.join(ROOT, 'games');
if (fs.existsSync(gamesDir))
  for (const [rel, full] of collect(gamesDir, 'games', ['.lua']))
    entries.push([rel, fs.readFileSync(full, 'utf8')]);

let loader = fs.readFileSync(LOADER, 'utf8');
const fetchAnchors = [
  'local function __fetch(url)\r\n    return game:HttpGet(url)\r\nend',
  'local function __fetch(url)\n    return game:HttpGet(url)\nend',
];
const anchor = fetchAnchors.find((a) => loader.includes(a));
if (!anchor) throw new Error('fetch anchor not found in loader');

const body = entries.map(([rel, text]) => `    ["${rel}"] = ` + luaString(text) + ',').join('\n');
const patchedFetch = `-- BUNDLE: embedded sources (offline). Falls back to HTTP for anything else (assets).
local EMBED = {
${body}
}
local function __fetch(url)
    local rel = url:match("^https?://[^/]+/[^/]+/[^/]+/[^/]+/(.+)$") or url
    if EMBED[rel] then return EMBED[rel] end
    return game:HttpGet(url)
end
print("[restore] single-file bundle: ${entries.length} embedded files, no src fetch")`;
loader = loader.replace(anchor, patchedFetch);

const assetAnchor = 'function inline_asset_b96(path)';
if (!loader.includes(assetAnchor)) throw new Error('asset anchor not found in loader');
loader = loader.replace(assetAnchor, `function inline_asset_b96(path)
    local rel = path:gsub("^@assets/", "assets/")
    if EMBED[rel] then return EMBED[rel] end
    return game:HttpGet(BASE_URL .. rel)
end
function __unused_inline_asset_b96(path)`);

fs.writeFileSync(OUT, loader);
console.log('wrote', OUT);
console.log('embedded files:', entries.length);
console.log('size bytes:', fs.statSync(OUT).size);
