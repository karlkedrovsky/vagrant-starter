#!/bin/bash

#
# This script is intended to be the counter to createdrupalsite.sh and
# it probably only makes sense to use it on sites created with that
# script. Take a look at the comments at the top of that script before
# using either one.
#

if [[ -z $1 || $2 ]]; then
    echo ""
    echo "Usage: $0 site_name"
    echo ""
    exit 1
fi

SITE_NAME=$1

if [[ ! -d "$SITE_NAME" ]]; then
    echo ""
    echo "No directory named \"$SITE_NAME\" found in the current directory."
    echo ""
    exit 1
fi

DATE_TIME=`date +"%Y%m%dT%H%M%S"`

echo ""
echo "Backing up database to $SITE_NAME-$DATE_TIME.sql.gz..."
echo ""

mysqldump -u$SITE_NAME -p$SITE_NAME $SITE_NAME >$SITE_NAME-$DATE_TIME.sql
gzip $SITE_NAME-$DATE_TIME.sql

echo ""
echo "Backing up docroot to $SITE_NAME-$DATE_TIME.tar.gz..."
echo ""

tar czf $SITE_NAME-$DATE_TIME.tar.gz $SITE_NAME

echo ""
echo "Removing docroot..."
echo ""

sudo rm -rf $SITE_NAME

echo ""
echo "Dropping database..."
echo ""

mysql -uroot -proot <<EOF
drop database $SITE_NAME;
drop user '$SITE_NAME'@'localhost';
flush privileges;
EOF

echo ""
echo "Removing nginx config..."
echo ""

sudo rm /etc/nginx/sites-enabled/$SITE_NAME
sudo rm /etc/nginx/sites-available/$SITE_NAME
sudo service nginx reload
