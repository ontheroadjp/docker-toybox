#!/bin/sh

db_name=${app_name}
db_user=${app_name}
db_user_pass=${app_name}

function __source() {
    if [ ! -e ${src} ]; then
        #git clone https://github.com/docker-library/owncloud.git ${src}
       : 
    fi
}

function __build() {
    docker build -t nutsp/owncloud:9.0.0-apache $TOYBOX_HOME/src/owncloud/9.0.0/apache
}


main_container=${fqdn}-${app_name}
db_container=${fqdn}-${app_name}-db
data_container=${fqdn}-${app_name}-data

function __init() {

    __build

    mkdir -p ${app_path}/bin
    cat <<-EOF > ${compose_file}
${main_container}:
    #image: owncloud:9.0.0-apache
    image: nutsp/owncloud:9.0.0-apache
    links:
        - ${db_container}:mysql
        - memcached:memcached
    environment:
        - VIRTUAL_HOST=${fqdn}
    #volumes_from:
    #    - ${data_container}
    volumes:
        - ${app_path}/data/config:/var/www/html/config
        - ${app_path}/data/data:/var/www/html/data
    ports:
        - "40110"

${db_container}:
    image: mariadb
    #volumes_from:
    #    - ${data_container}
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
    environment:
        MYSQL_ROOT_PASSWORD: root
        MYSQL_DATABASE: ${db_name}
        MYSQL_USER: ${db_user}
        MYSQL_PASSWORD: ${db_user_pass}
        TERM: xterm

memcached:
    image: memcached

#${data_container}:
#    image: busybox
#    volumes:
#        - /var/www/html
#        - /var/lib/mysql
EOF
}

function __up() {
    #__source; local status=$?
    #if [ ${status} -ne 0 ]; then
    #    echo ${project_name}": source code of ${app_name} does not download."
    #    exit 1
    #fi

    __init && {
        cd ${app_path}/bin
        docker-compose -p ${project_name} up -d && {
            echo '---------------------------------'
            echo 'URL: http://'${fqdn}
            echo 'WebDAV: http://'${fqdn}'/remote.php/webdav/'
            echo '---------------------------------'
            echo -n 'Database Host: '
            docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
                $(docker ps | grep ${project_name}_${db_container}_1 | awk '{print $1}')
            echo 'Database Username: '${db_user}
            echo 'Database Password: '${db_user_pass}
        }
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

