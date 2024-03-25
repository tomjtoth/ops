#tomjtoth

if [ "$(uname -o)" ==  "Android" ] \
&& [ $(tty) = "/dev/pts/0" ]
then
	pkill nginx
	pkill sshd
fi

