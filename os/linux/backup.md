### Rsync

- sync source to destination + old backups moved to 'old' + log
```bash
  /usr/bin/rsync -av --progress --delete user@0.0.0.0:/source/ /mnt/backup --backup --backup-dir=/mnt/backup/old/`date +%Y-%m-%d`/ >> /var/log/rsync/backup-`date +%Y-%m-%d`.log
```

- restore from backup only changed or deleted files
```bash
  /usr/bin/rsync -av --ignore-existing back_user@10.30.7.5:/mnt/backup/www/ /var/www/
```