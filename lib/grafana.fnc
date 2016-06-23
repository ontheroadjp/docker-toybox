#!/bin/sh

containers=( 
    ${fqdn}-${app_name}-influxdb 
    ${fqdn}-${app_name}-cadvisor 
    ${fqdn}-${app_name}-graphite 
    ${fqdn}-${app_name}-grafana 
)

function __init() {

    #__build

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/influxdb
    mkdir -p ${app_path}/data/graphite
    mkdir -p ${app_path}/data/grafana/log

    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: "tutum/influxdb:0.8.8"
    #image: "tutum/influxdb:0.9"
    #image: "influxdb:0.13.0-alpine"
    ports:
        - "8083:8083" # for WEB UI
        - "8086:8086" # for HTTP API
        #- "8083"
        #- "8086"
    volumes:
        - ${app_path}/data/influxdb:/data
        - ${app_path}/data/influxdb/log:/var/log/influxdb
    #expose:
    #    - "8090"
    #    - "8099"
    environment:
        - PRE_CREATE_DB=cadvisor;grafana
    #    - VIRTUAL_HOST=influxdb.docker-toybox.com
    #    - VIRTUAL_PORT=8083

${containers[1]}:
    image: "google/cadvisor:0.16.0"
    volumes:
        #- "/:/rootfs:ro"
        - "/var/run:/var/run:rw"
        - "/sys:/sys:ro"
        - "/var/lib/docker/:/var/lib/docker:ro"
    links:
        - ${containers[0]}:influxdb
    environment:
        - VIRTUAL_HOST=cadvisor.docker-toybox.com
    command: "-storage_driver=influxdb -storage_driver_db=cadvisor -storage_driver_host=influxdb:8086 -storage_driver_user=root -storage_driver_password=root -storage_driver_secure=False"
    ports:
        - "8080"

${containers[2]}:
    image: sitespeedio/graphite
    ports:
        #- "8080:80"
        #- "2003:2003"
        - "80"
        - "2003"
    environment:
        - VIRTUAL_HOST=graphite.docker-toybox.com
        - VIRTUAL_PORT=80
    volumes:
        - ${app_path}/data/graphite:/opt/graphite/storage/whisper
        - ${app_path}/data/graphite/log:/var/log/carbon
    
${containers[3]}:
    #image: "grafana/grafana:3.0.4"
    image: "grafana/grafana:master"
    links:
        - ${containers[0]}:influxdb
        - ${containers[1]}:graphite
    environment:
        - VIRTUAL_HOST=grafana.docker-toybox.com
        - GF_INSTALL_PLUGINS=grafana-influxdb-08-datasource
        - GF_SECURITY_ADMIN_USER=toybox
        - GF_SECURITY_ADMIN_PASSWORD=toybox
        - GF_DASHBOARDS_JSON_ENABLED=true
    #volumes:
    #    #- ${app_path}/data/grafana:/var/lib/grafana
    #    #- ${app_path}/data/grafana/:/usr/share/grafana
    #    - $TOYBOX_HOME/src/grafana/conf/dashboards.json:/var/lib/grafana/dashboards/dashboards.json
    #    - ${app_path}/data/grafana/log:/var/log/grafana
    ports:
        #- "3000:3000"
        - "3000"

#${containers[3]}:
#    image: "tutum/grafana"
#    links:
#        - ${containers[0]}:influxdb
#        - ${containers[1]}:graphite
#    environment:
#        - VIRTUAL_HOST=grafana.docker-toybox.com
#        - INFLUXDB_HOST=localhost
#        - INFLUXDB_PORT=8086
#        - INFLUXDB_NAME=cadvisor
#        - INFLUXDB_USER=root
#        - INFLUXDB_PASS=root
#        - INFLUXDB_IS_GRAFANADB=true
#        - HTTP_USER=test
#        - HTTP_PASS=test
#        #- GF_INSTALL_PLUGINS=grafana-influxdb-08-datasource
#        #- GF_SECURITY_ADMIN_USER=toybox
#        #- GF_SECURITY_ADMIN_PASSWORD=toybox
#        #- GF_DASHBOARDS_JSON_ENABLED=true
#    #volumes:
#    #    #- ${app_path}/data/grafana:/var/lib/grafana
#    #    #- ${app_path}/data/grafana/:/usr/share/grafana
#    #    - $TOYBOX_HOME/src/grafana/conf/dashboards.json:/var/lib/grafana/dashboards/dashboards.json
#    #    - ${app_path}/data/grafana/log:/var/log/grafana
#    ports:
#        - "3000"

#sitespeedio:
#    image: sitespeedio/sitespeed.io
#    privileged: true
#    links:
#        - ${graphite_container}
#    volumes:
#        - ${app_path}/data/sitespeed.io:/sitespeed.io
#
#sitespeedio-chrome:
#    image: sitespeedio/sitespeed.io-chrome
#    privileged: true
#    links:
#        - ${graphite_container}
#    volumes:
#        - ${app_path}/data/sitespeed.io:/sitespeed.io
EOF
}

#function __new() {
#    __init && {
#        cd ${app_path}/bin
#        docker-compose -p ${project_name} up -d && {
#            echo '---------------------------------'
#            echo 'URL: http://'${fqdn}
#            echo "URL: influxdb for web ui:http://xxx.xxx.xxx.xxx:8083 - root/root"
#            echo "URL: influxdb for api   :http://xxx.xxx.xxx.xxx:8086 - root/root"
#            echo "URL: graphite:http://xxx.xxx.xxx.xxx:8080 - guest/guest"
#            echo "URL: http://cadvisor.${domain}"
#            echo "URL: http://grafana.${domain} - admin/admin"
#            echo '---------------------------------'
#            echo "*/5 * * * * sh ${app_path}/bin/sitespeed.sh http://xxx.xxx.xxx"
#            #cp ${src}/sitespeed.sh ${app_path}/bin/
#            grafana_container_id=$(docker ps | grep toybox_grafana | awk '{print $1}')
#        }
#    }
#    sleep 10
#    docker exec -t ${grafana_container_id} sh -c '/usr/bin/sqlite3 /var/lib/grafana/grafana.db < /data_source.sql'
#}

#function __backup() {
#    prefix=$(date '+%Y%m%d_%H%M%S')
#    history_file=${app_path}/backup/history.txt
#    mkdir -p ${app_path}/backup
#    if [ ! -e $history_file ]; then
#        echo "" >> ${history_file}    
#    fi
#    sed -i -e "1s/^/${prefix}\n/" ${history_file}
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${data_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}_db.tar.gz /var/lib/mysql
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${main_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}.tar.gz /var/www/html
#}
#
#function __restore() {
#    prefix=$(cat ${app_path}/backup/history.txt | peco)
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${data_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}_db.tar.gz
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${main_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}.tar.gz
#    _stop && {
#        _start
#    }
#}

