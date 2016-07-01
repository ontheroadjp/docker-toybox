#!/bin/sh

apache2_version=2.4.20

uid=""
gid=""

function __build() {
    docker build -t toybox/${application}:${apache2_version} $TOYBOX_HOME/src/${application}/${apache2_version}
}

containers=( \
   ${application}-${apache2_version} 
)

function __init() {

    __build

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/apache2/docroot
    mkdir -p ${app_path}/data/apache2/conf

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: toybox/${application}:${apache2_version}
    volumes:
        - "${app_path}/data/apache2/docroot:/usr/local/apache2/htdocs"
        - "${app_path}/data/apache2/conf:/usr/local/apache2/conf"
    environment:
        - VIRTUAL_HOST=${fqdn}
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
        - TIMEZONE=${timezone}
    ports:
        - "80"
EOF
}

#function __new() {
#    #__source; local status=$?
#    #if [ ${status} -ne 0 ]; then
#    #    echo ${project_name}": source code of ${application} does not download."
#    #    exit 1
#    #fi
#
#    __init && {
#        cd ${app_path}/bin
#        docker-compose -p ${project_name} up -d && {
#            echo '---------------------------------'
#            echo 'URL: http://'${fqdn}
#            echo 'WebDAV: http://'${fqdn}'/remote.php/webdav/'
#            echo '---------------------------------'
#            #echo -n 'Database Host: '
#            #docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
#            #    $(docker ps | grep ${project_name}_${db_container}_1 | awk '{print $1}')
#            echo 'Database Username: '${db_user}
#            echo 'Database Password: '${db_user_pass}
#        }
#    }
#}

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

