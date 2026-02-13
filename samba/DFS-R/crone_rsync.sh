### Crone + Rsync  One way Replication, nano /usr/local/bin/sysvol-sync-from-dc01.sh (on DC02):

 
#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH
echo "Starting sysvol sync at $(date)" >> /tmp/sysvol-sync-debug.log
rsync -XAavz -e 'ssh -p 4193' --delete-after DC01:/usr/local/samba/var/locks/sysvol/ /usr/local/samba/var/locks/sysvol/ >> /tmp/sysvol-sync-debug.log 2>&1
rsync -XAavz -e 'ssh -p 4193' --delete-after DC01:/usr/local/samba/var/locks/sysvol/alprojects.tech/scripts/ /usr/local/samba/var/locks/sysvol/alprojects.tech/scripts/ >> /tmp/sysvol-sync-debug.log 2>&1
rsync -XAavz -e 'ssh -p 4193' --delete-after DC01:/usr/local/samba/var/locks/sysvol/alprojects.tech/SHARE/ /usr/local/samba/var/locks/sysvol/alprojects.tech/SHARE/ >> /tmp/sysvol-sync-debug.log 2>&1
rsync -XAavz -e 'ssh -p 4193' --delete-after DC01:/usr/local/samba/var/locks/sysvol/alprojects.tech/APPS/ /usr/local/samba/var/locks/sysvol/alprojects.tech/APPS/ >> /tmp/sysvol-sync-debug.log 2>&1
echo "Completed sysvol sync at $(date)" >> /tmp/sysvol-sync-debug.log
chmod +x /usr/local/bin/sysvol-sync-from-dc01.sh
mkdir -p /usr/local/samba/var/locks/sysvol/alprojects.tech/scripts/ **if not on DC02**
mkdir -p /usr/local/samba/var/locks/sysvol/alprojects.tech/SHARE/ **if not on DC02**
mkdir -p /usr/local/samba/var/locks/sysvol/alprojects.tech/APPS/ **if not on DC02**
chown -R root:root /usr/local/samba/var/locks/sysvol/ **if not done**
chmod -R 750 /usr/local/samba/var/locks/sysvol/ **both DCs should be locked down**
crontab -e
*/5 * * * * /usr/local/bin/sysvol-sync-from-dc01.sh >> /tmp/sysvol-sync.log 2>&1
/usr/local/bin/sysvol-sync-from-dc01.sh **if you have tmux its beneficial here**
tail -f /var/log/cron **toss this in a tmux split screen**
tail -f /var/log/syslog
systemctl restart samba
amba-tool fsmo show
