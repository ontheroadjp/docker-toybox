#!/bin/bash

db_name=owncloud
db_user=owncloud
db_user_pass=owncloud

function _source() {
    if [ ! -e $src ]; then
        git clone https://github.com/docker-library/owncloud.git $src
    fi
}

function _init() {
    mkdir -p ${app_path}/bin
    cat <<-EOF > $out
${sub_domain}-${name}:
    image: owncloud:9.0.0-apache
    links:
    - ${sub_domain}-${name}-db:mysql
    environment:
        - VIRTUAL_HOST=${url}
    volumes_from:
        - ${sub_domain}-${name}-data
    ports:
        - "40110"
${sub_domain}-${name}-db:
    image: mariadb
    volumes_from:
        - ${sub_domain}-${name}-data
    environment:
        MYSQL_ROOT_PASSWORD: root
        MYSQL_DATABASE: ${db_name}
        MYSQL_USER: ${db_user}
        MYSQL_PASSWORD: ${db_user_pass}
${sub_domain}-${name}-data:
    image: busybox
    volumes:
        - /var/www/html
        - /var/lib/mysql
EOF
}

function _start() {
    _init
    cd ${app_path}/bin
    docker-compose -p ${project_name} up -d
    echo '---------------------------------'
    echo 'URL: http://'${url}
    echo 'WebDAV: http://cloud.nuts.jp/remote.php/webdav/'
    echo '---------------------------------'
    echo -n 'Database Host: '
    docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
        $(docker ps | grep ${project_name}_${sub_domain}-${name}-db_1 | awk '{print $1}')
    echo 'Database Username: '${db_user}
    echo 'Database Password: '${db_user_pass}
}

function _backup() {
    prefix=$(date '+%Y%m%d_%H%M%S')
    history_file=${app_path}/backup/history.txt
    mkdir -p ${app_path}/backup
    if [ ! -e $history_file ]; then
        echo "" >> ${history_file}    
    fi
    sed -i -e "1s/^/${prefix}\n/" ${history_file}
    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}_db.tar.gz /var/lib/mysql
    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}.tar.gz /var/www/html
}

function _restore() {
    prefix=$(cat ${app_path}/backup/history.txt | peco)
    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}_db.tar.gz
    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}.tar.gz
    _stop
    _start
}

