# DEVLOG

Agent-maintained; human reviewed.
Entries before 2026-11-18 were seeded retrospectively from `git log` (era-level summaries, not per-commit); entries from that date on are recorded as they happen.

## 2023-01 - 2023-12: inception, dotfiles era

- Repo starts as a dbt "Module" system plus initial dotfiles.
- nvim plugin set built up: gitgutter, floaterm, mundo/undotree, telescope, surround, ALE.
- tmux replaces GNU screen; tmux-powerline made portable; tpm becomes a dependency.
- Bash config moves from `.bashrc` into `sourceme.sh`, callable from anywhere.
- `.config/` renamed to `config/`, foreshadowing the XDG-layout repo.

## 2024: maintenance era

- Periodic installs and plugin upkeep: pylint via ALE, treesitter-textobjects in (gutentags out), svlangserver removed as too noisy, lualine status bar.
- treesitter SV highlighting attempted and abandoned (still broken).

## 2025-11 - 2025-12: Wayland pivot + lazy.nvim migration

- Window manager direction changes: dwm dependency added then pointed at personal fork; st terminal for tmux; qutebrowser config and keybindings added.
- Plugin manager migrated packer -> lazy.nvim; plugins get per-file specs.
- verilator added to deps; filetype.nvim dropped (merged into core).

## 2026-05 - 2026-09: Wayland desktop assembles

- dwl + dwl-patches added; dwl points at personal fork, wlroots moved to system packages.
- `XDG_CONFIG_HOME` made explicit so `config/` becomes the live config dir.
- Waybar configs, dmenu -> wmenu switch, wlock.
- nvim: telescope replaced by snacks, vim-mundo back, nvim-treesitter plugin spec, mason + nvim-lint (fusesoc_verilator sarif -> quickfix).

## 2026-10-20 - 2026-10-22: nvim polish sprint

- Per-filetype colorschemes via window highlight namespaces, plus muted unfocused variant, background dimming, zen-mode, snacks pickers.
- render-markdown configured to non-default values only; blink.cmp autocomplete; lazyverilog LSP (non-mason); quickfix vs loclist toggles; core keymaps consolidated into `keymaps.lua`.

## 2026-10-23 - 2026-11-09: bootstrap architecture

- `bootstrap.sh` created and iterated hard: fetch delegated to `deps/scripts`, `-t` standalone / `-f` full desktop modes, made self-sufficient.
- Repo restructured: `DEPS/` -> `deps/`, dbt MODULE removed, apt deps move to `*-deps.yml` manifests, tarballs to `tarballs.yaml`.
- Wayland desktop completed: mako, swaybg, wmenu, foot, waybar, wlock, dwl.desktop into wayland-sessions.
  Tools: verilator, fusesoc, edalize, gtkwave, inkscape, qutebrowser-as-terminal-tool.
- `checkhealth.sh` added.
- Committed `bin/*.sh` wrappers replaced by generated shims in `envs/bin` so repo commands never shadow system commands before install.
- Fresh-install hardening: curl failures caught early, stale meson builddirs removed, tmux `st-256color` -> `tmux-256color` (present in ncurses-base), `koalemo` -> `ganoam` renames, `branch = dev` submodule fix, dwl.desktop path templating for arbitrary clone locations.

## 2026-11-17 - 2026-11-18: docs, README overhaul, agent conventions

- README restructured for public consumption: tagline, target audience, roadmap factored out, standalone-vs-full install framing, DWL survival notes, distro note (Ubuntu 26.04 target).
- `tricks/` committed as the home for lightweight how-tos (moved to `deps/workflows` a day later); em-dashes removed repo-wide.
- `desc` strings added across keymap configs so binds document themselves (which-key popups, generated README tables); nerdy.nvim bind fixed; fugitive/vinegar buffer-local maps redeclared with descs.
- Universal treesitter highlighting via `pcall(vim.treesitter.start)`; embedded-language tint via `paint_injections()` `line_hl` extmarks over injected regions (heredocs, fences).
- `update-docs.sh` added: regenerates fenced `keymaps:NAME` README tables from an `nvim --clean` baseline diff plus tmux parsing.
- `AGENTS.md` and this file established.

