# tar tricks

## `--no-same-owner`

As root, `tar -x` preserves archive uid/gid → `Cannot change ownership`
errors (or silently wrong ownership when it *can* chown). Always:

```shell
tar --no-same-owner -xf archive.tar.gz -C dest/
```

Default behavior for non-root anyway; only matters for root/containers.

## Flatten a single top-level directory

Release tarballs usually nest (`nvim-linux-x86_64/`, `ripgrep-13.0.0-…/`).
`--strip-components=1` breaks archives whose payload is a bare file
(e.g. `tmux`). Flatten conditionally instead:

```bash
tar --no-same-owner -xf "$archive" -C "$dest" || return 1
shopt -s nullglob dotglob
entries=("$dest"/*)
if [ ${#entries[@]} -eq 1 ] && [ -d "${entries[0]}" ]; then
    mv "${entries[0]}"/* "$dest/" && rmdir "${entries[0]}"
fi
shopt -u nullglob dotglob
```

## Quick checks

```shell
tar tzf archive.tar.gz | head   # top-level entries without extracting
tar xOf archive.tar.gz path/in/archive | head   # stream one file
```
