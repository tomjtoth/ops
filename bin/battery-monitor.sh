#!/bin/bash


if [[ ! -v CRIT_BAT_LEVEL  ||  ! -v CRIT_BAT_COMMAND  ||  ! -v PATH_TO_BAT ]]
then
	echo "example usage:
	PATH_TO_BAT=/sys/class/power_supply/BAT0 \\
	CRIT_BAT_LEVEL=10 \\
	CRIT_BAT_COMMAND=\"systemctl -i suspend\" \\
	$(basename $0)"
	exit 1
fi

while true; do
	CURR=($(cat "${PATH_TO_BAT}"/{capacity,status}))

	if [[ ${CURR[0]} -le $CRIT_BAT_LEVEL && "${CURR[1]}" != "Charging" ]]; then
		echo "${CURR[1]} at ${CURR[0]}% executing: \"$CRIT_BAT_COMMAND\""
		$CRIT_BAT_COMMAND
	fi

	sleep 1m
done
