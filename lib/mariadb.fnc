#!/bin/sh

containers=(
   ${application}-${mariadb_version}
)
images=(
    toybox/mariadb
)

db_root_password=root
mariadb_version=10.1.14

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="mariadb"
)
declare -A component_version=(
    ['mariadb']="${mariadb_version}"
)
declare -A params=(
    ['mariadb_mysql_root_password']=${db_root_password}
    ['mariadb_term']="xterm"
)

uid=""
gid=""

function __build() {
    docker build -t ${application}:${mariadb_version} $TOYBOX_HOME/src/${application}/${mariadb_version}
}

function __post_run() {
    local id=$(docker ps | grep ${containers[0]}_ | cut -d" " -f1)
    local ip=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${id})
    echo "---------------------------------"
    echo "Application: ${application}:${mariadb_version}"
    echo "Container ID: ${id}"
    echo "IP Address: ${ip}"
    echo "Root password: ${db_root_password}"
    echo "---------------------------------"
}

function __init() {

    __build || {
        echo "build error(${application})"
        exit 1
    }

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/mariadb

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${mariadb_version}
    volumes:
        - /etc/localtime:/etc/localtime:ro
        - ${app_path}/data/mariadb:/var/lib/mysql
    environment:
        - MYSQL_ROOT_PASSWORD=${db_root_password}
        - TERM=xterm
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    ports:
        - "3306"
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

