# workspaceconfig

Modular development workspace configuration: shell environment, Neovim, tmux,
Wayland desktop (dwl/waybar/wlock), qutebrowser, and a pinned EDA toolchain.

## Layout

```
bin/        # symlinked/wrapped binaries (on PATH)
config/     # nvim, tmux, waybar, qutebrowser, fusesoc configs (XDG_CONFIG_HOME)
sourceme/   # sourceme.sh
deps/       # fetched dependencies (partially gitignored)
envs/       # environment configurations (gitignored)
```

## Provided tools

(fetched into `deps/`):

**Terminal tools (no sudo required):**

| Dependency | Type | Purpose |
|---|---|---|
| neovim | binary tarball | editor, added to PATH |
| ripgrep | binary tarball | Fast grep |
| tmux | binary tarball | Terminal multiplexer |
| verilator | git | HDL simulator; `VERILATOR_ROOT` set, `bin/` prepended to PATH |
| qutebrowser | git | keyboard-driven browser |
| tpm | git | tmux plugin manager |
| scripts | git | `shortcut-menus` wmenu scripts added to PATH |
| fusesoc | git | SOC build system; installed into `envs/main` venv |
| neovim-remote (nvr) | pip | Neovim remote control for tmux integration; installed into `envs/main` venv |

**Wayland tools (full mode only, requires sudo for dwl and build/runtime dependencies (see: `tool-deps.yml`.):**

| Dependency | Type | Purpose |
|---|---|---|
| dwl + dwl-patches | git | Wayland compositor |
| waybar | git | Wayland statusbar |
| mako | git | Wayland notification daemon |
| swaybg | git | Wayland wallpaper utility |
| wmenu | git | Wayland menu launcher |
| foot | git | Wayland terminal emulator |
| wlock | git | Wayland screen locker |

Repo config dirs (`config/`): `nvim/`, `tmux/` (incl. tmux-powerline),
`waybar/`, `qutebrowser/`, `fusesoc/`.

## Activate

Add to `~/.bashrc`:

```
pushd path/to/workspaceconfig
. sourceme/sourceme.sh
popd
```

## External required tools

**Bootstrap dependencies** (must exist on the system):
- `bash`, `git`, `curl` - Fundamental system tools
- `python3-pip` / `pip3` - Required for installing Python packages into virtual environments

**Optional tools** (not required for basic functionality):
- `highlight` - Used by `LESSOPEN` for syntax-highlighted `less` (gracefully degrades if missing)

**EDA tools** (optional - for FPGA development, warn-only if missing):
- `vivado`, `verible-verilog-format`, Libero (`LIBERO_PATH`/`LIBERO_LIC_PATH`), `xauth`
- License env vars expected: `LM_LICENSE_FILE`, `XILINXD_LICENSE_FILE`

## Environment variables set by `sourceme.sh`

- `VERILATOR_ROOT=$ROOT/deps/verilator`
- `TOOLS_PATH` (default `~/tools`), `GOPATH` (default `~/go`),
  `CARGOPATH` (default `~/.cargo`), `USRBIN` (default `/usr/bin`)
  (GOPATH/CARGOPATH are for general Go/Rust development, not required by workspace tools)
- `CONFIGROOT=$ROOT/config`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`,
  `NVIMCONFIG`, `TMUX_HOME`
- `EDITOR=nvim`, `menu=wmenu`, `WORKSPACE_SET=1`
- `HISTSIZE`/`HISTFILESIZE=10000000`, shared history via `PROMPT_COMMAND`
- `LESSOPEN` pipes through `highlight` (solarized-light)
- PATH prepends: `$VERILATOR_ROOT/bin`, `$CARGOPATH/bin`, `$GOPATH/bin`,
  `$ROOT/bin`, `$ROOT/deps/scripts/shortcut-menus`, `$ROOT/deps/scripts/bin`


## Aliases

| Alias | Expansion |
|---|---|
| `vim`, `vi`, `nvim` | `nvim` |
| `vimdiff` | `nvim -d` |
| `h` / `v` / `t` | `nvr -o` / `nvr -O` / `nvr --remote-tab` |
| `less` | `less -m -N -g -i -J --line-numbers --underline-special` |
| `more` | `less` |
| `tmux` | `tmux -f $CONFIGROOT/tmux/tmux.conf` |
| `qutebrowser` | `qutebrowser -C $CONFIGROOT/qutebrowser/config.py` |
| `vvfi` | `verible-verilog-format --inplace` |
| `vvmts` | `vivado -mode tcl -source ` |
| `vvmbs` | `vivado -mode batch -source ` |
| `libefire` / `libedone` / `libelic` | Libero license daemon start/stop/restart (only if `LIBERO_PATH`/`LIBERO_LIC_PATH` set) |

Bash line editing is set to vi mode (`set -o vi`).

## Custom keybindings

### tmux (`config/tmux/tmux.conf`)

| Binding | Action |
|---|---|
| `C-a` | prefix (replaces `C-b`) |
| `prefix C-a` | last window |
| `prefix l` / `prefix h` (repeatable) | swap window right/left |

Status line keys are vi-style; plugins: tpm, tmux-sensible,
`Koalemo/tmux-resurrect` (nvim/vim session strategy, pane contents captured),
tmux-powerline. Default terminal: `st-256color`.
`SSH_AUTH_SOCK` is forced to `~/.ssh/ssh_auth_sock` (see `~/.ssh/rc` above).

#### Configuration Details
- **Terminal**: `st-256color` (suckless terminal)
- **Shell**: Non-login shell for proper environment
- **Status keys**: vi-style
- **Aggressive resize**: enabled
- **Window rename format**: Shows pane current path

#### Plugins (via tpm)
- `tmux-plugins/tpm`: Plugin manager
- `tmux-plugins/tmux-sensible`: Sensible defaults
- `Koalemo/tmux-resurrect`: Session restoration with nvim/vim session strategy and pane contents capture
- `erikw/tmux-powerline`: Powerline-style status bar

Install plugins: `prefix + I` (install), `prefix + U` (update)

### waybar (`config/waybar/`)

No custom keybindings (uses default waybar interactions).

#### Configuration
Custom configuration in `config/waybar/`:
- **config.jsonc**: Module layout and settings
  - Left: dwl/tags, custom/media
  - Center: sway/window
  - Right: MPD, idle_inhibitor, pulseaudio, network, power-profiles-daemon, cpu, memory, temperature, backlight, keyboard-state, sway/language, battery, clock, tray, custom/power
- **style.css**: Custom styling with color-coded modules
  - Transparent background with color-coded status indicators
  - Module-specific colors (e.g., battery critical animation, power profile colors)
  - Custom tag colors for dwl integration

### qutebrowser (`config/qutebrowser/config.py`)

| Key | Mode | Action | Source |
|---|---|---|---|
| `a` | normal | Enter insert mode | custom |
| `K` / `J` | normal | Next / prev tab | custom |
| `H` / `L` | normal | Back / forward | custom |
| `Q` | normal | Close tab | custom |
| `<Ctrl-n>` / `<Ctrl-p>` | command | Completion item next / prev | custom |

All other qutebrowser bindings are upstream defaults (e.g. `o` open, `d` close tab, `gg`/`G` scroll, `f` hint-follow, `yy` yank URL, `i` insert mode, `:` command mode).

### fusesoc (`config/fusesoc/fusesoc.conf`)

No custom keybindings (CLI tool).

#### Configuration
Custom configuration in `config/fusesoc/fusesoc.conf`:
- Library location: `~/code/`
- Auto-sync: disabled

### dwl (`deps/dwl/config.def.h`)

| Binding | Action | Source |
|---|---|---|
| `MOD + p` | Spawn menu (wmenu) | custom |
| `MOD + Shift + Return` | Spawn terminal (foot) | custom |
| `MOD + w` | Spawn browser (qutebrowser) | custom |
| `MOD + b` | Toggle bar | custom |
| `MOD + h` / `MOD + l` / `MOD + k` / `MOD + j` | Focus window (left/right/up/down) | custom |
| `MOD + i` / `MOD + d` | Increase/decrease master area | custom |
| `MOD + Shift + h` / `MOD + Shift + l` | Decrease/increase master factor | custom |
| `MOD + Return` | Zoom to focused window | custom |
| `MOD + Tab` | View last tag | custom |
| `MOD + Shift + c` | Kill focused client | custom |
| `MOD + t` / `MOD + f` / `MOD + m` / `MOD + u` / `MOD + o` | Set layout (tile/floating/monocle/bstack/bstackhoriz) | custom |
| `MOD + space` | Cycle layout | custom |
| `MOD + e` | Toggle fullscreen | custom |
| `MOD + 0` | View all tags | custom |
| `MOD + Shift + 0` | Tag with all tags | custom |
| `MOD + ,` / `MOD + .` | Focus monitor (left/right) | custom |
| `MOD + Shift + <` / `MOD + Shift + >` | Tag to monitor (left/right) | custom |
| `MOD + 1-9` | View tag | custom |
| `MOD + Shift + 1-9` | Tag with tag | custom |
| `MOD + Ctrl + 1-9` | Toggle view of tag | custom |
| `MOD + Ctrl + Shift + 1-9` | Toggle tag on client | custom |
| `MOD + Shift + q` | Quit dwl | custom |
| XF86MonBrightnessUp/Down | Increase/decrease backlight | custom |
| XF86AudioRaiseVolume/LowerVolume/Mute | Audio volume control | custom |
| XF86AudioMicMute | Microphone mute | custom |
| XF86Calculator | Lock and suspend | custom |
| `Ctrl + Alt + Backspace` | Quit dwl | custom |
| `Ctrl + Alt + F1-F12` | Switch VT | custom |

**Note**: MODKEY is defined as WLR_MODIFIER_LOGO (Windows/Super key)

#### Configuration
Built with patches from `deps/dwl-patches`. Desktop file installed to `/usr/local/share/wayland-sessions/`.
- **Keyboard layout**: us/ch(de) with caps lock toggle
- **Terminal**: foot
- **Menu**: wmenu-run
- **Browser**: qutebrowser
- **Layouts**: tile, floating, monocle, bstack, bstackhoriz
- **Colors**: Custom border, focus, and urgent colors

### mako, swaybg, wmenu, foot, wlock

No custom keybindings or configurations provided in this repo. These tools use their default configurations.

### ripgrep, tpm, scripts

No custom keybindings (CLI tools/utility scripts). Configuration is minimal or defaults are used.

### Neovim (`config/nvim/`)

`init.lua` loads `config.lazy` (lazy.nvim bootstrap), `config.keymaps`,
`config.options`, `config.autocmds` — see `config/nvim/lua/config/keymaps.lua`
and `config/nvim/lua/plugins/` for the full list of custom keymaps and plugin
specs.

`mapleader = " "` (space)

#### Core config (builtin, `keymaps.lua`)

| Key | Mode | Action | Source |
|---|---|---|---|
| `h` `j` `k` `l` | n | Move left/down/up/right | builtin |
| `w` `b` `e` `ge` | n | Word motions | builtin |
| `0` `^` `$` `gg` `G` `{` `}` `%` | n | Line/file/paragraph motions, matching bracket | builtin |
| `f{x}` `t{x}` `;` `,` | n | Find/till char, repeat | builtin |
| `*` `#` | n | Search word under cursor fwd/back | builtin |
| `/` `?` | n | Search fwd / back | builtin |
| `i` `a` `o` `O` `I` `A` | n | Enter insert mode variants (`o`/`O` overridden by your custom binds) | builtin |
| `v` `V` `<C-v>` | n | Visual char / line / block | builtin |
| `d` `c` `y` `p` `P` `x` | n | Delete / change / yank / paste | builtin |
| `u` `<C-r>` `.` | n | Undo / redo / repeat last change | builtin |
| `>>` `<<` `==` | n | Indent / dedent / autoindent line | builtin |
| `zz` `zt` `zb` | n | Center / top / bottom cursor line | builtin |
| `<C-f>` `<C-b>` | n | Page down / up (`<C-d>`/`<C-u>` overridden by your centered variants) | builtin |
| `<C-w>w` `<C-w>v` `<C-w>s` `<C-w>q` `=` | n | Window cycle / vsplit / split / close / equalize | builtin |
| `gt` `gT` | n | Next / prev tab | builtin |
| `:marks`, `m{a-z}` `` `{a-z}` `` | n | Set / jump to mark | builtin |
| `q{a-z}` `@a` `@@` | n | Record / play macro | builtin |
| `<C-o>` `<C-i>` | n | Jump back / forward in jumplist | builtin |
| `<C-g>` | n | Show file info | builtin |
| `<C-\><C-n>` | t | Exit terminal mode | builtin |
| `~` `gu{motion}` `gU{motion}` | n | Swap / lower / upper case | builtin |
| `r{x}` `R` `s` `S` | n | Replace char / replace mode / substitute | builtin |
| `J` / `K` | v | Move selection down/up | keymaps.lua |
| `J` | n | Join lines, keep cursor | keymaps.lua |
| `<C-d>` / `<C-u>` | n | Half-page down/up, centered | keymaps.lua |
| `n` / `N` | n | Search match next/prev, centered + unfold | keymaps.lua |
| `<leader>p` | x | Paste over selection without yanking | keymaps.lua |
| `<leader>y` / `<leader>Y` | n, v / n | Yank / yank-line to system clipboard | keymaps.lua |
| `<leader>d` | n, v | Delete to black-hole register | keymaps.lua |
| `<leader>fmt` | n | LSP format | keymaps.lua |
| `<C-k>` / `<C-j>` | n | Quickfix next / prev | keymaps.lua |
| `<leader>k` / `<leader>j` | n | Loclist next / prev | keymaps.lua |
| `[d` / `]d` | n | Prev / next diagnostic | keymaps.lua |
| `<leader>e` | n | Diagnostic float | keymaps.lua |
| `<leader>l` | n | Toggle Location List (diagnostics) | keymaps.lua |
| `<leader>q` | n | Toggle Quickfix List | keymaps.lua |
| `<leader>cd` | n | `cd` to file's directory | keymaps.lua |
| `<leader>bc` / `<leader>bd` | n | Close / force-close buffer | keymaps.lua |
| `<leader>o` / `<leader>O` | n | Blank line below / above | keymaps.lua |
| `<C-l>` / `<C-h>` | n | Widen / narrow split | keymaps.lua |
| `<C-n>` / `<C-p>` | n | Grow / shrink split vertically | keymaps.lua |
| `<` / `>` | x | Indent, keep selection | keymaps.lua |
| `o` | n (netrw) | Open entry | keymaps.lua|
#### LSP Keybinds (nvim core, `snacks.nvim`)


| Key | Mode | Action | Source |
|---|---|---|---|
| `gd` | n | LSP definitions (picker) | snacks.lua - overrides builtin local-declaration `gd` |
| `gD` | n | LSP declarations (picker) | snacks.lua |
| `gI` | n | LSP implementations (picker) | snacks.lua - overlaps builtin `gri` |
| `gy` | n | LSP type definitions (picker) | snacks.lua - overlaps builtin `grt` |
| `gai` | n | Incoming calls (call hierarchy) | snacks.lua |
| `gao` / `gaI` | n | Outgoing calls (call hierarchy) | snacks.lua|
| `<leader>ss` | n | LSP document symbols | snacks.lua |
| `<leader>sS` | n | LSP workspace symbols | snacks.lua |
| `<leader>fmt` | n | `vim.lsp.buf.format()` — format buffer | keymaps.lua |
| `[d` / `]d` | n | Prev / next diagnostic | keymaps.lua - shadows the 0.11 builtin pair |
| `<leader>e` | n | `vim.diagnostic.open_float()` — line diagnostics popup | keymaps.lua |
| `<leader>q` | n | Toggle Quickfix List | keymaps.lua |
| `<C-k>` / `<C-j>` | n | Quickfix next / prev (used to walk grep/LSP results) | keymaps.lua |
| `K` | n | Hover documentation (`vim.lsp.buf.hover`) | builtin |
| `grn` | n | Rename symbol | builtin |
| `grr` | n | List references (builtin picker/quickfix) | builtin |
| `gra` | n, v | Code actions | builtin |
| `gri` | n | Go to implementation | builtin |
| `grt` | n | Go to type definition | builtin |
| `gO` | n | Document symbol outline | builtin |
| `<C-s>` | i | Signature help | builtin |
| `<C-x><C-o>` | i | Omnifunc completion (when `omnifunc` set by lspconfig) | builtin |

- `gr` (snacks) vs `grr` (builtin) — both "references", different UIs; same for `gI`/`gri` and `gy`/`grt`.
- `gd` is fully shadowed: builtin `gd` = "goto local declaration", now unreachable.


### snacks.nvim (`plugins/snacks.lua`)

| Key | Action | Source |
|---|---|---|
| `<leader><space>` | Smart find files | custom |
| `<leader>,` / `<leader>fb` | Buffers | custom |
| `<leader>/` / `<leader>sg` | Grep | custom |
| `<leader>:` / `<leader>sc` | Command history | custom |
| `<leader>sC` | Commands | custom |
| `<leader>no` | Notification history | custom |
| `<leader>fc` | Find config file | custom |
| `<leader>ff` / `<leader>fo` | Find files | custom |
| `<leader>fg` | Git files | custom |
| `<leader>fp` | Projects | custom |
| `<leader>fr` | Recent | custom |
| `<leader>gb` | Git branches | custom |
| `<leader>gl` / `<leader>gL` / `<leader>gf` | Git log / log line / log file | custom |
| `<leader>gs` / `<leader>gS` | Status / stash | custom |
| `<leader>gd` | Diff hunks | custom |
| `<leader>gi` / `<leader>gI` | GitHub issues open / all | custom |
| `<leader>gp` / `<leader>gP` | GitHub PRs open / all | custom |
| `<leader>sb` | Buffer lines | custom |
| `<leader>sB` | Grep open buffers | custom |
| `<leader>sw` | Grep word/selection (n, x) | custom |
| `<leader>s"` / `<leader>s/` | Registers / search history | custom |
| `<leader>sa` | Autocmds | custom |
| `<leader>sd` / `<leader>sD` | Diagnostics / buffer diagnostics | custom |
| `<leader>sh` / `<leader>sH` | Help / highlights | custom |
| `<leader>si` | Icons | custom |
| `<leader>sj` / `<leader>sk` | Jumps / keymaps | custom |
| `<leader>sl` / `<leader>sq` | Loclist / quickfix | custom |
| `<leader>sm` / `<leader>sM` | Marks / man pages | custom |
| `<leader>sp` | Search plugin spec | custom |
| `<leader>sR` / `<leader>su` | Resume / undo history | custom |
| `<leader>uC` | Colorscheme picker | custom |
| `<leader>un` | Dismiss notifications | custom |
| `<leader>z` / `<leader>Z` | Zen / zoom | custom |
| `<leader>.` / `<leader>S` | Scratch / select scratch | custom |
| `<leader>cR` | Rename file | custom |
| `<leader>gB` | Git browse (n, v) | custom |
| `<leader>gg` | Lazygit | custom |
| `<leader>N` | Neovim news | custom |
| `<c-/>` / `<c-_>` | Toggle terminal | custom |
| `]]` / `[[` | Next / prev reference (n, t) | custom |
| `<cr>` `<c-v>` `<c-x>` `<Tab>` `q` etc. | Picker-internal navigation | plugin default |


### vim-floaterm (`plugins/floaterm.lua`)

| Key | Action | Source |
|---|---|---|
| `<leader>ftn` `ftk` `ftt` | New / kill / toggle | custom |
| `<leader>fh` / `<leader>fl` | Prev / next | custom |
| `<leader>fts` / `<leader>ftv` | Send line / send selection | custom |
| `<C-\><C-n>` | Exit terminal mode | Neovim builtin (not plugin) |

### vim-mundo (`plugins/vim-mundo.lua`)

| Key | Action | Source |
|---|---|---|
| `<leader>mt` | MundoToggle | custom |
| `<cr>` `o` `d` `p` `j`/`k` `q` etc. | Inside Mundo window: revert/diff/preview/navigate/quit | plugin default |

### nvim-surround (`plugins.lua`)

| Key | Action | Source |
|---|---|---|
| `ys{motion}{char}`, `yss{char}` | Add surround | plugin default |
| `ds{char}` / `cs{old}{new}` | Delete / change surround | plugin default |
| `S{char}` | v-mode surround | plugin default |

Empty `setup({})` → all defaults [8](#19-7) .

### vim-gitgutter (`plugins.lua`)

| Key | Action | Source |
|---|---|---|
| `]c` / `[c` | Next / prev hunk | plugin default |
| `<leader>hp` `hs` `hu` `hS` `hU` | Preview / stage / undo hunk / buffer | plugin default |
| `ic` / `ac` | Hunk text objects | plugin default |

### vim-vinegar (`plugins.lua`)

| Key | Action | Source |
|---|---|---|
| `-` | Open netrw at file's dir / go up | plugin default |
| `~`, `.`, `gh`, `y.` | Home / dotfiles / hidden / yank path | plugin default |

### vim-fugitive (`plugins.lua`)

| Key | Action | Source |
|---|---|---|
| `s` `u` `=` `dd` `dv` `dh` `cc` `q` (in `:G` buffer) | Stage/unstage/diff/commit/close | plugin default (buffer-local) |
| `y<C-G>` | Yank object path | plugin default |

### nerdy.nvim (`plugins.lua`)

| Key | Action | Source |
|---|---|---|
| `<leader>ni` | Icon picker | plugin default — `add_default_keybindings = true` |


### render-markdown.nvim (`plugins/render-markdown.lua`)

| Key | Action | Source |
|---|---|---|
| `<leader>bt`| Toggle markdown rendering (buffer)| custom|



## Install

Most tools are automatically bootstrapped by the bootstrap.sh script.
Run `./bootstrap.sh` to start the installation process.

Critical dependency of the bootstrap script: `curl` (`sudo apt install curl`)


### Installation Modes

The bootstrap script prompts you to choose between two installation modes:

1. **Terminal tools only** - Installs tools that require no sudo privileges:
   - neovim, ripgrep, verilator, fusesoc, neovim-remote (nvr)
   - Suitable for remote development or environments without sudo access

2. **Full wayland experience** - Includes terminal tools plus Wayland desktop components:
   - dwl, waybar, mako, swaybg, wmenu, foot, qutebrowser
   - Requires sudo for installing dwl desktop file to `/usr/local/share/wayland-sessions/`

**Flags:**
- `-t` or `--terminal`: Install terminal tools only (skip prompt)
- `-y` or `--yes`: Skip prompts (default to full wayland experience when used alone)
- Combine flags: `./bootstrap.sh -y -t` for automated terminal-only installation

### Terminal-only tools
Installation of the following tools is handled by the bootstrap script automatically.
All tools are made available via wrapper scripts in `bin/` which point to the build directories.
No system-wide installations required for terminal tools.

#### [fusesoc](https://github.com/olofk/fusesoc)
FPGA build system for managing IP cores and dependencies.
##### Installation
Fusesoc is installed into the `envs/main` virtual environment via `bootstrap.sh`.
##### Configuration
Custom configuration in `config/fusesoc/fusesoc.conf`:
- Library location: `~/code/`
- Auto-sync: disabled

#### [ripgrep](https://github.com/BurntSushi/ripgrep)
Fast text search tool (alternative to grep).
##### Installation
Binary tarball fetched and symlinked into `bin/`.
##### Configuration
Uses default ripgrep configuration. No custom config provided in this repo.

#### [wlock](https://codeberg.org/sewn/wlock)
Simple Wayland screen locker.
##### Installation
Git submodule fetched into `deps/wlock`. Built with make.
##### Configuration
Uses default wlock configuration. No custom config provided in this repo.

### #[tpm](https://github.com/tmux-plugins/tpm)
Tmux Plugin Manager for managing tmux plugins.
##### Installation
Git submodule fetched into `deps/tpm`. Plugins are installed via tmux prefix+I.
##### Configuration
See tmux section below for plugin configuration.

#### [scripts](https://github.com/ganoam/scripts)
Collection of utility scripts including shortcut-menus.
##### Installation
Git submodule fetched into `deps/scripts`. Scripts added to PATH.
##### Configuration
Utility scripts for wmenu integration. No additional configuration required.

#### [neovim](https://neovim.io)
Extensible Vim-based text editor.
##### Installation
Binary tarball fetched and added to PATH.
##### Configuration
See Neovim section below for detailed keymaps and plugin configuration.

#### [tmux](https://github.com/tmux/tmux)
Terminal multiplexer.
##### Installation
Static binary tarball fetched from tmux-builds and added to PATH.
##### Configuration
Custom configuration in `config/tmux/tmux.conf` and plugins managed via tpm.

#### [verilator](https://github.com/ganoam/verilator)
HDL simulator (Verilog to SystemVerilog).
##### Installation
Git submodule fetched into `deps/verilator`. Built with autoconf/make.
##### Configuration
`VERILATOR_ROOT` environment variable set to `$ROOT/deps/verilator`. `bin/` prepended to PATH.


### Wayland Tools

The following Wayland tools (dwl, waybar, mako, swaybg, wmenu, foot) use meson for building.
If building from source with the full wayland experience, ensure `meson` and `ninja` are installed:
```
sudo apt install meson ninja-build
```

Installation of the following tools is handled by the bootstrap script automatically, but they require system dependencies to be put into place.
If you want to take manual control, here's how.
These tools are not needed for terminal configuration only.


#### [dwl](https://github.com/ganoam/dwl)
Suckless minimalist wayland window manager.
Intro/Instructions: [dwl-deep-dive](https://codeberg.org/julmajustus/dwl-deep-dive)
##### Build from source
Bootstrap installation depends on the following system tools (see `dwl-deps.yml`):
```
sudo apt install libwlroots-0.19-dev
```
##### Configuration
Built with patches from `deps/dwl-patches`. Desktop file installed to `/usr/local/share/wayland-sessions/`.

#### [waybar](https://github.com/Alexays/Waybar)
Lightweight dwl statusbar.
##### Build from source: [System Dependencies](https://github.com/Alexays/Waybar#building-from-source)
Bootstrap installation depends on the following system tools (see `waybar-deps.yml`):

**Runtime dependencies**:
```
gtkmm3       jsoncpp      libsigc++    fmt          wayland
chrono-date  spdlog       xkbregistry  libgtk-3-dev upower

sudo apt install
    libpulse-dev libnl-3-dev  libappindicator3-dev  libdbusmenu-gtk3-dev \
    libmpdclient-dev libsndio-dev libevdev-dev
```

**build dependencies**:
```
sudo apt install cmake meson scdoc wayland-protocol
```
**Install Dependencies**:
```
sudo apt install \
  clang-tidy gobject-introspection libdbusmenu-gtk3-dev libevdev-dev \
  libfmt-dev libgirepository1.0-dev libgtk-3-dev libgtkmm-3.0-dev \
  libinput-dev libjsoncpp-dev libmpdclient-dev libnl-3-dev libnl-genl-3-dev \
  libpulse-dev libsigc++-2.0-dev libspdlog-dev libwayland-dev scdoc upower \
  libxkbregistry-dev libiniparser-dev libfftw3-dev
```

and let `bootstrap.sh` build it.

##### Or use your package manager:
```
sudo apt install waybar
```

##### Configuration
Custom configuration in `config/waybar/`:
- `config.jsonc`: Module layout (dwl/tags, media, MPD, idle inhibitor, pulseaudio, network, power profiles, CPU, memory, temperature, backlight, keyboard state, language, battery, clock, tray, power menu)
- `style.css`: Custom styling with color-coded modules (transparent background, color-coded status indicators)

##### Modules
Left: dwl/tags, custom/media
Center: sway/window
Right: MPD, idle_inhibitor, pulseaudio, network, power-profiles-daemon, cpu, memory, temperature, backlight, keyboard-state, sway/language, battery, clock, tray, custom/power

#### [mako](https://github.com/emersion/mako)
Wayland notification daemon.
##### Build from source: [System Dependencies](https://github.com/emersion/mako#building)
Bootstrap installation depends on the following system tools:
```
sudo apt install libpango1.0-dev libwayland-dev
```
##### Configuration
Uses default mako configuration. No custom config provided in this repo.

#### [swaybg](https://github.com/swaywm/swaybg)
Wallpaper utility for Wayland compositors.
##### Build from source: [System Dependencies](https://github.com/swaywm/swaybg#building)
Bootstrap installation depends on the following system tools:
```
sudo apt install libwayland-dev libcairo2-dev libpango1.0-dev
```
##### Configuration
Uses default swaybg configuration. No custom config provided in this repo.

#### [wmenu](https://codeberg.org/adnano/wmenu)
Wayland menu launcher.
##### Build from source: [System Dependencies](https://codeberg.org/adnano/wmenu)
Bootstrap installation depends on the following system tools:
```
sudo apt install libwayland-dev libcairo2-dev libpango1.0-dev libxkbcommon-dev
```
##### Configuration
Uses default wmenu configuration. No custom config provided in this repo.

#### [foot](https://codeberg.org/foot/foot)
Fast, lightweight Wayland terminal emulator.
##### Build from source: [System Dependencies](https://codeberg.org/foot/foot#building)
Bootstrap installation depends on the following system tools:
```
sudo apt install libwayland-dev libxkbcommon-dev libfontconfig1-dev libpixman-1-dev
```

##### Or use your package manager:
```
sudo apt install foot
```
##### Configuration
Uses default foot configuration. No custom config provided in this repo.

#### [qutebrowser](https://github.com/qutebrowser/qutebrowser)
keyboard-driven browser.
##### Build from source: [System Dependencies](https://github.com/qutebrowser/qutebrowser#building-from-source)
Bootstrap installation depends on the following system tools:
```
sudo apt install libpython3-dev
```

##### Or use your package manager:
```
sudo apt install qutebrowser
```

##### Configuration
Custom configuration in `config/qutebrowser/config.py`:
- `<Ctrl-n>` / `<Ctrl-p>`: Next/prev completion item in command mode
- `a`: Enter insert mode
- `K` / `J`: Next/prev tab
- `H` / `L`: Back/forward
- `Q`: Close tab


### Manual Changes for Persistent TMUX sessions across SSH reconnects

Need persistent `$SSH_AUTH_SOCK` and xauth cookie.
They would usually change on reconnect.

Add to `~/.ssh/rc` on each server:

```bash
#!/bin/bash
if test "$SSH_AUTH_SOCK" ; then
  ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
fi
if read proto cookie && [ -n "$DISPLAY" ]; then
  echo "add unix:${DISPLAY#localhost:} $proto $cookie" | xauth -q
fi
```

Learn more:

**Stable `SSH_AUTH_SOCK` symlink for tmux**

- https://werat.dev/blog/happy-ssh-agent-forwarding/ and https://gist.github.com/martijnvermaat/8070533

> Use `ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock` pattern so that tmux's fixed `SSH_AUTH_SOCK` resUolves to the current socket after reconnect.


**`~/.ssh/rc` semantics — cookies via stdin, runs before the shell**

- The `sshd(8)` man page, in the `SSHRC` section (https://man.openbsd.org/sshd.8#SSHRC).

  > "If X11 forwarding is in use, it will receive the 'proto cookie' pair in its standard input (and DISPLAY in its environment). The script must call `xauth(1)` because sshd will not run xauth automatically to add X11 cookies."

**`unix:` display name rewrite**

- `xauth(1)` / `Xsecurity(7)` man pages document the `unix:N` vs `hostname:N` display-name distinction — the X server matches cookies by exact display name, so a cookie stored as `localhost:10.0` won't be found when clients connect via `unix:10.0`. (https://man.openbsd.org/xauth.1, https://www.x.org/releases/X11R7.7/doc/man/man7/Xsecurity.7.xhtml)

One caveat: the exact `${DISPLAY#localhost:}` rewrite is convention rather than mandated protocol — whether `unix:` is needed depends on how X clients inside tmux resolve `DISPLAY`. The OpenBSD sshd man page example does `xauth -q -i merge -` style handling differently across versions, so verify against your sshd version's SSHRC section.



