pause(){
    read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

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

#Copy verification folder for SSL
//cd "/var/www/html"
//cp -r ".well-known" ${MY_SITE_PATH}

