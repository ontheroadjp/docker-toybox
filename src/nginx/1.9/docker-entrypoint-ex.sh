#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} nginx
groupmod -g ${TOYBOX_GID} nginx

docroot="/usr/share/nginx/html"
echo "extract ${docroot}"
tar xvzf /usr/src/nginx-default-doc.tar.gz -C ${docroot}
chown -R nginx:nginx ${docroot}

confdir="/etc/nginx"
echo "extract ${confdir}"
tar xvzf /usr/src/nginx-conf.tar.gz -C ${confdir}
chown -R nginx:nginx ${confdir}

exec nginx -g "daemon off;"
