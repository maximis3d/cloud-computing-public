#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Wait for apt to be fully ready
echo "⏳ Waiting for apt to unlock..."
while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
  sleep 1
done

echo "📦 Updating packages..."
sudo apt-get update -y

echo "📦 Installing packages..."
sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql unzip curl

echo "🚀 Enabling and starting services..."
sudo systemctl enable --now apache2 || echo "Apache2 failed to enable/start"
sudo systemctl enable --now mysql || echo "MySQL failed to enable/start"

echo "🧱 Configuring firewall..."
sudo ufw allow OpenSSH || true
sudo ufw allow 'Apache Full' || true
sudo ufw --force enable || true

# Download and deploy code
TEMP_DIR="/tmp/github-zip"
ZIP_URL="https://raw.githubusercontent.com/maximis3d/cloud-computing-public/main/cloud-computing.zip"

mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "⬇️ Downloading project ZIP..."
curl -L "$ZIP_URL" -o cloud-computing.zip

mkdir -p cloud-computing
unzip cloud-computing.zip -d cloud-computing

echo "🧹 Cleaning /var/www/html..."
sudo rm -rf /var/www/html/*
sudo cp -r ./cloud-computing/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html

echo "✅ Deployment complete. Visit: http://$(hostname -I | awk '{print $1}')"
