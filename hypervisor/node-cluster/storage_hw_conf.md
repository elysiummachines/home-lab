### P440-HW-RAID 0 on both NODES

```sh
3X - 300GB SAS 10K 60$ (Model:EG0300JFCKA - SN: 6C364910K4) - Raid 0 (P440ar) > Strip Size = 128KB/128KB > Sectors =63 > Caching enabled  
2X 256GB m.SSD in Riad 1 this will ensure data is protected in cache in case something happens while moving data on the Raid 0 volumes 
Created a QEMU VM, Bios SeaBIOS, Machine Type q35 > created a 52GB partition for the VM > loaded  
Partition 1: 1MB, BIOS boot area - Partition 2: 300MB - FAT32, /boot/efi - Partition 3: 3GB, swap - Partition 4: 1GB, ext4, /boot - Partition 5: 52GB, XFS, / 
```
