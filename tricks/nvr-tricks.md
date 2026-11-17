# neovim-remote (nvr) tricks

## How `$NVIM` propagates

Neovim sets `NVIM=<servername socket>` in every terminal job's env. Use it
to detect "am I inside an nvim terminal":

```shell
if [ -n "$NVIM" ]; then ... fi
```

## Use nvr as $EDITOR inside nvim terminals

The git-commit-in-nvim problem solved — git picks `GIT_EDITOR > core.editor
> VISUAL > EDITOR > vi`. Conditional in shell rc:

```shell
if [ -n "$NVIM" ]; then
    export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
    export VISUAL=$EDITOR
else
    export EDITOR=nvim
fi
```

Key pieces:
- `--remote-wait` blocks until the buffer is **wiped** — plain `:q` only hides
  it, hence `bufhidden=wipe` so `:q`/`:wq` unblocks it.
- `-cc split` runs `:split` in the host nvim *before* opening the file
  (splits the currently-focused window). `-cc vsplit` for vertical.
- Without `-wait`, git proceeds immediately with an empty commit message.

## Handy commands

```shell
nvr --servername /tmp/nvimsocket --remote-expr 'bufname("%")'   # check socket
nvr -o file   # open in split      nvr -O file   # vsplit
nvr --remote-tab file              # new tab
nvr --remote-expr 'execute("quit")' # run ex command remotely
```

nvr starts a fresh `nvim --listen` if no server answers — include `--nostart`
if you don't want that.

## Known breakage

`nvr --version` crashes on setuptools >= 81 (`pkg_resources` removed,
upstream unmaintained since 2022). Cosmetic only — RPC paths unaffected.
