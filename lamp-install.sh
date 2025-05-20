#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql

sudo systemctl enable apache2
sudo systemctl start apache2
sudo systemctl enable mysql
sudo systemctl start mysql

sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'
sudo ufw --force enable

echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

echo "✅ LAMP stack installed. Visit: http://$(hostname -I | awk '{print $1}')/info.php"
