#!/bin/sh

containers=(
    ${fqdn}-${application}
)
images=(
   toybox/gitbucket
   busybox
)
data_containers=(
    ${fqdn}-${application}-data
)

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="openJDK"
)
declare -A component_version=(
    ['openJDK']="1.8.0_92-internal"
)

gitbucket_version="4.1.0"
busybox_version="buildroot-2014.02"

uid=""
gid=""

function __build() {
    docker build -t toybox/gitbucket:${gitbucket_version} $TOYBOX_HOME/src/${application}/${gitbucket_version}
}

function __init() {

    __build

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/gitbucket

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${gitbucket_version}
    environment:
        - VIRTUAL_HOST=${fqdn}
        - VIRTUAL_PORT=8080
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    volumes_from:
        - ${containers[1]}
    volumes:
        - "/etc/localtime:/etc/localtime:ro"
    ports:
        - "29418:29418"
        - "8080"

${data_containers[0]}:
    image: ${images[1]}:${busybox_version}
    volumes:
        - "${app_path}/data/gitbucket:/gitbucket"
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

