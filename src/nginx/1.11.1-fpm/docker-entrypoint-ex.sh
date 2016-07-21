#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} nginx
groupmod -g ${TOYBOX_GID} nginx

docroot="/var/www/html"
#echo "extract ${docroot}"
#tar xvzf /usr/src/nginx-default-doc.tar.gz -C ${docroot}
chown -R nginx:nginx ${docroot}

confdir="/etc/nginx"
echo "extract ${confdir}"
tar xvzf /usr/src/nginx-conf.tar.gz -C ${confdir}
cp /default.conf /etc/nginx/conf.d
chown -R nginx:nginx ${confdir}

sed -i -e "s:server_name.*localhost;:server_name ${VIRTUAL_HOST};:" /etc/nginx/conf.d/default.conf

exec nginx -g "daemon off;"
