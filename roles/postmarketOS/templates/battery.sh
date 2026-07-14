#!/bin/bash


INFO="{{ pathToBattery | default('/sys/class/power_supply/qcom-battery/uevent')}}"

read STATUS CURRENT CAPACITY <<< $(\
    grep 'CURRENT_NOW\|CAPACITY\|STATUS' "$INFO" | \
    cut -d'=' -f 2 | tr '\n' ' '\
)

printf '\n\tBattery is %s by %dµA at %d%%\n\n' ${STATUS,,} $CURRENT $CAPACITY
