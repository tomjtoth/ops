
# shellcheck disable=SC2139
alias {é,ö}top="htop -F 'mega|onedrive|python'"
alias {é,ö}s="sudo -E -s"
alias {é,ö}m=mindenes.py
alias {é,ö}p='ping 1.1.1.1'

alias zzz='z() {
	[ -n "$1" ] && \
		echo "going to suspend in $1" && \
		sleep $1
	#playerctl pause
	#swaylock -f -c 000000
	systemctl -i suspend
	unset -f z
}
z'

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

# bluetooth devices
alias {é,ö}bt='f(){
	if [ "$1" == "off" ]; then
		bluetoothctl power off
		return 0
	fi

	local -A devices=(
		[lp40]=63:E8:A9:38:B0:2D
		[ht38]=E0:C8:14:B6:B5:21
	)

	local dev=${1:-lp40}
	if [ -z "${devices[${dev}]}" ]; then
		echo "no such device as $dev"
		return 0
	fi

	bluetoothctl power on
	bluetoothctl connect ${devices[${dev}]}

	unset -f f
}
f'

# systemctl
alias {é,ö}ss="sudo systemctl"
alias {é,ö}ssdr="sudo systemctl daemon-reload"
alias {é,ö}su="systemctl --user"
alias {é,ö}sudr="systemctl --user daemon-reload"


# Helsinging Yliopistolla
alias {é,ö}hy-home="smbclient //home8.ad.helsinki.fi/t/tjtoth -U 'ATKK/tjtoth'"


# if we are on Arch Linux
if [ -f /usr/bin/pacman ]; then
	if [ -f /usr/bin/pacaur ]; then
		AUR="pacaur"
	elif [ -f /usr/bin/paru ]; then
		AUR="paru"
	else
		AUR="pacman"
	fi
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
	alias éáű="$AUR -Ss"
	alias {é,ö}fix="sudo pacman-key --refresh-keys"
	
# if we are on a debian derivative
elif [ -f /usr/bin/apt ]; then
	INSTALL="sudo apt update && sudo apt install"
	REMOVE="sudo apt-get purge"
	SEARCH="apt search"
	INFO="apt show"
	LIST="dpkg-query -L"
	UPDATE="sudo apt autoremove && sudo apt update && sudo apt full-upgrade"
	
	alias {é,ö}u='sudo apt install'
	
# if we are on Android/Termux
elif [ -f /data/data/com.termux/files/usr/bin/pkg ]; then
	INSTALL="pkg install"
	REMOVE="pkg uninstall"
	SEARCH="pkg search"
	LIST="pkg files"
	UPDATE="pkg upgrade"
fi

alias {éá,öä}="$SEARCH"
alias {é,ö}i="$INFO"
alias {é,ö}l="$LIST"
alias {éé,öö}="$INSTALL"
alias {é,ö}r="$REMOVE"

alias {ééé,ööö}="$UPDATE"

alias {ééé,ööö}r="$UPDATE && systemctl -i reboot"
alias {ééé,ööö}p="$UPDATE && systemctl -i poweroff"
alias {ééé,ööö}z="$UPDATE && systemctl -i suspend"



: <<'SCRAP'

alias {é,ö}dload='bash ~/soft-hard-ware/linux/home/bin/conf-updater.sh; mmm.py --dconf-load'
alias {é,ö}ddump='mmm.py --dconf-dump'

TORSER=rk3328

alias {é,ö}rec='wf-recorder --audio=$(pactl list sources | grep -Po "(?<=Name: ).+")'

alias rtop1="sudo radeontop -b 0:1"
alias itop="sudo intel_gpu_top"
alias rprof="sudo radeon-profile"

alias {é,ö}h='h() {
[ "$(systemctl is-active sshd)" != "active" ] && \
	echo -e "\nsshd is not running, starting it now\n" && \
	sss start sshd

[ $# -lt 2 ] && echo "
invocation:
öh IP pSSH [ rSSH=rSSH ] [ lSSH=lSSH ] [ user=username ]
" && return

echo "
reverse SSH tunnel created
press CTRL+C to destroy it
"

local IP pSSH rSSH lSSH user
IP=$1
pSSH=$2
shift
shift
for i in "$@"; do
	eval $i # this is really dangerous, but flexible...
done

ssh -R ${rSSH:-60000}:localhost:${lSSH:-44422} -N -p ${pSSH} ${user:-guest}@${IP}

}
h'

alias {ö,é}share='s() {
	F="${1%.*}_$(date +%s).${1##*.}"
	mega-put "$1" "/shared/$F"
	LINK=$(mega-export -a "/shared/$F" | awk '\''{print $3}'\'')
	wl-copy "$LINK"
	printf "\nthis link is copied to your clipboard:\n\t%s\n\n" "$LINK"
	unset -f s
}
s'

alias {é,ö}hs='hs() {
	ssh root@localhost -p ${1:-60000} -i ~/.ssh/id_ed25519_remotehelp
	unset -f hs
}
hs'

alias tt='echo -e "
currently active transfers:
"
ps -C ssh -o args | grep -Po "append.+data\/download\/\K.+"
echo'
alias tl="minden.sh tl $TORSER"
alias tg="minden.sh tg $TORSER"
alias td="minden.sh td $TORSER"


alias doom_sw="gzdoom ~/downloads/Xim-StarWars-v2.8.2/Xim-StarWars-v2.8.2.pk3"
alias win32="WINEARCH=win32 WINEPREFIX=~/.wine32bit wine"

alias {é,ö}_ig2="MESA_GL_VERSION_OVERRIDE=3.3 MESA_GLSL_VERSION_OVERRIDE=330 wine ig2.exe"
alias {é,ö}_openmw_cs="env -u WAYLAND_DISPLAY openmw-cs"
alias code='code --enable-proposed-api ms-toolsai.jupyter --enable-proposed-api ms-python.python'
alias {é,ö}zyxel="sshpass -f ~/documents/vmg3625-t20a.pass ssh -oHostKeyAlgorithms=+ssh-rsa admin@home -p 44422"
alias {é,ö}saldo='CURR="$(pwd)";cd ~/.local/bin/projects/saldo-rs; target/debug/saldo; cd "$CURR"'


alias mmnt='
manual_mounter() {
	if [[ "$@" == *-u* ]]; then
		sudo umount ~/mnt
	else
		[ ! -d ~/mnt ] && mkdir ~/mnt
		sudo mount -o ro,loop "$1"  ~/mnt
	fi
	unset -f manual_mounter
}
manual_mounter'

alias {é,ö}d='d() {
	bg
	disown -h %$1
	unset -f d
}
d'

SCRAP

