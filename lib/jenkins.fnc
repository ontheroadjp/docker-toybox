#!/bin/sh
#set -eu


containers=( ${fqdn}-${app_name} )
images=( jenkins )
jenkins_version="latest"
build_dir=${app_path}/build

uid=""
gid=""

# --------------------------------------------------------
# Initialize
# --------------------------------------------------------

function __init() {

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/jenkins

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    

    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${jenkins_version}
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    environment:
        - VIRTUAL_HOST=${fqdn}
        - VIRTUAL_PORT=8080
        - PROXY_CACHE=true
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    volumes:
        - ${app_path}/data/jenkins:/var/jenkins_home
    ports:
        - "8080"
        - "50000"


#${containers[1]}:
#    image: busybox
#    volumes:
#        - ${app_path}/data/docroot:${document_root}
#        - ${app_path}/data/mysql:/var/lib/mysql
EOF
}


