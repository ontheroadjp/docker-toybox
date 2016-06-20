#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} nginx
groupmod -g ${TOYBOX_GID} nginx

cp /usr/src/nginx/* /usr/share/nginx/html

exec nginx -g "daemon off;"
