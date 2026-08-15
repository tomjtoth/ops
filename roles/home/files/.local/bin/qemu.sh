#!/bin/bash

set -Eeu

# as of 28.21.2024 shared folder support and GPU passthrough not working, win11-24H2 installed just fine
# setting up samba requires limiting it to localhost
# 13.8.2026 Code:43 on the VM, prolly needs intel_gop

VM_DIR="$HOME/.qemu-VMs/${VM_OS:-win11}"
VM_DISK="${VM_DIR}/disk"
VM_INPUT="-usb -device usb-tablet"
# VM_VIDEO="-vga qxl"
VM_VIDEO="-vga vmware -vnc 127.0.0.1:0"

# dumped host bios: sudo flashrom -p internal -r host_bios.bin
# uefitool host_bios.bin # CTRL+F IntelGopDriver -> PE32 image -> Extract body -> below file
INTEL_GOP=~/intel_gop.efi

SUDO=

if [ -n "${VFIO_PCI:-}" ]; then
    SUDO=sudo

    if [ ! -d /dev/kvmfr0 ]; then
        sudo modprobe kvmfr static_size_mb=32
        sudo chown root:kvm /dev/kvmfr0
        sudo chmod 0660 /dev/kvmfr0

        echo 0 | sudo tee /sys/bus/pci/devices/0000:00:02.0/sriov_drivers_autoprobe
        echo 1 | sudo tee /sys/bus/pci/devices/0000:00:02.0/sriov_numvfs

        lspci -nnk -s 00:02

        sudo modprobe vfio-pci
        echo vfio-pci | sudo tee /sys/bus/pci/devices/0000:00:02.1/driver_override
        echo 0000:00:02.1 | sudo tee /sys/bus/pci/drivers_probe

        lspci -nnk -s 00:02
    fi


    VM_VIDEO="
        -device ramfb -vga none -vnc 0.0.0.0:0
        -device vfio-pci,host=${VFIO_PCI}
        -object memory-backend-file,id=looking-glass,mem-path=/dev/kvmfr0,size=32M,share=yes
        -device ivshmem-plain,memdev=looking-glass
    "
fi

VM_AUDIO="-audiodev pipewire,id=snd0 -device ich9-intel-hda"

UEFI_FLAGS="
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd
    -drive if=pflash,format=raw,file=${VM_DIR}/.OVMF_VARS.4m.fd
"

TPM_DIR=$(mktemp -d)
TPM_FLAGS="
    -chardev socket,id=chrtpm,path=${TPM_DIR}/swtpm-sock
    -tpmdev emulator,id=tpm0,chardev=chrtpm
    -device tpm-tis,tpmdev=tpm0
"

if [[ "${1:-not}" == "install" ]]; then
    cp /usr/share/edk2/x64/OVMF_VARS.4m.fd \
        "${VM_DIR}/.OVMF_VARS.4m.fd"

    qemu-img create -f qcow2 "$VM_DISK" 500G

    INSTALL_FLAGS="-nic none -cdrom $2 -boot order=d"
fi

$SUDO swtpm socket \
    --tpm2 \
    --tpmstate "dir=$TPM_DIR" \
    --ctrl "type=unixio,path=$TPM_DIR/swtpm-sock" &

$SUDO qemu-system-x86_64 \
    -m 6G \
    -cpu host,hv-vendor-id=GenuineIntel \
    -smp 4 \
    -machine q35 \
    -drive file="$VM_DISK",format=qcow2 \
    -enable-kvm \
    -rtc base=localtime \
    $TPM_FLAGS \
    $UEFI_FLAGS \
    $VM_INPUT \
    `# $VM_AUDIO` \
    $VM_VIDEO \
    ${INSTALL_FLAGS:-}

$SUDO pkill swtpm
rm -rf $TPM_DIR
