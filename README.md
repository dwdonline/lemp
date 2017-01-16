LEMP Install for Magento and WordPress

This script is meant to be run on a fresh Ubuntu server with 14,15, or 16.

It will:

1. Update the server.

2. Install with Pagespeed.

3. Install Php5-fpm 7.

4. Install Percona (MySQL) 5.7.

5. Configure the server configurations for Magento and/or WordPress.

6. Install Magento and/or WordPress and create their databases (have to run the web installer after), setting up their files and MySQL databases.

7. Install a Let's Encrypt SSL. https://letsencrypt.org/. Note, this has been moved to a different script.



To use:
Login to your server and run the following:

cd to the directory you want to put the script in. I usually just go to root:

cd

wget -q https://raw.githubusercontent.com/dwdonline/lemp/master/lemp.sh

chmod 550 lemp.sh

./lemp.sh


To add a WordPress site:
cd

wget -q https://raw.githubusercontent.com/dwdonline/lemp/master/add_wp_site.sh

chmod 550 add_wp_site.sh

./add_wp_site.sh
