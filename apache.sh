#!/bin/sh

APACHE_CONFDIR=/etc/apache2
APACHE_ENVVARS=$APACHE_CONFDIR/envvars

# Load the environmentals
. $APACHE_ENVVARS

/usr/sbin/a2enmod fastcgi
/usr/sbin/a2enmod rewrite
exec /usr/sbin/apache2 -d /etc/apache2 -k start -DFOREGROUND
