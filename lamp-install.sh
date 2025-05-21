#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

MYSQL_ROOT_PASSWORD='NewRootPassword123!'
PROJECTS_DB_NAME='projects'

echo "⏳ Waiting for apt to unlock..."
while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done

echo "📦 Updating packages..."
sudo apt-get update -y

echo "📦 Installing packages..."
sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql unzip curl

echo "🚀 Enabling and starting services..."
sudo systemctl enable --now apache2 || echo "Apache2 failed to enable/start"
sudo systemctl enable --now mysql || echo "MySQL failed to enable/start"

echo "🔐 Securing MySQL root user and removing test DBs..."
sudo mysql <<-EOF
  ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
  DELETE FROM mysql.user WHERE User='';
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
EOF

echo "🗄️ Creating database for projects app..."
sudo mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOF
  CREATE DATABASE IF NOT EXISTS \`${PROJECTS_DB_NAME}\`;
EOF

echo "⬇️ Downloading project ZIP..."
TEMP_DIR="/tmp/github-zip"
ZIP_URL="https://raw.githubusercontent.com/maximis3d/cloud-computing-public/main/cloud-computing.zip"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
curl -L "$ZIP_URL" -o cloud-computing.zip

mkdir -p cloud-computing
unzip -o cloud-computing.zip -d cloud-computing

echo "🧹 Importing SQL schema..."
sudo mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" "${PROJECTS_DB_NAME}" < ./cloud-computing/sql/projects.sql

echo "🧹 Cleaning /var/www/html and deploying app..."
sudo rm -rf /var/www/html/*
sudo cp -r ./cloud-computing/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html

echo "🧱 Configuring firewall..."
sudo ufw allow OpenSSH || true
sudo ufw allow 'Apache Full' || true
sudo ufw --force enable || true

echo "✅ Deployment complete. Visit: http://$(hostname -I | awk '{print $1}')"
