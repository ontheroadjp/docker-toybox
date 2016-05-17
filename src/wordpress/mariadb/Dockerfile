FROM mariadb
MAINTAINER NutsProject,LLC

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh
RUN chmod +x /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
#ENTRYPOINT ["/docker-entrypoint.sh"]
#CMD ["mysqld"]
