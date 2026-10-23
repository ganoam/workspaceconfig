#!/usr/bin/env bash
# sourceme/bootstrap.sh [-y|--yes]
# Run manually. Ensures deps/scripts is available, then delegates
# submodule/tarball fetching to deps/scripts/setup/*.sh (or fetches
# fetch-repos.sh remotely if deps/scripts isn't present yet).

set -uo pipefail

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
    esac
done

ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT="$ROOT/.."
mkdir -p "$ROOT/deps"

# Generic helper: check -> prompt -> install
ensure_tool() {
    local name="$1" check_fn="$2" install_fn="$3"
    if "$check_fn"; then
        echo "[bootstrap] $name already present, skipping."
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
            echo "[bootstrap] Installing $name ..."
            if "$install_fn"; then
                echo "[bootstrap] $name installed."
            else
                echo "[bootstrap] ERROR: failed to install $name."
            fi
            ;;
        *)
            echo "[bootstrap] Skipping $name install."
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
        echo "[bootstrap] : WARNING: no pinned commit found for deps/scripts in the index."
        SHA="master"
    fi
    tmp=$(mktemp)
    curl -fsSL "https://raw.githubusercontent.com/koalemo/scripts/$SHA/setup/fetch-repos.sh" -o "$tmp"
    pushd $ROOT
    bash "$tmp" "$ROOT" $([ "$ASSUME_YES" -eq 1 ] && echo -y)
    popd
    rm -f "$tmp"
else
    bash "$FETCH_REPOS" "$ROOT" $([ "$ASSUME_YES" -eq 1 ] && echo -y)
fi

# --- tarballs, once deps/scripts is present ---
FETCH_TARBALLS="$ROOT/deps/scripts/setup/fetch-tarballs.sh"
if [ -f "$FETCH_TARBALLS" ]; then
    pushd $ROOT
    bash "$FETCH_TARBALLS" "$ROOT" $([ "$ASSUME_YES" -eq 1 ] && echo -y)
    popd
fi
