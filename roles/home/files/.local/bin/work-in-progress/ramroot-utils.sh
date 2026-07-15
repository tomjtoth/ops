#!/bin/bash

function abort() {
    echo "$@"
    exit 1
}

usage="
usage: $(basename "$0") [-m] [-u] [-s FOLDER]

OPTIONS:
    -a  | --all                 combination of -m -sb -s -u
    -h  | --help                show this menu
    -m  | --mount               mount REAL_ROOT on /mnt
    -p  | --poweroff            poweroff host in the end
    -s  | --sync                rsync FOLDER
    -sb | --stop-boinc          systemctl stop boinc
    -u  | --umount              umount /mnt
"

while [ $# -gt 0 ]; do
    case "$1" in
        -a|--all)
            MOUNT=1
            STOP_BOINC=1
            SYNC_BOINC=1
            UMOUNT=1
            ;;

        -m|--mount) MOUNT=1 ;;
        -u|--umount) UMOUNT=1 ;;
            
        -s|--sync)
            shift
            SYNC="$1"
            ;;
            
        (-sb|--stop-boinc) STOP_BOINC=1 ;;
        (-p|--poweroff) POWEROFF=1 ;;
        (-h|--help) PRINT_HELP=1 ;;
        (*) UNKNOWN_FLAGS+=("$1") ;;
    esac
    shift
done


# abort if unknown flags present
if [ ${#UNKNOWN_FLAGS[@]} -gt 0 ]; then
    abort "unknown flags: ${UNKNOWN_FLAGS[*]}"
fi


if [ -v PRINT_HELP ]; then
    printf '%s' "$usage"
    exit 0
fi

# this is hard-coded for the 2.5" HDD case atm
ROOT_UUID=5b7fab93-08ee-4704-a37c-22924826e2eb #$(grep -Po '(?<=#UUID=)[a-f\d-]+(?=\s+\/\s+)' /etc/fstab)
REAL_ROOT=/dev/disk/by-uuid/$ROOT_UUID
[ ! -b "$REAL_ROOT" ] && abort \
    "'$REAL_ROOT' is not a blockdevice," \
    "this must be run from ramroot"



if [ -v MOUNT ]; then
    mountpoint /mnt \
        && abort "xyz is already mounted on /mnt"
    
    mount "$REAL_ROOT" /mnt \
        || abort "failed to mount $REAL_ROOT on /mnt"
fi


if [ -v STOP_BOINC ]; then
    systemctl stop boinc-client \
        || abort "failed to stop boinc-client"

    # this might be unnecessary...
    # until [ "$(ps -u boinc --no-headers | wc -l)" -eq 0 ]; do
    # 	sleep 0.1
    # done
fi


if [ -v SYNC_BOINC ]; then
    rsync -a --progress --inplace --delete-after --stats \
    /var/lib/boinc/ /mnt/var/lib/boinc

    # wait for filesystem to sync (USB thimbdrives take several minutes)
    sync
fi


if [ -v UMOUNT ]; then
    umount /mnt \
        || abort "failed to umount /mnt"
fi

[ -v POWEROFF ] && poweroff
