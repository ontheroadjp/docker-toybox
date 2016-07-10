#!/bin/bash
set -e

user="www-data"
group="www-data"

usermod -u ${TOYBOX_UID} ${user}
groupmod -g ${TOYBOX_GID} ${group}

docroot="/var/www/html"
tar xvzf /usr/src/apache2-default-doc.tar.gz -C ${docroot}
chown -R ${user}:${group} ${docroot}

apache2_confdir="/etc/apache2"
tar xvzf /usr/src/apache2-conf.tar.gz -C ${apache2_confdir}
chown -R ${user}:${group} ${apache2_confdir}

php_confdir="/usr/local/etc/php"
tar xvzf /usr/src/php-conf.tar.gz -C ${php_confdir}
chown -R ${user}:${group} ${php_confdir}

exec "$@"
