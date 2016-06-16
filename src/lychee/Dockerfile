FROM php:7.0.7-apache
MAINTAINER NutsProject, LLC <dev@nutsproject.co.jp>

## ------------------------------------------------------------------------------
## Install base
#RUN apt-get update && install -yq supervisor wget git unzip nginx fontconfig-config fonts-dejavu-core \
#    php5-fpm php5-common php5-json php5-cli php5-common php5-mysql\
#    php5-gd php5-json php5-mcrypt php5-readline psmisc ssl-cert \
#    ufw php-pear libgd-tools libmcrypt-dev mcrypt

# ------------------------------------------------------------------------------
# Install Lychee
RUN apt-get update && apt-get install -y git libmcrypt-dev libpng12-dev unzip wget \
    && docker-php-ext-install exif gd json mbstring mysqli zip

WORKDIR /var/www
RUN git clone https://github.com/electerious/Lychee.git html \
    && chown -R www-data:www-data /var/www/html
#RUN chmod -R 770 /var/www/html
#RUN chmod -R 777 /var/www/html/uploads/ 
#RUN chmod -R 777 /var/www/html/data/
RUN chmod -R 777 html/data/ html/uploads/
COPY conf/lychee.ini /usr/local/etc/php/conf.d/

# ------------------------------------------------------------------------------
EXPOSE 80

WORKDIR /
RUN ln -s /var/www/html/uploads uploads 
RUN ln -s /var/www/html/data data

VOLUME /uploads
VOLUME /data

COPY docker-entrypoint.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
CMD ["apache2-foreground"]
