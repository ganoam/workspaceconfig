# workspaceconfig

All my favourite tools, ready to go.

Reproducible workstation bootstrap: shell environment, Neovim, tmux,
an EDA toolchain (verilator/fusesoc/gtkwave) and a Wayland desktop
(dwl/waybar/wlock), verified on a clean Ubuntu 26.04 install.

```systemverilog
assign target_audience = nvim_nerds & ic_engineers;
```

## Layout

```
bootstrap.sh        # install: standalone tools or full desktop environment
checkhealth.sh      # verify everything is in place
config/             # nvim, tmux, waybar, qutebrowser, fusesoc configs (XDG_CONFIG_HOME)
sourceme/           # sourceme.sh: env vars, PATH, aliases
deps/               # fetched dependencies (gitlinks; contents gitignored)
envs/               # generated: venvs + tool shims (gitignored)
tricks/             # assorted notes and gotchas (bash, git, nvim, bwrap, ...)
notes/              # running todo and current working context
tarballs.yml        # binary tarball manifest (nvim, ripgrep, tmux)
*-deps.yml          # per-tool apt package manifests
```

## Provided tools


### Standalone tools

All standalone tools are installed by `bootstrap.sh` automatically, fetched as
binary tarballs, git submodules, or pip packages into `envs/main`.
Nothing installed system-wide, but build/runtime deps are still
apt-installed where a `<tool>-deps.yml` exists (sudo prompt).
`envs/bin/` contains wrapper scripts generated at install time, pointing into `deps/`.

