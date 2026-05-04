# shellcheck disable=SC2142
# shellcheck disable=SC2139


# enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias ncdu='ncdu --color dark'
fi

alias {é,ö}s="sudo -E -s"
alias {é,ö}p='ping 1.1.1.1'
alias {é,ö}reminders='sed -i -E "s/^(source .+\/reminders.sh\)( 2>\/dev\/null)?)$/# \1/g" ~/.bashrc'

alias {é,ö}sleep='f() {
	[ -n "$1" ] && \
		echo "going to suspend in $1" && \
		sleep $1
	#playerctl pause
	#swaylock -f -c 000000
	systemctl -i suspend
	unset -f f
}
f'

alias {é,ö}ansible='f(){
	local path=~/Projects/IT/ops/ansible

	ansible-playbook -i "$path/hosts.ini" "$path/playbook.yml" $@

	unset -f f
}
f'

alias {é,ö}lz4='f(){
	tar cf - "$1" | lz4 -z --best > "${1%%/}.tar.lz4"
	unset -f f
}
f'

alias {é,ö}xz='f(){
	tar cf - "$1" | xz -z -9 > "${1%%/}.tar.xz"
	unset -f f
}
f'

alias {é,ö}tar='f(){
	tar cf "${1%/}.tar""$1"
	unset -f f
}
f'

alias {é,ö}dconf='f(){
	if [ "$1" == "load" ]; then
		if [ -f $2 ]; then
			dconf load / < "$2"
		fi
	else
		dconf dump /
	fi

	unset -f f
}
f'

# systemctl
alias {é,ö}ss="sudo systemctl"
alias {é,ö}ssdr="sudo systemctl daemon-reload"
alias {é,ö}su="systemctl --user"
alias {é,ö}sudr="systemctl --user daemon-reload"

# on Arch Linux
if [ -f /usr/bin/pacman ]; then
	if [ -f /usr/bin/pacaur ]; then
		AUR="pacaur"
	elif [ -f /usr/bin/paru ]; then
		AUR="paru"
	else
		AUR="pacman"
	fi
	# shellcheck disable=SC2016
	INSTALL='f() {
		[ $(( ($(date +%s) - \
			$(stat -c %Y /var/lib/pacman/sync/*.db \
			| sort | tail -n 1))/60/60 )) -ge 24 ] && \
			sudo pacman -Syy
		unset -f f
	}
	f && '$AUR' -S'
	REMOVE="sudo pacman -Rscn"
	SEARCH="pacman -Ss"
	INFO="$AUR -Si"
	LIST="pacman -Ql"
	UPDATE="$AUR -Syyu --noconfirm && sudo paccache -k 0 -r"

	alias {é,ö}u="sudo pacman -U --asdeps"
	alias {éáű,öäå}="$AUR -Ss"
	alias {é,ö}fix="sudo pacman-key --refresh-keys"

# on a debian derivative
elif [ -f /usr/bin/apt ]; then
	INSTALL="sudo apt update && sudo apt install"
	REMOVE="sudo apt-get purge"
	SEARCH="apt search"
	INFO="apt show"
	LIST="dpkg-query -L"
	UPDATE="sudo apt autoremove && sudo apt update && sudo apt full-upgrade"

# on Alpine
elif [ -f /sbin/apk ]; then
	INSTALL="sudo apk add"
	REMOVE="sudo apk del"
	SEARCH="apk search"
	INFO="apk info"
	LIST="apk info -L"
	UPDATE="sudo apk update && sudo apk upgrade"
fi

alias {éá,öä}="$SEARCH"
alias {é,ö}i="$INFO"
alias {é,ö}l="$LIST"
alias {éé,öö}="$INSTALL"
alias {é,ö}r="$REMOVE"

alias {ééé,ööö}="$UPDATE"

alias {ééé,ööö}r="$UPDATE && systemctl -i reboot"
alias {ééé,ööö}p="$UPDATE && systemctl -i poweroff"


# shellcheck disable=SC2139
alias {é,ö}boinc='boinctui -b localhost -p "$(cat /var/lib/boinc-client/gui_rpc_auth.cfg)"'

alias {é,ö}yt='f(){
	local mode=${2:-mp3}
	local FLAGS=" -x --audio-format mp3"
	if [ "$mode" == "best" ]; then
		FLAGS="-f '"'"'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"'"'"
	fi
	yt-dlp $FLAGS $1
	unset -f f
}
f'

alias {é,ö}bump='f(){
	# extract which one to bump
	[[ "$1" =~ .*(major|minor|patch)$ ]]
	local TRGT=${BASH_REMATCH[1]:-patch}

	if [ -f Cargo.toml ]; then
		cargo set-version --bump $TRGT
	elif [ -f package.json ]; then

		npm version \
			--commit-hooks false \
			--git-tag-version false \
			$TRGT

		else
		echo "  ERROR: unsupported project"
	fi
	unset -f f
}
f'

# Helsinging Yliopistolla
alias {é,ö}hy-home="smbclient //home8.ad.helsinki.fi/t/tjtoth -U 'ATKK/tjtoth'"
