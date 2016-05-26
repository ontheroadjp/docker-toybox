#!/bin/sh

function __source() {
    if [ ! -e ${src} ]; then
        git clone https://github.com/jwilder/nginx-proxy.git ${src}
    fi
}

function __build() {
    docker build -t nutsp/nginx-proxy ${src}
}

containers=(${app_name}-nginx ${app_name}-docker-gen)
#main_container=${app_name}-nginx
#docker_gen_container=${app_name}-docker-gen

src=${TOYBOX_HOME}/src/${app_name}

function __init() {
    mkdir -p ${app_path}/bin
    cat <<-EOF > ${compose_file}
${containers[0]}:
    restart: always
    image: nginx:1.9
    #image: nutsp/nginx-proxy
    volumes:
        - "/etc/localtime:/etc/localtime:ro"
        - "/tmp/nginx:/etc/nginx/conf.d"
        - "${src}/certs:/etc/nginx/certs"
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    #environment:
    #    - DOCKER_HOST=tcp://$(ip r | grep 'docker0' | awk '{print $9}'):2376
    #    - DOCKER_TLS_VERIFY=1
    ports:
        - "80:80"
        - "443:443"
${containers[1]}:
    restart: always
    image: jwilder/docker-gen
    links:
        - ${containers[0]}
    volumes_from:
        - ${containers[0]}
    volumes:
        - "/etc/localtime:/etc/localtime:ro"
        - "/var/run/docker.sock:/tmp/docker.sock:ro"
        - "${src}/docker-gen.conf:/docker-gen.conf"
        - "${src}/templates:/etc/docker-gen/templates"
    #    - "$HOME/.docker:/certs"
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

function __new() {
    __init && {
        cd ${app_path}/bin
        if docker-compose -p ${project_name} up -d; then
            echo '---------------------------------'
            echo 'Proxy started !'
            echo '---------------------------------'
        fi
    }
}

#function __backup() {
#    echo 'backup command is not available for ${app_name} application'
#}
#
#function __restore() {
#    echo 'restore command is not available for ${app_name} application'
#}

