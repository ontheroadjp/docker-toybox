#!/bin/sh

mariadb_version=10.1.14
db_root_password=root

uid=""
gid=""

function __build() {
    docker build -t toybox/${app_name}:${mariadb_version} $TOYBOX_HOME/src/${app_name}/${mariadb_version}
}

containers=( \
   ${app_name}-${mariadb_version} 
)

function __init() {

    __build

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/mysql

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: toybox/${app_name}:${mariadb_version}
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
    environment:
        - MYSQL_ROOT_PASSWORD=${db_root_password}
        - TERM=xterm
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
        - TIMEZONE=${timezone}
    ports:
        - "3306"
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

