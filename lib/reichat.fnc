#!/bin/sh

containers=( 
    ${fqdn}-${application}
)
images=(
    toybox/reichat
)

reichat_version="0.0.34"
node_version="0.12.13-slim"
app_version="${reichat_version}"

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="reichat node"
)
declare -A component_version=(
    ['reichat']="${reichat_version}"
    ['node']="${node_version}"
)

function __build(){
   docker build -t ${containers[0]} ${TOYBOX_HOME}/src/${application}/${reichat_version}
}

function __init() {

    __build || {
        echo "build error(${application})"
        exit 1
    }

    mkdir -p ${app_path}/bin
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}
    environment:
        - VIRTUAL_HOST=${fqdn}
    ports:
        - "10133"
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

