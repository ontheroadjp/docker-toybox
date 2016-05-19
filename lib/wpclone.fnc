#!/bin/sh

remote_clone=1

db_root_password="root"
db_name="toybox_wordpress"
db_user="toybox"
db_password="toybox"
db_table_prefix="wp_dev_"
db_alias="mysql"

containers=( ${fqdn}-${app_name} ${fqdn}-${app_name}-db )
wordpress_version="4.5.2-apache"
mariadb_version="10.1.14"
document_root="/var/www/html"


#function __source() {
#    if [ ! -e ${src} ]; then
#        git clone https://github.com/interconnectit/Search-Replace-DB.git ${src}
#        git clone https://github.com/docker-library/wordpress.git ${src}
#    fi
#}

components_path=${app_path}/components
wp_path=""
original_fqdn=""

function __get_original_wp_data(){
    local dist=${components_path}/wp-sync

    if [ ! -f ${components_path}/wp-sync/data/dump.sql.tar.gz ]; then
        echo -n "Enter remote host: "
        read ssh_remotehost
        echo -n "Enter remote wordpress dir: "
        read wp_path
        echo -n "Enter original wordpress's fqdn: "
        read original_fqdn

        # wp-sync 
        git clone https://github.com/ontheroadjp/wp-sync.git ${dist}
        cp ${components_path}/wp-sync/.env.sample ${dist}/.env
        sed -i -e "s:^wp_host=\"\":wp_host=\"${ssh_remotehost}\":" ${dist}/.env
        sed -i -e "s:^wp_root=\"/var/www/wordpress\":wp_root=\"${wp_path}\":" ${dist}/.env
        sh ${dist}/remote-admin.sh mysqldump
        cp ${TOYBOX_HOME}/wp.tar.gz ${dist}/data
    fi
}

function __after_start() {
    cd ${app_path}/data/wordpress
    sudo cp -r ./original/wp-content ./docroot
    sudo cp -r ./original/.htaccess ./docroot
    sudo chown -R www-data:www-data ./docroot
}

function __get_wp_components() {
    local dist=${components_path}/wordpress/bin
    mkdir -p ${dist}

    # WordPress HTML data
    #tar $TOYBOX_HOME/wp.tar.gz -C ${app_path}/data/wordpres
    mkdir -p ${app_path}/data/wordpress/original
    tar -xzf ${components_path}/wp-sync/data/wp.tar.gz -C ${app_path}/data/wordpress/original --strip-components 1
    rm ${components_path}/wp-sync/data/wp.tar.gz

    # Search-Replace-DB
    git clone https://github.com/interconnectit/Search-Replace-DB.git ${dist}/Search-Replace-DB

    # entrypoint-ex.sh
    cp ${src}/wordpress/docker-entrypoint-ex.sh ${dist}

    # Dockerfile
    local script="${document_root}/Search-Replace-DB/srdb.cli.php"
    local h=${db_alias}
    local u=${db_user}
    local p=${db_password}
    local n=${db_name}
    local s=${original_fqdn}
    local r=${fqdn}
    local replace_fqdn_cmd="php ${script} -h='${h}' -u='${u}' -p='${p}' -n='${n}' -s='${s}' -r='${r}'"

    local ss=${wp_path}
    local rr=${document_root}
    local replace_docroot_cmd="php ${script} -h='${h}' -u='${u}' -p='${p}' -n='${n}' -s='${ss}' -r='${rr}'"

    cat <<-EOF > ${components_path}/wordpress/bin/Dockerfile
FROM wordpress:${wordpress_version}
MAINTAINER NutsProject,LLC

RUN sed -i -e "$ i ${replace_fqdn_cmd}" /entrypoint.sh \
    && sed -i -e "$ i ${replace_docroot_cmd}" /entrypoint.sh

COPY Search-Replace-DB/ /usr/src/wordpress/Search-Replace-DB/
COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
EOF
}

function __get_mariadb_components() {
    local dist=${components_path}/mariadb/bin
    mkdir -p ${dist}

    ## DB dump data
    #tar xvzf ${components_path}/wp-sync/data/dump.sql.tar.gz -C ${dist}

    # entrypoint-ex.sh
    cp ${src}/mariadb/docker-entrypoint-ex.sh ${dist}

    # Dockerfile
    #cp ${src}/mariadb/Dockerfile ${dist}
    cat <<-EOF > ${dist}/Dockerfile
FROM mariadb:${mariadb_version}
MAINTAINER NutsProject,LLC

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
EOF
}

