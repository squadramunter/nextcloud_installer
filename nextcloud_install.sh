#!/bin/bash

## Before using this script keep in mind that you need a FQDN before continue

nextcloud_version="16.0.1"

php_version="php7.3"

timezone="Europe/Amsterdam"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

trap '' 2
while true
do
  clear
  echo "================================================================================"
  echo "//                Nextcloud installer made by @squadramunter                  //"
  echo "================================================================================"
  echo "Enter 1 to install Nextcloud automatically: "
  echo "Enter 2 to get a Let's Encrypt certificate: "
  echo "Enter q to exit the menu q: "
  echo -e "\n"
  echo -e "Enter your selection \c"
  read answer
  case "$answer" in
1)

sudo apt-get update

sudo apt install -y nginx

sudo systemctl stop nginx.service

sleep 2

sudo systemctl start nginx.service

sleep 2

sudo systemctl enable nginx.service

sudo apt install -y mariadb-server mariadb-client

sudo mysql_secure_installation

sleep 2

sudo systemctl restart mariadb.service

sudo apt-get install -y software-properties-common

sudo add-apt-repository -y ppa:ondrej/php

sudo apt update

sudo apt install -y $php_version-fpm $php_version-mbstring $php_version-xmlrpc $php_version-soap $php_version-apcu $php_version-smbclient $php_version-ldap $php_version-redis $php_version-gd \
$php_version-xml $php_version-intl $php_version-json $php_version-imagick $php_version-mysql $php_version-cli $php_version-ldap $php_version-zip $php_version-curl

## Change PHP ini file

sed -i '/file_uploads/c\file_uploads=On' /etc/php/$php_version/fpm/php.ini
sed -i '/allow_url_fopen/c\allow_url_fopen=On' /etc/php/$php_version/fpm/php.ini
sed -i '/memory_limit/c\memory_limit=256M' /etc/php/$php_version/fpm/php.ini
sed -i '/upload_max_filesize/c\upload_max_filesize=100M' /etc/php/$php_version/fpm/php.ini
sed -i '/display_errors/c\display_errors=Off' /etc/php/$php_version/fpm/php.ini
sed -i '/cgi.fix_pathinfo/c\cgi.fix_pathinfo=0' /etc/php/$php_version/fpm/php.ini
sed -i "/date.timezone/c\date.timezone=${timezone}" /etc/php/$php_version/fpm/php.ini

## Create Nextcloud Database

# create database
echo "Please enter a database name for Nextcloud: "
read NDATABASE

# create username
echo "Please enter a username for Nextcloud: "
read NUSERNAME

# create password
echo "Please enter a password for Nextcloud: "
read NPASSWORD

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then

    mysql -e "CREATE DATABASE ${NDATABASE};"
    mysql -e "CREATE USER ${NUSERNAME}@localhost IDENTIFIED BY '${NPASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${NDATABASE}.* TO '${NUSERNAME}'@'localhost' IDENTIFIED BY '${NPASSWORD}' WITH GRANT OPTION;"
    mysql -e "FLUSH PRIVILEGES;"

# If /root/.my.cnf doesn't exist then it'll ask for root password
else
    echo "Please enter root user MySQL password!"
    read rootpasswd
    mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${NDATABASE};"
    mysql -uroot -p${rootpasswd} -e "CREATE USER ${NUSERNAME}@localhost IDENTIFIED BY '${NPASSWORD}';"
    mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${NDATABASE}.* TO '${NUSERNAME}'@'localhost' IDENTIFIED BY '${NPASSWORD}' WITH GRANT OPTION;"
    mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
fi

## Download Nextcloud

cd /tmp && wget https://download.nextcloud.com/server/releases/nextcloud-$nextcloud_version.zip -O /tmp/nextcloud-$nextcloud_version.zip
unzip /tmp/nextcloud-$nextcloud_version.zip -d /tmp

## Move nextcloud to www root

read -p "Enter web root for Nextcloud [/var/www/html]: " NROOT
NROOT=${NROOT:-/var/www/html}
echo $NROOT

sudo mv /tmp/nextcloud $NROOT

