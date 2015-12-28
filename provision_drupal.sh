#!/bin/bash

# Provision a VM for Drupal development using nginx, php-fpm and mysql.
#
# Shamelessly snarfed from Jurgen Verhasselt - https://github.com/sjugge

##### VARIABLES #####

# Throughout this script, some variables are used, these are defined first.
# These variables can be altered to fit your specific needs or preferences.

# Server name
HOSTNAME="changeme"

# MySQL password
MYSQL_ROOT_PASSWORD="root" # can be altered, though storing passwords in a script is a bad idea!

# Locale
LOCALE_LANGUAGE="en_US" # can be altered to your prefered locale, see http://docs.moodle.org/dev/Table_of_locales
LOCALE_CODESET="en_US.UTF-8"

# Timezone
TIMEZONE="America/Chicago" # can be altered to your specific timezone, see http://manpages.ubuntu.com/manpages/jaunty/man3/DateTime::TimeZone::Catalog.3pm.html

# Site information
SOURCE_DIR_NAME=$HOSTNAME # this is a subdirectory under /var/www
BEHAT_DIR_NAME=${SOURCE_DIR_NAME}_behat
DOCROOT="/var/www/$HOSTNAME/htdocs"
# Only set one of these (svn or git)
# SVN_URL=""
# GIT_URL=""
SITE_NAME=$HOSTNAME
DB_NAME=$HOSTNAME
DB_USER=$HOSTNAME
DB_PASSWORD=$HOSTNAME

# Settings (e.g. svn username and password)
if [ -e "/vagrant/provision_settings.sh" ]
then
  source /vagrant/provision_settings.sh
fi

##### Provision check ######

# The provision check is intented to not run the full provision script when a box has already been provisioned.
# At the end of this script, a file is created on the vagrant box, we'll check if it exists now.
echo "[vagrant provisioning] Checking if the box was already provisioned..."

if [ -e "/home/vagrant/.provision_check" ]
then
  # Skipping provisioning if the box is already provisioned
  echo "[vagrant provisioning] The box is already provisioned..."
  exit
fi

##### Ensure packages are up to date #####

echo "[vagrant provisioning] Updating packages..."
apt-get update
apt-get dist-upgrade -y

##### System settings #####

# Set Locale, see https://help.ubuntu.com/community/Locale#Changing_settings_permanently
echo "[vagrant provisioning] Setting locale..."
locale-gen $LOCALE_LANGUAGE $LOCALE_CODESET

# Set timezone, for unattended info see https://help.ubuntu.com/community/UbuntuTime#Using_the_Command_Line_.28unattended.29
echo "[vagrant provisioning] Setting timezone..."
echo $TIMEZONE | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

echo "[vagrant provisioning] Installing mysql-server and mysql-client..."
# Set MySQL root password and install MySQL. Info on unattended install: http://serverfault.com/questions/19367
echo mysql-server mysql-server/root_password select $MYSQL_ROOT_PASSWORD | debconf-set-selections
echo mysql-server mysql-server/root_password_again select $MYSQL_ROOT_PASSWORD | debconf-set-selections
apt-get install -y mysql-server mysql-client
service mysql restart

echo "[vagrant provisioning] Installing common packages..."
apt-get install -y mg nginx php5-fpm php5-mysql php5-gd php5-curl php5-mcrypt php5-cli php-console-table php-pear php-codecoverage phpunit-mock-object keychain zsh subversion git curl nfs-kernel-server zip unzip exuberant-ctags libjpeg-progs optipng

echo "[vagrant provisioning] Securing MySQL..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD mysql <<EOF
drop user ''@'localhost';
drop user ''@'vagrant-ubuntu-precise-64';
drop user 'root'@'vagrant-ubuntu-precise-64';
delete from db where db like 'test%';
drop database test;
flush privileges;
EOF

echo "[vagrant provisioning] Configuring PHP..."
sed -i "s/^;opcache.enable=0/opcache.enable=1/" /etc/php5/fpm/php.ini

echo "[vagrant provisioning] Installing rvm and ruby..."
curl -L https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
usermod -a -G rvm vagrant

echo "[vagrant provisioning] Installing common ruby gems..."
gem install bundler
gem install rake

echo "[vagrant provisioning] Installing ssmtp..."
apt-get install -y ssmtp

if [ ! -z "$GMAIL_ADDRESS" ]
then
  cat <<EOF >/etc/ssmtp/ssmtp.conf
root=$GMAIL_ADDRESS
mailhub=smtp.gmail.com:587
rewriteDomain=$GMAIL_DOMAIN
hostname=$GMAIL_USER
UseSTARTTLS=YES
AuthUser=$GMAIL_USER
AuthPass=$GMAIL_PASSWORD
FromLineOverride=YES
EOF

    chmod 640 /etc/ssmtp/ssmtp.conf
    adduser www-data mail
fi

echo "[vagrant provisioning] Installing composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "[vagrant provisioning] Installing drush..."
composer global require "drush/drush:6.*"

