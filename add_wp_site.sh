#!/bin/bash
#### Installation script to add WordPress sites to already setup server.
#### By Philip N. Deatherage, Deatherage Web Development
#### www.dwdonline.com

pause(){
    read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

echo "---> WELCOME! FIRST WE NEED TO MAKE SURE THE SYSTEM IS UP TO DATE!"
pause
read -p "Would you like to install updates now? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
apt-get update
apt-get -y upgrade
;;
  n|N|No|no|NO )
echo "Ok, we won't update the system first. This may cause issues if you have a really old system."
;;
  * ) echo "invalid";;
esac

read -e -p "---> What is your main admin user?: " -i "" NEW_ADMIN

echo
read -e -p "---> What will your main domain be - ie: domain.com: " -i "" MY_DOMAIN

read -e -p "---> Any additional domain name(s) seperated: domain.com, dev.domain.com: " -i "www.${MY_DOMAIN}" MY_DOMAINS

read -e -p "---> Enter your web root path: " -i "/var/www/${MY_DOMAIN}/public" MY_SITE_PATH

#Create host root
cd
mkdir -p ${MY_SITE_PATH}

echo "---> NOW, LET'S SETUP SSL."
pause

read -p "Do you want to use Let's Encrypt? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
#cd /etc/ssl/
cd

export DOMAINS="${MY_DOMAIN},www.${MY_DOMAIN},${MY_DOMAINS}"
export DIR="${MY_SITE_PATH}"

sudo letsencrypt certonly -a webroot --webroot-path=$DIR -d $DOMAINS

openssl dhparam -out /etc/ssl/dhparams.pem 2048

echo "---> NOW, LET'S SETUP SSL to renew every 60 days."
pause

cd

cat > renewCerts.sh <<EOF
#!/bin/sh
# This script renews all the Let's Encrypt certificates with a validity < 30 days
if ! letsencrypt renew > /var/log/letsencrypt/renew.log 2>&1 ; then
    echo Automated renewal failed:
    cat /var/log/letsencrypt/renew.log
    exit 1
fi
nginx -t && nginx -s reload
EOF

#Add cronjob for renewing ssl
(crontab -l 2>/dev/null; echo "@daily /root/renewCerts.sh") | crontab -

chmod +x /root/renewCerts.sh

MY_SSL="/etc/letsencrypt/live/${MY_DOMAIN}/fullchain.pem"
MY_SSL_KEY="/etc/letsencrypt/live/${MY_DOMAIN}/privkey.pem"

;;
  n|N|No|no|NO )

echo "OK, we will install a self-signed SSL then."

echo
read -e -p "---> What is the 2 letter country? - ie: US: " -i "US" MY_COUNTRY
read -e -p "---> What is your state/province? - ie: California: " -i "California" MY_REGION
read -e -p "---> What is your city? - ie: Los Angeles: " -i "Los Angeles" MY_CITY
read -e -p "---> What is your company - ie: Deatherage Co: " -i "" MY_O
read -e -p "---> What is your departyment - ie: IT (Can be blank): " -i "" MY_OU

mkdir -p /etc/ssl/sites/

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/sites/${MY_DOMAIN}_selfsigned.key -out /etc/ssl/sites/${MY_DOMAIN}_selfsigned.crt -subj "/C=${MY_COUNTRY}/ST=${MY_REGION}/L=${MY_CITY}/O=${MY_O}/OU=${MY_OU}/CN=${MY_DOMAIN}"

MY_SSL="/etc/ssl/sites/${MY_DOMAIN}_selfsigned.crt"
MY_SSL_KEY="/etc/ssl/sites/${MY_DOMAIN}_selfsigned.key"

;;
  * ) echo "invalid";;
esac

openssl dhparam -out /etc/ssl/dhparams.pem 2048

