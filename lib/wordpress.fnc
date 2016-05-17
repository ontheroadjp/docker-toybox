#!/bin/sh

db_name=${app_name}
db_user=${app_name}
db_user_pass=${app_name}
containers=( ${fqdn}-${app_name} ${fqdn}-${app_name}-db )

containers=( ${fqdn}-${app_name} ${fqdn}-${app_name}-db )
wordpress_version="4.5.2-apache"
mariadb_version="10.1.14"

function __source() {
    if [ ! -e ${src} ]; then
        git clone https://github.com/docker-library/wordpress.git ${src}
    fi
}

function __init() {
    id www-data > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        sudo groupadd www-data
        echo "www-data group created."
        sudo useradd -g www-data www-data
        echo "www-data user created."
    fi
    
    local wordpress_uid=$(cat /etc/passwd | grep ^www-data | cut -d : -f3)
    local wordpress_gid=$(cat /etc/group | grep ^www-data | cut -d: -f3)

    id mysql > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        sudo groupadd mysql
        echo "mysql group created."
        sudo useradd -g mysql mysql
        echo "mysql user created."
    fi
    
    local mysql_uid=$(cat /etc/passwd | grep ^mysql | cut -d : -f3)
    local mysql_gid=$(cat /etc/group | grep ^mysql | cut -d: -f3)

    #echo "wordpress_uid=${wordpress_uid}"
    #echo "wordpress_gid=${wordpress_gid}"
    #echo "mysql_uid=${mysql_uid}"
    #echo "mysql_gid=${mysql_gid}"

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data

    docker build -t nuts/wordpress:${wordpress_version} ${src}/wordpress
    docker build -t nuts/mariadb:${mariadb_version} ${src}/mariadb
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    #image: wordpress
    image: nuts/wordpress:${wordpress_version}
    links:
        - ${containers[1]}:mysql
    environment:
        - VIRTUAL_HOST=${fqdn}
        - PROXY_CACHE=true
        - TOYBOX_WWW_DATA_UID=${wordpress_uid}
        - TOYBOX_WWW_DATA_GID=${wordpress_gid}
    volumes:
        - ${app_path}/data/docroot:/var/www/html
    ports:
        - "80"

${containers[1]}:
    image: nuts/mariadb:${mariadb_version}
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
        #- ${TOYBOX_HOME}/src/wordpress/mysql/conf.d:/etc/mysql/conf.d
    environment:
        - MYSQL_ROOT_PASSWORD=root
        - MYSQL_DATABASE=wordpress
        - TERM=xterm
        - TOYBOX_MYSQL_UID=${mysql_uid}
        - TOYBOX_MYSQL_GID=${mysql_gid}

#${containers[2]}:
#    image: busybox
#    volumes:
#        - ${app_path}/data/docroot:/var/www/html
#        - ${app_path}/data/mysql:/var/lib/mysql
EOF
}

#function __new() {
#    __init && {
#        cd ${app_path}/bin
#        docker-compose -p ${project_name} up -d && {
#            echo '---------------------------------' | tee -a ${app_path}/info.txt
#            echo 'URL: http://'${fqdn} | tee -a ${app_path}/info.txt
#            echo '---------------------------------' | tee -a ${app_path}/info.txt
#            echo -n 'Database Host: ' | tee -a ${app_path}/info.txt
#            docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
#                $(docker ps | grep ${containers[1]}_1 | awk '{print $1}' | tee -a ${app_path}/info.txt)
#            echo 'Database Username: '${db_user} | tee -a ${app_path}/info.txt
#            echo 'Database Password: '${db_user_pass} | tee -a ${app_path}/info.txt
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
