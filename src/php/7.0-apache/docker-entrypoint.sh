#!/bin/bash
set -e

root_dir="/var/www/html"

tar cf - --one-file-system -C /usr/src/default_docroot . | tar xf -
chown -R www-data:www-data ${root_dir}

apache2-foreground
exec "$@"
