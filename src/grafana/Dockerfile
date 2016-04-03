FROM grafana/grafana:2.6.0

RUN apt-get update && \
    apt-get install -y sqlite3 && \
    apt-get clean

#COPY dashboards /dashboards
#COPY grafana.db /grafana.db
COPY sql/data_source.sql /data_source.sql
RUN chmod 755 /data_source.sql

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
