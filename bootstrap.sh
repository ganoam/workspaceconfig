#!/usr/bin/env bash
# bootstrap.sh [-y|--yes]
# Run manually. Ensures deps/scripts is available, then delegates
# submodule/tarball fetching to deps/scripts/setup/*.sh (or fetches
# fetch-repos.sh remotely if deps/scripts isn't present yet).

set -uo pipefail
SCRIPT_NAME="$(basename "$0")"

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
    esac
done

find_repo_root() {
    local dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    while [ "$dir" != "/" ]; do
        [ -e "$dir/.git" ] && { echo "$dir"; return 0; }
        dir=$(dirname "$dir")
    done
    return 1
}

ROOT=$(find_repo_root) || { echo "[$SCRIPT_NAME] ERROR: could not find repo root."; exit 1; }
echo "[$SCRIPT_NAME] ROOT: $ROOT"
# exit 0
mkdir -p "$ROOT/deps"

# Generic helper: check -> prompt -> install
ensure_tool() {
    local name="$1" check_fn="$2" install_fn="$3"
    if "$check_fn"; then
        echo "[$SCRIPT_NAME] $name already present, skipping."
        return
    fi
    local answer="n"
    if [ "$ASSUME_YES" -eq 1 ]; then
        answer="y"
    else
        read -p "$name not found. Install it now? [y/N] " answer
    fi
    case "$answer" in
        y|Y|yes|Yes)
            echo "[$SCRIPT_NAME] Installing $name ..."
            if "$install_fn"; then
                echo "[$SCRIPT_NAME] $name installed."
            else
                echo "[$SCRIPT_NAME] ERROR: failed to install $name."
            fi
            ;;
        *)
            echo "[$SCRIPT_NAME] Skipping $name install."
            ;;
    esac
}

# --- nvr (neovim-remote), in a local venv ---
NVR_VENV="$ROOT/envs/main"
nvr_check() { [ -x "$NVR_VENV/bin/nvr" ]; }
nvr_install() {
    python3 -m venv "$NVR_VENV" &&
    "$NVR_VENV/bin/pip" install --quiet --upgrade pip &&
    "$NVR_VENV/bin/pip" install --quiet neovim-remote
}
ensure_tool "nvr" nvr_check nvr_install

# --- deps/scripts: fetch remotely if not yet present, then delegate ---
FETCH_REPOS="$ROOT/deps/scripts/setup/fetch-repos.sh"
if [ ! -f "$FETCH_REPOS" ]; then
    SHA=$(git -C "$ROOT" ls-tree HEAD -- deps/scripts | awk '{print $3}')
    if [ -z "$SHA" ]; then
        echo "[$SCRIPT_NAME] : WARNING: no pinned commit found for deps/scripts in the index."
        SHA="master"
    fi
    tmp=$(mktemp)
    curl -fsSL "https://raw.githubusercontent.com/koalemo/scripts/$SHA/setup/fetch-repos.sh" -o "$tmp"
    pushd $ROOT > /dev/null # fetch scripts need to run from workspaceconfig root.
    bash "$tmp" "$ROOT" $([ "$ASSUME_YES" -eq 1 ] && echo -y)
    popd > /dev/null
    rm -f "$tmp"
else
    pushd $ROOT > /dev/null
    bash "$FETCH_REPOS" "$ROOT" $([ "$ASSUME_YES" -eq 1 ] && echo -y)
    popd > /dev/null
fi

# --- tarballs, once deps/scripts is present ---
FETCH_TARBALLS="$ROOT/deps/scripts/setup/fetch-tarballs.sh"
if [ -f "$FETCH_TARBALLS" ]; then
    pushd $ROOT > /dev/null
    bash "$FETCH_TARBALLS" "$ROOT" $([ "$ASSUME_YES" -eq 1 ] && echo -y)
    popd > /dev/null
fi
