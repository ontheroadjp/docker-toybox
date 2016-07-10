#!/bin/sh

containers=(
    ${fqdn}-${application}
    ${fqdn}-${application}-db
)
images=(
    toybox/php
    toybox/mariadb
)

db_root_password="root"
mariadb_alias="mariadb"

apache2_version="2.4.10 (Debian)"
php_version="5.6.23-apache"
mariadb_version="10.1.14"
app_version="${php_version}"

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="apache2 php"
    ["${project_name}_${containers[1]}_1"]="mariadb"
)
declare -A component_version=(
    ['apache2']="${apache2_version}"
    ['php']="${php_version}"
    ['mariadb']="${mariadb_version}"
)
declare -A params=(
    ['mariadb_mysql_root_password']=${db_root_password}
    ['mariadb_mariadb_alias']=${mariadb_alias}
    ['mariadb_term']="xterm"
)

uid=""
gid=""

function __build() {
    docker build -t ${images[0]}:${php_version} $TOYBOX_HOME/src/php/${php_version}
}

function __init() {

    __build || {
        echo "build error(${application})"
        exit 1
    }

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/apache2/docroot
    mkdir -p ${app_path}/data/apache2/conf
    mkdir -p ${app_path}/data/php

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${php_version}
    volumes:
        - ${app_path}/data/apache2/docroot:/var/www/html
        - ${app_path}/data/apache2/conf:/etc/apache2
        - ${app_path}/data/php:/usr/local/etc/php
    links:
        - ${containers[1]}:${mariadb_alias}
    environment:
        - VIRTUAL_HOST=${fqdn}
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    ports:
        - "80"

${containers[1]}:
    image: ${images[1]}:${mariadb_version}
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
    #volumes_from:
    #    - ${data_container}
    environment:
        MYSQL_ROOT_PASSWORD: ${db_root_password}
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

