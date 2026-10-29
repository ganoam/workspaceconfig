#!/usr/bin/env bash
# bootstrap.sh [-y|--yes] [-t|--terminal]
# Run manually. Ensures deps/scripts is available, then delegates
# submodule/tarball fetching to deps/scripts/setup/*.sh (or fetches
# fetch-repos.sh remotely if deps/scripts isn't present yet).
#
# Flags:
#   -y, --yes     Skip prompts (default to full wayland experience)
#   -t, --terminal Install terminal tools only (no sudo required)

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
            log ": WARNING: no pinned commit found for deps/scripts in the index. Using master."
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

# helper variable for make multithreading.
jobs=$(nproc)
(( jobs > 1 )) && jobs=$((jobs-1))
log "jobs: $jobs"

# Parse custom flags
INSTALL_MODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--terminal)
            INSTALL_MODE="terminal"
            shift
            ;;
        *)
            # Pass other args to parse_common_args
            break
            ;;
    esac
done

# --- deps/scripts: fetch remotely if not yet present, then delegate ---
LIB="setup/lib.sh"
bootstrap_script "$LIB" "source"
parse_common_args "$@"
export -f bootstrap_script


ROOT="$CONFIGROOT/.."
log "ROOT: $ROOT"
# exit 0
mkdir -p "$ROOT/deps"

# --- prompt for installation mode ---
if [ -z "$INSTALL_MODE" ]; then
    if [ "$ASSUME_YES" -eq 1 ]; then
        INSTALL_MODE="full"
        log "ASSUME_YES is set, defaulting to full wayland experience"
    else
        echo ""
        echo "Select installation mode:"
        echo "  1) Terminal tools only (no sudo required)"
        echo "  2) Full wayland experience (includes wayland compositor and utilities)"
        echo ""
        while true; do
            read -p "Enter choice [1/2]: " choice
            case $choice in
                1)
                    INSTALL_MODE="terminal"
                    log "Installing terminal tools only"
                    break
                    ;;
                2)
                    INSTALL_MODE="full"
                    log "Installing full wayland experience"
                    break
                    ;;
                *)
                    echo "Invalid choice. Please enter 1 or 2."
                    ;;
            esac
        done
    fi
else
    log "Installation mode set via flag: $INSTALL_MODE"
fi

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

# --- fusesoc ---
fusesoc_install() {
    ensure_venv &&
    pushd "$ROOT/deps/fusesoc" > /dev/null
    "$MAIN_VENV/bin/pip" install .
    popd > /dev/null
}
ensure_tool "fusesoc" "tool_check fusesoc $MAIN_VENV" "fusesoc_install" "tool_describe fusesoc $MAIN_VENV"

# --- verilator ---
VERILATOR_BIN="$ROOT/deps/verilator/bin/verilator_bin"
verilator_install() {
  pushd "$ROOT/deps/verilator" > /dev/null
  autoconf && ./configure && make clean && make -j"$jobs"
  popd > /dev/null
}
ensure_tool "verilator" "tool_check $VERILATOR_BIN" "verilator_install" "tool_describe verilator"

# --- qutebrowser ---
if [ "$INSTALL_MODE" == "full" ]; then
  QB_VENV="$ROOT/envs/qb"
  qb_install() {
      local QB_DIR="$ROOT/deps/qutebrowser"
      ensure_venv $QB_VENV &&
      $QB_DIR/scripts/mkvenv.py --venv-dir $QB_VENV
  }
  ensure_tool "qutebrowser" "tool_check qutebrowser $QB_VENV" "qb_install" "tool_describe qutebrowser $QB_VENV"
fi

# --- waybar ---
if [ "$INSTALL_MODE" == "full" ]; then
    WB_BIN="$ROOT/deps/waybar/build/waybar"
    wb_install() {
        pushd "$ROOT/deps/waybar" > /dev/null
        meson setup build &&
        ninja -C build
        popd > /dev/null
    }
    ensure_tool "waybar" "tool_check $WB_BIN" "wb_install" "tool_describe waybar"
fi

# --- dwl ---
if [ "$INSTALL_MODE" == "full" ]; then
    DWL_BIN="$ROOT/deps/dwl/dwl"
    dwl_install() {
      pushd "$ROOT/deps/dwl" > /dev/null
      make clean && make -j"$jobs" &&
      sudo mkdir -p /usr/local/share/wayland-sessions &&
      sudo cp -r $ROOT/deps/dwl/dwl.desktop /usr/local/share/wayland-sessions/dwl.desktop
      sudo chmod 644 /usr/local/share/wayland-sessions/dwl.desktop
      popd > /dev/null
    }

    ensure_tool "dwl" "tool_check $DWL_BIN" "dwl_install" "tool_describe dwl"
fi

# --- mako ---
if [ "$INSTALL_MODE" == "full" ]; then
    MAKO_BIN="$ROOT/deps/mako/build/mako"
    mako_install() {
        pushd "$ROOT/deps/mako" > /dev/null
        meson setup build &&
        ninja -C build
        popd > /dev/null
    }
    ensure_tool "mako" "tool_check $MAKO_BIN" "mako_install" "tool_describe mako"
fi

# --- swaybg ---
if [ "$INSTALL_MODE" == "full" ]; then
    SWAYBG_BIN="$ROOT/deps/swaybg/build/swaybg"
    swaybg_install() {
        pushd "$ROOT/deps/swaybg" > /dev/null
        meson setup build &&
        ninja -C build
        popd > /dev/null
    }
    ensure_tool "swaybg" "tool_check $SWAYBG_BIN" "swaybg_install" "tool_describe swaybg"
fi

# --- wmenu ---
if [ "$INSTALL_MODE" == "full" ]; then
    WMENU_BIN="$ROOT/deps/wmenu/build/wmenu"
    wmenu_install() {
        pushd "$ROOT/deps/wmenu" > /dev/null
        meson setup build &&
        ninja -C build
        popd > /dev/null
    }
    ensure_tool "wmenu" "tool_check $WMENU_BIN" "wmenu_install" "tool_describe wmenu"
fi

# --- foot ---
if [ "$INSTALL_MOE" == "full" ]; then
    FOOT_BIN="$ROOT/deps/foot/build/foot"
    foot_install() {
        pushd "$ROOT/deps/foot" > /dev/null
        meson setup build &&
        ninja -C build
        popd > /dev/null
    }
    ensure_tool "foot" "tool_check $FOOT_BIN" "foot_install" "tool_describe foot"
fi

# --- verilator ---
VERILATOR_BIN="$ROOT/deps/verilator/bin/verilator_bin"
verilator_install() {
  pushd "$ROOT/deps/verilator" > /dev/null
  autoconf && ./configure && make clean && make -j"$jobs"
  popd > /dev/null
}
ensure_tool "verilator" "tool_check $VERILATOR_BIN" "verilator_install" "tool_describe verilator"
