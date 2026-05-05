#!/bin/bash


REMINDER_INTERVAL=7 # days
REMINDER=$(cat <<REMINDER
	this reminder is shown, when not issuing any commands for $REMINDER_INTERVAL days
	and can be disabled via running: "öreminders"

	typing "ööö" updates the whole system
	typing "öä xyz" searches for an officially supported app by the name "xyz"
	typing "öäå xyz" searches for any (also unofficially supported) app by the name "xyz"
	typing "öö x1 x2 x3" installs the apps "x1", "x2", "x3"
	typing "ör xyz" removes the application "xyz"
REMINDER
)


last=$(stat -c %Y ~/.bash_history)
now=$(date +%s)

if [ "${last:-0}" -lt $((now - REMINDER_INTERVAL*24*60*60)) ]; then
	echo "$REMINDER"
fi
