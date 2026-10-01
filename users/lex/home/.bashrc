# (Local: user:path$ | SSH: user@host:path$)
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
  export PS1='\[\033[38;5;212m\]\u@\h\[\033[38;5;241m\]:\[\033[38;5;141m\]\w\[\033[38;5;212m\]\$\[\033[0m\] '
else
  export PS1='\[\033[38;5;141m\]\u\[\033[38;5;241m\]:\[\033[38;5;84m\]\w\[\033[38;5;212m\]\$\[\033[0m\] '
fi

source "{{pkgs.bash-preexec}}/share/bash/bash-preexec.sh"
eval "$(atuin init bash --disable-up-arrow)"
alias history="atuin history list"
alias kilo="kilocode"
