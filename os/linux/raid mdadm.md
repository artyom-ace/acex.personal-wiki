### raid1 recovery /dev/sda

- check raid status
    ``` # cat /proc/mdstat ```
- check second bootloader
    ``` # dpkg-reconfigure grub-pc ```
- **!!! if "grub-install failure for /dev/sdb" !!!**
    remove all partitions /dev/sda from raid (sda1, sda2, sda3 ...)
    ```
    # mdadm /dev/md126 --fail /dev/sda1
    # mdadm /dev/md126 --remove /dev/sda1
    ```
- poweroff and replace disk
- check new disk
    ```
    # smartctl -i /dev/sda
    # fdisk -l | grep /dev/sda
    ```
- copy partition map from b to a
    ```
    # sfdisk -d /dev/sdb | sfdisk /dev/sda
    ```
- check partition map
    ```
    # fdisk -l
    ```
- add new disk to raid
    ```
    # mdadm /dev/md126 --add /dev/sda1
    ```
- check raid status
    ```
    # watch cat /proc/mdstat
    ```
- **!!! if "md127 : inactive sdb3[1](S)" !!!**
  - re-run this partition
      ```
      # mdadm --run /dev/md127
      mdadm: started array /dev/md/installrescue:43
      ```
  - add partition
      ```
      # mdadm /dev/md127 --add /dev/sda3
      mdadm: added /dev/sda3
      ```
- add new bootloader to sda
      ``` # dpkg-reconfigure grub-pc ```
