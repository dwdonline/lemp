#!/bin/bash
#### Installation script to setup Ubuntu, Nginx, Percona, Php-fpm, Magento and Wordpress
#### By Philip N. Deatherage, Deatherage Web Development
#### www.dwdonline.com

pause(){
    read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

echo "---> WELCOME! FIRST WE NEED TO MAKE SURE THE SYSTEM IS UP TO DATE!"

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
read -e -p "---> Enter your web user usually www-data (nginx for Centos): " -i "www-data" MY_WEB_USER

adduser ${NEW_ADMIN} --disabled-password --gecos ""
echo "${NEW_ADMIN}:${NEW_ADMIN_PASSWORD}"|chpasswd

gpasswd -a ${NEW_ADMIN} sudo

sudo usermod -a -G ${MY_WEB_USER} ${NEW_ADMIN}

sed -i "s,PermitRootLogin yes,PermitRootLogin no,g" /etc/ssh/sshd_config

sed -i "s,Port 22,Port ${NEW_SSH_PORT},g" /etc/ssh/sshd_config

service ssh restart

echo "---> ALRIGHT, NOW WE ARE READY TO INSTALL THE GOOD STUFF!"
pause

echo "---> INSTALLING NGINX AND PHP-FPM"

add-apt-repository -y ppa:ondrej/php

apt-get -y update

apt-get -y install php-pear php7.0-fpm php7.0-mcrypt php7.0-curl php7.0-cli php7.0-mysql php7.0-gd php7.0-intl php7.0-xsl php7.0-gd php-ssh2 php7.0-mbstring php7.0-soap php7.0-zip libgd2-xpm-dev libgeoip-dev libgd2-xpm-dev libssh2-1 libzip4 libperl-dev libpcre3 libpcre3-dev libssl-dev zlib1g-dev nginx

apt-get -y install php5.6-fpm php-pear php5.6-mcrypt php5.6-curl php5.6-cli php5.6-mysql php5.6-gd php5.6-intl php5.6-xsl php5.6-gd php-ssh2 php5.6-mbstring php5.6-soap php5.6-zip

echo "---> NOW, LET'S COMPILE NGINX WITH PAGESPEED"
pause

apt-get autoremove nginx* -y

apt-get install libxslt-dev gcc -y

cd 

mkdir nginx_install

read -e -p "---> What version of Pagespeed do you want to use?: " -i "1.12.34.2" NPS_VERSION

cd $HOME/nginx_install

wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.zip
unzip v${NPS_VERSION}-beta.zip

cd ngx_pagespeed-${NPS_VERSION}-beta/
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url}
tar -xzvf $(basename ${psol_url})  # extracts to psol/

cd /root/nginx_install
wget https://github.com/arut/nginx-dav-ext-module/archive/master.zip
unzip master.zip
rm master.zip

cd /root/nginx_install
wget https://github.com/openresty/echo-nginx-module/archive/master.zip
unzip master.zip
rm master.zip

cd /root/nginx_install
wget https://github.com/itoffshore/nginx-upstream-fair/archive/master.zip
unzip master.zip
rm master.zip

cd /root/nginx_install
wget https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/master.zip
unzip master.zip
rm master.zip

cd $HOME/nginx_install
wget -q http://nginx.org/download/nginx-1.11.8.tar.gz
tar -xzvf nginx-1.11.8.tar.gz
cd nginx-1.11.8

PS_NGX_EXTRA_FLAGS="--with-cc=/usr/bin/gcc --with-ld-opt=-static-libstdc++"

./configure --user=www-data --group=www-data --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now' --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_geoip_module=dynamic --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module=dynamic --with-http_sub_module --with-http_xslt_module=dynamic --with-stream=dynamic --with-stream_ssl_module --with-mail=dynamic --with-mail_ssl_module --add-module=$HOME/nginx_install/nginx-dav-ext-module-master --add-module=$HOME/nginx_install/echo-nginx-module-master --add-module=$HOME/nginx_install/nginx-upstream-fair-master --add-module=$HOME/nginx_install/ngx_http_substitutions_filter_module-master --add-module=$HOME/nginx_install/ngx_pagespeed-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS}

make

make install

service nginx restart

echo "Don't worry, that message is normal. We'll unmask and restart it."

sudo systemctl unmask nginx.service

service nginx restart

echo "---> INSTALLING PERCONA"
pause

echo
read -e -p "---> What do you want your MySQL root password to be?: " -i "" MYSQL_ROOT_PASSWORD
read -e -p "---> What version of Ubuntu? 14 is trusty, 15 is wily, 16 is xenial: " -i "xenial" UBUNTU_VERSION

apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5

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

pause

    read -e -p "---> What will your main domain be - ie: domain.com: " -i "" MY_DOMAIN
    read -e -p "---> Enter your web root path: " -i "/var/www/${MY_DOMAIN}/public" MY_SITE_PATH   
    read -e -p "---> Which version of php will you be using? Either enter 5.6 or 7.0: " -i "5.6" PHP_VERSION   
    
    #Create host root
    cd
    mkdir -p ${MY_SITE_PATH}
    
    mkdir -p /etc/nginx/conf.d
    
    cd /etc/nginx/conf.d

    wget -qO  /etc/nginx/conf.d/pagespeed.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/pagespeed.conf
    wget -qO  /etc/nginx/conf.d/fastcgi-params.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/fastcgi-params.conf
    wget -qO  /etc/nginx/conf.d/gzip.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/gzip.conf
    wget -qO  /etc/nginx/conf.d/http.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/http.conf
    wget -qO  /etc/nginx/conf.d/limits.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/limits.conf
    wget -qO  /etc/nginx/conf.d/mime_types.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/conf.d/mime_types.conf
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

