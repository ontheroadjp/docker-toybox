#!/bin/sh

function __source() {
    if [ ! -e $src ]; then
        git clone https://github.com/jwilder/nginx-proxy.git $src
    fi
}

function __init() {
    mkdir -p ${app_path}/bin
    cat <<-EOF > $out
${url}-${app_name}:
    restart: always
    image: jwilder/nginx-proxy
    environment:
        - security-opt=label:type:docker_t
    volumes:
        - "/var/run/docker.sock:/tmp/docker.sock"
    ports:
        - "80:80"
EOF
}

function __new() {
    __init
    cd ${app_path}/bin
    docker-compose -p ${project_name} up -d
    echo '---------------------------------'
    echo 'Proxy started !'
    echo '---------------------------------'
}


function __backup() {
    echo 'backup command is not available for ${app_name} application'
}

function __restore() {
    echo 'restore command is not available for ${app_name} application'
}

