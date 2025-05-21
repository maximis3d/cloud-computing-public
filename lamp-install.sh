#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

MYSQL_ROOT_PASSWORD='NewRootPassword123!'
PROJECTS_DB_NAME='projects'

while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done

sudo apt-get update -y

sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql unzip curl


sudo mysql <<-EOF
  ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
  DELETE FROM mysql.user WHERE User='';
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
EOF

sudo mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOF
  CREATE DATABASE IF NOT EXISTS \`${PROJECTS_DB_NAME}\`;
EOF

TEMP_DIR="/tmp/github-zip"
ZIP_URL="https://raw.githubusercontent.com/maximis3d/cloud-computing-public/main/cloud-computing.zip"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
curl -L "$ZIP_URL" -o cloud-computing.zip

mkdir -p cloud-computing
unzip -o cloud-computing.zip -d cloud-computing

sudo mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" "${PROJECTS_DB_NAME}" < ./cloud-computing/sql/projects.sql

sudo rm -rf /var/www/html/*
sudo cp -r ./cloud-computing/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html

sudo ufw allow OpenSSH || true
sudo ufw allow 'Apache Full' || true
sudo ufw --force enable || true

