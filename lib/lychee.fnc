#!/bin/sh

src=$TOYBOX_HOME/src/${app_name}

db_name=lychee
db_user=lychee
db_user_pass=lychee

function __source() {
    #if [ ! -e $src ]; then
    #    git clone https://github.com/docker-library/wordpress.git $src
    #fi
    :
}

function __build() {
    docker build -t nutsp/lychee ${src}
}

main_container=${fqdn}-${app_name}
db_container=${fqdn}-${app_name}-db
data_container=${fqdn}-${app_name}-data

function __init() {
    
    mkdir -p ${app_path}/bin
    
    __build && {
    
        cat <<-EOF > ${compose_file}
${main_container}:
    image: nutsp/lychee
    environment:
        - VIRTUAL_HOST=${fqdn}
    links:
        - ${db_container}:lychee-mysql
    volumes:
        - ${app_path}/data/data:/data
        - ${app_path}/data/uploads/big:/uploads/big
        - ${app_path}/data/uploads/medium:/uploads/medium
        - ${app_path}/data/uploads/thumb:/uploads/thumb
        - ${app_path}/data/uploads/import:/uploads/import
    #volumes_from:
    #    - ${data_container}
    ports:
        - "80"
${db_container}:
    image: mariadb
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
    #volumes_from:
    #    - ${data_container}
    environment:
        MYSQL_ROOT_PASSWORD: root
        MYSQL_DATABASE: ${db_name}
        MYSQL_USER: ${db_user}
        MYSQL_PASSWORD: ${db_user_pass}
        TERM: xterm
#${data_container}:
#    image: busybox
#    volumes:
#        - /var/lib/mysql
#        - /var/www/lychee/data
#        - /var/www/lychee/uploads/big
#        - /var/www/lychee/uploads/medium
#        - /var/www/lychee/uploads/thumb
#        - /var/www/lychee/uploads/import
EOF
    }
}

function __up() {
    __init
    cd ${app_path}/bin
    docker-compose -p ${project_name} up -d
    echo '---------------------------------'
    echo 'URL: http://'${fqdn}
    echo '---------------------------------'
    echo -n 'Database Host: '
    docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
        $(docker ps | grep ${db_container} | awk '{print $1}')
    echo 'Database Username: '${db_user}
    echo 'Database Password: '${db_user_pass}
    echo 'New Username: username as you like'
    echo 'New Password: password as you like'
}

#function __backup() {
#    prefix=$(date '+%Y%m%d_%H%M%S')
#    history_file=${app_path}/backup/history.txt
#    mkdir -p ${app_path}/backup
#    if [ ! -e $history_file ]; then
#        echo "" >> ${history_file}    
#    fi
#    sed -i -e "1s/^/${prefix}\n/" ${history_file}
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}_db.tar.gz /var/lib/mysql
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}_images.tar.gz /var/www/lychee/uploads
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar cvzf /backup/${prefix}.tar.gz /var/www/lychee/data
#}
#
#function __restore() {
#    #prefix=$(ls -la $(dirname $0)/backup/ | peco | awk '{print $10}' | sed "s/_[a-z]*\.tar\.gz$//")
#    prefix=$(cat $(dirname $0)/backup/history.txt | peco)
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}_db.tar.gz
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}_images.tar.gz
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${name}-data_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}.tar.gz
#    __stop
#    __start
#    #docker exec -t $(docker ps -a | grep lychee_lychee_1 | awk '{print $1}') sh /entrypoint.sh
#}

