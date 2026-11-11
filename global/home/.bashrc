# Tool locations are session variables (global/xdg.nix). Bash presets
# HISTFILE to ~/.bash_history before reading this file, so assign it outright.
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/bash/history"

mkdir -p \
    "${XDG_STATE_HOME:-$HOME/.local/state}"/{bash,less,node} \
    "${XDG_CONFIG_HOME:-$HOME/.config}/npm/config"

if [ -f "$HOME/.config/theme/palette.sh" ]; then
    . "$HOME/.config/theme/palette.sh"
fi

if [ -f "$HOME/.config/theme/man.sh" ]; then
    . "$HOME/.config/theme/man.sh"
fi

# Magenta is the theme's accent in kitty's palette, so the prompt follows
# theme switches in open shells too.
export PS1="\n\[\033[35m\][\u@\h:\w]\\$\[\033[0m\] "

alias publicip="dig +short myip.opendns.com @resolver1.opendns.com"

EZA_BASE="--icons --git --group-directories-first"
alias ls="eza $EZA_BASE"
alias l="eza -la $EZA_BASE"
alias ll="eza -l $EZA_BASE --time-style=relative"
alias la="eza -a $EZA_BASE"
alias lt="eza -la --icons --git --time-style=relative --sort modified"
alias ltr="eza -la --icons --git --time-style=relative --sort modified --reverse"
alias tree="eza --tree $EZA_BASE"

rm() {
    rmtrash "$@"
}

# Runs a command on the NVIDIA GPU. Hybrid hosts have nvidia-offload, which
# also lifts the offloadOnly restrictions (EGL and Vulkan limited to the iGPU).
gpu () {
    if command -v nvidia-offload >/dev/null; then
        nvidia-offload "$@"
    else
        __NV_PRIME_RENDER_OFFLOAD=1 \
        __GLX_VENDOR_LIBRARY_NAME=nvidia \
        "$@"
    fi
}

eval "$(direnv hook bash)"
