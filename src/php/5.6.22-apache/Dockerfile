FROM php:5.6.22-apache
MAINTAINER NutsProject, LLC <dev@nutsproject.co.jp>

RUN a2enmod rewrite expires

RUN apt-get update && apt-get install -y git unzip wget \
    libmcrypt-dev mcrypt libpng12-dev libjpeg-dev libgd-tools && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install exif gd json mbstring mcrypt mysqli opcache zip

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install calendar exif gd gettext json mbstring mcrypt mysqli opcache pdo_mysql sockets zip

RUN pecl install -o -f redis xdebug \
    && rm -rf /tmp/pear \
    && echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini \
    && echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20131226/xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini

# set php.ini
RUN { \
        echo 'max_execution_time = 200'; \
        echo 'post_max_size = 100M'; \
        echo 'upload_max_size = 100M'; \
        echo 'upload_max_filesize = 20M'; \
        echo 'memory_limit = 256M'; \
        echo ''; \
        echo '[Date]'; \
        echo 'date.timezone = Asia/Tokyo'; \
	} > /usr/local/etc/php/php.ini

# set conf.d/opcache.ini
# see https://secure.php.net/Ref man ual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN echo '<?php phpinfo(); ?>' > /var/www/html/info.php

VOLUME /var/www/html
COPY docker-entrypoint.sh /entrypoint-ex.sh
ENTRYPOINT ["/entrypoint-ex.sh"]
CMD ["apache2-foreground"]
