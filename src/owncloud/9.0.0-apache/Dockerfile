FROM owncloud:9.0.1-apache

RUN apt-get update && apt-get install -y sudo
#RUN apt-get install -y redis-server php5-redis

RUN a2enmod ssl && a2ensite default-ssl

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