| Tool | Description | Config | System deps |
|---|---|---|---|
| [neovim](https://neovim.io) | text editor | `config/nvim/` (see keybindings below) | none (tarball) |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | fast grep; editor plugins | default | none (tarball) |
| [tmux](https://github.com/tmux/tmux) | terminal multiplexer | `config/tmux/tmux.conf` + tpm plugins + `config/tmux-powerline/` | none (static tarball) |
| [verilator](https://github.com/ganoam/verilator) | HDL simulator | `VERILATOR_ROOT` env var | see `verilator-deps.yml` |
| [fusesoc](https://github.com/olofk/fusesoc) | FPGA build system | `config/fusesoc/fusesoc.conf` | none (pip → `envs/main`) |
| [edalize](https://github.com/olofk/edalize) | EDA tool abstraction library | default | none (pip → `envs/main`) |
| [nvr](https://github.com/mhinz/neovim-remote) | remote-control running nvim (tmux integration) | n/a | none (pip → `envs/main`) |
| [tpm](https://github.com/tmux-plugins/tpm) | tmux plugin manager | plugins via tmux `prefix + I` | none (submodule) |
| [scripts](https://github.com/ganoam/scripts) | utility scripts incl. `shortcut-menus` | n/a | none (submodule → PATH) |
| [gtkwave](https://github.com/gtkwave/gtkwave) | waveform viewer (VCD/FST etc.); v4 dev branch | default | `gtkwave-deps.yml`; GUI needs a display |
| [inkscape](https://gitlab.com/inkscape/inkscape) | vector graphics editor | `config/inkscape/` | official AppImage (gitlab release); needs FUSE |
| [qutebrowser](https://github.com/qutebrowser/qutebrowser) | keyboard-driven browser | `config/qutebrowser/config.py` (command-mode/tab keymaps) | `qutebrowser-deps.yml`; venv in `envs/qb` |

### Full Desktop Environment

Only installed in full mode.
Fetched as submodules and built with meson/ninja or make.
Each tool's system dependencies are listed in its `<tool>-deps.yml` and installed by `bootstrap.sh` (after confirmation, or with `-y`).

| Tool | Description | Config | System deps |
|---|---|---|---|
| [dwl](https://github.com/ganoam/dwl) + [dwl-patches](https://codeberg.org/dwl/dwl-patches) | wayland compositor | patched fork (`dev` branch); `deps/dwl-patches` kept for reference | `dwl-deps.yml`; session file → `/usr/local/share/wayland-sessions/` (sudo) |
| [waybar](https://github.com/Alexays/Waybar) | statusbar | `config/waybar/` (layout + styling) | `waybar-deps.yml` |
| [mako](https://github.com/emersion/mako) | notification daemon | default | `mako-deps.yml` |
| [swaybg](https://github.com/swaywm/swaybg) | wallpaper | default | `swaybg-deps.yml` |
| [wmenu](https://codeberg.org/adnano/wmenu) | menu launcher | default | `wmenu-deps.yml` |
| [foot](https://codeberg.org/foot/foot) | wayland terminal emulator | default | `foot-deps.yml` |
| [wlock](https://codeberg.org/sewn/wlock) | screen locker | default | `wlock-deps.yml`; setuid install → `/usr/local/bin/` (sudo) |

If you'd rather not build from source, most wayland tools are also in apt (`waybar`, `foot`, `qutebrowser`, …), but `bootstrap.sh` only uses the submodule builds.

### Planned tools

Not integrated yet. Together these cover an open-source digital
backend flow: synthesis, place-and-route, and static timing
analysis with no vendor tools.

| Tool | Role | Planned install |
|---|---|---|
| [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build) | prebuilt FPGA toolchain (yosys, nextpnr, ...) | tarball via `tarballs.yml` + `sourceme` env |
| [sv2v](https://github.com/zachjs/sv2v) | SystemVerilog -> Verilog-2005, for Verilog-only tools | standalone: submodule + stack build |
| [OpenSTA](https://github.com/The-OpenROAD-Project/OpenSTA) | static timing analysis (liberty/SDC/SDF) | standalone: submodule + cmake build |
| [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) | RTL-to-GDSII implementation flow | heavyweight opt-in: submodule + OpenROAD binaries or docker |

Reference flows on the same toolchain, to be reviewed:
[OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
documents RTL -> GDSII end to end (yosys synthesis, OpenROAD PnR,
OpenSTA signoff); [LibreLane](https://github.com/librelane/librelane)
(OpenLane's successor) packages the same components turnkey.

No tool above supplies a PDK; candidates for the foundry side:

| PDK | Status | How it lands |
|---|---|---|
| Nangate45, ASAP7 | academic test platforms; shipped inside OpenROAD-flow-scripts | nothing to install; flow bring-up |
| [sky130](https://github.com/RTimothyEdwards/open_pdks) | real 130nm, manufacturable (long MPW shuttle history) | `ciel` pip PDK manager, or open_pdks source build |
| [gf180mcu](https://github.com/google/gf180mcu-pdk) | real 180nm, manufacturable | same: `ciel` / open_pdks |
| [IHP SG13G2](https://github.com/IHP-GmbH/IHP-Open-PDK) | real 130nm BiCMOS; early access, not yet production-qualified | repo checkout pointed at by the flow config |

How the pieces relate: known overlaps and alternatives. These are
open questions, not decisions; each needs careful study when the
tools actually get integrated, nothing here is settled.

| Tools | Relationship |
|---|---|
| OpenSTA / OpenROAD-flow-scripts | OpenSTA is the timing engine inside OpenROAD; ORFS uses it at every signoff stage. A standalone build only adds a lightweight `sta` binary for timing checks without the ORFS install. |
| oss-cad-suite / verilator, gtkwave | The suite bundles both, which are already integrated separately (`deps/`). PATH precedence between `envs/bin` shims and the suite's `bin/` needs a decision at install time. |
| oss-cad-suite / OpenROAD-flow-scripts | Both bundle yosys: the suite's serves the FPGA path, ORFS's the ASIC synth step. Two yosys installs coexist; same role name, different flows. |
| oss-cad-suite / OpenROAD-flow-scripts | Complementary targets, not redundant: FPGA synth/PnR/bitstream vs. ASIC RTL-to-GDSII. |
| sv2v / yosys-slang (sv-elab) | sv2v exists for yosys's limited native SV parsing. If the slang frontend is used instead (newer suites can ship it), sv2v is unnecessary. |


## Activate

Add to `~/.bashrc`:

```
pushd path/to/workspaceconfig
. sourceme/sourceme.sh
popd
```

## Install

The workspace config is usually cloned into `~/workspaceconfig`.
Other paths should work but are not tested.
Most tools are automatically bootstrapped by the bootstrap.sh script.

```bash
cd path/to/workspaceconfig
. sourceme/sourceme.sh
./bootstrap.sh
./checkhealth.sh   # verify everything is in place
```
Targeted at **Ubuntu 26.04** only. Other distros/releases are welcome to try; mileage may vary.
If it does not work, the required system packages in the `*-deps.yml` files are likely named differently on your distro.
Critical dependency of the bootstrap script: `curl` (`sudo apt install curl`)
You may need to re-source the `./sourceme/sourceme.sh` script to make your changes immediately apply (standalone tools only)
For the desktop environment to take effect you'll need to logout and login.

**What to expect:** The bootstrap downloads and builds a lot.
The verilator build alone can take a while.
Everything it installs stays inside this directory (deps/, envs/, config/share/).
The only things committed to your system are apt packages, which are only installed after a sudo.
In full mode, dwl's session file is also copied to `/usr/local/share/wayland-sessions/`
and wlock is installed setuid to `/usr/local/bin/` (it needs root to verify your password).

**Starting dwl from the login screen:** After logging out (or rebooting), click your
username on the Ubuntu login screen. Before typing your password, click the gear icon
in the bottom-right corner: it lists the installed sessions. Select `dwl`, then log in
as usual. To go back to the regular desktop, log out and pick `Ubuntu` from the same
gear menu.

### DWL Survival Notes

dwl boots to a wallpaper and a status bar. That's not broken, it's the whole desktop.
It's a keyboard-driven tiling compositor; `MOD` is the Super/Windows key.

- `MOD + Shift + Return`: open a terminal (foot)
- `MOD + p`: app launcher; runs anything on your PATH in addition to special menu scripts (`wifi`, `bluetooth`, ...)
- Volume, mic mute and brightness should work via the usual media keys
- `MOD + Shift + q`: quit dwl, back to the login screen (memorize this one)

The full keybinding table is under [dwl](#dwl-depsdwlconfigdefh) further down.
Deleting the `workspaceconfig` directory removes everything the bootstrap added inside it.
Left behind on the system: the installed apt packages and, in full mode,
`/usr/local/share/wayland-sessions/dwl.desktop` and `/usr/local/bin/wlock`; remove those manually.


### External required tools

**Bootstrap dependencies** (must exist on the system):
- `bash`, `git`, `curl` - Fundamental system tools
- `python3` and `python3-venv` - Required to create the virtual environments

**EDA tools** (optional - for FPGA development, warn-only if missing):
- `vivado`, `verible-verilog-format`, Libero (`LIBERO_PATH`/`LIBERO_LIC_PATH`), `xauth`
- License env vars expected: `LM_LICENSE_FILE`, `XILINXD_LICENSE_FILE`


### Installation Modes

The bootstrap script prompts you to choose between two installation modes:

1. **Standalone tools:** everything needed for the editor/shell workflow.
Nothing installed system-wide; some tools still need apt build deps (sudo).

2. **Full Desktop environment:** standalone tools plus my personal fork of the DWL desktop environment (compositor, bar, launcher, terminal, notifications).
Requires sudo for build/runtime dependencies and the dwl session file.

See the tables under [Provided tools](#provided-tools) above for what's included in each mode.

**Flags:**
- `-t` or `--tools`: Install standalone tools only (skip prompts for DE tools)
- `-f` or `--full`: Install full desktop environment
- `-y` or `--yes`: Skip all prompts (defaults to standalone mode when used alone)
- Combine flags: `./bootstrap.sh -y -t` for automated standalone installation
    - You will still be asked for sudo privileges when needed.


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


**`~/.ssh/rc` semantics: cookies via stdin, runs before the shell**

- The `sshd(8)` man page, in the `SSHRC` section (https://man.openbsd.org/sshd.8#SSHRC).

  > "If X11 forwarding is in use, it will receive the 'proto cookie' pair in its standard input (and DISPLAY in its environment). The script must call `xauth(1)` because sshd will not run xauth automatically to add X11 cookies."

**`unix:` display name rewrite**

- `xauth(1)` / `Xsecurity(7)` man pages document the `unix:N` vs `hostname:N` display-name distinction: the X server matches cookies by exact display name, so a cookie stored as `localhost:10.0` won't be found when clients connect via `unix:10.0`. (https://man.openbsd.org/xauth.1, https://www.x.org/releases/X11R7.7/doc/man/man7/Xsecurity.7.xhtml)

One caveat: the exact `${DISPLAY#localhost:}` rewrite is convention rather than mandated protocol; whether `unix:` is needed depends on how X clients inside tmux resolve `DISPLAY`. The OpenBSD sshd man page example does `xauth -q -i merge -` style handling differently across versions, so verify against your sshd version's SSHRC section.

## Environment variables set by `sourceme.sh`

- `VERILATOR_ROOT=$ROOT/deps/verilator`
- `TOOLS_PATH` (default `~/tools`), `GOPATH` (default `~/go`),
  `CARGOPATH` (default `~/.cargo`), `USRBIN` (default `/usr/bin`)
  (GOPATH/CARGOPATH are for general Go/Rust development, not required by workspace tools)
- `CONFIGROOT=$ROOT/config`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`,
  `NVIMCONFIG`, `TMUX_HOME`
- `EDITOR=nvim`, `menu=wmenu`, `WORKSPACE_SET=1`
- `HISTSIZE`/`HISTFILESIZE=10000000`, shared history via `PROMPT_COMMAND`
- PATH prepends: `$VERILATOR_ROOT/bin` (only when built),
  `$CARGOPATH/bin`, `$GOPATH/bin`, `$ROOT/envs/bin`, `$ROOT/bin`,
  `$ROOT/deps/scripts/shortcut-menus`, `$ROOT/deps/scripts/bin`
- `envs/bin/` holds shims generated by `bootstrap.sh`

## Aliases

| Alias | Expansion |
|---|---|
| `vim`, `vi`, `nvim` | `nvim` |
| `vimdiff` | `nvim -d` |
| `h` / `v` / `t` | `nvr -o` / `nvr -O` / `nvr --remote-tab` |
| `less` | `less -m -N -g -i -J --line-numbers --underline-special` |
| `more` | `less` |
| `cdr` | `cd` to the root of the current git repository (no-op outside a repo) |
| `tmux` | `tmux -f $CONFIGROOT/tmux/tmux.conf` |
| `vvfi` | `verible-verilog-format --inplace` |
| `vvmts` | `vivado -mode tcl -source ` |
| `vvmbs` | `vivado -mode batch -source ` |
| `libefire` / `libedone` / `libelic` | Libero license daemon start/stop/restart (only if `LIBERO_PATH`/`LIBERO_LIC_PATH` set) |

Bash line editing is set to vi mode (`set -o vi`).

## Custom keybindings

### tmux (`config/tmux/tmux.conf`)

<!-- keymaps:tmux:begin -->
| Binding | Action |
|---|---|
| `C-b` | unbound |
| `C-a` | prefix key |
| `prefix C-a` | `last-window` |
| `prefix l` (repeatable) | `swap-window -t +` |
| `prefix h` (repeatable) | `swap-window -t -` |
<!-- keymaps:tmux:end -->

Status line keys are vi-style; plugins: tpm, tmux-sensible,
`tmux-plugins/tmux-resurrect` (nvim/vim session strategy, pane contents captured),
tmux-powerline. Default terminal: `tmux-256color`.
`SSH_AUTH_SOCK` is forced to `~/.ssh/ssh_auth_sock` (see `~/.ssh/rc` above).

#### Configuration Details
- **Terminal**: `tmux-256color`
- **Shell**: Non-login shell for proper environment
- **Status keys**: vi-style
- **Aggressive resize**: enabled
- **Window rename format**: Shows pane current path

#### Plugins (via tpm)
- `tmux-plugins/tpm`: Plugin manager
- `tmux-plugins/tmux-sensible`: Sensible defaults
- `tmux-plugins/tmux-resurrect`: Session restoration with nvim/vim session strategy and pane contents capture
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

No custom keybindings or configurations provided in this repo.
These tools use their default configurations.

### ripgrep, tpm, scripts, edalize

No custom keybindings (CLI tools/utility scripts).
Configuration is minimal or defaults are used.

### Neovim (`config/nvim/`)

`init.lua` loads `config.lazy` (lazy.nvim bootstrap), `config.keymaps`,
`config.options`, `config.autocmds`; see `config/nvim/lua/config/keymaps.lua`
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

Custom binds (`keymaps.lua`, generated by `update-docs.sh`):

<!-- keymaps:keymaps:begin -->
| Key | Mode | Action |
|---|---|---|
| `<leader>O` | n | Blank line above |
| `<leader>Y` | n | Yank-line to system clipboard |
| `<leader>bc` | n | Close buffer |
| `<leader>bd` | n | Force-close buffer |
| `<leader>cd` | n | cd to file's directory |
| `<leader>d` | n | Delete to black-hole register |
| `<leader>j` | n | Loclist prev |
| `<leader>k` | n | Loclist next |
| `<leader>o` | n | Blank line below |
| `<leader>q` | n | Toggle Quickfix List |
| `<leader>y` | n | Yank to system clipboard |
| `<C-D>` | n | Half-page down, centered |
| `<C-H>` | n | Narrow split |
| `<C-J>` | n | Quickfix prev |
| `<C-K>` | n | Quickfix next |
| `<C-L>` | n | Widen split |
| `<C-N>` | n | Grow split vertically |
| `<C-P>` | n | Shrink split vertically |
| `<C-U>` | n | Half-page up, centered |
| `J` | n | Join lines, keep cursor |
| `N` | n | Search match prev, centered + unfold |
| `n` | n | Search match next, centered + unfold |
| `<leader>d` | v | Delete to black-hole register |
| `<leader>p` | v | Paste over selection without yanking |
| `<leader>y` | v | Yank to system clipboard |
| `<lt>` | v | Outdent, keep selection |
| `>` | v | Indent, keep selection |
| `J` | v | Move selection down |
| `K` | v | Move selection up |
| `<leader>d` | x | Delete to black-hole register |
| `<leader>p` | x | Paste over selection without yanking |
| `<leader>y` | x | Yank to system clipboard |
| `<lt>` | x | Outdent, keep selection |
| `>` | x | Indent, keep selection |
| `J` | x | Move selection down |
| `K` | x | Move selection up |
<!-- keymaps:keymaps:end -->

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
| `K` | n | Hover documentation (`vim.lsp.buf.hover`) | builtin |
| `grn` | n | Rename symbol | builtin |
| `grr` | n | List references (builtin picker/quickfix) | builtin |
| `gra` | n, v | Code actions | builtin |
| `gri` | n | Go to implementation | builtin |
| `grt` | n | Go to type definition | builtin |
| `gO` | n | Document symbol outline | builtin |
| `<C-s>` | i | Signature help | builtin |
| `<C-x><C-o>` | i | Omnifunc completion (when `omnifunc` set by lspconfig) | builtin |

Custom LSP binds (`keymaps.lua`, generated by `update-docs.sh`):

<!-- keymaps:lsp:begin -->
| Key | Mode | Action |
|---|---|---|
| `<leader>e` | n | Diagnostic float |
| `<leader>fmt` | n | LSP format |
| `<leader>l` | n | Toggle Location List (diagnostics) |
| `[d` | n | Prev diagnostic |
| `]d` | n | Next diagnostic |
<!-- keymaps:lsp:end -->

- `gr` (snacks) vs `grr` (builtin): both "references", different UIs; same for `gI`/`gri` and `gy`/`grt`.
- `gd` is fully shadowed: builtin `gd` = "goto local declaration", now unreachable.


### snacks.nvim (`plugins/snacks.lua`)

<!-- keymaps:snacks:begin -->
| Key | Mode | Action |
|---|---|---|
| `<leader><Space>` | n | Smart Find Files |
| `<leader>,` | n | Buffers |
| `<leader>.` | n | Toggle Scratch Buffer |
| `<leader>/` | n | Grep |
| `<leader>:` | n | Command History |
| `<leader>N` | n | Neovim News |
| `<leader>S` | n | Select Scratch Buffer |
| `<leader>Z` | n | Toggle Zoom |
| `<leader>cR` | n | Rename File |
| `<leader>fT` | n | Terminal Buffers |
| `<leader>fb` | n | Buffers |
| `<leader>fc` | n | Find Config File |
| `<leader>ff` | n | Find Files |
| `<leader>fg` | n | Find Git Files |
| `<leader>fo` | n | Find Files |
| `<leader>fp` | n | Projects |
| `<leader>fr` | n | Recent |
| `<leader>gB` | n | Git Browse |
| `<leader>gI` | n | GitHub Issues (all) |
| `<leader>gL` | n | Git Log Line |
| `<leader>gP` | n | GitHub Pull Requests (all) |
| `<leader>gS` | n | Git Stash |
| `<leader>gb` | n | Git Branches |
| `<leader>gd` | n | Git Diff (Hunks) |
| `<leader>gf` | n | Git Log File |
| `<leader>gg` | n | Lazygit |
| `<leader>gi` | n | GitHub Issues (open) |
| `<leader>gl` | n | Git Log |
| `<leader>gp` | n | GitHub Pull Requests (open) |
| `<leader>gs` | n | Git Status |
| `<leader>no` | n | Notification History |
| `<leader>s"` | n | Registers |
| `<leader>s/` | n | Search History |
| `<leader>sB` | n | Grep Open Buffers |
| `<leader>sC` | n | Commands |
| `<leader>sD` | n | Buffer Diagnostics |
| `<leader>sH` | n | Highlights |
| `<leader>sM` | n | Man Pages |
| `<leader>sR` | n | Resume |
| `<leader>sS` | n | LSP Workspace Symbols |
| `<leader>sa` | n | Autocmds |
| `<leader>sb` | n | Buffer Lines |
| `<leader>sc` | n | Command History |
| `<leader>sd` | n | Diagnostics |
| `<leader>sg` | n | Grep |
| `<leader>sh` | n | Help Pages |
| `<leader>si` | n | Icons |
| `<leader>sj` | n | Jumps |
| `<leader>sk` | n | Keymaps |
| `<leader>sl` | n | Location List |
| `<leader>sm` | n | Marks |
| `<leader>sp` | n | Search for Plugin Spec |
| `<leader>sq` | n | Quickfix List |
| `<leader>ss` | n | LSP Symbols |
| `<leader>su` | n | Undo History |
| `<leader>sw` | n | Visual selection or word |
| `<leader>uC` | n | Colorschemes |
| `<leader>un` | n | Dismiss All Notifications |
| `<leader>z` | n | Toggle Zen Mode |
| `<C-/>` | n | Toggle Terminal |
| `[[` | n | Prev Reference |
| `]]` | n | Next Reference |
| `gD` | n | Goto Declaration |
| `gI` | n | Goto Implementation |
| `gai` | n | C[a]lls Incoming |
| `gao` | n | C[a]lls Outgoing |
| `gd` | n | Goto Definition |
| `gy` | n | Goto T[y]pe Definition |
| `[[` | t | Prev Reference |
| `]]` | t | Next Reference |
| `<leader>gB` | v | Git Browse |
| `<leader>sw` | v | Visual selection or word |
| `<leader>gB` | x | Git Browse |
| `<leader>sw` | x | Visual selection or word |
<!-- keymaps:snacks:end -->

`<c-/>` is mode-sensitive: in a terminal buffer the first press escapes to
normal mode, the second press (normal mode) toggles the terminal closed.


### vim-floaterm (`plugins/floaterm.lua`)

<!-- keymaps:vim-floaterm:begin -->
| Key | Mode | Action |
|---|---|---|
| `<leader>fh` | n | Prev terminal |
| `<leader>fl` | n | Next terminal |
| `<leader>ftk` | n | Kill terminal |
| `<leader>ftn` | n | New terminal |
| `<leader>fts` | n | Send line |
| `<leader>ftt` | n | Toggle terminal |
| `<leader>ftv` | n | Send selection |
<!-- keymaps:vim-floaterm:end -->

Plus the Neovim builtin `<C-\><C-n>`: exit terminal mode (not plugin).

### vim-mundo (`plugins/vim-mundo.lua`)

<!-- keymaps:vim-mundo:begin -->
| Key | Mode | Action |
|---|---|---|
| `<leader>mt` | n | Mundo Toggle |
<!-- keymaps:vim-mundo:end -->

Inside the Mundo window (buffer-local plugin defaults): `<cr>` `o` `d` `p`
`j`/`k` `q`: revert/diff/preview/navigate/quit.

### nvim-surround (`plugins.lua`)

<!-- keymaps:nvim-surround:begin -->
| Key | Mode | Action |
|---|---|---|
| `<C-G>S` | i | Add a surrounding pair around the cursor, on new lines (insert mode) |
| `<C-G>s` | i | Add a surrounding pair around the cursor (insert mode) |
| `cS` | n | Change a surrounding pair, putting replacements on new lines |
| `cs` | n | Change a surrounding pair |
| `ds` | n | Delete a surrounding pair |
| `yS` | n | Add a surrounding pair around a motion, on new lines (normal mode) |
| `ySS` | n | Add a surrounding pair around the current line, on new lines (normal mode) |
| `ys` | n | Add a surrounding pair around a motion (normal mode) |
| `yss` | n | Add a surrounding pair around the current line (normal mode) |
| `S` | v | Add a surrounding pair around a visual selection |
| `gS` | v | Add a surrounding pair around a visual selection, on new lines |
| `S` | x | Add a surrounding pair around a visual selection |
| `gS` | x | Add a surrounding pair around a visual selection, on new lines |
<!-- keymaps:nvim-surround:end -->

Empty `setup({})` → all defaults [8](#19-7) .

### vim-gitgutter (`plugins.lua`)

<!-- keymaps:vim-gitgutter:begin -->
| Key | Action | Source |
|---|---|---|
| `]c` / `[c` | Next / prev hunk | plugin default |
| `<leader>hp` `hs` `hu` `hS` `hU` | Preview / stage / undo hunk / buffer | plugin default |
| `ic` / `ac` | Hunk text objects | plugin default |
<!-- keymaps:vim-gitgutter:end -->

### vim-vinegar (`plugins.lua`)

In netrw buffers (buffer-local plugin defaults): `-` up a dir, `~` home,
`.` prepend filename to cmdline, `gh` toggle hidden, `y.` yank path.

<!-- keymaps:vim-vinegar:begin -->
| Key | Mode | Action |
|---|---|---|
| `-` | n | Open netrw at file's dir / go up |
<!-- keymaps:vim-vinegar:end -->

### vim-fugitive (`plugins.lua`)

In `:G` buffers (buffer-local plugin defaults): `s` `u` `=` `dd` `dv` `dh`
`cc` `q`: stage / unstage / inline diff / diff splits / commit / close.

<!-- keymaps:vim-fugitive:begin -->
| Key | Mode | Action |
|---|---|---|
| `y<C-G>` | n | Yank object path |
<!-- keymaps:vim-fugitive:end -->

### nerdy.nvim (`plugins.lua`)

<!-- keymaps:nerdy.nvim:begin -->
| Key | Mode | Action |
|---|---|---|
| `<leader>iN` | n | Recent nerd icons |
| `<leader>in` | n | Browse nerd icons |
<!-- keymaps:nerdy.nvim:end -->

### nvim-lint (`plugins/nvim-lint.lua`)

<!-- keymaps:nvim-lint:begin -->
| Key | Mode | Action |
|---|---|---|
| `<leader>le` | n | fusesoc lint: load errors into quickfix |
| `<leader>lw` | n | fusesoc lint: load warnings into quickfix |
<!-- keymaps:nvim-lint:end -->

Lint runs automatically on `BufWritePost` for `verilog`/`systemverilog`:
`fusesoc run --target=lint` on the core named by `vim.g.fusesoc_target`
(set per project in `.nvim.lua`). Results land as buffer diagnostics;
the keys above refill quickfix from the run's `.sarif`, project-wide:
errors or warnings respectively.


### render-markdown.nvim (`plugins/render-markdown.lua`)

<!-- keymaps:render-markdown.nvim:begin -->
| Key | Mode | Action |
|---|---|---|
| `<leader>bt` | n | Toggle markdown rendering (buffer) |
<!-- keymaps:render-markdown.nvim:end -->


## Known issues


## Random Workflow Tipps


### Systemverilog LSP
Nvim comes with the **LazyVerilog** LSP Plugin (which bypasses mason).
To function properly, it needs a file list of everything involved in the project you're working on.
You can autogenerate such a file list like so:

1. List the top level name(s) of the fusesoc core you are working on
```
# toplevels.list
ganoam:util:stream_reg_tb:0
```

2. Run
```
gen_flist.py --target=sim toplevels.list > vcode.f
```


