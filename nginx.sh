#!/bin/bash
#Install nginx
apt-get update
sudo apt install nginx -y
sudo yes | sudo cp -i sites-enabled/sample /etc/nginx/sites-enabled/
sudo systemctl restart nginx
