#!/bin/bash

# as of 28.21.2024 shared folder support and GPU passthrough not working, win11-24H2 installed just fine
# setting up samba requires limiting it to localhost

VM_DIR=~/qemu/${VM_OS:-win11}
VM_DISK="${VM_DIR}/disk"
VM_INPUT="-usb -device usb-tablet"
VM_VIDEO="-vga qxl"
VM_VIDEO="-vga vmware"
VM_AUDIO="-audiodev pipewire,id=snd0 -device ich9-intel-hda"

UEFI_FLAGS="
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd
    -drive if=pflash,format=raw,file=${VM_DIR}/.OVMF_VARS.4m.fd
"

TPM_DIR=${VM_DIR}/.tpm
TPM_FLAGS="
    -chardev socket,id=chrtpm,path=${TPM_DIR}/swtpm-sock
    -tpmdev emulator,id=tpm0,chardev=chrtpm
    -device tpm-tis,tpmdev=tpm0
"

if [[ "$1" == "install" ]]; then
    mkdir -p "${TPM_DIR}"
    cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "${VM_DIR}/.OVMF_VARS.4m.fd"
    
    qemu-img create -f qcow2 $VM_DISK 100G

    INSTALL_FLAGS="-nic none -cdrom $2 -boot order=d"
fi

# starting TPM2.0 emulation for win11
swtpm socket --tpm2 --tpmstate dir=${TPM_DIR} \
    --ctrl type=unixio,path=${TPM_DIR}/swtpm-sock &

TPM_PID=$!

qemu-system-x86_64 \
    -m 6G -cpu host -smp $(nproc) \
    -machine q35 \
    -drive file=${VM_DISK} \
    -enable-kvm \
    -rtc base=localtime \
    $TPM_FLAGS \
    $UEFI_FLAGS \
    $VM_INPUT \
    $VM_AUDIO \
    $VM_VIDEO \
    $INSTALL_FLAGS

# swtpm seems to be killed after qemu exits...
# kill $TPM_PID
