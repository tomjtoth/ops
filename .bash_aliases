# shellcheck disable=SC2139
alias {é,ö}top="htop -F 'mega|onedrive|python'"
alias éboinc='boinctui -b localhost -p "$(cat ~/gui_rpc_auth.cfg)"'
alias énmcli="nohup bash -c 'while true; do nmcli c up ttj; sleep 1h; done' &"
alias {é,ö}gpu='echo -e "\n\tTODO: implement single GPU passthrough for qemu\n"'

# WiP
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
	if [ -f package.json ]; then
		# extract which one to bump
		[[ "$1" =~ .*(major|minor|patch)$ ]]

		npm version \
			--commit-hooks false \
			--git-tag-version false \
			${BASH_REMATCH[1]:-patch}
	else
		echo "  ERROR: unsupported project"
		echo "  ERROR: ./package.json not found"
	fi
	unset -f f
}
f'

# Helsinging Yliopistolla
alias {é,ö}hy-home="smbclient //home8.ad.helsinki.fi/t/tjtoth -U 'ATKK/tjtoth'"

