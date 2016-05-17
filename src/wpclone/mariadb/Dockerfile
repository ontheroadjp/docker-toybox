FROM mariadb
MAINTAINER NutsProject,LLC

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh
RUN chmod +x /entrypoint-ex.sh

COPY db_dump.sql /docker-entrypoint-initdb.d/db_dump.sql

ENTRYPOINT ["/entrypoint-ex.sh"]
