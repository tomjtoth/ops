#!/bin/bash

set -Eeux

SCRIPT_DIR=$(realpath "$0")
SCRIPT_DIR=${SCRIPT_DIR%/*}

VM_DIR="$HOME/qemu-VMs"
[ ! -d "$VM_DIR" ] && mkdir -p "${VM_DIR}"

VM=${VM:-win11}
if [[ $VM = */* ]]; then
    echo "VM should be a simple prefix for .qcow in $VM_DIR, not a path"
    exit 1
fi

VM="$VM_DIR/$VM"
VM_DISK="${VM}.qcow"
VM_UEFI_VARS="${VM}.OVMF_VARS.4m.fd"

VM_INPUT="-usb -device usb-tablet"

VM_VIDEO="-vga virtio -display gtk,zoom-to-fit=on"
VM_AUDIO="-audiodev pipewire,id=snd0 -device ich9-intel-hda"

VM_SHARED_FOLDER="-nic user,smb=$HOME/Downloads"

# Spoof host CPU while disabling hypervisor bits and KVM paravirtualization features
VM_CPU="host,kvm=off,-hypervisor,hv-vendor-id=GenuineIntel,kvm-pv-eoi=off,kvm-pv-ipi=off,kvm-asyncpf=off,kvm-steal-time=off"

# required for PSpice-for-TI installation
VM_SMBIOS=(
    -smbios "type=0,vendor=American Megatrends International LLC.,version=F.30,date=04/15/2024"
    -smbios "type=1,manufacturer=ASUSTeK COMPUTER INC.,product=ROG STRIX Z790-E GAMING WIFI,version=1.0,serial=L1N0CV01G37424X,uuid=00010203-0405-0607-0809-0a0b0c0d0e0f,sku=SKU_777,family=ROG_STRIX"
)

UEFI_FLAGS="
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd
    -drive if=pflash,format=raw,file=$VM_UEFI_VARS
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
        -cpu $VM_CPU \
        -smp $(nproc) \
        -machine q35 \
        -drive file="$VM_DISK",format=qcow2 \
        -enable-kvm \
        -rtc base=localtime,clock=host \
        "${VM_SMBIOS[@]}" \
        $TPM_FLAGS \
        $UEFI_FLAGS \
        $VM_INPUT \
        `# $VM_AUDIO` \
        $VM_VIDEO \
        $VM_SHARED_FOLDER \
        "$@"

    pkill swtpm
    rm -rf $TPM_DIR
}

case "${1:-}" in 
    install)
        qemu-img create -f qcow2 "$VM_DISK" 500G
        cp /usr/share/edk2/x64/OVMF_VARS.4m.fd $VM_UEFI_VARS
        VM_SHARED_FOLDER=""

        main -nic none -cdrom "$2" -boot order=d
        ;;

    sr-iov|gvt-g|pt) source "$SCRIPT_DIR/qemu-igpu" ;&

    sr-iov) sriov; main;;

    gvt-g) gvt; main;;

    # based on https://github.com/cy4n1c/single-intel-gpu-passthrough
    pt) 
        if [ "${2:-}" = revert ]; then
            set +Eeu
            rebind
        else
            unbind; main; rebind
        fi
    ;;

    *) main ;;
esac
