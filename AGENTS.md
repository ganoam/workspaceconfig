# AGENTS.md: notes for anyone working in this repo

Generic binding rules and operating workflow live in `deps/workflows/agents/` (`rules.md`, `workflow.md`) and the prose style guide `deps/workflows/MdStyle.md`; all apply in full here.
Resolve them through the checkout chain: `~/workspaceconfig/deps/workflows`, then `deps/workflows` in this repo, then `../workflows` for dependency checkouts; if none exists, warn the owner and prompt them to clone the workflows repo.
This file holds only repo-specific guidance.
Keep it current per the shared rules.

## What this is

Personal, reproducible Ubuntu 26.04 workstation bootstrap + dotfiles.
Also serves as public/job-hunt material: keep documentation accurate,
do not oversell.

## Repo-specific rules

Deltas on top of the shared rules:

- Public/private split (recipe: `deps/workflows/recipes/git-privacy.md`):
  work happens on `private` (a superset of `master`), `.gitprivate`
  declares private paths, `deps/scripts/git-util/publish.sh` replays
  public commits onto `master` (owner runs it).
- Commit style: `[area] short lowercase summary` (see `git log`).
- **Self-documenting code.** State the high-level goal in a section
  header, then explain each block adjacent to it. Names mentioned in
  comments must match actual identifiers. Document contracts (env vars,
  file formats) before their first use, not only where they are set.
- Prefer single-file scripts when it aids readability (`update-docs.sh`
  keeps its lua/python helpers in heredocs; an earlier extraction into
  `util/` files was reverted for this reason).
- Honest technical assessment over validation; the user wants pushback
  when an idea is wrong.
- Do not change GUI behavior without need (qutebrowser opening a real
  window in checkhealth is accepted).
- Never edit git config; never commit secrets.
- Root-level untracked files (`post.txt`, `DEPS/` reference
  checkouts, `learnings.md`, scratch tests) are intentional; do not
  delete or gitignore them. `DEPS/` reintroduction candidates are
  tracked in `ROADMAP.md`.
- `DEVLOG.md` format: `deps/workflows/recipes/devlog.md` (dated
  sections, newest at the bottom, terse per-packet bullets).
- `README.md` is the install contract: a fresh-clone reader should be
  able to reproduce without asking (`bootstrap.sh -t` / `-f`,
  `python3`/`python3-venv`, etc.).

## Reusable workflows

`deps/workflows/recipes/` documents reusable detailed workflows; a
project-local `recipes/` directory, if present, layers on top and
overrides. When a task falls under one, read and follow it.

