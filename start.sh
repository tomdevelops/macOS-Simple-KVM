#!/bin/bash

# ssh connnect
# ssh user@localhost -p 5555

HEADLESS=0
USB_PCI_PASSTROUGH=1
USB_PCI_ADDRESS="0000:00:1a.0"
SYSTEM_DISK="MyDisk.qcow2"
CPUS=6
MEM="4G"

OSK="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
VMDIR=$PWD
OVMF=$VMDIR/firmware

MOREARGS=()

function addUsbPciController {
    modprobe vfio-pci
    echo "$USB_PCI_ADDRESS" > /sys/bus/pci/drivers/ehci-pci/unbind
    echo "$USB_PCI_ADDRESS" > /sys/bus/pci/drivers/vfio-pci/bind
}

function runvm {
    [[ "$HEADLESS" = "1" ]] && {
        MOREARGS+=(-nographic -vnc :0 -k en-us)
    }

    [[ "$USB_PCI_PASSTROUGH" = "1" ]] && {
        MOREARGS+=(-device vfio-pci,host=00:1a.0,bus=pcie.0,addr=1c.0)
    }

    qemu-system-x86_64 \
        -enable-kvm \
        -m $MEM \
        -machine q35,accel=kvm \
        -smp $CPUS \
        -cpu Penryn,vendor=GenuineIntel,kvm=on,+sse3,+sse4.2,+aes,+xsave,+avx,+xsaveopt,+xsavec,+xgetbv1,+avx2,+bmi2,+smep,+bmi1,+fma,+movbe,+invtsc \
        -device isa-applesmc,osk="$OSK" \
        -smbios type=2 \
        -drive if=pflash,format=raw,readonly,file="$OVMF/OVMF_CODE.fd" \
        -drive if=pflash,format=raw,file="$OVMF/OVMF_VARS-1024x768.fd" \
        -vga qxl \
        -usb -device usb-kbd -device usb-tablet \
        -device e1000-82545em,netdev=net0,mac=52:54:00:0e:0d:20 \
        -netdev user,id=net0,hostfwd=tcp::5555-:22 \
        -device ich9-ahci,id=sata \
        -drive id=ESP,if=none,format=qcow2,file=ESP.qcow2 \
        -device ide-hd,bus=sata.2,drive=ESP \
        -drive id=InstallMedia,format=raw,if=none,file=BaseSystem.img \
        -device ide-hd,bus=sata.3,drive=InstallMedia \
        -drive id=SystemDisk,if=none,file="${SYSTEM_DISK}" \
        -device ide-hd,bus=sata.4,drive=SystemDisk \
        "${MOREARGS[@]}"
}

function removeUsbPciController {
    # make devices usable again to the host
    echo "$USB_PCI_ADDRESS" > /sys/bus/pci/drivers/vfio-pci/unbind
    echo "$USB_PCI_ADDRESS" > /sys/bus/pci/drivers/ehci-pci/bind
}

#  main

[[ "$USB_PCI_PASSTROUGH" = "1" ]] && {
    addUsbPciController
}

runvm

[[ "$USB_PCI_PASSTROUGH" = "1" ]] && {
    removeUsbPciController
}

exit 0