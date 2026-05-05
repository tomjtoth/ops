# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\[\e[92;1m\]\u\[\e[0m\]@\[\e[91;1m\]\H\[\e[0m\] \[\e[94;1m\]\W\[\e[0m\]]\$ '

shopt -s checkwinsize

# ignore dupes and lines starting with a space
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

[ -f ~/.bash_aliases ] && . ~/.bash_aliases

if [ -d ~/.bash_aliases.d ]; then
    for aliases in ~/.bash_aliases.d/*; do
        source "$aliases"
    done
fi