## Set the right permissions for nextcloud
sudo chown -R www-data:www-data $NROOT/nextcloud
sudo chmod -R 755 $NROOT/nextcloud

## Configure Nextcloud VirtualHost for nginx

# enter domainname FQDN for Nextcloud
read -p "Enter your Domain Name for Nextcloud: " NDOMAIN
echo "You have set $NDOMAIN as your Domain Name"
sleep 3

touch /etc/nginx/sites-available/nextcloud

NVHOST="/etc/nginx/sites-available/nextcloud"

/bin/cat <<EOM >$NVHOST
upstream php-handler {
	server unix:/var/run/php/$php_version-fpm.sock;
}

server {
    listen 80;
    server_name  $NDOMAIN;
    return       301 http://www.$NDOMAIN$request_uri;
}

server {
    listen 80;
    server_name www.$NDOMAIN;

    #ssl_certificate /etc/ssl/nginx/cloud.example.com.crt;
    #ssl_certificate_key /etc/ssl/nginx/cloud.example.com.key;

    # Add headers to serve security related headers
    # Before enabling Strict-Transport-Security headers please read into this
    # topic first.
    #add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
    #
    # WARNING: Only add the preload option once you read about
    # the consequences in https://hstspreload.org/. This option
    # will add the domain to a hardcoded list that is shipped
    # in all major browsers and getting removed from this list
    # could take several months.
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header Referrer-Policy no-referrer;

    # Remove X-Powered-By, which is an information leak
    fastcgi_hide_header X-Powered-By;

    # Path to the root of your installation
    root /srv/NAS-Data/www/cloud.squadrasec.com/html/nextcloud/;

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # The following 2 rules are only needed for the user_webfinger app.
    # Uncomment it if you're planning to use this app.
    #rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
    #rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json last;

    # The following rule is only needed for the Social app.
    # Uncomment it if you're planning to use this app.
    # rewrite ^/.well-known/webfinger /public.php?service=webfinger last;

    location = /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }
    location = /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    location / {
        rewrite ^ /index.php$request_uri;
    }

    location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
        deny all;
    }
    location ~ ^\/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:$|\/) {
        fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS on;
        #Avoid sending the security headers twice
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ ^\/(?:updater|oc[ms]-provider)(?:$|\/) {
        try_files $uri/ =404;
        index index.php;
    }

    # Adding the cache control header for js, css and map files
    # Make sure it is BELOW the PHP block
    location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
        try_files $uri /index.php$request_uri;
        add_header Cache-Control "public, max-age=15778463";
        # Add headers to serve security related headers (It is intended to
        # have those duplicated to the ones above)
        # Before enabling Strict-Transport-Security headers please read into
        # this topic first.
        # add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
        #
        # WARNING: Only add the preload option once you read about
        # the consequences in https://hstspreload.org/. This option
        # will add the domain to a hardcoded list that is shipped
        # in all major browsers and getting removed from this list
        # could take several months.
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;

        # Optional: Don't log access to assets
        access_log off;
    }

    location ~ \.(?:png|html|ttf|ico|jpg|jpeg)$ {
        try_files $uri /index.php$request_uri;
        # Optional: Don't log access to other assets
        access_log off;
    }
}
EOM

## Enable Nextcloud VirtualHost
sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/

sudo systemctl restart nginx.service

echo "Do you want to setup a Let's Encrypt Certificate?"
read -p "Would you like to proceed y/n? " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]
then

  sudo add-apt-repository -y ppa:certbot/certbot
  sudo apt install -y python-certbot-apache
  sudo certbot --apache -d $NDOMAIN -d www.$NDOMAIN

else
   echo "Thanks for using Nextcloud Auto Installer made by @SquadraMunter"
   sleep 5
fi

;;

2)

read -p "Enter your Domain Name for Let's Encrypt: " NDOMAIN
echo "You have set $NDOMAIN as your Domain Name"

sleep 3

sudo add-apt-repository -y ppa:certbot/certbot
sudo apt install -y python-certbot-apache
sudo certbot --apache -d $NDOMAIN -d www.$NDOMAIN

;;

q) exit ;;

  esac
  echo -e "Enter return to continue \c"
  read input
done
