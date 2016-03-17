#!/bin/sh

function _source() {
    if [ ! -e $src ]; then
        git clone https://github.com/jwilder/nginx-proxy.git $src
    fi
}

function _init() {
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

function _start() {
    _init
    cd ${app_path}/bin
    docker-compose -p ${project_name} up -d
    echo '---------------------------------'
    echo 'Proxy started !'
    echo '---------------------------------'
}

function _stop() {
    cd ${app_path}/bin
    docker-compose -p ${project_name} stop
}

function _rm() {
    cd ${app_path}/bin
    docker-compose -p ${project_name} rm
}

function _state() {
    cd ${app_path}/bin
    docker-compose -p ${project_name} ps
}

function _backup() {
    echo 'backup command is not available for ${app_name} application'
}

function _restore() {
    echo 'restore command is not available for ${app_name} application'
}