echo "[vagrant provisioning] Installing Pantheon drush components..."
ORIG_DIR=`pwd`
mkdir /home/vagrant/.drush
git clone https://github.com/pantheon-systems/terminus.git /home/vagrant/.drush/terminus
cd /home/vagrant/.drush/terminus
composer update --no-dev
drush cc drush
drush dl drush_sql_sync_pipe --destination=/home/vagrant/.drush
chown -R vagrant:vagrant /home/vagrant/.drush
cd $ORIG_DIR

echo "[vagrant provisioning] Installing java..."
add-apt-repository -y ppa:webupd8team/java
apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get -y install oracle-java7-installer

echo "[vagrant provisioning] Installing selenium..."
mkdir /usr/local/selenium
wget -P /usr/local/selenium http://selenium.googlecode.com/files/selenium-server-standalone-2.39.0.jar

# echo "[vagrant provisioning] Installing node..."
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install -y nodejs

echo "[vagrant provisioning] Creating /var/www..."
mkdir -p /var/www
chmod 777 /var/www

echo "[vagrant provisioning] Installing behat..."
mkdir /var/www/$BEHAT_DIR_NAME
ORIG_DIR=`pwd`
cd /var/www/$BEHAT_DIR_NAME
cat <<EOF >composer.json
{
  "require": {
    "drupal/drupal-extension": "*"
  },
  "config": {
    "bin-dir": "bin/"
  }
}
EOF
composer install
cat <<EOF >behat.yml
default:
  paths:
    features: 'features'
  extensions:
    Behat\MinkExtension\Extension:
      goutte: ~
      selenium2: ~
      base_url: http://$SITE_NAME/
    Drupal\DrupalExtension\Extension:
      blackbox: ~
EOF
cd $ORIG_DIR

##### Configuration #####

echo "[vagrant provisioning] Configuring vagrant box..."

echo "[vagrant provisioning] Setting hostname..."
sh -c "echo 127.0.0.1 $HOSTNAME >>/etc/hosts"
sh -c "echo $HOSTNAME >/etc/hostname"
hostname $HOSTNAME

echo "[vagrant provisioning] Configuring ssh..."
cat <<EOF >>/etc/ssh/ssh_config
    StrictHostKeyChecking no
EOF

# Personal configuration
if [ -e "/vagrant/provision_personal.sh" ]
then
  source /vagrant/provision_personal.sh
fi

##### Project Setup #####

echo "[vagrant provisioning] Checking out project..."
if [ ! -z "$SVN_URL" ]
then
  svn co --username $SVN_USER --password $SVN_PASSWORD --non-interactive --trust-server-cert $SVN_URL /var/www/$SOURCE_DIR_NAME
elif [ ! -z "$GIT_URL" ]
then
  git clone $GIT_URL /var/www/$SOURCE_DIR_NAME
else
  mkdir /var/www/$SOURCE_DIR_NAME
fi
chown -R vagrant:vagrant /var/www/$SOURCE_DIR_NAME

echo "[vagrant provisioning] Setting up nginx..."
cat <<EOF >/etc/nginx/sites-available/$SITE_NAME
server {
    server_name $SITE_NAME;
    root $DOCROOT;

    access_log /var/log/nginx/$SITE_NAME-access.log;
    error_log /var/log/nginx/$SITE_NAME-error.log;

    client_max_body_size 0;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # This matters if you use drush
    location = /backup {
        deny all;
    }

    # Very rarely should these ever be accessed outside of your lan
    location ~* \.(txt|log)\$ {
        allow 10.1.0.0/16;
        deny all;
    }

    location ~ \..*/.*\.php\$ {
        return 403;
    }

    location / {
        # This is cool because no php is touched for static content
        try_files \$uri @rewrite;
    }

    location @rewrite {
        # Some modules enforce no slash (/) at the end of the URL
        # Else this rewrite block wouldn't be needed (GlobalRedirect)
        rewrite ^/(.*)\$ /index.php?q=\$1;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param DRUPAL_CONFIG /var/www/nginx/drupal-config/;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
    }

    # Fighting with ImageCache? This little gem is amazing.
    location ~ ^/sites/.*/files/imagecache/ {
        try_files \$uri @rewrite;
    }
    # Catch image styles for D7 too.
    location ~ ^/sites/.*/files/styles/ {
        try_files \$uri @rewrite;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)\$ {
        expires max;
        log_not_found off;
    }
}
EOF
ln -s /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/$SITE_NAME
service nginx restart

echo "[vagrant provisioning] Setting up mysql..."
mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
create database $DB_NAME;
grant all on $DB_NAME.* to '$DB_USER'@'localhost' identified by '$DB_PASSWORD';
flush privileges;
EOF

echo "[vagrant provisioning] Setting up nfs export..."
mkdir -p /export/$SITE_NAME
cat <<EOF >>/etc/exports
/export 10.1.0.1/24(rw,fsid=root,no_subtree_check)
/export/$SITE_NAME 10.1.0.1/24(rw,sync,all_squash,anonuid=1000,anongid=1000,no_subtree_check,insecure)
EOF
cat <<EOF >>/etc/fstab
/var/www    /export/$SITE_NAME   none    bind  0  0
EOF
mount -a
service nfs-kernel-server restart

##### Provision check #####

# Create .provision_check for the script to check on during a next vargant up.
echo "[vagrant provisioning] Creating .provision_check file..."
touch .provision_check
