#!/bin/sh
set -e

cp -r /dashboards/ /var/lib/grafana
cp -r /grafana.db /var/lib/grafana

sh /run.sh

## ----- /run.sh -----
#: "${GF_PATHS_DATA:=/var/lib/grafana}"
#: "${GF_PATHS_LOGS:=/var/log/grafana}"
#
#chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_LOGS"
#chown -R grafana:grafana /etc/grafana
#
###exec gosu grafana /usr/sbin/grafana-server  \
#gosu grafana /usr/sbin/grafana-server  \
#    --homepath=/usr/share/grafana           \
#    --config=/etc/grafana/grafana.ini       \
#    cfg:default.paths.data="$GF_PATHS_DATA" \
#    cfg:default.paths.logs="$GF_PATHS_LOGS"
## ----- /run.sh -----

#sqlite3 /var/lib/grafana/grafana.db < /data_source.sql

#exec "$@"
