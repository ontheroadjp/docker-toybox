FROM wordpress:4.5.3-fpm
MAINTAINER NutsProject, LLC

COPY Search-Replace-DB/ /usr/src/wordpress/Search-Replace-DB/
COPY default.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
