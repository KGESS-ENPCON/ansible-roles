#!/bin/bash

# Place this script in /etc/cron.daily/netbox-maintain.sh
# sudo vim /etc/cron.daily/netbox-maintain.sh
# sudo chmod a+x /etc/cron.daily/netbox-maintain.sh

sudo apt update
PGBACKUPDATETIME=$(date --utc +"%Y-%m-%d-%H%M%S")
sudo -u postgres pg_dump -C -f /opt/netbox-backup/pgdump-$PGBACKUPDATETIME.sql netbox
cd /opt/netbox/
sudo git pull
sudo apt full-upgrade -y
sudo /opt/netbox/upgrade.sh
sudo systemctl restart netbox netbox-rq
sudo systemctl restart nginx
sudo shutdown -r now
