#!/bin/sh

containers=(
    ${fqdn}-${application}
    ${fqdn}-${application}-db
)
images=(
   toybox/gitbucket
   toybox/mariadb
)
data_containers=(
    ${fqdn}-${application}-data
)
data_images=(
    busybox
)

db_root_password="root"
db_name="toybox_gitbucket"
db_user="toybox"
db_password="toybox"
db_table_prefix="tb_gitbucket_"
db_alias="mysql"
docroot="/var/www/html"

gitbucket_version="4.1.0"
openJDK_version="1.8.0_92-internal"
mariadb_version="10.1.14"
busybox_version="buildroot-2014.02"
app_version="${gitbucket_version}"

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="gitbucket openJDK"
    ["${project_name}_${containers[1]}_1"]="mariadb"
)
declare -A component_version=(
    ['gitbucket']="${gitbucket_version}"
    ['openJDK']="${openJDK_version}"
    ['mariadb']="${mariadb_version}"
)

uid=""
gid=""

function __build() {
    docker build -t ${images[0]}:${gitbucket_version} $TOYBOX_HOME/src/${application}/${gitbucket_version}
    docker build -t ${images[1]}:${mariadb_version} $TOYBOX_HOME/src/mariadb/${mariadb_version}
}

function __init() {

    __build || {
        echo "build error(${application})"
        exit 1
    }

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/gitbucket

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${gitbucket_version}
    links:
        - ${containers[1]}:${db_alias}
    environment:
        - VIRTUAL_HOST=${fqdn}
        - VIRTUAL_PORT=8080
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    volumes_from:
        - ${data_containers[0]}
    volumes:
        - "/etc/localtime:/etc/localtime:ro"
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    ports:
        - "29418:29418"
        - "8080"

${containers[1]}:
    image: ${images[1]}:${mariadb_version}
    volumes:
        - "/etc/localtime:/etc/localtime:ro"
    volumes_from:
        - ${data_containers[0]}
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    environment:
        - MYSQL_ROOT_PASSWORD=${db_root_password}
        - MYSQL_DATABASE=${db_name}
        - MYSQL_USER=${db_user}
        - MYSQL_PASSWORD=${db_password}
        - TERM=xterm
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}

${data_containers[0]}:
    image: ${data_images[0]}:${busybox_version}
    volumes:
        - "${app_path}/data/gitbucket:/gitbucket"
        - "${app_path}/data/mariadb:/var/lib/mysql"
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