pause
    
    cd /etc/nginx/sites-available
    
    wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/sites-available/wp.conf

    sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s/www.example.com/www.${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,root /var/www/html,root ${MY_SITE_PATH},g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,user  www-data,user  ${MY_WEB_USER},g" /etc/nginx/nginx.conf
    sed -i "s,ssl_certificate_name,ssl_certificate  ${MY_SSL};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,ssl_certificate_key,ssl_certificate_key ${MY_SSL_KEY};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,access_log,access_log /var/log/nginx/${MY_DOMAIN}_access.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,error_log,error_log /var/log/nginx/${MY_DOMAIN}_error.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

    ln -s /etc/nginx/sites-available/${MY_DOMAIN}.conf /etc/nginx/sites-enabled/${MY_DOMAIN}.conf
        
    sed -i "s,#	include wordpress/yoast.conf;,	include wordpress/yoast.conf;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#	include wordpress/wordfence.conf;,	include wordpress/wordfence.conf;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

#Move to site root
cd ${MY_SITE_PATH}

read -p "Would you like to install Adminer for managing your MySQL databases now? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
    wget -q https://www.adminer.org/static/download/4.2.5/adminer-4.2.5-mysql.php
    mv adminer-4.2.5-mysql.php adminer.php
;;
  n|N|No|no|NO )
    echo "You chose not to install Adminer."
;;
  * ) echo "invalid choice";;
esac

read -p "Would you like to install WordPress now? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
echo
read -e -p "---> What do you want to name your WordPress MySQL database?: " -i "" WP_MYSQL_DATABASE
read -e -p "---> What do you want to name your WordPress MySQL user?: " -i "" WP_MYSQL_USER
read -e -p "---> What do you want your WordPress MySQL password to be?: " -i "" WP_MYSQL_USER_PASSWORD
read -e -p "---> What do you want your WordPress directory to be. ${MY_SITE_PATH}:" -i "${MY_SITE_PATH}" WP_DIRECTORY

cd "${MY_SITE_PATH}"

mkdir -p ${WP_DIRECTORY}

cd "${WP_DIRECTORY}"

MY_WP_SITE_PATH="${WP_DIRECTORY}"

wget -q https://wordpress.org/latest.zip

unzip latest.zip

cd wordpress

mv * ../

echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${WP_MYSQL_DATABASE}; CREATE user '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${WP_MYSQL_DATABASE}.* TO '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${WP_MYSQL_DATABASE}"
echo "Your database user is: ${WP_MYSQL_USER}"
echo "Your databse password is: ${WP_MYSQL_USER_PASSWORD}"

service mysql restart

cd "${MY_WP_SITE_PATH}"

cp -r wp-config-sample.php wp-config.php

sed -i "s,database_name_here,${WP_MYSQL_DATABASE},g" wp-config.php
sed -i "s,username_here,${WP_MYSQL_USER},g" wp-config.php
sed -i "s,password_here,${WP_MYSQL_USER_PASSWORD},g" wp-config.php

#set WP salts
perl -i -pe'
  BEGIN {
    @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
    push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
    sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
  }
  s/put your unique phrase here/salt()/ge
' wp-config.php

;;
  n|N|No|no|NO )
    echo "You didn\'t install WordPress."
    service mysql restart
;;
  * ) echo "invalid choice";;
esac

echo "---> Let's add a robots.txt file:"
wget -qO ${MY_SITE_PATH}/robots.txt https://raw.githubusercontent.com/dwdonline/lemp/master/robots.txt
sed -i "s,Sitemap: http://YOUR-DOMAIN.com/sitemap_index.xml,Sitemap: https://www.${MY_DOMAIN}/sitemap_index.xml,g" ${MY_SITE_PATH}/robots.txt

echo "---> Let's set the permissions for the site:"
pause

echo "Lovely, this may take a few minutes. Dont fret."

cd "${MY_SITE_PATH}"

chown -R ${NEW_ADMIN}.www-data ${MY_SITE_PATH}

chown -R ${NEW_ADMIN}.www-data /var/www

chown -R ${NEW_ADMIN}.www-data robots.txt

cd ${WP_DIRECTORY}
find ${WP_DIRECTORY}/wp-content/ -type f -exec chmod 600 {} \; 
find ${WP_DIRECTORY}/wp-content/ -type d -exec chmod 700 {} \;
chmod 700 wp-includes
chmod 600 wp-config.php

chown -R www-data.www-data wp-content

sudo chmod -R 775 ${MY_SITE_PATH}
