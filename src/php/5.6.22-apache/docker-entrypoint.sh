#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} www-data
groupmod -g ${TOYBOX_GID} www-data

docroot="/var/www/html"

echo "hohoo!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#tar cf - --one-file-system -C /usr/src/default_docroot . | tar xf -
chown -R www-data:www-data ${docroot}

exec "$@"
