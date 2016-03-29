#!/bin/sh

function __source() {
    if [ ! -e ${src} ]; then
        git clone https://github.com/jwilder/nginx-proxy.git ${src}
    fi
}

main_container=${fqdn}-${app_name}

src=${TOYBOX_HOME}/src/${app_name}

#function __init() {
#    mkdir -p ${app_path}/bin
#    cat <<-EOF > ${compose_file}
#${main_container}:
#    restart: always
#    image: nginx:1.9
#    volumes:
#        - "/tmp/nginx:/etc/nginx/conf.d"
#        - "${src}/certs:/etc/nginx/certs"
#    ports:
#        - "80:80"
#nginx-docker-gen:
#    restart: always
#    image: jwilder/docker-gen
#    links:
#        - ${main_container}
#    volumes_from:
#        - ${main_container}
#    volumes:
#        - /var/run/docker.sock:/tmp/docker.sock:ro
#        - ${src}/templates:/etc/docker-gen/templates
#    command: -notify-sighup ${main_container} -watch -only-exposed /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
#EOF
#}

function __init() {
    mkdir -p ${app_path}/bin
    cat <<-EOF > ${compose_file}
${main_container}:
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

