#!/bin/bash
set -e

root_dir="/var/www/html"
chown -R www-data:www-data ${root_dir}
apache2-foreground

exec "$@"
