FROM wordpress
MAINTAINER NutsProject,LLC

COPY Search-Replace-DB/ /usr/src/wordpress/Search-Replace-DB/
COPY docker-entrypoint-ex.sh /entrypoint-ex.sh
RUN chmod +x /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
