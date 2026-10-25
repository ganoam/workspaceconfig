#!/usr/bin/env bash
# bootstrap.sh [-y|--yes]
# Run manually. Ensures deps/scripts is available, then delegates
# submodule/tarball fetching to deps/scripts/setup/*.sh (or fetches
# fetch-repos.sh remotely if deps/scripts isn't present yet).

set -uo pipefail
SCRIPT_NAME="$(basename "$0")"

# Note: The bootstrap function will be overwritten by the version in lib.sh.
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

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
    esac
done

# find root of containing repo
find_repo_root() {
    local dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    while [ "$dir" != "/" ]; do
        [ -e "$dir/.git" ] && { echo "$dir"; return 0; }
        dir=$(dirname "$dir")
    done
    return 1
}

ROOT=$(find_repo_root) || { log "ERROR: could not find repo root."; exit 1; }
log "ROOT: $ROOT"
# exit 0
mkdir -p "$ROOT/deps"

# --- deps/scripts: fetch remotely if not yet present, then delegate ---
FETCH_REPOS="setup/fetch-repos.sh"
bootstrap_script "$FETCH_REPOS" "run"

# --- tarballs, once deps/scripts is present ---
FETCH_TARBALLS="$ROOT/deps/scripts/setup/fetch-tarballs.sh"
if [ -f "$FETCH_TARBALLS" ]; then
    pushd $ROOT > /dev/null
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
ensure_tool "nvr" "tool_check nvr" "nvr_install" "tool_describe nvr"

# --- qutebrowser ---
QB_VENV="$ROOT/envs/qb"
qb_install() {
    local QB_DIR="$ROOT/deps/qutebrowser"
    ensure_venv $QB_VENV &&
    $QB_DIR/scripts/mkvenv.py --venv-dir $QB_VENV
}
ensure_tool "qutebrowser" "tool_check qutebrowser  $QB_VENV" "qb_install" "tool_describe qutebrowser"
