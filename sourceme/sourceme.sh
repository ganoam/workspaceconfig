#!/usr/bin/env bash

# Set repo root variable
ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT="$ROOT/.."
echo "Sourcing workspace config from $ROOT"

# Export configuration paths
export CONFIGROOT=$ROOT/config
export SCREENRC=$CONFIGROOT/screen/screenrc
export NVIMCONFIG=$CONFIGROOT # nvim specs its own subdir.
export TMUX_HOME=$CONFIGROOT/tmux
export XDG_CONFIG_HOME=$CONFIGROOT
export XDG_DATA_HOME=$CONFIGROOT/share

source


# --- Tool presence checks (warnings only, no interactive prompts) ---
#
# nvr (neovim-remote)
if [ ! -x "$ROOT/envs/main/bin/nvr" ]; then
    echo "WARNING: nvr not found. Run bootstrap.sh to install it."
fi

# git submodules
if [ -f "$ROOT/.gitmodules" ]; then
    OUT_OF_DATE=$(git -C "$ROOT" submodule status 2>/dev/null | grep -E '^[+-]' || true)
    if [ -n "$OUT_OF_DATE" ]; then
        echo "WARNING: some git submodules are missing or out of date:"
        echo "$OUT_OF_DATE"
        echo "WARNING: Run bootstrap.sh to sync them."
    fi
fi

# TODO (ng): This is just hacked in here. MAy depend on the terminal emulator if this works or not
# Function to extract the last 2 levels from the current path
function CustomPWD {
    # Remove from $PWD the shortest part of /*/* that matches the back end of $var
    tmp=${PWD%/*/*};
    # If tmp is of positive length not equal PWD, print the last characters of PWD.
    # Else, print PWD.
    [ ${#tmp} -gt 0 -a "$tmp" != "$PWD" ] && echo ${PWD:${#tmp}+1} || echo $PWD;
}

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Create prompt header
PS1='\h:\[\033[1;31m\][$(CustomPWD)]\[\033[32m\]$(parse_git_branch)\[\033[00m\] \$ '
#
# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
   # PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
	PS1="\[\e]0;\u@\h: \w\a\]$PS1"
	;;
*)
    ;;
esac


# Make history available across all console
# Avoid duplicates
HISTCONTROL=ignoredups:erasedups

# After each command, append to the history file and reread it
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"


# Enable dbt command competion
#. $ROOT/sourceme/dbt-completion.sh

# Run in place verilator
export VERILATOR_ROOT=$ROOT/deps/verilator
# Put this verilator at the top of the path
export PATH=$VERILATOR_ROOT/bin:$PATH

#Update path only if we haven't done that yet.
if [[ -z "$WORKSPACE_SET" ]]; then

    if [[ -z $TOOLS_PATH ]]; then
      echo WARNING: variable TOOLS_PATH is not set. using default: ~/tools
	    export TOOLS_PATH=$HOME/tools
    fi
    # Export binaries from local tools to path
    # export PATH=$PATH"$(find "$TOOLS_PATH" -type d -name bin -printf ':%p')"
    echo WARNING: Not exporting tools. Use export-bin script

    if [[ -z $GOPATH ]]; then
    	echo "WARNING: variable GOPATH is not set. setting default: ~/go"
	    export GOPATH=$HOME/go
    fi


    if [[ -z $VERILATOR_ROOT ]]; then
        echo "WARNING: variable VERILATOR_ROOT is not set."
    else
        export PATH=$VERILATOR_ROOT/bin:$PATH
    fi

    if [[ -z $CARGOPATH ]]; then
        echo "WARNING: variable CARGOPATH is not set. usign default: ~/.cargo"
        export CARGOPATH=$HOME/.cargo
    fi

    export PATH=$CARGOPATH/bin:$PATH
    #
    # Export binaries from workspaceconfig repo to path
    export  PATH=$ROOT/bin:$ROOT/deps/neovim/bin:$PATH

    # Export dmenu scripts to path
    # TODO: find a better solution
    export PATH=$ROOT/deps/scripts/shortcut-menus:$PATH
    export PATH=$ROOT/deps/scripts/bin:$PATH

    #export PATH="$(find "$ROOT" -type d -name bin -printf '%p:')"$PATH
fi

if [ "$XDG_SESSION_DESKTOP" == "dwl" ]; then
  export menu='wmenu'
else
  export menu='dmenu'
fi


# Export configuration paths
export CONFIGROOT=$ROOT/config
export SCREENRC=$CONFIGROOT/screen/screenrc
export NVIMCONFIG=$CONFIGROOT # nvim specs its own subdir.
export TMUX_HOME=$CONFIGROOT/tmux
export XDG_CONFIG_HOME=$CONFIGROOT
export XDG_DATA_HOME=$CONFIGROOT/share

# Replace oldvim
echo "Setting aliases"
alias nvim=nvim
alias vim=nvim
alias vi=nvim
alias vimdiff="nvim -d"
export EDITOR=nvim

#shortcuts to open files in new split / tab
alias h='nvr -o'
alias v='nvr -O'
alias t='nvr --remote-tab'

# Pipe Highlight to less
export LESSOPEN="| $(which highlight) %s --out-format xterm256 --quiet --force --style solarized-light -D /scratch/msc20f1/highlight_data"
export LESS=" -R"
alias less='less -m -N -g -i -J --line-numbers --underline-special'
#alias less='less -N -m -g -i -J --line-numbers --underline-special'
alias more='less'

# Make tmux use conf file from workspaceconfig:
# NOTE: Wrapper file does not seem to work here: tpm does not load...
alias tmux="tmux -f $CONFIGROOT/tmux/tmux.conf"
source $CONFIGROOT/tmux/.tmux-powerlinerc

# Make qutebrowser use conf file from workspaceconfig
alias qutebrowser="qutebrowser -C $CONFIGROOT/qutebrowser/config.py"

# Use "highlight" in place of "cat"
# alias cat="highlight $1 --out-format xterm256 --line-numbers --quiet --force --style solarized-light -D ${SCRATCHPATH}/highlight_data"


# Commodities
alias vvfi="verible-verilog-format --inplace"

alias vvmts="vivado -mode tcl -source "
alias vvmbs="vivado -mode batch -source "

export HISTSIZE=10000000
export HISTFILESIZE=10000000


if [[ -z $LM_LICENSE_FILE ]]; then
    echo "WARNING: variable LM_LICENSE_FILE is not set."
fi

if [[ -z $XILINXD_LICENSE_FILE ]]; then
    echo WARNING: variable XILINXD_LICENSE_FILE is not set.
fi

if [[ -z $USRBIN ]]; then
    echo WARNING: variable usrbin is not set. setting default: /usr/bin
    export USRBIN=/usr/bin
fi

if [[ -z $LIBERO_PATH && -z LIBERO_LIC_PATH ]]; then
    echo WARNING: variable LIBERO_PATH and / or LIBERO_LIC_PATH is not set.
else
    # Alias for Libero launch command
    alias libefire='pkill -f lmgrd ; $LIBERO_PATH/lic/lmgrd -c $LIBERO_LIC_PATH/License.dat

    Microchip/Libero/bin/libero'
    alias libedone='pkill -f lmgrd ; pkill -f libero'

    alias libelic='$LIBERO_PATH/lic/lmgrd -c $LIBERO_LIC_PATH/License.dat'
fi


export WORKSPACE_SET=1

set -o vi

