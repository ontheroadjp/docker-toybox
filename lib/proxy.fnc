#!/bin/sh

containers=(
    ${application}-nginx 
    ${application}-docker-gen
    ${application}-letsencrypt
)
images=(
    toybox/nginx
    jwilder/docker-gen
    jrcs/letsencrypt-nginx-proxy-companion
)

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="nginx"
    ["${project_name}_${containers[1]}_1"]="docker-gen"
    ["${project_name}_${containers[1]}_1"]="lets-encrypt"
)
declare -A component_version=(
    ['nginx']="1.9.15"
    ['docker-gen']="n/a"
    ['lets-encrypt']="n/a"
)

nginx_version=1.9

function __build() {
    docker build -t ${images[0]}:${nginx_version} $TOYBOX_HOME/src/nginx/${nginx_version}
}

function __init() {

    __build

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/nginx/conf.d
    mkdir -p ${app_path}/data/nginx/vhost.d
    mkdir -p ${app_path}/data/nginx/docroot
    mkdir -p ${app_path}/data/nginx/certs

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    restart: always
    image: ${images[0]}:${nginx_version}
    volumes:
        - "/etc/localtime:/etc/localtime:ro"
        - "${app_path}/data/nginx/conf.d:/etc/nginx/conf.d"
        - "${app_path}/data/nginx/vhost.d:/etc/nginx/vhost.d"
        - "${app_path}/data/nginx/docroot:/usr/share/nginx/html"
        - "${app_path}/data/nginx/certs:/etc/nginx/certs"
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    environment:
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
    #    - DOCKER_HOST=tcp://$(ip r | grep 'docker0' | awk '{print $9}'):2376
    #    - DOCKER_TLS_VERIFY=1
    ports:
        - "80:80"
        - "443:443"

${containers[1]}:
    restart: always
    image: ${images[1]}
    links:
        - ${containers[0]}
    volumes_from:
        - ${containers[0]}
    volumes:
        - "/etc/localtime:/etc/localtime:ro"
        - "/var/run/docker.sock:/tmp/docker.sock:ro"
        - "${src}/docker-gen/docker-gen.conf:/docker-gen.conf"
        - "${src}/docker-gen/templates:/etc/docker-gen/templates"
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    #environment:
    #    - DOCKER_HOST=tcp://$(ip r | grep 'docker0' | awk '{print $9}'):2376
    #    - DOCKER_CERT_PATH=/certs
    #    - DOCKER_TLS_VERIFY=1
    #    - security-opt=label:type:docker_t
    command: -config /docker-gen.conf
    #command: -notify-sighup ${project_name}_${containers[0]}_1 -watch -only-exposed /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
    #command: -tlscacert=$HOME/.docker/ca.pem -tlscert=$HOME/.docker/cert.pem -tlskey=$HOME/.docker/key.pem -notify-sighup ${project_name}_${containers[0]}_1 -watch -only-exposed /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf

${containers[2]}:
    restart: always
    image: ${images[2]}
    links:
        - ${containers[0]}
    volumes_from:
        - ${containers[0]}
    volumes:
        - "/etc/localtime:/etc/localtime:ro"
        - "/var/run/docker.sock:/var/run/docker.sock:ro"
        - "${app_path}/data/nginx/certs:/etc/nginx/certs:rw"
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    environment:
        - NGINX_DOCKER_GEN_CONTAINER=${container[1]}
        - ACME_CA_URI=https://acme-staging.api.letsencrypt.org/directory
EOF
}

#function __init() {
#    mkdir -p ${app_path}/bin
#    cat <<-EOF > ${compose_file}
#${main_container}:
#    restart: always
#    image: jwilder/nginx-proxy
#    environment:
#        - security-opt=label:type:docker_t
#    volumes:
#        - "/var/run/docker.sock:/tmp/docker.sock"
#    ports:
#        - "80:80"
#        - "443:443"
#EOF
#}

#function __new() {
#    __init && {
#        cd ${app_path}/bin
#        if docker-compose -p ${project_name} up -d; then
#            echo '---------------------------------'
#            echo 'Proxy started !'
#            echo '---------------------------------'
#        fi
#    }
#}

#function __backup() {
#    echo 'backup command is not available for ${application} application'
#}
#
#function __restore() {
#    echo 'restore command is not available for ${application} application'
#}

