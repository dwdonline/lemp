LEMP Install for Magento and WordPress

This script will take a fresh Ubuntu 14/15/16 server update it, then install Nginx, Php5-fpm, Percona (MySQL), and Pagespeed, then set up the server configuration for Magento and/or WordPress.

It will also install Magento and/or Wordpress (have to run the web installer after), setting up their files and MySQL databases.



To use, login to your server and run the following:

cd to the directory you want to put the script in. I usually just go to root:

cd

wget -q https://raw.githubusercontent.com/dwdonline/lemp/master/lemp.sh

chmod 550 lemp.sh

./lemp.sh
