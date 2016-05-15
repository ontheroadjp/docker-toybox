#!/bin/sh

db_name=${app_name}
db_user=${app_name}
db_user_pass=${app_name}
containers=( ${fqdn}-${app_name} ${fqdn}-${app_name}-db )

function __source() {
    if [ ! -e ${src} ]; then
        git clone https://github.com/docker-library/wordpress.git ${src}
    fi
}

function __init() {
    local uid
    local gid

    id www-data > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        sudo groupadd -g ${gid} www-data
        echo "create www-data group"
        sudo useradd -u ${uid} -g www-data www-data
        echo "create www-data user"
    fi
    
    uid=$(cat /etc/passwd | grep ^www-data | cut -d : -f3)
    gid=$(cat /etc/group | grep ^www-data | cut -d: -f3)

    echo "uid=${uid}"
    echo "gid=${gid}"

    mkdir -p ${app_path}/bin
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: wordpress
    links:
        - ${containers[1]}:mysql
    environment:
        - VIRTUAL_HOST=${fqdn}
        - PROXY_CACHE=true
        - UID=${uid}
        - GID=${gid}
    volumes:
        - ${app_path}/data/docroot:/var/www/html
    ports:
        - "80"

${containers[1]}:
    image: mariadb
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
    #    - ${app_path}/data/docroot/db-dump.sql:/docker-entrypoint-initdb.d
    #    - ${app_path}/data/docroot/db-dump.sql:/db-dump.sql
    environment:
        - MYSQL_ROOT_PASSWORD=root
        - TERM=xterm

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