Project-local recipes: `recipes/fresh-install-testing.md` (bwrap
sandbox bootstrap verification). Shared recipes this repo
exercises: `git-privacy.md` (public/private split),
`deps-management.md` and `vendoring.md` (`deps/` submodules),
`agent-setup.md` (this file's shape).

Shared how-tos/gotchas live in `deps/workflows/tricks/` (they no
longer live in this repo); non-obvious discoveries get added there in
the dep clone, then the owner bumps the pin.

## Layout

- `bootstrap.sh [-y] [-t|--tools] [-f|--full]`: entry point; delegates
  submodule/tarball fetching and tool builds to `deps/scripts/setup/*.sh`
  (`fetch-repos.sh`, `fetch-tarballs.sh`, `lib.sh`). `-t` = standalone
  tools only, `-f` = full Wayland desktop.
- `sourceme/sourceme.sh`: must be sourced first. Sets
  `CONFIGROOT=$ROOT/config`, `XDG_CONFIG_HOME=$CONFIGROOT`, PATH.
  Because XDG points at the repo, `config/` is the *live* config dir:
  edits take effect immediately, there is no install/copy step.
- `config/`: mirrors a ~/.config layout. Notable: `nvim` (LazyVim-ish:
  `lua/config/{options,keymaps,autocmds}.lua` + `lua/plugins/*.lua`
  specs), `tmux`, `qutebrowser`, `waybar`, `dwl`.
- `envs/bin/`: generated command shims (absolute paths, created at
  install time, not committed). Invariant: **a repo-provided command
  must never shadow a system command before its tool is installed.**
  This is why committed `bin/` wrappers were replaced by generated shims.
- `deps/`: vendored source checkouts (`.gitmodules` uses
  `branch = dev`) and build trees. `deps/scripts/` carries the bootstrap
  machinery plus `git-util/` (hooks installer, `publish.sh`);
  `deps/workflows/` pins the shared agent workflow, recipes, and
  tricks.
- `*-deps.yml`: apt manifests per tool. Do NOT add Python packages to
  them (triggers sudo prompts); document `python3`/`python3-venv` in
  the README instead.
- `notes/`: private (listed in `.gitprivate`).

## Toolchain and build

- `./bootstrap.sh -t` / `-f`: install standalone tools / full Wayland
  desktop.
- `./checkhealth.sh`: post-install validation. Tools that only exist
  in `-f` installs are warnings, not failures, so `-t` stays green.
- `./update-docs.sh`: regenerates the fenced README keymap tables
  (below).

## README generated tables

`update-docs.sh` fills `<!-- keymaps:NAME:begin/end -->` fences from
`@@NAME` blocks (nvim dump, tmux parse, python splice). Rules:

- Never hand-edit inside fences. To change table content, add/fix
  `desc` in the bind's config and re-run the script; the descs also
  feed which-key popups.
- Groups with no fence are reported on stderr; fences without a group
  are left untouched, so hand-written prose survives.
- Buffer-local maps are invisible to `nvim_get_keymap`; document them
  as prose outside fences (vinegar/fugitive buffer maps).

## Neovim config specifics

- `vim.g.mapleader = " "`. Config dir is `config/nvim` via XDG, so the
  running editor reads these files directly; restarting nvim is needed
  to pick up changes.
- `autocmds.lua`: universal `pcall(vim.treesitter.start)` FileType
  autocmd (silent no-op without parser; this is what enables injected
  highlighting). TS indentexpr stays scoped to python/rust/lua.
- `set_custom_hl()` in autocmds.lua holds ALL custom/overridden
  highlight groups and re-runs on `ColorScheme`; put new group defs
  there, not inline.
- Per-filetype colorschemes via `nvim_win_set_hl_ns` namespaces built
  in `build_ns()` (`ft_colors` map).
- `plugins/nvim-treesitter.lua` spec owns the embedded-language tint:
  `paint_injections()` paints `line_hl` extmarks over injected-language
  regions (heredocs, fences). `skip_ft`/`skip_lang` exclude
  double-rendering cases (markdown is handled by render-markdown).

## Gotchas (documented, verified in this repo)

- Treesitter heredoc injections key on the delimiter name:
  `<<'lua'` works, `<<'LUA'` does not (case-sensitive language names).
- `print()` output is lost in headless nvim when stdout is a file;
  write via `io.open()` instead.
- `lazy.plugins()` is not name-keyed; iterate and use `plugin.name`.
- `VeryLazy` never fires headless; `event`-gated plugins need
  force-loading to inspect their state.
- `get_parser()` returns nil (not an error) when a parser is missing;
  `parse()` without args skips injections, `parse(true)` is needed for
  `children()`/`included_regions()`.
- Lua API maps carry negative pseudo-sids and `require`d modules get
  sid-attributed to `init.lua`; attribute via `debug.getinfo(callback)`
  or rhs/plugin-name matching.
- `vim.fn.mapset()` needs the full `maparg()` dict plus modifications.

## Current state and next steps

- Public/private split is set up: `.gitprivate` started (still
  untracked), hooks live in `deps/scripts/git-hooks` (activated by
  `core.hooksPath`, not yet set), `private` remote configured.
  `AGENTS.md`/`DEVLOG.md` are public. Pending owner actions: run the
  hooks installer and commit `.gitprivate` (hooks read the committed
  list).
- Tricks live in `deps/workflows/tricks/`; the old tracked copies at
  repo root were removed (`e4a8321`).
- The installed Devin plugin is a `--local` link to this checkout of
  `deps/workflows`, so the pinned docs and injected skills stay in
  sync.
