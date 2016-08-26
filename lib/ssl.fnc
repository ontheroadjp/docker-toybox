#!/bin/sh

containers=(
    ${fqdn}-${application}
)
images=(
    toybox/nginx
)

nginx_version=1.9.15

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="nginx"
)
declare -A component_version=(
    ['nginx']="${nginx_version}"
)


uid=""
gid=""

ssl_email=""

function __build() {
    docker build -t ${images[0]}:${nginx_version} $TOYBOX_HOME/src/nginx/${nginx_version}
}

function __post_run() {
    if [ "${ssl_email}" != "" ]; then
        certs_dir="$TOYBOX_HOME/stack/proxy/80/data/nginx/certs"
        #echo "Starting new HTTPS connection: acme-staging.api.letsencrypt.org"
        echo "Starting new HTTPS connection"
        echo "This is going to take a few minits"
        timeout=0
        while [ ! -h ${certs_dir}/${fqdn}.crt ] \
                        && [ ! -h ${certs_dir}/${fqdn}.dhparam.pem ] \
                        && [ ! -h ${certs_dir}/${fqdn}.key ]; do
            if [ ${timeout} -gt 180 ]; then
                echo "Timeout.."
                _down > /dev/null 2>&1
                exit 1
            fi
            echo "wait(${timeout}).." && sleep 3 && timeout=$(( ${timeout} + 3 ))
        done
        _restart
    fi
}

function __init() {
    certs_dir="$TOYBOX_HOME/stack/proxy/80/data/nginx/certs"
    if [ ! -h ${certs_dir}/${fqdn}.crt ] \
                    && [ ! -h ${certs_dir}/${fqdn}.dhparam.pem ] \
                    && [ ! -h ${certs_dir}/${fqdn}.key ]; then

        while [ ! $(echo ${ssl_email} | egrep -e '^[a-zA-Z0-9_\.\-]+?@[A-Za-z0-9_\.\-]+$') ]; do
            echo -n "Enter e-mail address for SSL certificate:  "
            read ssl_email
        done

        echo "------------------------------------------------------------"
        echo "FQDN for SSL: ${fqdn}"
        echo "Email address for SSL certification: ${ssl_email}"
        echo "------------------------------------------------------------"
        echo -n "Are you sure? (y/n): " 
        read confirm
        if [ ${confirm} != "y" ]; then
            exit 1
        fi && echo

        domain=$(echo ${ssl_email} | cut -d "@" -f2)
        result=$(dig MX ${domain} +short)
        if [ "${result}" != "0 ${domain}." ]; then
            echo "${ssl_email} doesn't exsist."
            rm -rf ${app_path}
            exit 0
        fi
        
        echo "success!"
        rm -rf ${app_path}
        exit 0

    fi

    __build

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/nginx/docroot
    mkdir -p ${app_path}/data/nginx/conf

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: ${images[0]}:${nginx_version}
    volumes:
        - /etc/localtime:/etc/localtime:ro
        - "${app_path}/data/nginx/docroot:/usr/share/nginx/html"
        - "${app_path}/data/nginx/conf:/etc/nginx"
    environment:
        - VIRTUAL_HOST=${fqdn}
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
        - TIMEZONE=${timezone}
        - LETSENCRYPT_HOST=${fqdn}
        - LETSENCRYPT_EMAIL=${ssl_email}
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

