#!/bin/sh

containers=( 
    ${fqdn}-${application} 
)
images=( 
    toybox/jenkins 
)

jenkins_version="1.651.3"
openjdk_version="1.8.0_91"
app_version=${jenkins_version}

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="jenkins openjdk"
)
declare -A component_version=(
    ['jenkins']="${jenkins_version}"
    ['openjdk']="${openjdk_version}"
)
declare -A params=(
    ['jenkins_javaopt']="-Duser.timezone=Asia/Tokyo -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
)

uid=""
gid=""

# --------------------------------------------------------
# Initialize
# --------------------------------------------------------

function __build() {
    docker build -t ${images[0]}:${jenkins_version} ${src}/${jenkins_version}
}

function __post_run() {
    id=$(docker ps | tail -n +2 | grep "${containers[0]}" | cut -d" " -f1)
    docker exec -it ${id} sh /post-run.sh
}

function __init() {

    __build || {
        echo "build error(${application})"
        exit 1
    }

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/jenkins

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)

    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${jenkins_version}
    #user: jenkins
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    environment:
        - VIRTUAL_HOST=${fqdn}
        - VIRTUAL_PORT=8080
        - PROXY_CACHE=true
        - JENKINS_USER=toybox
        - JENKINS_PASSWORD=toybox
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
        - JAVA_OPTS="-Duser.timezone=Asia/Tokyo -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
    volumes:
        - /etc/localtime:/etc/localtime:ro
        - ${app_path}/data/jenkins:/var/jenkins_home
        - /var/run/docker.sock:/var/run/docker.sock:ro
        - $(which docker):/bin/docker:ro
        - $(which docker-compose):/bin/docker-compose:ro
        - /usr/lib64/libdevmapper.so.1.02:/usr/lib/x86_64-linux-gnu/libdevmapper.so.1.02:ro
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


