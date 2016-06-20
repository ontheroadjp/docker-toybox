#!/bin/bash
set -e

TOYBOX_UID=1000
TOYBOX_GID=1000

user="www-data"
group="www-data"

usermod -u ${TOYBOX_UID} ${user}
groupmod -g ${TOYBOX_GID} ${group}

docroot="/usr/local/apache2/htdocs"
tar xvzf /usr/src/apache2-default-doc.tar.gz -C ${docroot}

confdir="/usr/local/apache2/conf"
tar xvzf /usr/src/apache2-conf.tar.gz -C ${confdir}
chown -R ${user}:${group} ${confdir}

exec httpd-foreground
