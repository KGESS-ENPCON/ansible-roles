#!/bin/bash
sudo apt update
sudo -u postgres pg_dump -C -f /opt/netbox-backup/pgdump.sql netbox
cd /opt/netbox/
sudo git pull
sudo apt full-upgrade -y
sudo /opt/netbox/upgrade.sh
sudo systemctl restart netbox netbox-rq
sudo systemctl restart nginx
sudo shutdown -r now
