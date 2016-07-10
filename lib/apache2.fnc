#!/bin/sh

containers=(
    ${fqdn}-${application}
)
images=(
    toybox/apache2
)
declare -A components=(
    ["${project_name}_${containers[0]}_1"]="apache2"
)
declare -A component_version=(
    ['apache2']="2.4.20"
)

apache2_version=2.4.20

uid=""
gid=""

function __build() {
    docker build -t ${containers[0]}:${apache2_version} $TOYBOX_HOME/src/${application}/${apache2_version}
}

function __post_run() {
    local id=$(docker ps | grep ${containers[0]}_ | cut -d" " -f1)
    local ip=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' ${id})

    echo "---------------------------------"
    echo "Application: ${application}:${apache2_version}"
    echo "URL: http(s)://${fqdn}"
    echo "Container ID: ${id}"
    echo "IP Address: ${ip}"
    echo "---------------------------------"
}

function __init() {

    __build || {
        echo "build error(${application})"
        exit 1
    }

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/apache2/docroot
    mkdir -p ${app_path}/data/apache2/conf

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}/${application}:${apache2_version}
    volumes:
        - /etc/localtime:/etc/localtime:ro
        - "${app_path}/data/apache2/docroot:/usr/local/apache2/htdocs"
        - "${app_path}/data/apache2/conf:/usr/local/apache2/conf"
    environment:
        - VIRTUAL_HOST=${fqdn}
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    ports:
        - "80"
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

