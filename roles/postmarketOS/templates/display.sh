#!/bin/bash

FILE="{{ pathToBlank | default('/sys/class/graphics/fb0/blank') }}"

if [[ "$1" =~ [01] ]]; then
    STATE=$1
else
    STATE=$(cat "$FILE")

    if [[ ! $STATE =~ [01] ]]; then
        STATE=0
    fi
fi

echo $((1 - STATE)) | sudo tee "$FILE" > /dev/null
