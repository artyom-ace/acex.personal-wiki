## APT cleaning
```bash
    sudo apt autoremove
    sudo apt autoclean
    sudo apt purge
    sudo apt clean
    
    sudo apt-get check ; sudo apt-get -f install
    
    sudo rm -v /var/log/*.gz                                                  - remove old compress log files from the system
    sudo find /var/log -type f -name "*.gz" -exec rm -v {} \;                 - remove old compress log files from /var/log and subfolders
    sudo find /var/log -type f -regex '.*\.\([0-9]\)$' -exec rm -v {} \;      - remove old log files end to .0 ... .9 from /var/log and subfolders
    sudo find /var/log -type f -regex '.*\.\([0-9]\)\.log$' -exec rm -v {} \; - remove old log files end to .0.log ... .9.log from /var/log and subfolders
    
    apt-get clean, 
    apt-get autoclean, 
    apt-get remove python3-setuptools, 
    dpkg --remove python3-setuptools, 
    apt-get install -f,
    dpkg -P --force-remove-reinstreq, 
    dpkg -P --force-all --force-remove-reinstreq 
    dpkg --purge
```


## KERNEL cleaning
### Check your current kernel  !!!DO NOT REMOVE THIS KERNEL!!!!
```bash
    uname -r
```
### List all installed kernels
```bash
    dpkg --list | grep linux-image 
    sudo apt-get purge linux-image-x.x.x-x-generic
```
### delete all dependies for this kernel
```bash
    apt-get purge `apt-cache pkgnames | fgrep 4.4.0-104`
    sudo update-grub2 
    reboot
```
### If apt-get isn't functioning because your /boot is at 100%, you'll need to clean out /boot first
```bash
    sudo dpkg --list 'linux-image*'|awk '{ if ($1=="ii") print $2}'|grep -v `uname -r`
    sudo rm -rf /boot/*-3.2.0-{23,45,49,51,52,53,54,55}-*
    sudo apt-get -f install
```
### If you run into an error that includes a line like "Internal Error: Could not find image (/boot/vmlinuz-3.2.0-56-generic)", then run the command
```bash
    sudo apt-get purge linux-image-3.2.0-56-generic -- (with your appropriate version)
```
### Finally
```bash
    sudo apt-get autoremove
```


## SNAP cleaning
### Shows installed snap packages
    ```bash
      snap list --all
    ```
### Remove disabled (unused) snap packages
    ```bash
      LANG=C snap list --all | while read snapname ver rev trk pub notes; do if [[ $notes = *disabled* ]]; then sudo snap remove "$snapname" --revision="$rev"; fi; done
    ```
### Free space by removing snap's cache
    ```bash
        sudo du -sh /var/lib/snapd/cache/                  # Get used space
        sudo find /var/lib/snapd/cache/ -exec rm -v {} \;  # Remove cache
    ```
