#!/bin/bash
#Install Apache2 MySQL PHP Python3
apt-get update
sudo apt-get install apache2 -y
sudo apt-get install mysql-server -y
sudo apt-get install python3-pip -y
sudo pip3 install pymysql -y
sudo apt install php libapache2-mod-php php-mysql -y
sudo a2dismod mpm_event
sudo a2enmod mpm_prefork cgi
sudo yes | sudo cp -i  sites-conf/000-default.conf /etc/apache2/sites-enabled/
sudo cp -i mod-conf/php.conf /etc/apache2/mods-enabled
sudo systemctl restart apache2

