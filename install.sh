#!/bin/bash
# =============================================================================
# LAMP Stack Installer for Ubuntu 22.04 LTS
# Apache2 + PHP + MySQL 8.0 + Useful tools
# Run as root or with sudo
# =============================================================================

set -e  # Exit on any error

echo "=================================================="
echo "  LAMP Stack Installer - Ubuntu 22.04 LTS"
echo "  Apache2 + PHP 8.x + MySQL 8.0 + phpMyAdmin (optional)"
echo "=================================================="

# Update system
echo "Updating package index..."
apt update && apt upgrade -y

# Install Apache2
echo "Installing Apache2..."
apt install -y apache2 apache2-utils
systemctl enable apache2
systemctl start apache2

# Set ServerName to avoid warning
echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf
a2enconf servername
systemctl restart apache2

# Install MySQL 8.0
echo "Installing MySQL Server 8.0..."
debconf-set-selections <<< "mysql-server mysql-server/root_password password temp123root"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password temp123root"
apt install -y mysql-server mysql-client

# Secure MySQL installation (removes anonymous users, test DB, sets strong root password)
echo "Securing MySQL installation..."
mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'StrongRootPass2025!';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Install PHP and common modules (perfect for your asset/risk app)
echo "Installing PHP and required modules..."
apt install -y php libapache2-mod-php php-mysql php-cli php-common php-mbstring \
               php-xml php-json php-curl php-zip php-gd php-intl php-bcmath \
               php-soap php-ldap php-imap php-opcache php-redis

# PHP 8.1 is default on 22.04; optionally upgrade to latest (8.2 or 8.3 via PPA)
# Uncomment next 4 lines if you want the absolute latest PHP
# echo "Adding Ondřej Surý PPA for latest PHP..."
# apt install -y software-properties-common
# add-apt-repository ppa:ondrej/php -y
# apt update && apt install -y php8.2 php8.2-mysql php8.2-cli php8.2-common php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip php8.2-gd php8.2-bcmath

# Enable Apache mod_rewrite (needed for pretty URLs)
a2enmod rewrite
a2enmod headers
a2enmod ssl

# Restart Apache to load PHP
systemctl restart apache2

# Adjust PHP settings for larger uploads, better performance
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 64M/" /etc/php/*/apache2/php.ini
sed -i "s/post_max_size = .*/post_max_size = 64M/" /etc/php/*/apache2/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/*/apache2/php.ini
sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/*/apache2/php.ini

# Install useful tools
echo "Installing additional tools..."
apt install -y curl wget git unzip htop certbot python3-certbot-apache

# Create web root info file
echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Final restart
systemctl restart apache2

# =============================================================================
# OPTIONAL: Install phpMyAdmin (uncomment if you want it)
# =============================================================================
# echo "Installing phpMyAdmin..."
# debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
# debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password temp123root"
# debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password StrongRootPass2025!"
# debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password temp123root"
# debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
# apt install -y phpmyadmin php-mbstring php-gettext
# ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# =============================================================================
# DONE
# =============================================================================

echo ""
echo "LAMP stack successfully installed!"
echo ""
echo "Apache   : http://$(hostname -I | awk '{print $1}')"
echo "PHP Info : http://$(hostname -I | awk '{print $1}')/info.php  (delete after testing!)"
# echo "phpMyAdmin : http://$(hostname -I | awk '{print $1}')/phpmyadmin"
echo ""
echo "MySQL root password set to: StrongRootPass2025!"
echo "   → Change it immediately with: sudo mysql -u root -p"
echo ""
echo "Recommended next steps:"
echo "   1. Delete /var/www/html/info.php when done testing"
echo "   2. Change MySQL root password"
echo "   3. Create a dedicated MySQL user for your app"
echo "   4. Run: sudo ufw allow 'Apache Full'   (if firewall enabled)"
echo "   5. Consider installing free SSL: sudo certbot --apache"
echo ""
echo "All done! Your PHP + MySQL asset/risk platform is ready to deploy."
