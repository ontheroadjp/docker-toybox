#!/bin/sh

containers=(
    ${fqdn}-${application}
    ${fqdn}-${application}-mariadb
    ${fqdn}-${application}-redis
)
images=(
   toybox/owncloud
   toybox/mariadb
   toybox/redis
)

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="apache php owncloud"
    ["${project_name}_${containers[1]}_1"]="mariadb"
    ["${project_name}_${containers[1]}_1"]="redis"
)
declare -A component_version=(
    ['apache']="2.4.10"
    ['php']="5.6.22"
    ['owncloud']="9.0.2"
    ['mariadb']="10.1.14"
    ['redis']="3.2.0"
)

db_name=${application}
db_user=${application}
db_user_pass=${application}

owncloud_version="9.0.2-apache"
mariadb_version="10.1.14"
redis_version="3.2.0-alpine"

uid=""
gid=""

function __build() {
    docker build -t toybox/owncloud:${owncloud_version} $TOYBOX_HOME/src/owncloud/${owncloud_version}
    docker build -t toybox/mariadb:${mariadb_version} $TOYBOX_HOME/src/mariadb/${mariadb_version}
    docker build -t toybox/redis:${redis_version} $TOYBOX_HOME/src/redis/${redis_version}
}

function __init() {

    __build

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/owncloud/config
    mkdir -p ${app_path}/data/owncloud/data

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${owncloud_version}
    links:
        - ${containers[1]}:mysql
        - ${containers[2]}:redis
    environment:
    #    - security-opt=label:type:docker_t
        - VIRTUAL_HOST=${fqdn}
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
        - TIMEZONE=${timezone}
    volumes:
    #    - "/etc/localtime:/etc/localtime:ro"
        - ${app_path}/data/owncloud/config:/var/www/html/config
        - ${app_path}/data/owncloud/data:/var/www/html/data
    ports:
        - "40110"

${containers[1]}:
    #image: mariadb
    image: ${images[1]}:${mariadb_version}
    volumes:
        - ${app_path}/data/mariadb:/var/lib/mysql
    environment:
    #    - "/etc/localtime:/etc/localtime:ro"
    #    security-opt: label:type:docker_t
        MYSQL_ROOT_PASSWORD: root
        MYSQL_DATABASE: ${db_name}
        MYSQL_USER: ${db_user}
        MYSQL_PASSWORD: ${db_user_pass}
        TOYBOX_UID: ${uid}
        TOYBOX_GID: ${gid}
        TERM: xterm
        TIMEZONE: ${timezone}

${containers[2]}:
    image: ${images[2]}:${redis_version}
    environment:
        - TIMEZONE=${timezone}
    #volumes:
    #    - "/etc/localtime:/etc/localtime:ro"

#${data_container}:
#    image: busybox
#    volumes:
#        - /var/www/html
#        - /var/lib/mysql
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
#
#function __restore() {
#    prefix=$(cat ${app_path}/backup/history.txt | peco)
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${data_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}_db.tar.gz
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${main_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}.tar.gz
#    _stop && {
#        _start
#    }
#}

