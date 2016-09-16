#!/bin/sh

containers=(
   ${application}-${mariadb_version}-master
   ${application}-${mariadb_version}-slave
)
images=(
   toybox/mariadb
)

mariadb_version=10.1.14
app_version=${mariadb_version}
db_root_password=root

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="mariadb"
    ["${project_name}_${containers[1]}_1"]="mariadb"
)
declare -A component_version=(
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
    docker build -t ${images[0]}:${mariadb_version} $TOYBOX_HOME/src/${application}/${mariadb_version}
}

function __init() {

    __build || {
        echo "build error(${application})"
        exit 1
    }

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/master
    mkdir -p ${app_path}/data/slave

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    #image: toybox/${application}:${mariadb_version}
    image: ${images[0]}:${mariadb_version}
    volumes:
        - ${app_path}/data/master:/var/lib/mysql
        - /etc/localtime:/etc/localtime:ro
    environment:
        - MYSQL_ROOT_PASSWORD=${db_root_password}
        - TERM=xterm
        - SERVER_TYPE=master
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    ports:
        - "3306"
${containers[1]}:
    #image: toybox/${application}:${mariadb_version}
    image: ${images[0]}:${mariadb_version}
    volumes:
        - ${app_path}/data/slave:/var/lib/mysql
        - /etc/localtime:/etc/localtime:ro
    links:
        - ${containers[0]}:master
    environment:
        - MYSQL_ROOT_PASSWORD=${db_root_password}
        - TERM=xterm
        - SERVER_TYPE=slave
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

