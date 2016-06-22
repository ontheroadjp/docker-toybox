#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} www-data
groupmod -g ${TOYBOX_GID} www-data
chown -R www-data:root /var/run/apache2/
chown -R www-data:www-data /usr/src/wordpress


if [ ${EXEC_REPLACE_DB} -eq 1 ]; then

    script="/var/www/html/Search-Replace-DB/srdb.cli.php"

    # replace db infomation
    h=${MYSQL_PORT_3306_TCP_ADDR}
    u=${WORDPRESS_DB_USER}
    p=${WORDPRESS_DB_PASSWORD}
    n=${WORDPRESS_DB_NAME}
    s=${FQDN_REPLACED}
    r=${VIRTUAL_HOST}
    replace_fqdn_cmd="php ${script} -h='${h}' -u='${u}' -p='${p}' -n='${n}' -s='${s}' -r='${r}'"

    # replace document root
    ss=${REMOTE_WP_DIR}
    rr="/var/www/html"
    replace_docroot_cmd="php ${script} -h='${h}' -u='${u}' -p='${p}' -n='${n}' -s='${ss}' -r='${rr}'"

    sed -i -e "$ i ${replace_fqdn_cmd}" /entrypoint.sh
    sed -i -e "$ i ${replace_docroot_cmd}" /entrypoint.sh
fi

exec /entrypoint.sh apache2-foreground
