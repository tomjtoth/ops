#!/bin/bash

# based on https://github.com/cy4n1c/single-intel-gpu-passthrough

BL_PATH=(
    /sys/class/backlight/intel_backlight/brightness 
    /tmp/qemu-igpu-pt-backlight
    /sys/class/backlight/intel_backlight/max_brightness 
)
BL_LEVEL=$(cat ${BL_PATH[0]} || cat ${BL_PATH[1]} || cat ${BL_PATH[2]})

set -Eeux

ids=($( lspci -nnkD | \
        grep "VGA compatible controller" -A 3 | \
        grep -oE '^\S+|8086:....'))

bind_tty() {
    for i in /sys/class/vtconsole/*/bind; do
        echo $1 | sudo tee "$i"
    done
}


unbind() {
    # store backlight level
    echo $BL_LEVEL > ${BL_PATH[1]}

    sudo systemctl stop display-manager.service
    bind_tty 0
    sudo modprobe -rv xe || true
    echo ${ids[0]} | sudo tee /sys/module/i915/drivers/pci:i915/unbind
    # killall pipewire || true

    sleep 2

    # sudo rmmod snd_sof
    sudo modprobe -rv i915

    # Load vfio
    sudo modprobe vfio-pci ids="${ids[1]}"

    lspci -nnkd ${ids[1]}
}

rebind() {
    sudo modprobe -rv  vfio_pci

    # modprobe snd_hda_intel
    sudo modprobe i915

    bind_tty 1

    sudo systemctl start display-manager.service

    # restore backlight level
    echo $BL_LEVEL | sudo tee ${BL_PATH[0]}
}

if [ "${1:-}" = "revert" ]; then
    set +Eeux
    rebind
	exit 0
fi

unbind

VFIO_PCI=0000:00:02.1 qemu.sh

rebind

