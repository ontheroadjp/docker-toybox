#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} www-data
groupmod -g ${TOYBOX_GID} www-data
chown -R www-data:root /var/run/apache2/
chown -R www-data:www-data /usr/src/wordpress

script="${DOCROOT}/Search-Replace-DB/srdb.cli.php"
h=${MYSQL_PORT_3306_TCP_ADDR}
u=${WORDPRESS_DB_USER}
p=${WORDPRESS_DB_PASSWORD}
n=${WORDPRESS_DB_NAME}
s=${FQDN_REPLACED}
r=${VIRTUAL_HOST}
replace_fqdn_cmd="php ${script} -h='${h}' -u='${u}' -p='${p}' -n='${n}' -s='${s}' -r='${r}'"

ss=${REMOTE_WP_DIR}
rr=${DOCROOT}
replace_docroot_cmd="php ${script} -h='${h}' -u='${u}' -p='${p}' -n='${n}' -s='${ss}' -r='${rr}'"

if='if [ ${EXEC_REPLACE_DB} -eq 1 ]; then'
fi="fi"

sed -i -e "$ i ${if}" /entrypoint.sh
sed -i -e "$ i ${replace_fqdn_cmd}" /entrypoint.sh
sed -i -e "$ i ${replace_docroot_cmd}" /entrypoint.sh
sed -i -e "$ i ${fi}" /entrypoint.sh

echo "post_max_size = 32M" >> /usr/local/etc/php/php.ini
echo "upload_max_filesize = 32M" >> /usr/local/etc/php/php.ini

exec /entrypoint.sh apache2-foreground
