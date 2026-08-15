#!/bin/bash

set -Eeux

SCRIPT_DIR=$(realpath "$0")
SCRIPT_DIR=${SCRIPT_DIR%/*}

VM_DIR="$HOME/.qemu-VMs/${VM:-win11}"
VM_DISK="${VM_DIR}/disk"
VM_INPUT="-usb -device usb-tablet"
VM_VIDEO="-vga vmware -vnc 127.0.0.1:0"
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

main(){
    swtpm socket \
        --tpm2 \
        --tpmstate "dir=$TPM_DIR" \
        --ctrl "type=unixio,path=$TPM_DIR/swtpm-sock" &

    ${SUDO:-} qemu-system-x86_64 \
        -m 6G \
        -cpu host,kvm=off,hv-vendor-id=GenuineIntel \
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
        $@

    pkill swtpm
    rm -rf $TPM_DIR
}

case "${1:-}" in 
    install)
        [ ! -d "$VM_DIR" ] && mkdir -p "$VM_DIR"

        qemu-img create -f qcow2 "$VM_DISK" 500G

        main -nic none -cdrom $2 -boot order=d
        ;;

    # based on https://github.com/cy4n1c/single-intel-gpu-passthrough
    igpu)
        source $SCRIPT_DIR/qemu-igpu

        if [ "${2:-}" = sriov ]; then
            sriov
            main
        else
            unbind
            main
            rebind
        fi
        ;;

    revert)
        set +Eeu
        source $SCRIPT_DIR/qemu-igpu
        rebind
        ;;

    *) main ;;
esac
