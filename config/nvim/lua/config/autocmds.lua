-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)                       -- Highlighting (no-op without parser)
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()' -- Folding
    -- vim.wo.foldmethod = 'expr'
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'python', 'rust', 'lua' },
  callback = function()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- Indentation
  end,
})

---------------------------------------------------------------
-- trim trailing whitespaces without moving the cursor/view  --
---------------------------------------------------------------
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-------------------------------
-- Override search highlight --
-------------------------------
local function set_search_hl()
  vim.api.nvim_set_hl(0, "Search",     { fg = "#000000", bg = "#ffd75f" })
  vim.api.nvim_set_hl(0, "CurSearch",  { fg = "#000000", bg = "#ff8700", bold = true })
  vim.api.nvim_set_hl(0, "IncSearch",  { link = "CurSearch" })
  vim.api.nvim_set_hl(0, "Substitute", { fg = "#000000", bg = "#87afff" })
end

set_search_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_search_hl,
})

----------------------------------------------------------------------------
-- Per-filetype colorschemes via window highlight namespaces (Nvim 0.10+) --
----------------------------------------------------------------------------
local ft_colors = {
  -- python        = "habamax",
  lua           = "darkblue",
  rust          = "darkblue",
  verilog       = "torte",
  systemverilog = "torte",
  markdown      = "habamax",
}
local default_scheme = "torte"   -- matches options.lua
local ns_full  = {}              -- scheme -> normal ns
local ns_muted = {}              -- scheme -> muted ns

-- gray-mix a "#rrggbb" color; t=0 → gray, t=1 → original
local function mute_color(hex, t)
  if type(hex) ~= "number" then return hex end
  local r = math.floor(hex / 65536) % 256
  local g = math.floor(hex / 256) % 256
  local b = hex % 256
  local lum = math.floor(0.299 * r + 0.587 * g + 0.114 * b)
  local mix = function(c) return math.floor(lum + (c - lum) * t + 0.5) end
  return mix(r) * 65536 + mix(g) * 256 + mix(b)
end

-- scale RGB by factor f (0 = black, 1 = unchanged) — keeps hue
local function dim_color(hex, f)
  if type(hex) ~= "number" then return hex end
  local r = math.floor(math.floor(hex / 65536) % 256 * f + 0.5)
  local g = math.floor(math.floor(hex / 256) % 256 * f + 0.5)
  local b = math.floor(hex % 256 * f + 0.5)
  return r * 65536 + g * 256 + b
end

local BG_GROUPS = { "Normal", "NormalNC", "NonText", "EndOfBuffer",
                    "SignColumn", "LineNr", "CursorLine", "WinBar" }

local function build_ns(scheme)
  local full  = vim.api.nvim_create_namespace("ft_" .. scheme)
  local muted = vim.api.nvim_create_namespace("ft_" .. scheme .. "_muted")

  if pcall(vim.cmd.colorscheme, scheme) then
    local groups = vim.api.nvim_get_hl(0, {})

    -- seed bg/fg for groups that paint the window background
    local normal = groups.Normal or {}
    for _, g in ipairs(BG_GROUPS) do
      groups[g] = groups[g] or {}
      if groups[g].bg == nil then groups[g].bg = normal.bg end
      if groups[g].fg == nil then groups[g].fg = normal.fg end
    end

    local function resolve(def, depth)
      if def.link and depth < 10 then
        return resolve(groups[def.link] or {}, depth + 1)
      end
      return def
    end

    for name, def in pairs(groups) do
      local r = resolve(def, 0)
      r.link, r.cterm = nil, nil

      vim.api.nvim_set_hl(full, name, r)

      local m = vim.tbl_extend("force", {}, r)
      m.fg = mute_color(r.fg, 0.55)
      m.bg = dim_color(r.bg, 0.55)
      m.sp = mute_color(r.sp, 0.55)
      m.bold, m.italic, m.underline = false, false, false
      vim.api.nvim_set_hl(muted, name, m)
    end

    local mp = groups.MatchParen or {}
    local mp_bg = mp.bg or 0x5f5f5f
    vim.api.nvim_set_hl(full,  "MatchParen", { bg = mp_bg, bold = true })
    vim.api.nvim_set_hl(muted, "MatchParen", { bg = dim_color(mp_bg, 0.8), bold = true })

  else
    vim.api.nvim_del_namespace(full)
    vim.api.nvim_del_namespace(muted)
    full, muted = 0, 0
  end

  ns_full[scheme], ns_muted[scheme] = full, muted
end

for _, s in pairs(ft_colors) do
  if not ns_full[s] then build_ns(s) end
end
build_ns(default_scheme)
pcall(vim.cmd.colorscheme, vim.g.colors_name or default_scheme) -- restore once

local function win_scheme()
  return ft_colors[vim.bo.filetype] or default_scheme
end

local function set_ns(ns)
  if ns ~= 0 then pcall(vim.api.nvim_win_set_hl_ns, 0, ns) end
end

local function is_overlay_win()
  local cfg = vim.api.nvim_win_get_config(0)
  return cfg.relative ~= ""
      and (vim.bo.buftype ~= ""
           or vim.bo.filetype == ""
           or vim.bo.filetype == "diff"          -- git hunk previews
           or vim.w.snacks_picker ~= nil         -- snacks picker/preview windows
           or bt == "quickfix")                  -- qf + loclist windows
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType" }, {
  callback = function()
    if is_overlay_win() then
      pcall(vim.api.nvim_win_set_hl_ns, 0, 0)
      return
    end
    set_ns(ns_full[win_scheme()])
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    if is_overlay_win() then return end
    set_ns(ns_muted[win_scheme()])
  end,
})

