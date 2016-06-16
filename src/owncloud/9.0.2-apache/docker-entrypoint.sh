#!/bin/bash
set -e

usermod -u ${TOYBOX_UID} www-data
groupmod -g ${TOYBOX_GID} www-data

sh /entrypoint.sh

docroot="/var/www/html"
chown -R www-data:www-data ${docroot}
#cd ${docroot}

sleep 30 

if [ -f "${docroot}/config/config.php" ]; then
    sed -i -e "s/'dbhost' => '.*\..*\..*\..*'/'dbhost' => '${MYSQL_PORT_3306_TCP_ADDR}'/g" ${docroot}/config/config.php
else
    sudo -u www-data php /usr/src/owncloud/occ maintenance:install \
        --database "mysql" \
        --database-host ${MYSQL_PORT_3306_TCP_ADDR} \
        --database-name ${MYSQL_ENV_MYSQL_DATABASE} \
        --database-user ${MYSQL_ENV_MYSQL_USER} \
        --database-pass ${MYSQL_ENV_MYSQL_PASSWORD} \
        --admin-user "toybox" \
        --admin-pass "toybox"

    sudo -u www-data php /usr/src/owncloud/occ config:system:set trusted_domains \
        0 --value ${VIRTUAL_HOST}

    sudo -u www-data php /usr/src/owncloud/occ config:system:set logtimezone \
        --value=${TIMEZONE}

    sudo -u www-data php /usr/src/owncloud/occ config:system:set memcache.local \
        --value="\OC\Memcache\APCu"

    sudo -u www-data php /usr/src/owncloud/occ config:system:set memcache.locking \
        --value="\OC\Memcache\Redis"

    sudo -u www-data php /usr/src/owncloud/occ config:system:set redis \
        'host' --value redis

    sudo -u www-data php /usr/src/owncloud/occ config:system:set redis \
        'port' --value 6379

fi

exec "$@"
