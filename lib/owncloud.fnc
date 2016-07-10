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

owncloud_user="toybox"
owncloud_password="toybox"
database="mysql"
db_root_password="root"
db_name=${application}
db_user=${application}
db_user_password=${application}
mariadb_alias="mysql"

apache2_version="2.4.10"
php_version="5.6.22"
owncloud_version="9.0.2-apache"
mariadb_version="10.1.14"
redis_version="3.2.0-alpine"
app_version=${owncloud_version}

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="apache2 php owncloud"
    ["${project_name}_${containers[1]}_1"]="mariadb"
    ["${project_name}_${containers[2]}_1"]="redis"
)
declare -A component_version=(
    ['apache2']="${apache2_version}"
    ['php']="${php_version}"
    ['owncloud']="${owncloud_version}"
    ['mariadb']="${mariadb_version}"
    ['redis']="${redis_version}"
)
declare -A params=(
    ['owncloud_user']=${owncloud_uer}
    ['owncloud_password']=${owncloud_password}
    ['owncloud_database']=${database}
    ['mariadb_mysql_root_password']=${db_root_password}
    ['mariadb_mysql_database']=${db_name}
    ['mariadb_mysql_user']=${db_user}
    ['mariadb_mysql_password']=${db_user_password}
    ['mariadb_mariadb_alias']=${mariadb_alias}
    ['mariadb_term']="xterm"
)

uid=""
gid=""

proto="http"

function __build() {
    docker build -t ${images[0]}:${owncloud_version} $TOYBOX_HOME/src/owncloud/${owncloud_version}
    docker build -t ${images[1]}:${mariadb_version} $TOYBOX_HOME/src/mariadb/${mariadb_version}
    docker build -t ${images[2]}:${redis_version} $TOYBOX_HOME/src/redis/${redis_version}
}

function __post_run() {
    http_status=$(curl -kLI ${proto}://${fqdn} -o /dev/null -w '%{http_code}\n' -s)
    while [ ${http_status} -ne 200 ]; do
        echo "waiting(${http_status})..." && sleep 3
        http_status=$(curl -kLI ${proto}://${fqdn} -o /dev/null -w '%{http_code}\n' -s)
    done
}

function __init() {

    __build || {
        echo "build error(${application})"
        exit 1
    }

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/owncloud/config
    mkdir -p ${app_path}/data/owncloud/data

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${owncloud_version}
    links:
        - ${containers[1]}:${mariadb_alias}
        - ${containers[2]}:redis
    environment:
    #    - security-opt=label:type:docker_t
        - VIRTUAL_HOST=${fqdn}
        - DATABASE=${database}
        - OWNCLOUD_USER=${owncloud_user}
        - OWNCLOUD_PASSWORD=${owncloud_password}
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    volumes:
        - /etc/localtime:/etc/localtime:ro
        - ${app_path}/data/owncloud/config:/var/www/html/config
        - ${app_path}/data/owncloud/data:/var/www/html/data
    ports:
        - "40110"

${containers[1]}:
    image: ${images[1]}:${mariadb_version}
    volumes:
        - /etc/localtime:/etc/localtime:ro
        - ${app_path}/data/mariadb:/var/lib/mysql
    environment:
    #    security-opt: label:type:docker_t
        MYSQL_ROOT_PASSWORD: ${db_root_password}
        MYSQL_DATABASE: ${db_name}
        MYSQL_USER: ${db_user}
        MYSQL_PASSWORD: ${db_user_password}
        TOYBOX_UID: ${uid}
        TOYBOX_GID: ${gid}
        TERM: xterm

${containers[2]}:
    image: ${images[2]}:${redis_version}
    volumes:
        - /etc/localtime:/etc/localtime:ro

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

