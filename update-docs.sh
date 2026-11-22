#!/usr/bin/env bash
# update-docs.sh - regenerate the generated tables in README.md
# Agent-generated; output verified
#
# == Intent ==
#
# Generated regions are fenced in the README:
#   <!-- keymaps:NAME:begin -->
#   ...generated content...
#   <!-- keymaps:NAME:end -->
# The checked-in tables must track the live configs; this script
# rewrites the fenced interiors so they never drift.
#
# == Method ==
#
# Pipeline: nvim baseline dump -> nvim config dump -> tmux parse ->
# splice. Each generator emits blocks headed "@@NAME"; the splicer at
# the bottom replaces the matching fenced region. Groups with no fence
# are reported on stderr; fences with no generated group are left
# untouched, so hand-written prose inside fences survives.
#
# == Caveats ==
#
# - The nvim stages degrade to a stderr warning when nvim is missing
#   or the dump fails; fenced nvim tables then stay stale.
# - The splice is a textual match on NAME: a generator/fence name
#   mismatch leaves the region untouched (group reported as missing).
#
# Usage: ./update-docs.sh  (rewrites README.md in place;
#        CONFIGROOT overrides the config dir, default ./config)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGROOT="${CONFIGROOT:-$ROOT/config}"
README="$ROOT/README.md"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

NVIM="$(command -v nvim || echo "$ROOT/envs/bin/nvim")"

# Output contract: the lua helpers write results to files instead of
# printing, because print() output is lost in headless mode when stdout
# is redirected to a file. File paths arrive via env vars, all inside
# $WORK (cleaned up by the trap); they are set at the nvim invocations
# at the bottom of stage 2:
#   NVIM_DUMP_OUT       output file each lua script writes its dump to
#   NVIM_DUMP_DEFAULTS  input file: the baseline stage 1 produced

# ------------------------------------------------------------------
# Stage 1 - nvim default-map baseline
# ------------------------------------------------------------------

# Dump every keymap a `nvim --clean` session has, as mode/lhs/source
# tuples. "Custom" is defined later as "not identical to a baseline
# tuple" - comparing source as well as lhs lets remapped defaults like
# [d / ]d count as custom overrides instead of being filtered out.

cat > "$WORK/defaults.lua" <<'lua'
local out = assert(io.open(os.getenv("NVIM_DUMP_OUT"), "w"))
for _, mode in ipairs({ "n", "v", "x", "i", "t" }) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        local src = map.rhs or ""
        if map.callback then
            local s = debug.getinfo(map.callback, "S").source
            src = "cb:" .. (s:sub(1, 1) == "@" and s:sub(2) or s)
        end
        out:write(mode .. "\t" .. map.lhs .. "\t" .. src .. "\n")
    end
end
out:close()
lua

# ------------------------------------------------------------------
# Stage 2 - our config's keymaps, grouped by defining file
# ------------------------------------------------------------------

# Attribution waterfall (see classify below):
#   1. lua callback source file      -> config file or lazy/<plugin>
#   2. maparg sid -> sourced script  -> vimscript plugins
#   3. plugin name inside rhs        -> <Plug>-mapped / config redeclared
#   4. lazy keys-spec lhs match      -> keys-spec binds (lazy.nvim hides
#                                       itself as the defining source)
#   5. fallback "keymaps"            -> our config; fails loud rather
#                                       than silently dropping binds

cat > "$WORK/dump.lua" <<'lua'
local modes = { "n", "v", "x", "i", "t" }

-- baseline tuples from stage 1: anything identical is a nvim default
local defaults = {}
local df = os.getenv("NVIM_DUMP_DEFAULTS")
if df then
    for line in io.lines(df) do
        local m, l, s = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
        if m then defaults[m .. "\0" .. l] = s end
    end
end

-- which file defined this mapping: callback source for lua maps,
-- script id for vimscript rhs maps. lua api maps carry pseudo-sids
-- (negative) and resolve to nil here.
local function source_of(map, mode)
    if map.callback then
        local src = debug.getinfo(map.callback, "S").source
        if src:sub(1, 1) == "@" then return src:sub(2) end
    end
    local info = vim.fn.maparg(map.lhs, mode, false, true)
    if info and info.sid and info.sid > 0 then
        local si = vim.fn.getscriptinfo({ sid = info.sid })[1]
        if si and si.name then return si.name end
    end
    return nil
end

-- keys-spec attribution: lazy's keys handler creates spec binds itself,
-- so their source is lazy.nvim; match lhs+mode back to the owning spec.
-- Spec lhs uses <leader> notation, runtime lhs is already expanded.
local function norm_lhs(lhs)
    return (lhs
        :gsub("<[lL]eader>", vim.g.mapleader or "\\")
        :gsub("<[lL]ocalleader>", vim.g.maplocalleader or "\\")
        :gsub("<[sS]pace>", " "))
