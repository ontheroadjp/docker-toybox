#!/bin/sh

src=$TOYBOX_HOME/src/${app_name}

db_name=${app_name}
db_user=${app_name}
db_user_pass=${app_name}

function __source() {
    if [ ! -e ${src} ]; then
        git clone https://github.com/docker-library/wordpress.git ${src}
    fi
}

function __build() {
    docker build -t nutsp/toybox-monitor ${src}
}

main_container=${fqdn}-${app_name}
db_container=${fqdn}-${app_name}-db
data_container=${fqdn}-${app_name}-data

function __init() {

    __build

    mkdir -p ${app_path}/bin
#    cat <<-EOF > ${app_path}/bin/sitespeed.sh
##docker run --privileged --rm -v $(pwd)/data:/sitespeed.io sitespeedio/sitespeed.io sitespeed.io -u http://dev.ontheroad.jp -b firefox -n 3 --connection cable --graphiteHost 172.17.2.98 --graphiteData summary,rules,pagemetrics,timings,timings
##docker run     \
##    --privileged \ # 権限を与える
##    --rm         \ # 実行したらコンテナを消す
##    -v $(pwd)/data:/sitespeed.io \ # ディレクトリを共有
##    sitespeedio/sitespeed.io \ # コンテナ名
##    sitespeed.io             \ # ここからはコマンド実行
##    -u http://dev.ontheroad.jp       \ # ターゲット URL
##    -b firefox               \ # ブラウザ
##    -n 3                     \ # 回数
##    --connection cable       \ # 回線エミュレート
##    --graphiteHost 160.16.229.167 \ # ここはホストを IP で指定 2003 ポートに送られる
##    --graphiteData summary,rules,pagemetrics,timings,timings \ # 全ての情報を graphite に送る
#EOF

#    sitespeed_shell_file=${app_path}/bin/sitespeed.sh
#    echo '#!/bin/bash' > ${app_path}/bin/sitespeed.sh
#    echo 'YOU=`whoami`' >> ${app_path}/bin/sitespeed.sh
#    echo 'HELP=' >> ${app_path}/bin/sitespeed.sh
#    echo 'BROWSER="firefox"' >> ${app_path}/bin/sitespeed.sh
#    echo 'IMAGE="sitespeed.io"' >> ${app_path}/bin/sitespeed.sh
#    echo '' >> ${app_path}/bin/sitespeed.sh
#    echo 'while getopts d: OPT; do' >> ${app_path}/bin/sitespeed.sh
#    echo '    case $OPT in' >> ${app_path}/bin/sitespeed.sh
#    echo '        d) BROWSER=$OPTARG' >> ${app_path}/bin/sitespeed.sh
#    echo '           ;;' >> ${app_path}/bin/sitespeed.sh
#    echo '    esac' >> ${app_path}/bin/sitespeed.sh
#    echo 'done' >> ${app_path}/bin/sitespeed.sh
#    echo '' >> ${app_path}/bin/sitespeed.sh
#    echo 'usage_exit() {' >> ${app_path}/bin/sitespeed.sh
#    echo '    echo "Measurement URL must be supplied!"' >> ${app_path}/bin/sitespeed.sh
#    echo '    echo "Usage: "' >> ${app_path}/bin/sitespeed.sh
#    echo '    echo "    ./sitespeedio.sh [-b browser] [URL]"' >> ${app_path}/bin/sitespeed.sh
#    echo '    exit 1' >> ${app_path}/bin/sitespeed.sh
#    echo '}' >> ${app_path}/bin/sitespeed.sh
#    echo '' >> ${app_path}/bin/sitespeed.sh
#    echo 'if [ "$1" = "" ];then' >> ${app_path}/bin/sitespeed.sh
#    echo '    usage_exit' >> ${app_path}/bin/sitespeed.sh
#    echo 'fi' >> ${app_path}/bin/sitespeed.sh
#    echo '' >> ${app_path}/bin/sitespeed.sh
#    echo 'if [ ! "$BROWSER" = "chrome" -a ! "$BROWSER" = "firefox" ]; then' >> ${app_path}/bin/sitespeed.sh
#    echo '    echo "[ERROR] Invalid target browser."' >> ${app_path}/bin/sitespeed.sh
#    echo '    usage_exit' >> ${app_path}/bin/sitespeed.sh
#    echo 'fi' >> ${app_path}/bin/sitespeed.sh
#    echo '' >> ${app_path}/bin/sitespeed.sh
#    echo 'if [ "$BROWSER" = "chrome" ]; then' >> ${app_path}/bin/sitespeed.sh
#    echo '    IMAGE="sitespeed.io-chrome"' >> ${app_path}/bin/sitespeed.sh
#    echo 'fi' >> ${app_path}/bin/sitespeed.sh
#    echo '' >> ${app_path}/bin/sitespeed.sh
#    echo 'echo "==================================================="' >> ${app_path}/bin/sitespeed.sh
#    echo 'echo "sitespeed.io performance tracking"' >> ${app_path}/bin/sitespeed.sh
#    echo 'echo "==================================================="' >> ${app_path}/bin/sitespeed.sh
#    echo '' >> ${app_path}/bin/sitespeed.sh
#    
#    echo 'selfpath=$(cd $(dirname $0);pwd)' >> ${app_path}/bin/sitespeed.sh
#    
#    echo '' >> ${app_path}/bin/sitespeed.sh
#    echo 'docker run \' >> ${app_path}/bin/sitespeed.sh
#    echo '    --privileged \' >> ${app_path}/bin/sitespeed.sh
#    echo '    --rm \' >> ${app_path}/bin/sitespeed.sh
#    echo '    --link toybox_graphite_1:graphite \' >> ${app_path}/bin/sitespeed.sh
#    echo '    -v ${selfpath}/../data/sitespeed.io:/sitespeed.io \' >> ${app_path}/bin/sitespeed.sh
#    echo '    sitespeedio/${IMAGE} \' >> ${app_path}/bin/sitespeed.sh
#    echo '    ${IMAGE} \' >> ${app_path}/bin/sitespeed.sh
#    echo '    -u $1 \' >> ${app_path}/bin/sitespeed.sh
#    echo '    -b ${BROWSER} \' >> ${app_path}/bin/sitespeed.sh
#    echo '    -n 5 \' >> ${app_path}/bin/sitespeed.sh
#    echo '    -d 0 \' >> ${app_path}/bin/sitespeed.sh
#    echo '    -r /tmp \' >> ${app_path}/bin/sitespeed.sh
#    echo '    --graphiteHost graphite \' >> ${app_path}/bin/sitespeed.sh
#    echo '    --graphiteNamespace sitespeed.io \' >> ${app_path}/bin/sitespeed.sh
#    echo '    --graphiteDate summary,rules,pagemetrics,timings \' >> ${app_path}/bin/sitespeed.sh
#    
    cat <<-EOF > ${compose_file}
influxDB:
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

graphite:
    image: sitespeedio/graphite
    ports:
        - "8080:80"
        - "2003:2003"
    volumes:
        - ${app_path}/data/graphite:/opt/graphite/storage/whisper
        - ${app_path}/data/graphite/log:/var/log/carbon
    
grafana:
    #image: "grafana/grafana:2.1.3"
    #image: "grafana/grafana:2.6.0"
    image: "nutsp/toybox-monitor"
    links:
        - "influxDB:influxdb"
        - "graphite:graphite"
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

cadvisor:
    image: "google/cadvisor:0.16.0"
    volumes:
        - "/:/rootfs:ro"
        - "/var/run:/var/run:rw"
        - "/sys:/sys:ro"
        - "/var/lib/docker/:/var/lib/docker:ro"
    links:
        - "influxDB:influxdb"
    environment:
        - VIRTUAL_HOST=cadvisor.docker-toybox.com
    command: "-storage_driver=influxdb -storage_driver_db=cadvisor -storage_driver_host=influxdb:8086 -storage_driver_user=root -storage_driver_password=root -storage_driver_secure=False"
    ports:
        - "8080"

sitespeedio:
    image: sitespeedio/sitespeed.io
    privileged: true
    links:
        - graphite
    volumes:
        - ${app_path}/data/sitespeed.io:/sitespeed.io

sitespeedio-chrome:
    image: sitespeedio/sitespeed.io-chrome
    privileged: true
    links:
        - graphite
    volumes:
        - ${app_path}/data/sitespeed.io:/sitespeed.io
EOF
}

function __new() {
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
        }
        cp ${src}/sitespeed.sh ${app_path}/bin/
    }
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

