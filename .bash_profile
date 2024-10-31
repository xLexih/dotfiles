#
# ~/.bash_profile
#

export PATH="$PATH:/usr/bin:/usr/bin/scp"
[ -f $ZSH/bin/zsh ] && exec $ZSH/bin/zsh -l
[[ -f ~/.bashrc ]] && . ~/.bashrc
