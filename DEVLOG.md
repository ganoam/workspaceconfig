# DEVLOG

Entries before 2026-11-18 were seeded retrospectively from `git log`
(era-level summaries, not per-commit); entries from that date on are
recorded as they happen.

## 2023-01 - 2023-12: inception, dotfiles era

- Repo starts as a dbt "Module" system plus initial dotfiles.
- nvim plugin set built up: gitgutter, floaterm, mundo/undotree,
  telescope, surround, ALE.
- tmux replaces GNU screen; tmux-powerline made portable; tpm becomes
  a dependency.
- Bash config moves from `.bashrc` into `sourceme.sh`, callable from
  anywhere.
- `.config/` renamed to `config/`, foreshadowing the XDG-layout repo.

## 2024: maintenance era

- Periodic installs and plugin upkeep: pylint via ALE,
  treesitter-textobjects in (gutentags out), svlangserver removed as
  too noisy, lualine status bar.
- treesitter SV highlighting attempted and abandoned (still broken).

## 2025-11 - 2025-12: Wayland pivot + lazy.nvim migration

- Window manager direction changes: dwm dependency added then pointed
  at personal fork; st terminal for tmux; qutebrowser config and
  keybindings added.
- Plugin manager migrated packer -> lazy.nvim; plugins get per-file
  specs.
- verilator added to deps; filetype.nvim dropped (merged into core).

## 2026-05 - 2026-09: Wayland desktop assembles

- dwl + dwl-patches added; dwl points at personal fork, wlroots moved
  to system packages.
- `XDG_CONFIG_HOME` made explicit so `config/` becomes the live
  config dir.
- Waybar configs, dmenu -> wmenu switch, wlock.
- nvim: telescope replaced by snacks, vim-mundo back, nvim-treesitter
  plugin spec, mason + nvim-lint (fusesoc_verilator sarif ->
  quickfix).

## 2026-10-20 - 2026-10-22: nvim polish sprint

- Per-filetype colorschemes via window highlight namespaces, plus
  muted unfocused variant, background dimming, zen-mode, snacks
  pickers.
- render-markdown configured to non-default values only; blink.cmp
  autocomplete; lazyverilog LSP (non-mason); quickfix vs loclist
  toggles; core keymaps consolidated into `keymaps.lua`.

## 2026-10-23 - 2026-11-09: bootstrap architecture

- `bootstrap.sh` created and iterated hard: fetch delegated to
  `deps/scripts`, `-t` standalone / `-f` full desktop modes, made
  self-sufficient.
- Repo restructured: `DEPS/` -> `deps/`, dbt MODULE removed, apt deps
  move to `*-deps.yml` manifests, tarballs to `tarballs.yaml`.
- Wayland desktop completed: mako, swaybg, wmenu, foot, waybar,
  wlock, dwl.desktop into wayland-sessions. Tools: verilator,
  fusesoc, edalize, gtkwave, inkscape, qutebrowser-as-terminal-tool.
- `checkhealth.sh` added.
- Committed `bin/*.sh` wrappers replaced by generated shims in
  `envs/bin` so repo commands never shadow system commands before
  install.
- Fresh-install hardening: curl failures caught early, stale meson
  builddirs removed, tmux `st-256color` -> `tmux-256color` (present
  in ncurses-base), `koalemo` -> `ganoam` renames, `branch = dev`
  submodule fix, dwl.desktop path templating for arbitrary clone
  locations.

## 2026-11-17 - 2026-11-18: docs, README overhaul, agent conventions

- README restructured for public consumption: tagline, target
  audience, roadmap factored out, standalone-vs-full install framing,
  DWL survival notes, distro note (Ubuntu 26.04 target).
- `tricks/` committed as the home for lightweight how-tos (moved to
  `deps/workflows` a day later); em-dashes removed repo-wide.
- `desc` strings added across keymap configs so binds document
  themselves (which-key popups, generated README tables); nerdy.nvim
  bind fixed; fugitive/vinegar buffer-local maps redeclared with
  descs.
- Universal treesitter highlighting via
  `pcall(vim.treesitter.start)`; embedded-language tint via
  `paint_injections()` `line_hl` extmarks over injected regions
  (heredocs, fences).
- `update-docs.sh` added: regenerates fenced `keymaps:NAME` README
  tables from an `nvim --clean` baseline diff plus tmux parsing.
- `AGENTS.md` and this file established.

## 2026-11-19: agent workflow + git privacy setup

- Adopted the shared agent workflow (`deps/workflows` submodule):
  agent rules, recipes, and tricks get one pinned source shared
  across repos; the Devin plugin symlinks this checkout, so injected
  skills and pinned docs can't drift.
- Moved repo tricks into `deps/workflows/tricks/` (single shared
  home).
- Set up public/private publishing so private files never reach the
  public remote: `private` superset branch + private mirror,
  `.gitprivate` declares private paths, pre-commit/pre-push guards
  live in `deps/scripts/git-hooks` activated via `core.hooksPath`.
- Restructured `AGENTS.md` onto the shared template (pointer
  preamble, repo-specific deltas only).
- `recipes/devlog.md` added to the workflows repo: this file's entry
  format became the shared house format; the log reworked onto it.
