FROM mariadb
MAINTAINER NutsProject,LLC

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh
RUN chmod +x /entrypoint-ex.sh

COPY dump.sql /docker-entrypoint-initdb.d/dump.sql

ENTRYPOINT ["/entrypoint-ex.sh"]
