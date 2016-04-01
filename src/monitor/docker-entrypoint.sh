#!/bin/sh
set -e

cp -r /dashboards/ /var/lib/grafana
cp -r /grafana.db /var/lib/grafana
#sqlite3 /var/lib/grafana/grafana.db < /data_source.sql

sh /run.sh

#exec "$@"
