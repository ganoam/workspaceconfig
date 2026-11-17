# bash tricks (bootstrap-script bug patterns)

## `popd` masking real failures

Install fns ending in bare `popd` always return 0:

```bash
bad() { pushd d >/dev/null; make; popd >/dev/null; }   # rc always 0!

good() {
  local rc
  pushd d >/dev/null || return 1
  make
  rc=$?
  popd >/dev/null
  return $rc
}
```

## `((x++))` post-increment is falsy when x=0

`((PASS++))` returns the OLD value → status 1 when PASS was 0 → `||`
branches fire after a success. Use `((++PASS))` or `PASS=$((PASS+1))`.

## `source` inside a pipeline runs in a subshell

```bash
source env.sh | grep -v warning   # env vars lost — subshell!
```

Never pipe `source`.

## `set -u` + required env vars

`[[ -z $VAR ]]` under `set -u` dies with "unbound variable" — a graceful
check still needs `${VAR:-}`: `[[ -z ${VAR:-} ]]`.

## Flags don't reach delegated `bash` subprocesses

`bash "$script"` drops the parent's args/env(unexported). Either pass
explicitly (`bash "$script" $args`) or export — users prefer explicit
passing so nothing ambient leaks.

## Function overrides after `source`

A sourced lib redefining a function silently replaces your version — the
LATER call site uses the lib's semantics, not yours.

## Failure arrays don't cross process boundaries

`FAILED+=()` populated in a `bash`ed child script is invisible to the
parent — the child must `exit 1` and the parent record it:
`bash child.sh || FAILED+=("child")`.

## `git ls-tree` pathspecs are relative to `-C` dir

`git -C repo/config ls-tree HEAD -- deps/x` looks for `config/deps/x` →
empty. Run from repo root, and note output is `<mode> <type> <sha>\t<path>`
— the sha is `$3` in awk, not `$2`.

## Templating a file into a root-owned dir: `sed | sudo tee`

```bash
sed "s|~/workspaceconfig|$ROOT|g" "$ROOT/deps/dwl/dwl.desktop" |
  sudo tee /usr/local/share/wayland-sessions/dwl.desktop > /dev/null &&
  sudo chmod 644 /usr/local/share/wayland-sessions/dwl.desktop
```

- `sed "s|old|$NEW|g" file` — rewrite to stdout, source untouched.
  `|` delimiter avoids escaping `/` in paths; `g` = all matches per line.
- `| sudo tee <dst>` — `>` / `sudo cmd > dst` FAILS: the redirect is
  opened by your shell before sudo runs. `tee` puts the write inside
  the elevated process.
- `> /dev/null` — drops tee's stdout echo (it copies stdin to stdout
  AND the file); the file write is unaffected.
- `&&` — with `pipefail` this needs sed AND tee to succeed.