function __init() {

    # general wordpress
    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data

    # ---- wpclone only ----
    if [ ${remote_clone} -eq 1 ]; then
        __get_original_wp_data
        __get_wp_components
        __get_mariadb_components
    fi
    # ---- wpclone only ----

    id www-data > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        sudo groupadd www-data
        echo "www-data group created."
        sudo useradd -g www-data www-data
        echo "www-data user created."
    fi
    
    local wordpress_uid=$(cat /etc/passwd | grep ^www-data | cut -d : -f3)
    local wordpress_gid=$(cat /etc/group | grep ^www-data | cut -d: -f3)

    id mysql > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        sudo groupadd mysql
        echo "mysql group created."
        sudo useradd -g mysql mysql
        echo "mysql user created."
    fi
    
    local mysql_uid=$(cat /etc/passwd | grep ^mysql | cut -d : -f3)
    local mysql_gid=$(cat /etc/group | grep ^mysql | cut -d: -f3)

    docker build -t toybox/wordpress:${wordpress_version} ${components_path}/wordpress/bin
    docker build -t toybox/mariadb:${mariadb_version} ${components_path}/mariadb/bin
    
    cat <<-EOF > ${compose_file}
${containers[0]}:
    image: toybox/wordpress:${wordpress_version}
    links:
        - ${containers[1]}:${db_alias}
    environment:
        - VIRTUAL_HOST=${fqdn}
        - PROXY_CACHE=true
        - TOYBOX_WWW_DATA_UID=${wordpress_uid}
        - TOYBOX_WWW_DATA_GID=${wordpress_gid}
        - WORDPRESS_DB_NAME=${db_name}
        - WORDPRESS_DB_USER=${db_user}
        - WORDPRESS_DB_PASSWORD=${db_password}
        - WORDPRESS_TABLE_PREFIX=${db_table_prefix}
    volumes:
        - ${app_path}/data/wordpress/docroot:${document_root}
    ports:
        - "80"

${containers[1]}:
    image: toybox/mariadb:${mariadb_version}
    volumes:
        - ${app_path}/data/mariadb:/var/lib/mysql
        - ${components_path}/wp-sync/data:/docker-entrypoint-initdb.d

    environment:
        - MYSQL_ROOT_PASSWORD=${db_root_password}
        - MYSQL_DATABASE=${db_name}
        - MYSQL_USER=${db_user}
        - MYSQL_PASSWORD=${db_password}
        - TERM=xterm
        - TOYBOX_MYSQL_UID=${mysql_uid}
        - TOYBOX_MYSQL_GID=${mysql_gid}

#${containers[2]}:
#    image: busybox
#    volumes:
#        - ${app_path}/data/docroot:${document_root}
#        - ${app_path}/data/mysql:/var/lib/mysql
EOF
}

#function __new() {
#    __init && {
#        cd ${app_path}/bin
#        docker-compose -p ${project_name} up -d && {
#            echo '---------------------------------' | tee -a ${app_path}/info.txt
#            echo 'URL: http://'${fqdn} | tee -a ${app_path}/info.txt
#            echo '---------------------------------' | tee -a ${app_path}/info.txt
#            echo -n 'Database Host: ' | tee -a ${app_path}/info.txt
#            docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
#                $(docker ps | grep ${containers[1]}_1 | awk '{print $1}' | tee -a ${app_path}/info.txt)
#            echo 'Database Username: '${db_user} | tee -a ${app_path}/info.txt
#            echo 'Database Password: '${db_user_pass} | tee -a ${app_path}/info.txt
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

#function __restore() {
#    prefix=$(cat ${app_path}/backup/history.txt | peco)
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${data_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}_db.tar.gz
#    docker run --rm --volumes-from $(docker ps -a | grep ${project_name}_${main_container}_1 | awk '{print $1}') -v ${app_path}/backup:/backup busybox tar xvzf /backup/${prefix}.tar.gz
#    _stop && {
#        _start
#    }
#}