read -p "Is this Magento 1? Answer No for Magento 2. <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES|1 ) 
    wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/sites-available/magento.conf
;;
  n|N|No|no|NO|2 )
    wget -qO /etc/nginx/sites-available/${MY_DOMAIN}.conf https://raw.githubusercontent.com/dwdonline/lemp/master/sites-available/magento2.conf
;;
  * ) echo "invalid choice";;
esac

    sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s/www.example.com/www.${MY_DOMAIN}/g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,root /var/www/html,root ${MY_SITE_PATH},g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,user  www-data,user  ${MY_WEB_USER},g" /etc/nginx/nginx.conf
    sed -i "s,access_log,access_log /var/log/nginx/${MY_DOMAIN}_access.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,error_log,error_log /var/log/nginx/${MY_DOMAIN}_error.log;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

    sed -i "s,fastcgi_pass,fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

    ln -s /etc/nginx/sites-available/${MY_DOMAIN}.conf /etc/nginx/sites-enabled/${MY_DOMAIN}.conf
    ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

read -p "Would you like to setup the host files for WordPress? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 

    cd /etc/nginx
    mkdir -p wordpress
    cd wordpress
    
    wget -qO  /etc/nginx/wordpress/yoast.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/wordpress/yoast.conf
    wget -qO  /etc/nginx/wordpress/wordfence.conf https://raw.githubusercontent.com/dwdonline/lemp/master/nginx/wordpress/wordfence.conf
    
    cd /etc/nginx
        
    sed -i "s,#	include wordpress/yoast.conf;,	include wordpress/yoast.conf;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#	include wordpress/wordfence.conf;,	include wordpress/wordfence.conf;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    
;;
  n|N|No|no|NO )
    echo "You just skipped installing WordPress host files."
;;
  * ) echo "invalid choice";;
esac

echo "---> NOW, LET'S SETUP SSL."
pause

read -p "Do you want to use Let's Encrypt? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 
#cd /etc/ssl/
cd

apt-get install letsencrypt -y

read -e -p "---> Any additional domain name(s) seperated: domain.com, dev.domain.com: " -i "www.${MY_DOMAIN}" MY_DOMAINS
export DOMAINS="${MY_DOMAIN},www.${MY_DOMAIN},${MY_DOMAINS}"
export DIR="${MY_SITE_PATH}"

sudo letsencrypt certonly -a webroot --webroot-path=$DIR -d $DOMAINS

openssl dhparam -out /etc/ssl/dhparams.pem 2048

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

openssl dhparam -out /etc/ssl/dhparams.pem 2048

;;
  * ) echo "invalid";;
esac

    sed -i "s,listen 80;,listen 443 http2 ssl;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#listen80,listen  80;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#servername,server_name  ${MY_DOMAIN} www.${MY_DOMAIN};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#return,return 301 https://www.${MY_DOMAIN}$request_uri;,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#ssl_certificate_name,ssl_certificate  ${MY_SSL};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#ssl_certificate_key,ssl_certificate_key ${MY_SSL_KEY};,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf
    sed -i "s,#include conf.d/ssl.conf,include conf.d/ssl.conf,g" /etc/nginx/sites-available/${MY_DOMAIN}.conf

service nginx restart

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

echo "---> Let's remove sendmail and install Postfix to handle sending mail:"
pause

apt-get --purge remove sendmail sendmail-base sendmail-bin

read -e -p "---> What would you like your host to be? I like it to be something like sendmail.domain.com: " -i "sendmail.${MY_DOMAIN}" POSTFIX_SERVER

debconf-set-selections <<< "postfix postfix/mailname string ${POSTFIX_SERVER}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix

read -p "Would you like to install Magento now? <y/N> " choice
case "$choice" in 
  y|Y|Yes|yes|YES ) 

echo "You will need to install Magento afterwards. The database will be setup however." pause

echo "Let's setup the database"
read -e -p "---> What do you want to name your Magento MySQL database?: " -i "" MAGENTO_MYSQL_DATABASE
read -e -p "---> What do you want to name your Magento MySQL user?: " -i "" MAGENTO_MYSQL_USER
read -e -p "---> What do you want your Magento MySQL password to be?: " -i "" MAGENTO_MYSQL_USER_PASSWORD

echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${MAGENTO_MYSQL_DATABASE}; CREATE user '${MAGENTO_MYSQL_USER}'@'localhost' IDENTIFIED BY '${MAGENTO_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${MAGENTO_MYSQL_DATABASE}.* TO '${MAGENTO_MYSQL_USER}'@'localhost' IDENTIFIED BY '${MAGENTO_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${MAGENTO_MYSQL_DATABASE}"
echo "Your database user is: ${MAGENTO_MYSQL_USER}"
echo "Your databse password is: ${MAGENTO_MYSQL_USER_PASSWORD}"

;;
  n|N|No|no|NO )

    echo "You didn't want to install Magento I guess. It kinda defeats the purpose of this script, unless you are installing WordPress."
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
read -e -p "---> What do you want your WordPress directory to be. If this will be at the root enter the same as your root ${MY_SITE_PATH} or if it will be for Magento wp:" -i "${MY_SITE_PATH}/wp" WP_DIRECTORY

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
