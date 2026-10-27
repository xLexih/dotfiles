# [user:path]$ locally, [user@host:path]$ over SSH. Colors are ANSI palette
# entries, so the prompt follows kitty's theme live: bright black (muted),
# magenta (accent), bright magenta (focus) and green. $PS1CUSTOM (set by
# directory integrations such as direnv) overrides both. direnv never exports
# PS1 itself, so re-apply PS1CUSTOM before every prompt.
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then # SSH
  PS1_DEFAULT='\[\033[90m\][\[\033[95m\]\u@\h\[\033[90m\]:\[\033[35m\]\w\[\033[90m\]]\[\033[95m\]\$\[\033[0m\] '
else # LOCAL
  PS1_DEFAULT='\[\033[90m\][\[\033[35m\]\u\[\033[90m\]:\[\033[32m\]\w\[\033[90m\]]\[\033[95m\]\$\[\033[0m\] '
fi

_ps1_sync() {
  PS1="${PS1CUSTOM:-$PS1_DEFAULT}"
}
_ps1_sync
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }_ps1_sync"

source "{{pkgs.bash-preexec}}/share/bash/bash-preexec.sh"
eval "$(atuin init bash --disable-up-arrow)"
alias history="atuin history list"
alias kilo="kilocode"