## 2026-11-19: agent workflow + git privacy setup

- Adopted the shared agent workflow (`deps/workflows` submodule): agent rules, recipes, and tricks get one pinned source shared across repos; the Devin plugin symlinks this checkout, so injected skills and pinned docs can't drift.
- Moved repo tricks into `deps/workflows/tricks/` (single shared home).
- Set up public/private publishing so private files never reach the public remote: `private` superset branch + private mirror, `.gitprivate` declares private paths, pre-commit/pre-push guards live in `deps/scripts/git-hooks` activated via `core.hooksPath`.
- Restructured `AGENTS.md` onto the shared template (pointer preamble, repo-specific deltas only).
- `recipes/devlog.md` added to the workflows repo: this file's entry format became the shared house format; the log reworked onto it.
- New shared style rule adopted via `deps/workflows`: one sentence per line in prose docs, no fixed-column rewrapping.
  Sweeps of this repo's and the workflows repo's docs queued in both roadmaps, timing is the owner's call.
- snippet: `README.md` gained a planned-tools section.

## 2026-11-20: fresh-install test rerun + first local recipe

- Re-ran the bwrap fresh-install test on `ubuntu-base-26.04.1` (was 24.04): 36 ok / 7 warn (wayland tools, expected in `-t`) / 1 fail; second bootstrap run fully idempotent.
- New sandbox findings vs the notes doc: `apparmor_restrict_unprivileged_userns` strips `CAP_DAC_OVERRIDE`, so real `sudo` can't unpack (mode-000 `.dpkg-new` reopen fails EACCES) and is dropped from the container apt list in favor of the shim; `chown` to unmapped uids EINVALs, so the `dbus` postinst cascade into "N not fully installed" is noise, not signal.
- Real repo gap surfaced: `qutebrowser-deps.yml` carries build deps only; QtWebEngine needs `libnspr4 libnss3 libasound2t64 libxkbfile1 libxcb-cursor0 libxkbcommon-x11-0` at runtime (queued in `BACKLOG.md`).
- `recipes/fresh-install-testing.md` added: first project-local recipe, distilled from `~/code/notes/fresh-install-testing.md` plus this run's findings; `AGENTS.md` recipe list updated.
- `deps/workflows`: `MdStyle.md` added as a third binding doc in the AGENTS preamble and given a path in `rules.md` after a prose style miss; DEVLOG prompting rule changed to direct edit prompts in `rules.md` + `workflow.md`.
  Owner commits + pin bump pending.
- `BACKLOG.md` added for noticed-not-fixed items.

## 2026-11-22: doc upkeep + update-docs.sh attribution

- `AGENTS.md` preamble re-synced verbatim to `deps/workflows/agents/template.md` (the three-doc pointer including `MdStyle.md`); the copy had drifted to the older two-doc wording.
- `BACKLOG.md` maintenance: canonical header adopted; the workflows gitlink bump moved to `## In flight` (checkout at `b971a90`, parent commit pending); decided items recorded: an `update-docs.sh` CI gate (Actions job: regen + `git diff --exit-code` on push) and a bootstrap fresh-install CI job porting `recipes/fresh-install-testing.md` (bwrap) onto the runner.
- `update-docs.sh` restyled to the `deps/workflows/hooks` comment convention (`== Intent/Method/Caveats/Usage ==` header, `# ---` separators); comments only, still a shell script; verified idempotent against the checked-out README.
- `update-docs.sh` is agent-authored (Devin session, 2026-11): output verified, deliberately not line-reviewed by the owner.
  Authorship recorded here and in the script header since this repo is portfolio material.
