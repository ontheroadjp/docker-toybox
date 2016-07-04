#!/bin/sh

db_name=${application}
db_user=${application}
db_user_pass=${application}

uid=""
gid=""

php_version="5.6.22-apache"
mariadb_version="10.1.14"

containers=( ${fqdn}-${application} ${fqdn}-${application}-db )

function __build() {
    docker build -t toybox/${application}:${php_version} $TOYBOX_HOME/src/${application}/${php_version}
}

function __init() {

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/apache2/docroot
    mkdir -p ${app_path}/data/apache2/conf
    mkdir -p ${app_path}/data/php

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    __build

    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: toybox/${application}:${php_version}
    volumes:
        - ${app_path}/data/apache2/docroot:/var/www/html
        - ${app_path}/data/apache2/conf:/etc/apache2
        - ${app_path}/data/php:/usr/local/etc/php
    links:
        - ${containers[1]}:mariadb
    environment:
        - VIRTUAL_HOST=${fqdn}
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    ports:
        - "80"

${containers[1]}:
    image: toybox/mariadb:${mariadb_version}
    #image: mariadb
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
    #volumes_from:
    #    - ${data_container}
    environment:
        MYSQL_ROOT_PASSWORD: root
        TOYBOX_UID: ${uid}
        TOYBOX_GID: ${gid}
        TERM: xterm

#${data_container}:
#    image: busybox
#    volumes:
#        - ${app_path}/data/apache2/docroot:/var/www/html
#        - ${app_path}/data/apache2/conf:/etc/apache2
#        - ${app_path}/data/mysql:/var/lib/mysql
EOF
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

#function __restore() {
#    prefix=$(cat ${app_path}/backup/history.txt | peco)
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${data_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}_db.tar.gz
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${main_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}.tar.gz
#    _stop && {
#        _start
#    }
#}

