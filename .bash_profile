#
# ~/.bash_profile
#

[ -f ~/.bashrc ] && . ~/.bashrc

#Android related config
if [ "$(uname -o)" ==  "Android" ]; then
	clear
	export HOSTNAME=$(< ~/.hostname)
	conf-update.py
	printf '\n  %s\n\n' \
		"your local IPv4 is: $(ip route get 1 | grep -Po '(?<=src )[\d\.]+')"
	
	if ! $(ps uax | grep -q 'sshd'); then
		sshd -p 44422
	fi
	
	<<-SKIP
	if ! $(ps uax | grep -q 'nginx: master process nginx$'); then
		nginx
	fi
	SKIP
	
else
	case $HOSTNAME in
        *)
            [ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"
			[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
            
            ;;&
            
		15-ab125no)
			export VDPAU_DRIVER=radeonsi
			export LIBVA_DRIVER_NAME=radeonsi
			;;&
		
		ebook820g4|switch3)
			export MOZ_USE_XINPUT2=1
			;;&
            
        rk3328)
            # simply stops doing the below
            ;;
		
		*)
			#export TERM=xterm-256color
			#export HOSTALIASES=~/.hosts
			export LANG=en_US.UTF-8
			export LC_MESSAGES=en_US.UTF-8

			
			for var in LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY \
				LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT \
				LC_IDENTIFICATION; do
				export $var=hu_HU.UTF-8
			done
			;;
	esac
fi


<<SKIP
#Distro specific config
if [ -f /etc/os-release ]; then
	DISTRO=$(cat /etc/os-release | grep -Poi '^id=\K.+')
	echo "you are running ${DISTRO}, additional measures will be taken later based on this info"
fi


#if it's a headless server
if [ -f /usr/bin/transmission-remote ] ; then
	minden.sh tl
	echo
	df -h
	echo
fi
SKIP


<<SWAY
if [ -z $DISPLAY ] \
&& [[ "$(tty)" =~ \/dev\/tty[1-3] ]] \
&& [ -f /bin/sway ] \
&& [ -f ~/.config/sway/config ]
then
	export PATH
	export _JAVA_AWT_WM_NONREPARENTING=1
	[ "$HOSTNAME" == "tv_machine" ] && sleep 5
	sway > ~/.sway.stdout 2>~/.sway.stderr
fi
SWAY
