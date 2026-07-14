#!/bin/bash

set -Eeuo pipefail

declare -A MOUNTS=(
    [etcd]=/var/lib/k0s/etcd
    [logs1]=/var/log/calico
    [logs2]=/var/log/pods
    [logs3]=/var/log/containers
)

__mount() {
    local LBL=k0s_$1
    local DEV=$(blkid -L $LBL 2>/dev/null)
    local MNT=${MOUNTS[$1]}

    if ! mountpoint -q $MNT; then
        if [ -z "$DEV" ]; then
            DEV=$(zramctl -f -s $2)
            mkfs.ext4 -q -L $LBL $DEV
            mkdir -p $MNT || true
        fi

        mount $DEV $MNT
    fi

    __sync $1
}

__umount() {
    __sync $1 reversed

    local MNT=${MOUNTS[$1]}

    umount $MNT
}

__sync() {
    local MNT=${MOUNTS[$1]}
    local BAK=/var/lib/k0s-zram$MNT
    local DIRS=($BAK/ $MNT/)

    mkdir -p $BAK || true

    [ $# -gt 1 ] && DIRS=($MNT/ $BAK/)

    rsync -a --exclude='lost+found' --delete-after ${DIRS[@]}
    sync
}

case "$1" in
    -m|--mount)
        __mount etcd 512M
        __mount logs1 64M
        __mount logs2 128M
        __mount logs3 512M
    ;;

    -u|--umount)
        __umount etcd
        __umount logs1
        __umount logs2
        __umount logs3
    ;;
esac
