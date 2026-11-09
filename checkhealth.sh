#!/usr/bin/env bash
# checkhealth.sh — verify the workspace config is correctly set up.
# Sources sourceme.sh, then checks env vars, binaries, and versions.
# Exit code: number of failed checks (0 = healthy).

cd -- "$(dirname -- "${BASH_SOURCE[0]}")" || exit 1
source sourceme/sourceme.sh

PASS=0; FAIL=0; WARN=0
ok()   { echo "  ok    $1"; ((++PASS)); }
fail() { echo "  FAIL  $1"; ((++FAIL)); }
warn() { echo "  warn  $1"; ((++WARN)); }

echo "== environment =="
for var in CONFIGROOT XDG_CONFIG_HOME XDG_DATA_HOME EDITOR; do
    [ -n "${!var:-}" ] && ok "$var=${!var}" || fail "$var not set"
done

echo "== git submodules =="
while read -r status path _; do
    [ -z "$status" ] && continue
    case "$status" in
        -*) fail "submodule not initialized: $path" ;;
        +*) warn "submodule on different commit: $path" ;;
        *)  ok "submodule $path" ;;
    esac
done < <(git submodule status 2>/dev/null)

echo "== binaries on PATH =="
for b in nvim rg tmux nvr fusesoc verilator_bin gtkwave inkscape qutebrowser; do
    command -v "$b" >/dev/null && ok "$b -> $(command -v $b)" || fail "$b not on PATH"
done

echo "== wayland tools (full install only) =="
for b in dwl waybar mako swaybg wmenu foot; do
    command -v "$b" >/dev/null && ok "$b -> $(command -v $b)" || warn "$b not on PATH"
done

echo "== versions (runtime check) =="
check_version() { # name, command
    local out rc; out=$("$@" 2>&1); rc=$?
    out=$(head -1 <<<"$out")
    [ $rc -eq 0 ] && [ -n "$out" ] && ok "$out" || fail "$1 failed: $out"
}
check_version nvim --version
check_version rg --version
check_version tmux -V
check_version verilator_bin --version
check_version fusesoc --version
check_version gtkwave --version
check_version qutebrowser --version
# inkscape AppImage needs FUSE to run — presence on PATH above is the check

echo "== nvim config =="
if nvim --headless "+qa!" >/dev/null 2>&1; then
    ok "nvim starts without errors"
else
    warn "nvim startup reported errors (check :checkhealth)"
fi

echo ""
echo "== summary: $PASS ok, $WARN warnings, $FAIL failed =="
exit "$FAIL"
