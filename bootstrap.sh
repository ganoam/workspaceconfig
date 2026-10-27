#!/usr/bin/env bash
# bootstrap.sh [-y|--yes]
# Run manually. Ensures deps/scripts is available, then delegates
# submodule/tarball fetching to deps/scripts/setup/*.sh (or fetches
# fetch-repos.sh remotely if deps/scripts isn't present yet).

set -uo pipefail

# Note: The bootstrap function will be overwritten by the version in lib.sh.
log() {
  echo "[$(basename "$0")] $*" >&2
}
bootstrap_script() {
    local RELPATH="$1"
    local MODE="${2:-run}" # source or run

    _run_script() {
      local script="$1"
      if [ "$MODE" == "source" ]; then
        source "$script"
      else
        bash "$script"
      fi
    }

    if [[ -z $CONFIGROOT ]]; then
      echo "[$basename "$0"] ERROR: variable CONFIGROOT not set."
      return 1
    fi

    local FULLPATH="$CONFIGROOT/../deps/scripts/$RELPATH"

    if [ ! -f "$FULLPATH" ]; then
        local SHA
        SHA=$(git -C "$CONFIGROOT" ls-tree HEAD -- deps/scripts | awk '{print $2}')
        if [ -z "$SHA" ]; then
            log ": WARNING: no pinned commit found for deps/scripts in the index."
            SHA="master"
        fi
        local tmp
        tmp=$(mktemp)
        curl -fsSL "https://raw.githubusercontent.com/koalemo/scripts/$SHA/$RELPATH" -o "$tmp"
        pushd "$CONFIGROOT/.." > /dev/null # fetch scripts need to run from workspaceconfig root.
        _run_script "$tmp"
        popd > /dev/null
        rm -f "$tmp"
    else
        pushd "$CONFIGROOT/.." > /dev/null
        _run_script "$FULLPATH"
        popd > /dev/null
    fi
}

# --- deps/scripts: fetch remotely if not yet present, then delegate ---
LIB="setup/lib.sh"
bootstrap_script "$LIB" "source"
parse_common_args "$@"


ROOT="$CONFIGROOT/.."
log "ROOT: $ROOT"
# exit 0
mkdir -p "$ROOT/deps"

# --- deps/scripts: fetch remotely if not yet present, then delegate ---
FETCH_REPOS="setup/fetch-repos.sh"
bootstrap_script "$FETCH_REPOS" "run"

# --- tarballs, once deps/scripts is present ---
FETCH_TARBALLS="$ROOT/deps/scripts/setup/fetch-tarballs.sh"
if [ -f "$FETCH_TARBALLS" ]; then
    pushd "$ROOT" > /dev/null
    bash "$FETCH_TARBALLS" "$ROOT" $([ "$ASSUME_YES" -eq 1 ] && echo -y)
    popd > /dev/null
fi

# --- shared venv for tools (nvr, qutebrowser, etc) ---
MAIN_VENV="$ROOT/envs/main"

# --- nvr ---
nvr_install() {
    ensure_venv &&
    "$MAIN_VENV/bin/pip" install neovim-remote
}
ensure_tool "nvr" "tool_check nvr $MAIN_VENV" "nvr_install" "tool_describe nvr $MAIN_VENV"

# --- qutebrowser ---
QB_VENV="$ROOT/envs/qb"
qb_install() {
    local QB_DIR="$ROOT/deps/qutebrowser"
    ensure_venv $QB_VENV &&
    $QB_DIR/scripts/mkvenv.py --venv-dir $QB_VENV
}
ensure_tool "qutebrowser" "tool_check qutebrowser $QB_VENV" "qb_install" "tool_describe qutebrowser $QB_VENV"

# --- waybar ---
WB_BIN="$ROOT/deps/waybar/build/waybar"
wb_install() {
    pushd "$ROOT/deps/waybar" > /dev/null
    meson setup build &&
    ninja -C build
    popd > /dev/null
}
ensure_tool "waybar" "tool_check $WB_BIN" "wb_install" "tool_describe waybar"

# --- dwl ---
DWL_BIN="/usr/local/bin/dwl"
dwl_install() {
  pushd "$ROOT/deps/dwl" > /dev/null
  make clean && make &&
  sudo cp -f dwl.desktop /usr/local/share/wayland-sessions/dwl.desktop &&
  sudo chmod 644 /usr/local/share/wayland-sessions/dwl.desktop
}

ensure_tool "dwl" "tool_check $DWL_BIN" "dwl_install" "tool_describe dwl"
