#!/bin/sh

db_name=${app_name}
db_user=${app_name}
db_user_pass=${app_name}

function _source() {
    if [ ! -e $src ]; then
        git clone https://github.com/docker-library/wordpress.git $src
    fi
}

function _init() {
    mkdir -p ${app_path}/bin
    
    cat <<-EOF > $out
${sub_domain}-${app_name}:
    image: wordpress
    links:
        - ${sub_domain}-${app_name}-db:mysql
    environment:
        - VIRTUAL_HOST=${url}
    volumes_from:
        - ${sub_domain}-${app_name}-data
    ports:
        - "80"

${sub_domain}-${app_name}-db:
    image: mariadb
    volumes_from:
        - ${sub_domain}-${app_name}-data
    environment:
        MYSQL_ROOT_PASSWORD: root

${sub_domain}-${app_name}-data:
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
    echo '---------------------------------'
    echo -n 'Database Host: '
    docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
        $(docker ps | grep ${project_name}_${sub_domain}-${app_name}-db_1 | awk '{print $1}')
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
    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${app_name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}_db.tar.gz /var/lib/mysql
    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${app_name}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}.tar.gz /var/www/html
}

function _restore() {
    prefix=$(cat ${app_path}/backup/history.txt | peco)
    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${app_name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}_db.tar.gz
    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${app_name}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}.tar.gz
    _stop
    _start
}
