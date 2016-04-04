#!/bin/sh

src=$TOYBOX_HOME/src/${app_name}

db_name=${app_name}
db_user=${app_name}
db_user_pass=${app_name}

function __source() {
    #if [ ! -e ${src} ]; then
    #    git clone https://github.com/docker-library/wordpress.git ${src}
    #fi
    :
}

function __build() {
    docker build -t nutsp/toybox-grafana ${src}
}

main_container=${fqdn}-${app_name}
db_container=${fqdn}-${app_name}-db
data_container=${fqdn}-${app_name}-data

influxdb_container=influxdb
graphite_container=graphite
grafana_container=grafana

function __init() {

    __build

    mkdir -p ${app_path}/bin
    cat <<-EOF > ${compose_file}
${influxdb_container}:
    #image: "tutum/influxdb:0.8.8"
    image: "tutum/influxdb:0.9"
    ports:
        - "8083:8083" # for WEB UI
        - "8086:8086" # for HTTP API
        #- "8083"
        #- "8086"
    volumes:
        - ${app_path}/data/influxdb:/data
        - ${app_path}/data/influxdb/log:/var/log/influxdb
    expose:
        - "8090"
        - "8099"
    environment:
        - PRE_CREATE_DB=cadvisor;test;test2
        #- VIRTUAL_HOST=influxdb.docker-toybox.com
        #- VIRTUAL_PORT=8083

${graphite_container}:
    image: sitespeedio/graphite
    ports:
        - "8080:80"
        - "2003:2003"
    volumes:
        - ${app_path}/data/graphite:/opt/graphite/storage/whisper
        - ${app_path}/data/graphite/log:/var/log/carbon
    
${grafana_container}:
    #image: "grafana/grafana:2.1.3"
    #image: "grafana/grafana:2.6.0"
    image: "nutsp/toybox-grafana"
    links:
        - ${influxdb_container}:influxdb
        - ${graphite_container}:graphite
    environment:
        - INFLUXDB_HOST=localhost
        - INFLUXDB_PORT=8086
        - INFLUXDB_NAME=cadvisor
        - INFLUXDB_USER=root
        - INFLUXDB_PASS=root
        - GF_SECURITY_ADMIN_USER=toybox
        - GF_SECURITY_ADMIN_PASSWORD=toybox
        - GF_DASHBOARDS_JSON_ENABLED=true
        - VIRTUAL_HOST=grafana.docker-toybox.com
    volumes:
        - ${app_path}/data/grafana:/var/lib/grafana
        - ${app_path}/data/grafana/log:/var/log/grafana
    ports:
        - "3000"

#cadvisor:
#    image: "google/cadvisor:0.16.0"
#    volumes:
#        - "/:/rootfs:ro"
#        - "/var/run:/var/run:rw"
#        - "/sys:/sys:ro"
#        - "/var/lib/docker/:/var/lib/docker:ro"
#    links:
#        - ${influxdb_container}:influxdb
#    environment:
#        - VIRTUAL_HOST=cadvisor.docker-toybox.com
#    command: "-storage_driver=influxdb -storage_driver_db=cadvisor -storage_driver_host=influxdb:8086 -storage_driver_user=root -storage_driver_password=root -storage_driver_secure=False"
#    ports:
#        - "8080"
#
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

function __up() {
    __init && {
        cd ${app_path}/bin
        docker-compose -p ${project_name} up -d && {
            echo '---------------------------------'
            echo 'URL: http://'${fqdn}
            echo "URL: influxdb for web ui:http://xxx.xxx.xxx.xxx:8083 - root/root"
            echo "URL: influxdb for api   :http://xxx.xxx.xxx.xxx:8086 - root/root"
            echo "URL: graphite:http://xxx.xxx.xxx.xxx:8080 - guest/guest"
            echo "URL: http://cadvisor.${domain}"
            echo "URL: http://grafana.${domain} - admin/admin"
            echo '---------------------------------'
            echo "*/5 * * * * sh ${app_path}/bin/sitespeed.sh http://xxx.xxx.xxx"
            #cp ${src}/sitespeed.sh ${app_path}/bin/
            grafana_container_id=$(docker ps | grep toybox_grafana | awk '{print $1}')
        }
    }
    sleep 10
    docker exec -t ${grafana_container_id} sh -c '/usr/bin/sqlite3 /var/lib/grafana/grafana.db < /data_source.sql'
}

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

