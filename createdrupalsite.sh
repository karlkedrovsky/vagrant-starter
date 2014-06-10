#!/bin/bash

#
# This script takes a single parameter ("site name") and creates a
# drupal site. This is simply an automation of the manual steps I
# would go through when setting up a temporary or demo drupal site.
#
# This is NOT meant to be a bullet proof, all encompassing solution
# for every need. It's just something that saves me a little
# time. Before using this script make sure you read through it
# completely and understand what it's doing.
#
# Currently the only server I run this on is Ubuntu Server
# 14.04. There's a good chance that something in here may be specific
# to that platform.
#
# There is also a companion script, deletedrupalsite.sh, that reverses
# everything you'll find here.
#

if [[ -z $1 || $2 ]]; then
    echo ""
    echo "Usage: $0 site_name"
    echo ""
    exit 1
fi

SITE_NAME=$1

if [[ ${#SITE_NAME} -gt 16 ]]; then
    echo ""
    echo "Usage: $0 site_name"
    echo "  Site name must be 16 characters or less"
    echo ""
    exit 1
fi

echo ""
echo "Creating mysql database and user..."
echo ""

mysql -uroot -proot <<EOF
create database $SITE_NAME;
grant all on $SITE_NAME.* to '$SITE_NAME'@'localhost' identified by '$SITE_NAME';
flush privileges;
EOF

echo ""
echo "Downloading Drupal..."
echo ""

drush dl drupal
mv drupal-7.* $SITE_NAME
cd $SITE_NAME
mkdir sites/all/modules/contrib
mkdir sites/all/modules/custom
mkdir sites/all/modules/features
drush si standard install_configure_form.update_status_module='array(FALSE,FALSE)' -y --account-name=admin --account-pass=admin --account-mail=karl+$SITE_NAME@kedrovsky.com --db-url=mysql://$SITE_NAME:$SITE_NAME@localhost/$SITE_NAME --site-name=$SITE_NAME --site-mail=karl+$SITE_NAME@kedrovsky.com
drush dl admin_menu ctools views devel coder features strongarm token pathauto backup_migrate webform
drush dis -y toolbar
drush en -y ctools token admin_menu admin_menu_toolbar views views_ui devel coder features strongarm pathauto backup_migrate webform
drush cc all

echo ""
echo "Fixing permissions..."
echo ""

chmod a+w sites/default
chmod -R a+w sites/default/files

echo ""
echo "Creating initial tags file..."
echo ""

ctags -e --langmap=php:.engine.inc.module.theme.install.php --php-kinds=cdfi --languages=php --recurse

echo ""
echo "Setting up initial git repo..."
echo ""

cat <<EOF >>.gitignore

# Ignore emacs tags file
/TAGS
EOF
git init
git add .
git commit -qm 'Initial checkin'

echo ""
echo "Setting up nginx virtual host..."
echo ""

cat <<EOF >/tmp/nginx_$$
server {
    server_name $SITE_NAME;
    root /var/www/$SITE_NAME;

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
sudo mv /tmp/nginx_$$ /etc/nginx/sites-available/$SITE_NAME
sudo ln -s /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/$SITE_NAME
sudo service nginx reload