end
local keyspec = {}
local plugin_names = {}
local ok, lazy = pcall(require, "lazy")
if ok then
    for _, plugin in pairs(lazy.plugins()) do
        local name = plugin.name
        if name then plugin_names[name] = true end
        for _, k in ipairs(plugin.keys or {}) do
            local lhs = type(k) == "table" and k[1] or k
            local km = type(k) == "table" and (k.mode or { "n" }) or { "n" }
            if type(km) == "string" then km = { km } end
            for _, m in ipairs(km) do
                keyspec[m .. "\0" .. norm_lhs(lhs)] = {
                    name = name,
                    desc = type(k) == "table" and k.desc or nil,
                    cmd = type(k) == "table" and type(k[2]) == "string"
                        and k[2] or nil,
                }
            end
        end
    end
end

local function classify(map, mode)
    local path = source_of(map, mode)
    if path then
        -- defined inside our config: lua/config/* or lua/plugins/*
        local cfg = path:match("config/nvim/lua/(.-)%.lua$")
        if cfg then
            if cfg == "config/keymaps" then return "keymaps" end
            local g = cfg:match("plugins/(.+)")
            if g and g ~= "plugins" then return g end
        end
        -- defined inside an installed plugin checkout
        local plugin = path:match("lazy/([^/]+)/")
        if plugin == "lazy.nvim" then
            local ks = keyspec[mode .. "\0" .. map.lhs]
            return ks and ks.name or plugin
        end
        if plugin then return plugin end
    end
    -- rhs names the plugin: <Plug>(nvim-surround-normal), <Plug>VinegarUp,
    -- or a plugin-namespaced call like fugitive#Object(...)
    local plug = map.rhs and map.rhs:match("<Plug>%(?([%w%._%-]+)")
    if plug then plug = plug:lower() end
    local rhs_l = map.rhs and map.rhs:lower()
    if plug or rhs_l then
        for name in pairs(plugin_names) do
            local l = name:lower()
            local stripped = l:gsub("^vim%-", ""):gsub("^nvim%-", "")
            if plug and (plug:sub(1, #l) == l or
               (stripped ~= "" and plug:sub(1, #stripped) == stripped)) then
                return name
            end
            if rhs_l and stripped ~= "" and rhs_l:find(stripped, 1, true) then
                return name
            end
        end
    end
    -- keys-spec binds whose handler hides the owning plugin
    local ks = keyspec[mode .. "\0" .. map.lhs]
    if ks then return ks.name end
    -- required lua modules all get sid-attributed to init.lua, so an
    -- unresolvable custom map is most likely ours
    return "keymaps"
end

-- identity of a map for baseline comparison
local function map_src(map, mode)
    if map.rhs and map.rhs ~= "" then return map.rhs end
    if map.callback then
        local s = debug.getinfo(map.callback, "S").source
        return "cb:" .. (s:sub(1, 1) == "@" and s:sub(2) or s)
    end
    return ""
end

local function esc(s) return (s:gsub("|", "\\|"):gsub("`", "\\`")) end
-- display: mapleader is a space; render it as <leader>, other spaces <Space>
local function disp(lhs)
    return (lhs:gsub("^ ", "<leader>"):gsub(" ", "<Space>"))
end

local groups = {}
for _, mode in ipairs(modes) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        if defaults[mode .. "\0" .. map.lhs] == map_src(map, mode) then
            goto continue              -- unchanged nvim default
        end
        if map.lhs:match("<Plug>") or map.lhs:match("<SNR>") then
            goto continue              -- internal machinery
        end
        if map.desc == "which_key_ignore" then goto continue end
        local group = classify(map, mode)
        local action = map.desc
        if not action or action == "" then
            local ks = keyspec[mode .. "\0" .. map.lhs]
            action = (ks and (ks.desc or ks.cmd))
                or (map.callback and "lua fn" or (map.rhs or ""))
        end
        -- LSP-flavored keymaps.lua binds go to their own table
        if group == "keymaps" and
           (action:lower():match("lsp") or action:lower():match("diagnostic")) then
            group = "lsp"
        end
        groups[group] = groups[group] or {}
        table.insert(groups[group],
            { lhs = map.lhs, mode = mode, action = action })
        ::continue::
    end
end

local out = assert(io.open(os.getenv("NVIM_DUMP_OUT"), "w"))
local names = {}
for name in pairs(groups) do table.insert(names, name) end
table.sort(names)
for _, name in ipairs(names) do
    local rows = groups[name]
    out:write("@@" .. name .. "\n")
    out:write("| Key | Mode | Action |\n|---|---|---|\n")
    table.sort(rows, function(a, b)
        return a.mode == b.mode and a.lhs < b.lhs or a.mode < b.mode
    end)
    for _, r in ipairs(rows) do
        out:write(string.format("| `%s` | %s | %s |\n",
            esc(disp(r.lhs)), r.mode, esc(r.action)))
    end
end
out:close()
lua

# event-gated plugins (VeryLazy etc.) never load in a headless session,
# so their maps would be invisible; force-load everything by name first
# (lazy.plugins() is not name-keyed - iterate and use plugin.name).
cat > "$WORK/load-all.lua" <<'lua'
local ok, lazy = pcall(require, "lazy")
if ok then
    for _, p in pairs(lazy.plugins()) do
        pcall(lazy.load, { plugins = { p.name }, wait = true })
    end
end
lua

if [ -x "$NVIM" ] || command -v "$NVIM" >/dev/null 2>&1; then
    # stage 1: default-map baseline from a clean session
    NVIM_DUMP_OUT="$WORK/defaults.txt" \
    "$NVIM" --clean --headless -c "luafile $WORK/defaults.lua" +qa! \
        2>/dev/null
    # stage 2: our maps, grouped - baseline tuples filtered out
    NVIM_DUMP_DEFAULTS="$WORK/defaults.txt" NVIM_DUMP_OUT="$WORK/nvim.txt" \
    "$NVIM" --headless -u "$CONFIGROOT/nvim/init.lua" \
        -c "luafile $WORK/load-all.lua" \
        -c "luafile $WORK/dump.lua" +qa! 2>"$WORK/nvim.err" \
        || echo "WARNING: nvim keymap dump failed (see $WORK/nvim.err)" >&2
else
    echo "WARNING: nvim not found, skipping nvim keymaps" >&2
fi

# ------------------------------------------------------------------
# Stage 3 - tmux binds
# ------------------------------------------------------------------

# Parse tmux.conf directly: our custom layer is a handful of prefix,
# unbind and bind-key lines.

awk '
    /^[[:space:]]*set -g prefix/ {
        gsub(/["'"'"']/, "", $4)
        print "| `" $4 "` | prefix key |"
        next
    }
    /^[[:space:]]*unbind/ {
        gsub(/["'"'"']/, "", $2)
        print "| `" $2 "` | unbound |"
        next
    }
    /^[[:space:]]*bind-key?/ {
        rep = ""; i = 2
        while ($i ~ /^-/) { if ($i == "-r") rep = " (repeatable)"; i++ }
        key = $i; gsub(/["'"'"']/, "", key)
        i++
        cmd = ""; for (; i <= NF; i++) cmd = cmd (cmd ? " " : "") $i
        gsub(/["'"'"']/, "", cmd)
        printf "| `prefix %s`%s | `%s` |\n", key, rep, cmd
    }
' "$CONFIGROOT/tmux/tmux.conf" > "$WORK/tmux-rows.txt"
{
    echo "@@tmux"
    echo "| Binding | Action |"
    echo "|---|---|"
    cat "$WORK/tmux-rows.txt"
} > "$WORK/tmux.txt"

# ------------------------------------------------------------------
# Stage 4 - splice generated blocks into fenced README regions
# ------------------------------------------------------------------

python3 - "$README" "$WORK/nvim.txt" "$WORK/tmux.txt" <<'python'
import re, sys

readme_path, *files = sys.argv[1:]
readme = open(readme_path).read()

# collect @@NAME blocks from every generator output file
blocks = {}
for f in files:
    try:
        text = open(f).read()
    except OSError:
        continue
    for m in re.finditer(r'^@@(\S+)\n(.*?)(?=^@@|\Z)', text, re.M | re.S):
        blocks[m.group(1)] = m.group(2).strip()

# replace the interior of each matching fenced region
updated, missing = [], []
for name, content in blocks.items():
    pat = re.compile(
        r'(<!-- keymaps:' + re.escape(name) + r':begin -->).*?'
        r'(<!-- keymaps:' + re.escape(name) + r':end -->)', re.S)
    if pat.search(readme):
        readme = pat.sub(lambda m: m.group(1) + '\n' + content + '\n' + m.group(2), readme)
        updated.append(name)
    else:
        missing.append(name)

open(readme_path, 'w').write(readme)
print("updated:", ", ".join(sorted(updated)) or "none")
if missing:
    print("no region for groups:", ", ".join(sorted(missing)), file=sys.stderr)
python
