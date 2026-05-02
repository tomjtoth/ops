# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\[\e[91;1m\]\u\[\e[0m\]@\[\e[92;1m\]\H\[\e[0m\] \W]\$ '

shopt -s checkwinsize

# ignore dupes and lines starting with a space
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# if ! shopt -oq posix; then
#   if [ -r /usr/share/bash-completion/bash_completion ]; then
#     . /usr/share/bash-completion/bash_completion
#   fi
# fi