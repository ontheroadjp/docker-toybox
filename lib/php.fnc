#!/bin/sh

db_name=${app_name}
db_user=${app_name}
db_user_pass=${app_name}

function __source() {
    if [ ! -e ${src} ]; then
        #git clone https://github.com/docker-library/wordpress.git ${src}
        :
    fi
}

main_container=${fqdn}-${app_name}
db_container=${fqdn}-${app_name}-db
data_container=${fqdn}-${app_name}-data

echo "app_name: ${app_name}"
echo "app_version: ${app_version}"

#app_version="7.0-apache"
if [ -z ${app_version} ]; then
    app_version=5.6-apache
elif [ ${app_version} != "5.6" ] && [ ${app_version} != "7.0" ]; then
    app_version=5.6-apache
else
    app_version=${app_version}-apache
fi

echo "app_name: ${app_name}"
echo "app_version: ${app_version}"

function __build() {
    docker build -t nutsp/${app_name}:${app_version} $TOYBOX_HOME/src/${app_name}/${app_version}
}

function __init() {

    __build

    mkdir -p ${app_path}/bin
    
    cat <<-EOF > ${compose_file}
${main_container}:
    image: nutsp/${app_name}:${app_version}
    volumes:
        - ${app_path}/data/apache2/docroot:/var/www/html
        #- ${app_path}/data/apache2/conf:/etc/apache2
    links:
        - ${db_container}:mysql
    environment:
        - VIRTUAL_HOST=${fqdn}
    ports:
        - "80"

${db_container}:
    image: mariadb
    volumes:
        - ${app_path}/data/mysql:/var/lib/mysql
    #volumes_from:
    #    - ${data_container}
    environment:
        MYSQL_ROOT_PASSWORD: root
        TERM: xterm

#${data_container}:
#    image: busybox
#    volumes:
#        - ${app_path}/data/apache2/docroot:/var/www/html
#        - ${app_path}/data/apache2/conf:/etc/apache2
#        - ${app_path}/data/mysql:/var/lib/mysql
EOF
}

function __new() {
    __init && {
        cd ${app_path}/bin
        docker-compose -p ${project_name} up -d && {
            echo '---------------------------------'
            echo 'URL: http://'${fqdn}
            echo '---------------------------------'
            echo -n 'Database Host: '
            docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
                $(docker ps | grep ${db_container}_1 | awk '{print $1}')
            echo 'Database Username: '${db_user}
            echo 'Database Password: '${db_user_pass}
        }
    }
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

