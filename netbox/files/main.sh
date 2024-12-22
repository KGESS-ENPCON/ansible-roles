#!/bin/bash

# Bash script for a default Netbox Setup
# https://github.com/netbox-community/netbox

# Password
DBPASSWORD=$(openssl rand -base64 25)

# PostgreSQL
sudo apt update
sudo apt install -y postgresql
psql -V

sudo -u postgres psql <<'EOF'

CREATE DATABASE netbox;
CREATE USER netbox WITH PASSWORD '$DBPASSWORD';
ALTER DATABASE netbox OWNER TO netbox;
-- the next two commands are needed on PostgreSQL 15 and later
\connect netbox;
GRANT CREATE ON SCHEMA public TO netbox;
\q
EOF

echo 'Make sure the postgresql server is only listening on localhost'

# Redis
sudo apt install -y redis-server
redis-server -v
echo 'You may wish to modify the Redis configuration at /etc/redis.conf or /etc/redis/redis.conf however in most cases the default configuration is sufficient'

redis-cli ping
echo 'Make sure the redis server is only listening on localhost'


# Netbox
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev git
python3 -V

sudo mkdir -p /opt/netbox/
cd /opt/netbox/

sudo git clone -b master --depth 1 https://github.com/netbox-community/netbox.git .

sudo adduser --system --group netbox
sudo chown --recursive netbox /opt/netbox/netbox/media/
sudo chown --recursive netbox /opt/netbox/netbox/reports/
sudo chown --recursive netbox /opt/netbox/netbox/scripts/

cd /opt/netbox/netbox/netbox/
sudo cp configuration_example.py configuration.py

SECRETKEYNETBOX=$(python3 ../generate_secret_key.py)
sudo vim configuration.py

sudo /opt/netbox/upgrade.sh

# Create Admin user
source /opt/netbox/venv/bin/activate
cd /opt/netbox/netbox
python3 manage.py createsuperuser


sudo ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

# Gunicorn
sudo cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py
sudo cp -v /opt/netbox/contrib/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now netbox netbox-rq

# HTTP server
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/netbox.key \
-out /etc/ssl/certs/netbox.crt

sudo apt install -y nginx
sudo cp /opt/netbox/contrib/nginx.conf /etc/nginx/sites-available/netbox
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/netbox /etc/nginx/sites-enabled/netbox
sudo systemctl restart nginx
