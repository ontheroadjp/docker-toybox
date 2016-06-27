#!/bin/sh

containers=( 
    ${fqdn}-${application} 
    ${fqdn}-${application}-db
)
images=(
   toybox/lychee
   toybox/mariadb
)
declare -A components=(
    ["${project_name}_${containers[0]}_1"]="apache php lychee"
    ["${project_name}_${containers[1]}_1"]="mariadb"
)
declare -A component_version=(
    ['apache']="2.4.10 (Debian)"
    ['php']="7.0.7"
    ['lychee']="latest"
    ['mariadb']="10.1.14"
)

mariadb_version="10.1.14"

db_name=lychee
db_user=lychee
db_user_pass=lychee

uid=""
gid=""

function __build() {
    docker build -t toybox/lychee $TOYBOX_HOME/src/lychee
    docker build -t toybox/mariadb:${mariadb_version} $TOYBOX_HOME/src/mariadb/${mariadb_version}
}


function __init() {
    
    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/lychee/data
    mkdir -p ${app_path}/data/lychee/uploads
    
    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    __build && {
    
        cat <<-EOF > ${compose_file}
${containers[0]}:
    image: toybox/lychee
    environment:
        - VIRTUAL_HOST=${fqdn}
        - PROXY_CACHE=true
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    links:
        - ${containers[1]}:mariadb
    volumes:
        - ${app_path}/data/lychee/data:/data
        - ${app_path}/data/lychee/uploads/big:/uploads/big
        - ${app_path}/data/lychee/uploads/medium:/uploads/medium
        - ${app_path}/data/lychee/uploads/thumb:/uploads/thumb
        - ${app_path}/data/lychee/uploads/import:/uploads/import
    #volumes_from:
    #    - ${containers[2]}
    ports:
        - "80"
${containers[1]}:
    #image: mariadb
    image: toybox/mariadb:${mariadb_version}
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
    #volumes_from:
    #    - ${containers[2]}
    environment:
        MYSQL_ROOT_PASSWORD: root
        MYSQL_DATABASE: ${db_name}
        MYSQL_USER: ${db_user}
        MYSQL_PASSWORD: ${db_user_pass}
        TOYBOX_UID: ${uid}
        TOYBOX_GID: ${gid}
        TERM: xterm
    ports:
        - "3306"
#${containers[2]}:
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

#function __new() {
#    __init
#    cd ${app_path}/bin
#    docker-compose -p ${project_name} up -d
#    echo '---------------------------------'
#    echo 'URL: http://'${fqdn}
#    echo '---------------------------------'
#    echo -n 'Database Host: '
#    docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
#        $(docker ps | grep ${containers[1]} | awk '{print $1}')
#    echo 'Database Username: '${db_user}
#    echo 'Database Password: '${db_user_pass}
#    echo 'New Username: username as you like'
#    echo 'New Password: password as you like'
#}

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

