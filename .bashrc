#
# /etc/bash.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# this is done without the check for DISPLAY on armbian...
[[ $DISPLAY ]] && shopt -s checkwinsize

# ~/.bash_history
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

<<SKIP
PS1='[\u@\h \W]\$ '

case ${TERM} in
    xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
        PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
        ;;
    screen*)
        PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
        ;;
esac
SKIP

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -r /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -r /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# retired
[ -f ~/.user_pass ] && cat ~/.user_pass

GITHUB=~/.config/.tomjtoth
if [ -d $GITHUB ]; then
    LAST=.last_github_sync
    if [ ! -f $GITHUB/$LAST ] \
    || [ $(<$GITHUB/$LAST) -lt $(($(date +%s)-60*60*24)) ]; then
        echo -e "\n\tupdating config files\n"
        git -C $GITHUB stash
        git -C $GITHUB pull
        echo
        date +%s > $GITHUB/$LAST
        . ~/.bash_aliases
    fi
fi

[ ! -v WAYLAND_DISPLAY ] && echo "

  gdm is running on Xorg

"

