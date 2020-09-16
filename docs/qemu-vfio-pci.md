# setup

## setting up iommu. add kernel paramter intel_iommu=on or amd_iommu=on, add ids from corresponding iommu group
```
sudo vim /etc/default/grub
    ...
    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash iommu=pt intel_iommu=on vfio-pci.ids=8086:1c2d"
    ...

sudo update-grub
```

## print iommu groups
```
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
```

## example output for usb controller

```
IOMMU Group 4:
        00:1a.0 USB controller [0c03]: Intel Corporation 6 Series/C200 Series Chipset Family USB Enhanced Host Controller #2 [8086:1c2d] (rev 04)
```

## add option vfio.conf
```
sudo vim /etc/modprobe.d/vfio.conf

    options vfio-pci ids=8086:1c2d
```

## regenerate and reboot after

```
sudo update-initramfs -u -k all
```

# load or unload

## load vfio-pci kernel module and unbind + bind new driver

```
sudo -i
modprobe vfio-pci
echo '0000:00:1a.0' > /sys/bus/pci/drivers/ehci-pci/unbind
echo '0000:00:1a.0' > /sys/bus/pci/drivers/vfio-pci/bind
```

## check if vfio-pci kernel driver is used on 00:1a.0, should be kernel driver 'vfio-pci'
```
lspci -vnn
```

## add to qemu config, update host, bus and addr
```
-device vfio-pci,host=00:1a.0,bus=pcie.0,addr=1c.0
```

## or

<qemu:arg value='-device'/>
<qemu:arg value='vfio-pci,host=00:1a.0,bus=pcie.0,addr=1c.0'/>

## make devices usable again to the host to reset
```
echo '0000:00:1a.0' > /sys/bus/pci/drivers/vfio-pci/unbind
echo '0000:00:1a.0' > /sys/bus/pci/drivers/ehci-pci/bind
```