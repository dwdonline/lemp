#!/bin/bash
#### Installation script to setup Ubuntu, Nginx, Percona, Php-fpm, Magento and Wordpress
#### By Philip N. Deatherage, Deatherage Web Development
#### www.dwdonline.com

pause(){
    read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

echo "---> WELCOME! FIRST WE NEED TO MAKE SURE THE SYSTEM IS UP TO DATE!"

read -p "Would you like to install updates now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
apt-get update
apt-get -y upgrade

else
echo "Ok, we won't update the system first. This may cause issues if you have a really old system."
fi

echo "---> Now, we'll install build-essentials and zip/unzip."
pause

apt-get update
apt-get -y install build-essential zip unzip

echo "All done with the system basics."

echo "---> Let's add a new admin user and block the default root from logging in:"
pause

read -e -p "---> What would you like your new admin user to be?: " -i "" NEW_ADMIN
read -e -p "---> What should the new admin password be?: " -i "" NEW_ADMIN_PASSWORD
read -e -p "---> What should we make the SSH port?: " -i "" NEW_SSH_PORT

adduser ${NEW_ADMIN} --disabled-password --gecos ""
echo "${NEW_ADMIN}:${NEW_ADMIN_PASSWORD}"|chpasswd

gpasswd -a ${NEW_ADMIN} sudo

sed -i "s,PermitRootLogin yes,PermitRootLogin no,g" /etc/ssh/sshd_config

sed -i "s,Port 22,Port ${NEW_SSH_PORT},g" /etc/ssh/sshd_config

service ssh restart

echo "---> ALRIGHT, NOW WE ARE READY TO INSTALL THE GOOD STUFF!"
pause

echo "---> INSTALLING NGINX AND PHP-FPM"

nginx=development

add-apt-repository ppa:nginx/$nginx

apt-get -y update

apt-get -y install php7.0-fpm php7.0-mcrypt php7.0-curl php7.0-cli php7.0-mysql php7.0-gd php7.0-intl php7.0-xsl php7.0-gd php-ssh2 php7.0-mbstring php7.0-soap php7.0-zip libgd2-xpm-dev libgeoip-dev libgd2-xpm-dev libssh2-1 libzip4 libperl-dev libpcre3 libpcre3-dev libssl-dev zlib1g-dev nginx
echo "---> NOW, LET'S COMPILE NGINX WITH PAGESPEED"
pause

cd

service nginx stop
pkill nginx

wget -q https://github.com/pagespeed/ngx_pagespeed/archive/master.zip
unzip master.zip
cd ngx_pagespeed-master
wget -q https://dl.google.com/dl/page-speed/psol/1.11.33.4.tar.gz
tar -xzvf 1.11.33.3.tar.gz # expands to psol/
cd
wget -q http://nginx.org/download/nginx-1.11.5.tar.gz
tar -xzvf nginx-1.11.5.tar.gz
cd nginx-1.11.5

./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --with-http_stub_status_module --user=www-data --group=www-data --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_image_filter_module --add-module=$HOME/ngx_pagespeed-master --with-http_geoip_module --with-http_realip_module;

make

make install

service nginx restart

echo "---> NOW, LET'S SETUP SSL."
pause

sudo apt-get -y install letsencrypt

echo
read -e -p "---> What will your main domain be - ie: domain.com: " -i "" MY_DOMAIN
read -e -p "---> Any additional domain name(s) seperated: domain.com, dev.domain.com: " -i "www.${MY_DOMAIN}" MY_DOMAINS

#cd /etc/ssl/
cd

export DOMAINS="${MY_DOMAIN},www.${MY_DOMAIN},${MY_DOMAINS}"
export DIR=/var/www/html
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

echo "---> INSTALLING PERCONA"
pause

echo
read -e -p "---> What do you want your MySQL root password to be?: " -i "" MYSQL_ROOT_PASSWORD
read -e -p "---> What version of Ubuntu? 14 is trusty, 15 is wily, 16 is xenial: " -i "xenial" UBUNTU_VERSION

apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A

echo "deb http://repo.percona.com/apt ${UBUNTU_VERSION} main" >> /etc/apt/sources.list

echo "deb-src http://repo.percona.com/apt ${UBUNTU_VERSION} main" >> /etc/apt/sources.list

touch /etc/apt/preferences.d/00percona.pref

echo "Package: *" >> /etc/apt/preferences.d/00percona.pref
echo "Pin: release o=Percona Development Team" >> /etc/apt/preferences.d/00percona.pref
echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/00percona.pref

apt-get -y update

export DEBIAN_FRONTEND=noninteractive
echo "percona-server-server-5.7 percona-server-server/root_password password ${MYSQL_ROOT_PASSWORD}" | sudo debconf-set-selections
echo "percona-server-server-5.7 percona-server-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" | sudo debconf-set-selections
apt-get -y install percona-server-server-5.7 percona-server-client-5.7

service mysql restart

/usr/bin/mysql_secure_installation

cd

echo "---> OK, WE ARE DONE SETTING UP THE SERVER. LET'S PROCEED TO CONFIGURING THE NGINX HOST FILES."

read -p "Would you like to setup the host files for Magento? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

    read -e -p "---> Enter your web root path: " -i "/var/www/html" MY_SITE_PATH
    read -e -p "---> Enter your web user usually www-data (nginx for Centos): " -i "www-data" MY_WEB_USER
    
    cd /etc/nginx/conf.d

    wget -qO  /etc/nginx/conf.d/pagespeed.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/pagespeed.conf
    wget -qO  /etc/nginx/conf.d/fastcgi-params.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/fastcgi-params.conf
    wget -qO  /etc/nginx/conf.d/gzip.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/gzip.conf
    wget -qO  /etc/nginx/conf.d/http.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/http.conf
    wget -qO  /etc/nginx/conf.d/limits.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/limits.conf
    wget -qO  /etc/nginx/conf.d/mime-types.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/mime-types.conf
    wget -qO  /etc/nginx/conf.d/security.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/security.conf
    wget -qO  /etc/nginx/conf.d/ssl.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/ssl.conf
    wget -qO  /etc/nginx/conf.d/static-files.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/static-files.conf
    
    cd /etc/nginx
    
    mv nginx.conf nginx.conf.bak
    wget -qO  /etc/nginx/nginx.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/nginx.conf

    mkdir -p /etc/nginx/sites-enabled

    rm -rf /etc/nginx/sites-available/default

    mkdir -p /etc/nginx/sites-available
    
    cd /etc/nginx/sites-available
    
    wget -q https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/sites-available/default.conf

    wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/lemp/master/sites-available/magento.conf
    
    sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s/www.example.com/www.${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,root /var/www/html,root ${MY_SITE_PATH},g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,user  www-data,user  ${MY_WEB_USER},g" /etc/nginx/nginx.conf
    sed -i "s,ssl_certificate_name,ssl_certificate  /etc/letsencrypt/live/${MY_DOMAIN}/fullchain.pem;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,ssl_certificate_key,ssl_certificate_key /etc/letsencrypt/live/${MY_DOMAIN}/privkey.pem;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,access_log,access_log /var/log/nginx/${MY_DOMAIN}_access.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,error_log,error_log /var/log/nginx/${MY_DOMAIN}_error.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

    ln -s /etc/nginx/sites-available/${MY_DOMAIN}.conf /etc/nginx/sites-enabled/${MY_DOMAIN}.conf
    ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

else
    echo "You just skipped installing the host files for Magento."
fi

read -p "Would you like to setup the host files for WordPress? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

    cd /etc/nginx
    mkdir -p wordpress
    cd wordpress
    
    wget -qO  /etc/nginx/conf.d/yoast.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/wordpress/yoast.conf
    wget -qO  /etc/nginx/conf.d/wordfence.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/wordpress/wordfence.conf
    
    cd /etc/nginx
        
    sed -i "s,#	include wordpress/yoast.conf,	include wordpress/yoast.conf,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#	include wordpress/wordfence.conf,	include wordpress/wordfence.conf,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

else
    echo "You just skipped installing WordPress host files."
fi

#Create host root
cd
mkdir -p ${MY_SITE_PATH}

#Copy verification folder for SSL
cd "/var/www/html"
cp -r ".well-known" ${MY_SITE_PATH}

#Move to site root
cd ${MY_SITE_PATH}

read -p "Would you like to install Adminer for managing your MySQL databases now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
    wget -q https://www.adminer.org/static/download/4.2.5/adminer-4.2.5-mysql.php
    mv adminer-4.2.5-mysql.php adminer.php
else
    echo "You chose not to install Adminer."
fi

echo "---> Let's remove sendmail and install Postfix to handle sending mail:"
pause

apt-get --purge remove sendmail sendmail-base sendmail-bin

read -e -p "---> What would you like your host to be? I like it to be something like sendmail.domain.com: " -i "sendmail.${MY_DOMAIN}" POSTFIX_SERVER

debconf-set-selections <<< "postfix postfix/mailname string ${POSTFIX_SERVER}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix

read -p "Would you like to install Magento now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

cd "${MY_SITE_PATH}"

wget -qO  "https://docs.google.com/uc?export=download&confirm=f7el&id=0B9WPON9sDtVkQlpxdHhMOVVKQzQ"

echo "Let's setup the database"
read -e -p "---> What do you want to name your Magento MySQL database?: " -i "" MAGENTO_MYSQL_DATABASE
read -e -p "---> What do you want to name your Magento MySQL user?: " -i "" MAGENTO_MYSQL_USER
read -e -p "---> What do you want your Magento MySQL password to be?: " -i "" MAGENTO_MYSQL_USER_PASSWORD

echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${MAGENTO_MYSQL_DATABASE}; CREATE user '${MAGENTO_MYSQL_USER}'@'localhost' IDENTIFIED BY '${MAGENTO_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${MAGENTO_MYSQL_DATABASE}.* TO '${MAGENTO_MYSQL_USER}'@'localhost' IDENTIFIED BY '${MAGENTO_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${MAGENTO_MYSQL_DATABASE}"
echo "Your database user is: ${MAGENTO_MYSQL_USER}"
echo "Your databse password is: ${MAGENTO_MYSQL_USER_PASSWORD}"

else
    echo "You didn't want to install Magento I guess. It kinda defeats the purpose of this script."
fi

read -p "Would you like to install WordPress now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

cd "${MY_SITE_PATH}"

mkdir wp

cd wp

wget -q https://wordpress.org/latest.zip

unzip latest.zip

#mv wordpress blog

cd wordpress

mv * .htaccess ../

echo
read -e -p "---> What do you want to name your WordPress MySQL database?: " -i "" WP_MYSQL_DATABASE
read -e -p "---> What do you want to name your WordPress MySQL user?: " -i "" WP_MYSQL_USER
read -e -p "---> What do you want your WordPress MySQL password to be?: " -i "" WP_MYSQL_USER_PASSWORD


echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${WP_MYSQL_DATABASE}; CREATE user '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${WP_MYSQL_DATABASE}.* TO '${WP_MYSQL_USER}'@'localhost' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${WP_MYSQL_DATABASE}"
echo "Your database user is: ${WP_MYSQL_USER}"
echo "Your databse password is: ${WP_MYSQL_USER_PASSWORD}"

service mysql restart

cd "${MY_SITE_PATH}"

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

else
    echo "You didn't install WordPress."
    service mysql restart
fi

echo "---> Let's add a robots.txt file:"
wget -qO ${MY_SITE_PATH}/robots.txt https://raw.githubusercontent.com/dwdonline/lemp/master/robots.txt
sed -i "s,Sitemap: http://YOUR-DOMAIN.com/sitemap_index.xml,Sitemap: https://www.${MY_DOMAIN}/sitemap_index.xml,g" ${MY_SITE_PATH}/robots.txt


echo "---> Let's set the permissions for Magento and WordPress:"
pause

echo "Lovely, this may take a few minutes. Dont fret."

cd "${MY_SITE_PATH}"

chown -R ${NEW_ADMIN}.www-data *

chown -R ${NEW_ADMIN}.www-data robots.txt

find . -type f -exec chmod 400 {} \;
find . -type d -exec chmod 500 {} \; 
find var/ -type f -exec chmod 600 {} \; 
find media/ -type f -exec chmod 600 {} \;
find var/ -type d -exec chmod 700 {} \; 
find media/ -type d -exec chmod 700 {} \;
find ${MY_SITE_PATH}/wp-content/ -type f -exec chmod 600 {} \; 
find ${MY_SITE_PATH}/wp-content/ -type d -exec chmod 700 {} \;
chmod 700 includes
chmod 600 includes/config.php

chown -R www-data.www-data wp-content

echo "---> Let;s cleanup:"
pause
cd
rm -rf master.zip nginx-1.11.5 nginx-1.11.5.tar.gz ngx_pagespeed-master

cd ${MY_SITE_PATH}

rm -rf wordpress latest.zip

apt-mark hold nginx*

cd /etc/nginx/sites-enabled

rm -rf /etc/nginx/sites-enabled/default

cd

# Let's set the server to update itself:
sudo dpkg-reconfigure --priority=low unattended-upgrades

echo "I just saved you a shitload of time and headache. You're welcome."
