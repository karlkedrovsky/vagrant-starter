#!/bin/bash

# Provision a VM with just a simple web server (nginx)
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

echo "[vagrant provisioning] Installing common packages..."
apt-get install -y mg nginx keychain zsh subversion git curl nfs-kernel-server zip unzip libjpeg-progs optipng

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
mkdir -p /var/www
chmod 777 /var/www
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

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)\$ {
        expires max;
        log_not_found off;
    }
}
EOF
ln -s /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/$SITE_NAME
service nginx restart

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
