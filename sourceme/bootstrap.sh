#!/usr/bin/env bash
# sourceme/bootstrap.sh [-y|--yes]

# --- nvr (neovim-remote), in a local venv ---

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
    esac
done

# Get repo root
ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT="$ROOT/.."

# Generic helper: check -> prompt -> install
ensure_tool() {
    local name="$1"          # human-readable name, e.g. "nvr"
    local check_cmd="$2"     # shell command/test string; success = already installed
    local install_cmd="$3"   # shell command string to run if user agrees

    if eval "$check_cmd"; then
        echo "[bootstrap] $name already present, skipping."
        return
    fi

    local answer="n"
    if [ "$ASSUME_YES" -eq 1 ]; then
        answer="y"
    else
        read -p "$name not found. Install it now? [y/N] " answer < /dev/tty
    fi

    case "$answer" in
        y|Y|yes|Yes)
            echo "[bootstrap] Installing $name ..."
            if eval "$install_cmd"; then
                echo "[bootstrap] $name installed."
            else
                echo "[bootstrap] ERROR: failed to install $name." >&2
            fi
            ;;
        *)
            echo "[bootstrap] Skipping $name install."
            ;;
    esac
}

# Ensure deps/ exists before any submodule/tool checks run
mkdir -p "$ROOT/deps"

# --- git submodules ---
while IFS= read -r name; do
    submodule_dirty() {
        [ -n "$(git -C "$ROOT/$1" status --porcelain 2>/dev/null)" ]
    }
    submodule_check() {
        local status_output
        status_output=$(git -C "$ROOT" submodule status -- "$1" 2>/dev/null) || return 1   # git itself failed (unknown pathspec)
        [ -n "$status_output" ] || return 1                                                  # no output at all
        ! echo "$status_output" | grep -qE '^[+-]'
    }
    submodule_install() {
        if submodule_dirty "$1"; then
            echo "[bootstrap] WARNING: submodule '$1' has uncommitted changes, skipping update."
            return 1
        fi

        git -C "$ROOT" submodule update --init --recursive -- "$1"
    }
    ensure_tool "submodule:$name" "submodule_check $name" "submodule_install $name"
done < <(git -C "$ROOT" config --file "$ROOT/.gitmodules" --get-regexp path | awk '{print $2}')

# --- nvr ---
NVR_VENV="$ROOT/envs/main"
nvr_check() { [ -x "$NVR_VENV/bin/nvr" ]; }
nvr_install() {
    python3 -m venv "$NVR_VENV"
    "$NVR_VENV/bin/pip" install --quiet --upgrade pip
    "$NVR_VENV/bin/pip" install --quiet neovim-remote
}
ensure_tool "nvr" nvr_check nvr_install

