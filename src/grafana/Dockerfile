FROM grafana/grafana:2.6.0

RUN apt-get update && \
    apt-get install -y sqlite3 && \
    apt-get clean

#COPY dashboards/ /var/lib/grafana/
#COPY grafana.db /grafana.db
COPY sql/data_source.sql /data_source.sql

#cp -r /dashboards/ /var/lib/grafana
RUN touch /var/lib/grafana/grafana.db \
    && sqlite3 /var/lib/grafana/grafana.db < /data_source.sql

ENTRYPOINT ["/run.sh"]
