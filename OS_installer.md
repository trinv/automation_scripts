1. Language: English
2. Keyboard: U.S. English
3. Select storage device: Basic Storage Devices

4. Enter hostname
5. Set timezone: UTC
6. Enter root password
7. Configure partitions, use "Create custom layout".
    a. Remove all existing partitions
    b. Create a new partition
        i. Size: 512MB
        ii. File System: ext2
        iii. Mount Point: /boot
    c. Create a new volume group (LVM) for all spare space with name "vg"
    d. Create a new logical volume inside "vg"
        i. Name: tmp
        ii. Size: 4 GiB
        iii. File System: ext4/XFS
        iv. Mount Point: /tmp
    e. Create a new logical volume inside "vg"
        i. Name: root
        ii. Size: 30% * all free space
        iii. File System: ext4/XFS
        iv. Mount Point: /
    f. Create a new logical volume inside "vg"
        i. Name: swap
        ii. Size: 2 * RAM size
        iii. Mount Point / type: swap
    g. Create a new logical volume inside "vg"
        i. Name: data
        ii. Size: all free space
        iii. File System: ext4/XFS
        iv. Mount Point: /    
    h. Write changes
8. Configure Boot loader, install into /dev/sda
9. Select "Minimal" installation
10. Start installation process
11. Reboot the server when installation is finished