- snippet: `README.md` gained the generated keymap tables (first committed `update-docs.sh` run), a known-issues section, and a refreshed contents listing.
- snippet: `sourceme/sourceme.sh` adds `deps/scripts/git-util` to PATH.
- snippet: private branch gained its `.gitprivate` declaration and first private-only docs.

## 2026-11-22: bump scripts 498f6288...5648d6ae (9 commits)
## 2026-11-22: bump scripts 5d1c2933...4d663e70 (1 commit)
## 2026-11-22: bump workflows 2c5127e7...9a5a2460 (30 commits)
## 2026-11-23: bump scripts 4d663e70...e9d58ae3 (4 commits)

## 2026-11-22: readme-docs gate (--check, hook dispatch, CI)

- `update-docs.sh --check`: regenerates into a temp copy and diffs against README.md instead of writing in place; nonzero exit plus the drift diff on stale tables, missing nvim is a hard error (otherwise the gate passes on unverified tables).
- `deps/scripts/git-hooks` split into run-parts multiplexers: `pre-commit`/`pre-push` now run every executable in `<hook>.d/` (shared) then `<repo>/git-hooks/<hook>.d/` (consumer-local); the privacy guards moved to `10-git-private` files unchanged.
  `tests/test-git-privacy.sh` gained dispatch cases; 20/20 pass.
- `git-hooks/pre-push.d/readme-docs`: repo-local gate running the same `--check`; verified live (an origin push was blocked by the privacy guard, a mirror push ran the docs check).
- `.github/workflows/fresh-install.yml`: the bwrap fresh-install flow from `recipes/fresh-install-testing.md` ported to Actions (ubuntu-base 26.04 rootfs, userns sysctl, git@->https rewrite); `update-docs.sh --check` is its last step, running on the nvim the bootstrap just installed, so the docs gate uses the bootstrap result as a true precondition.
  Path-gated on bootstrap+doc inputs plus a nightly cron.
