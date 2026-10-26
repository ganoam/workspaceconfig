# workspaceconfig

Modular development workspace configuration: shell environment, Neovim, tmux,
Wayland desktop (dwl/waybar/wlock), qutebrowser, and a pinned EDA toolchain.

## Install

```
cd path/to/workspaceconfig/
./install.sh
```

`install.sh` performs:
- `apt install python3-pip` + `pip3 install neovim-remote` (provides `nvr`)
- `apt install golang` + `go install github.com/daedaleanai/dbt@latest`
- `dbt sync` — fetches all pinned dependencies from `MODULE` into `DEPS/`
- creates `bin/` and symlinks `DEPS/ripgrep/rg` → `bin/rg`

See `install.sh` for manual steps (xpra, tmux builds).

### waybar
#### [System Dependencies](https://github.com/Alexays/Waybar#building-from-source)
Bootstrap installation depends on the following system tools:

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

## Activate

Add to `~/.bashrc`:

```
pushd path/to/workspaceconfig
. sourceme/sourceme.sh
popd
```

### Persistent TMUX sessions across SSH reconnects

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


## Provided tools

Pinned via `MODULE` (fetched into `DEPS/` by `dbt`):

| Dependency | Type | Purpose |
|---|---|---|
| neovim | binary tarball | editor (`v0.12.5`), added to PATH |
| ripgrep | binary tarball | `rg`, symlinked into `bin/` |
| verilator | git | HDL simulator; `VERILATOR_ROOT` set, `bin/` prepended to PATH |
| oss-cad-suite-build | tar.gz | FPGA/EDA toolchain bundle |
| OpenSTA | git | static timing analysis |
| OpenROAD-flow-scripts | git | RTL-to-GDS flow |
| sv2v | git | SystemVerilog→Verilog converter |
| dbt-rules | git | build rules for `dbt` |
| dwl + dwl-patches | git | Wayland compositor |
| wlock | git | Wayland screen locker |
| qutebrowser | git | keyboard-driven browser |
| tpm | git | tmux plugin manager |
| scripts | git | `shortcut-menus` dmenu/wmenu scripts added to PATH |




Repo config dirs (`config/`): `nvim/`, `tmux/` (incl. tmux-powerline),
`waybar/`, `qutebrowser/`, `fusesoc/`.

## External required tools

Not provisioned by this repo — must exist on the system:

- `bash`, `git`, `sed`
- `python3-pip` / `pip3` (installed by `install.sh`)
- `golang` / `go` (for `dbt`)
- `highlight` — used by `LESSOPEN` for syntax-highlighted `less`
- `tmux`, `nvim` runtime deps; `nvr` (neovim-remote) for the `h`/`v`/`t` aliases
- `dmenu` or `wmenu` (selected via `$XDG_SESSION_DESKTOP`)
- `vivado`, `verible-verilog-format`, Libero (`LIBERO_PATH`/`LIBERO_LIC_PATH`),
  `xauth` — optional; warn-only if missing
- License env vars expected: `LM_LICENSE_FILE`, `XILINXD_LICENSE_FILE`

## Environment variables set by `sourceme.sh`

- `VERILATOR_ROOT=$ROOT/DEPS/verilator`
- `TOOLS_PATH` (default `~/tools`), `GOPATH` (default `~/go`),
  `CARGOPATH` (default `~/.cargo`), `USRBIN` (default `/usr/bin`)
- `CONFIGROOT=$ROOT/config`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`,
  `NVIMCONFIG`, `TMUX_HOME`, `SCREENRC`
- `EDITOR=nvim`, `menu=dmenu|wmenu`, `WORKSPACE_SET=1`
- `HISTSIZE`/`HISTFILESIZE=10000000`, shared history via `PROMPT_COMMAND`
- `LESSOPEN` pipes through `highlight` (solarized-light)
- PATH prepends: `$VERILATOR_ROOT/bin`, `$CARGOPATH/bin`, `$ROOT/bin`,
  `$ROOT/DEPS/neovim/bin`, `$ROOT/DEPS/scripts/shortcut-menus`

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


### qutebrowser (`config/qutebrowser/config.py`)

| Key | Mode | Action | Source |
|---|---|---|---|
| `a` | normal | Enter insert mode | custom |
| `K` / `J` | normal | Next / prev tab | custom [2](#21-1)  |
| `H` / `L` | normal | Back / forward | custom [3](#21-2)  |
| `Q` | normal | Close tab | custom [4](#21-3)  |
| `<Ctrl-n>` / `<Ctrl-p>` | command | Completion item next / prev | custom [5](#21-4)  |

All other qutebrowser bindings are upstream defaults (e.g. `o` open, `d` close tab, `gg`/`G` scroll, `f` hint-follow, `yy` yank URL, `i` insert mode, `:` command mode).

### Neovim (`config/nvim/`)

`init.lua` loads `config.lazy` (lazy.nvim bootstrap), `config.keymaps`,
`config.options`, `config.autocmds` — see `config/nvim/lua/config/keymaps.lua`
and `config/nvim/lua/plugins/` for the full list of custom keymaps and plugin
specs.

`mapleader = " "` (space) [1](#19-0)

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
| `<leader>q` | n | Diagnostics to loclist toggle| keymaps.lua |
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
| `<leader>q` | n | `vim.diagnostic.setloclist()` — buffer diagnostics to loclist | keymaps.lua |
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
| `<leader>no` | Notification history (defined twice; notifier wins) | custom |
| `<leader>e` | File explorer (`explorer` module disabled — likely dead) | custom [4](#19-3)  |
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
| `<leader>sb` | Buffer lines (declared twice) | custom |
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
| `<C-\><C-n>` | Exit terminal mode | Neovim builtin (not plugin) | [6](#19-5)

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
| `<leader>ni` | Icon picker | plugin default — `add_default_keybindings = true`; lhs from upstream, verify locally [10](#19-9)  |


### render-markdown.nvim (`plugins/render-markdown.lua`)

| Key | Action | Source |
|---|---|---|
| `<leader>bt`| Toggle markdown rendering (buffer)| custom|


## Layout

```
bin/        # symlinked/wrapped binaries (on PATH)
config/     # nvim, tmux, waybar, qutebrowser, fusesoc configs (XDG_CONFIG_HOME)
sourceme/   # sourceme.sh + dbt-completion.sh
MODULE      # pinned dependency manifest (dbt)
DEPS/       # fetched dependencies (gitignored)
BUILD/      # build output (gitignored)
r``
```
