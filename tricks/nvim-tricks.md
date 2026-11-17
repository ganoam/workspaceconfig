# nvim tricks

## Headless testing / probing

```shell
nvim --headless -u NONE -c "luafile test.lua"
nvim --headless "+Lazy! sync" +qa          # install plugins non-interactively
```

Load plugin internals directly instead of the full config:

```lua
vim.opt.rtp:append("/path/to/plugin.nvim")
local M = require("plugin.internal.module")
```

## `:terminal` buffers

- `buftype == "terminal"` — many tools skip them as "non-file".
- `:buffer N` / `:e file` on a terminal window works fine — the terminal
  just hides and keeps running.
- Any insert-command (`i`, `a`, `o`) enters Terminal-Insert mode; `<Esc>`
  does NOT leave it — needs `<C-\><C-n>`.
- Neovim exports `NVIM=<socket>` into terminal jobs' env (see nvr-tricks).

## GUI app --version checks in CI/headless

Qt apps abort without a platform — use the offscreen plugin:

```shell
QT_QPA_PLATFORM=offscreen qutebrowser --version
```

GTK apps print "Could not initialize GTK" without DISPLAY (harmless for
presence checks).

## Buffers vs windows

`win_findbuf()`, `getbufinfo().lastused`, `nvim_win_get_buf` — the tools
that pick "which window gets a new buffer" all rank by MRU/lastused of the
*buffer in the window*, not the window itself.

## Word text objects (visual select)

| Keys | Selects |
|---|---|
| `viw` | word under cursor (keyword chars: letters, digits, `_`) |
| `vaw` | word + trailing whitespace |
| `viW` | WORD (everything up to whitespace) — for `foo.bar/baz` |
| `vaW` | WORD + trailing whitespace |

`iw`/`aw`/`iW`/`aW` compose with any operator: `diw`, `yiw`, `ciw`, `gUiw`.

## Hopping between occurrences

- `*` / `#` — next / prev whole-word match of word under cursor (no visual
  select needed); `n` / `N` keep hopping.
- Visual selection → search for it: `y` then `/<C-r>"<CR>`, then `n`/`N`.
  (A visual-mode `*` map needs a small custom keymap — not configured.)
- `gn` / `gN` — visually *select* the next / prev match of the current `/`
  search; chain `gn gn gn` to select successive occurrences.
- `cgn` — change the next occurrence, then `.` repeats the change on each
  following match (poor man's rename).
- `]]` / `[[` — snacks.words: hop between LSP *references* of the symbol
  under cursor (semantic, not text match).
- `<leader>sw` — snacks grep_word on visual selection, project-wide.
