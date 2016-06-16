#!/bin/sh

db_name=${app_name}
db_user=${app_name}
db_user_pass=${app_name}

owncloud_version="9.0.2-apache"
mariadb_version="10.1.14"
redis_version="3.2.0-alpine"

uid=""
gid=""

function __source() {
    if [ ! -e ${src} ]; then
        #git clone https://github.com/docker-library/owncloud.git ${src}
       : 
    fi
}

function __build() {
    #docker build -t toybox/owncloud:9.0.2-apache $TOYBOX_HOME/src/owncloud/9.0.2-apache
    docker build -t toybox/owncloud:${owncloud_version} $TOYBOX_HOME/src/owncloud/${owncloud_version}
    docker build -t toybox/mariadb:${mariadb_version} $TOYBOX_HOME/src/mariadb/${mariadb_version}
}


containers=( \
    ${fqdn}-${app_name} \
    ${fqdn}-${app_name}-mariadb \
    ${fqdn}-${app_name}-redis \
)

#main_container=${fqdn}-${app_name}
#db_container=${fqdn}-${app_name}-db
#data_container=${fqdn}-${app_name}-data

function __init() {

    __build

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/owncloud/config
    mkdir -p ${app_path}/data/owncloud/data

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: toybox/owncloud:${owncloud_version}
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
    image: toybox/mariadb:${mariadb_version}
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
    image: redis:${redis_version}
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

#function __new() {
#    #__source; local status=$?
#    #if [ ${status} -ne 0 ]; then
#    #    echo ${project_name}": source code of ${app_name} does not download."
#    #    exit 1
#    #fi
#
#    __init && {
#        cd ${app_path}/bin
#        docker-compose -p ${project_name} up -d && {
#            echo '---------------------------------'
#            echo 'URL: http://'${fqdn}
#            echo 'WebDAV: http://'${fqdn}'/remote.php/webdav/'
#            echo '---------------------------------'
#            #echo -n 'Database Host: '
#            #docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
#            #    $(docker ps | grep ${project_name}_${db_container}_1 | awk '{print $1}')
#            echo 'Database Username: '${db_user}
#            echo 'Database Password: '${db_user_pass}
#        }
#    }
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

