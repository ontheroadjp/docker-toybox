#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} nginx
groupmod -g ${TOYBOX_GID} nginx

docroot="/usr/share/nginx/html"
tar xvzf /usr/src/nginx-default-doc.tar.gz -C ${docroot}
chown -R nginx:nginx ${docroot}

exec nginx -g "daemon off;"