- `bootstrap.sh` runs `git-util/setup-git-hooks.sh` after fetch-repos (needs the dep checkout present; the remote-fetch fallback can't resolve `../git-hooks`).

## 2026-11-23: bump dwl (1 commit)

## 2026-11-23: bump scripts e9d58ae3...2894d87d (2 commits)
## 2026-11-23: bump workflows 9a5a2460...414afbd1 (3 commits)

## 2026-11-23: MdStyle sweep

- One-sentence-per-line and no-em-dash rules applied across the repo's own docs (`AGENTS.md`, `DEVLOG.md`, `README.md`, `ROADMAP.md`, `notes/debug-suspend-hanging.md`): wrapped sentences joined, second sentences moved onto lines indented under their item, em/en-dashes replaced.
- `questions.md`, `notes/todo.md`, `recipes/fresh-install-testing.md` already compliant; tables and `keymaps:` generated fences exempt, untouched.
- Dep checkouts (`deps/workflows`, `deps/scripts`) deliberately out of scope; their docs still carry wrap violations for a later sweep there.
## 2026-11-23: bump workflows 414afbd1...62669ea2 (1 commit)

## 2026-11-23: provenance-mark sweep

- `Agent-maintained` head marks on `README.md`, `DEVLOG.md`, `BACKLOG.md`, `ROADMAP.md` (living docs the agent keeps updated; same convention as the dep-repo sweeps); `Agent-generated` on `recipes/fresh-install-testing.md`, `checkhealth.sh` (owner-confirmed agent-authored), `bootstrap.sh` (mixed authorship; mark records agent involvement in provenance).
- `update-docs.sh`, `git-hooks/pre-push.d/readme-docs`, `.github/workflows/fresh-install.yml` already carried marks; dep checkouts were swept separately.
- Marks are bare: review suffixes (`; human reviewed`, `; output verified`) are owner-stated, not self-applied.

## 2026-11-23: bump workflows 62669ea2...f95b9003 (1 commit)
## 2026-11-23: bump scripts 87ea8bd2...4ffc5754 (1 commit)

## 2026-11-23: tricks entries land + pts bind dropped

- `deps/workflows/tricks/linux-tricks.md` (general `/dev/pts` + `/dev/shm`) and `bwrap-tricks.md` sections written in the dep checkout; dep commit and pin bump pending.
- Verified on bwrap 0.11.1: `--dev` mounts a private devpts, so `--dev-bind-try /dev/pts /dev/pts` under `--unshare-user` shadows it with the host instance and breaks `/dev/ptmx` (`EACCES`, `out of pty devices`).
- Flag removed from `recipes/fresh-install-testing.md` and `.github/workflows/fresh-install.yml`; `--tmpfs /dev/shm` stays.
- BACKLOG `## Tricks entry` items moved to `## In flight` (uncommitted); answers the `/dev/pts` question in `questions.md`.
## 2026-11-23: bump scripts 4ffc5754...f4c1869c (1 commit)

## 2026-11-23: scripts restructure consumer updates

- snippet: `sourceme` PATH and README updated for the `deps/scripts` rename (`shortcut-menus` -> `menus`); the `shell/` -> `desktop/` references live in the bumped `deps/dwl` pin.
## 2026-11-24: bump workflows 720c0a39...cc8c0c06 (2 commits)

## 2026-11-24: agent-setup upkeep

- README gained the canonical agent-workflow onboarding entry (checkout chain + `--local` plugin install); rest of the `agent-setup.md` checklist verified current: AGENTS.md preamble identical to `agents/template.md`, hooks and privacy split active, plugin already `--local`.
- `.devin/skills/fresh-install-testing/SKILL.md` generated for the repo-local recipe (agent-setup step 5); `.devin/`: local agent workflow data -> private mirror.

## 2026-11-24: bump workflows cc8c0c06...2a941679 (8 commits)
## 2026-11-24: bump workflows 2a941679...5de22a4b (4 commits)
## 2026-11-24: bump scripts f4c1869c...5407dd69 (2 commits)

## 2026-11-24: gitsigns for visual-selection staging

- `plugins.lua`: `lewis6991/gitsigns.nvim` added alongside vim-gitgutter as the hunk-staging engine (its `signcolumn` off, symbols stay gitgutter's); `<leader>ghs` in visual mode stages the selected line range (`stage_hunk` on the `line('.')`/`line('v')` span).
  Loads on `BufReadPre` so gitsigns' own attach autocmd is in place before the buffer's read finishes (first attempt on `BufReadPost` raced the attach and staged nothing).
  Verified in a scratch repo: one selected line of a two-line hunk staged, the rest stayed unstaged.
- `update-docs.sh`: keyspec classification now tries the sibling visual modes ('v'/'x'/'s') before the `keymaps` fallback; nvim reports one map under several visual-mode enumerations, and a spec-mode-'x' bind otherwise split its rows across groups (first live hit: `<leader>hl` landed in `keymaps` AND the unfenced `gitsigns.nvim` group).
- `README.md`: `gitsigns.nvim` section + fence added next to vim-gitgutter's; generated rows land there (`v` and `x` enumerations), `--check` green.

## 2026-11-24: update-docs mode-merge: one row per declared bind

- `update-docs.sh`: nvim lists one map under every enumeration it is effective in (an `x`-map also shows in `v`), so single-mode visual specs rendered duplicated `v`/`x` rows. Rows now resolve the map's real mode via `maparg()` and merge entries sharing group+lhs+action into one line with mode letters joined (`nv`, `nt`): the `<leader>hl` bind renders a single `x` row, `{'n','v'}` specs a single `nv` row, and the longstanding v/x duplicates across `keymaps`/`snacks`/`nvim-surround` collapse.
- `README.md`: all keymap tables regenerated; `--check` green.
