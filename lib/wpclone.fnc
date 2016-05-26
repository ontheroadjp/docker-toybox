#!/bin/sh
#set -eu

clone=1

containers=( ${fqdn}-${app_name} ${fqdn}-${app_name}-db )
if [ ${clone} -eq 0 ]; then
    images=( wordpress mariadb)
else
    images=( toybox/wordpress toybox/mariadb)
fi
wordpress_version="4.5.2-apache"
mariadb_version="10.1.14"

db_root_password="root"
db_name="toybox_wordpress"
db_user="toybox"
db_password="toybox"
db_table_prefix="wp_dev_"
db_alias="mysql"
document_root="/var/www/html"

uid=""
gid=""

#function __source() {
#    if [ ! -e ${src} ]; then
#        git clone https://github.com/interconnectit/Search-Replace-DB.git ${src}
#        git clone https://github.com/docker-library/wordpress.git ${src}
#    fi
#}

build_dir=${app_path}/build
wp_path=""
original_fqdn=""

wp_build_dir=${build_dir}/wordpress
mariadb_build_dir=${build_dir}/mariadb
original_wp_data=${app_path}/data/wordpress/original_wp_data

# --------------------------------------------------------
# Build function
# --------------------------------------------------------

function __prepare_wp_data(){
    local dist=${build_dir}/wp-sync

    if [ ! -f ${build_dir}/wp-sync/data/dump.sql.tar.gz ]; then
        set -eu
        echo -n "Enter remote host: "
        read ssh_remotehost
        echo -n "Enter remote wordpress dir: "
        read wp_path
        echo -n "Enter original FQDN: "
        read original_fqdn
        echo "------------------------------------------------------------"
        echo "Remote Host: ${ssh_remotehost}"
        echo "Remote WordPress dir: ${wp_path}"
        echo "Remote WordPress  FQDN: ${original_fqdn}"
        echo "------------------------------------------------------------"
        echo -n "Are you sure? (y/n): " 
        read confirm
        if [ ${confirm} != "y" ]; then
            exit 1
        fi
        echo ""

        # wp-sync 
        echo ">>> Get wp-sync..."
        git clone https://github.com/ontheroadjp/wp-sync.git ${dist}
        cp ${build_dir}/wp-sync/.env.sample ${dist}/.env
        sed -i -e "s:^wp_host=\"\":wp_host=\"${ssh_remotehost}\":" ${dist}/.env
        sed -i -e "s:^wp_root=\"/var/www/wordpress\":wp_root=\"${wp_path}\":" ${dist}/.env
        sh ${dist}/remote-admin.sh mysqldump        # temporary
        cp ${TOYBOX_HOME}/wp.tar.gz ${dist}/data    # temporary
        echo ""
        set +eu
    fi
}

function __prepare_wp_build() {
    local dist=${wp_build_dir}
    mkdir -p ${dist}

    # WordPress HTML data
    mkdir -p ${original_wp_data}
    tar -xzf ${build_dir}/wp-sync/data/wp.tar.gz -C ${original_wp_data} --strip-components 1
    rm ${build_dir}/wp-sync/data/wp.tar.gz

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

    cat <<-EOF > ${dist}/Dockerfile
FROM wordpress:${wordpress_version}
MAINTAINER NutsProject,LLC

RUN sed -i -e "$ i ${replace_fqdn_cmd}" /entrypoint.sh \
    && sed -i -e "$ i ${replace_docroot_cmd}" /entrypoint.sh \
    && rm -rf /usr/src/wordpress/wp-content

COPY Search-Replace-DB/ /usr/src/wordpress/Search-Replace-DB/
COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
EOF
}

function __prepare_mariadb_build() {
    local dist=${mariadb_build_dir}
    mkdir -p ${dist}

    # entrypoint-ex.sh
    cp ${src}/mariadb/docker-entrypoint-ex.sh ${dist}

    # Dockerfile
    cat <<-EOF > ${dist}/Dockerfile
FROM mariadb:${mariadb_version}
MAINTAINER NutsProject,LLC

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
EOF
}

function __post_run() {
    if [ ${clone} -eq 1 ]; then

        echo ">>> Apply original WordPress data..."
        local host_docroot=${app_path}/data/wordpress/docroot

        echo -n "copy wp-content dir..."
        cp -rf ${original_wp_data}/wp-content/ ${host_docroot} && echo "done."

        echo -n "copy .htaccess file..."
        cp -f ${original_wp_data}/.htaccess ${host_docroot} && echo "done."

        # for DB Connection
        echo -n "modify wp-config.php file..."
        local out=${original_wp_data}/wp-config.php
        sed -i -e "s:^define('DB_NAME', '.*');:define('DB_NAME', '${db_name}');:" ${out}
        sed -i -e "s:^define('DB_USER', '.*');:define('DB_USER', '${db_user}');:" ${out}
        sed -i -e "s:^define('DB_PASSWORD', '.*');:define('DB_PASSWORD', '${db_password}');:" ${out}
        sed -i -e "s:^define('DB_HOST', '.*');:define('DB_HOST', '${db_alias}');:" ${out}
        echo "done."

        # for wp-supercache
        local wpcachehome=${document_root}/wp-content/plugins/wp-super-cache/
        sed -i -e "s:^define( 'WPCACHEHOME', '.*' );:define( 'WPCACHEHOME', '${wpcachehome}' );:" ${out}

        # copy wp-config.php
        cp -f ${out} ${host_docroot}
    fi
}

# --------------------------------------------------------
# Initialize
# --------------------------------------------------------

function __init() {

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/wordpress/docroot
    mkdir -p ${app_path}/data/mariadb

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)
    
    ##id www-data > /dev/null 2>&1
    ##if [ $? -ne 0 ]; then
    ##    sudo groupadd www-data
    ##    echo "www-data group created."
    ##    sudo useradd -g www-data www-data
    ##    echo "www-data user created."
    ##fi
    ##
    ##local wordpress_uid=$(cat /etc/passwd | grep ^www-data | cut -d : -f3)
    ##local wordpress_gid=$(cat /etc/group | grep ^www-data | cut -d: -f3)

    ##id mysql > /dev/null 2>&1
    ##if [ $? -ne 0 ]; then
    ##    sudo groupadd mysql
    ##    echo "mysql group created."
    ##    sudo useradd -g mysql mysql
    ##    echo "mysql user created."
    ##fi
    ##
    ##local mysql_uid=$(cat /etc/passwd | grep ^mysql | cut -d : -f3)
    ##local mysql_gid=$(cat /etc/group | grep ^mysql | cut -d: -f3)

    # ---- wpclone only ----
    if [ ${clone} -eq 1 ] && [ ! -d ${build_dir}/wp-sync/data ]; then
        __prepare_wp_data

        echo ">>> Prepare WordPress build..."
        __prepare_wp_build && echo ""

        echo ">>> Prepare MariaDB build..."
        __prepare_mariadb_build && echo ""

        echo ">>> build WordPress container..."
        docker build -t toybox/wordpress:${wordpress_version} ${wp_build_dir} && echo ""

        echo ">>> build MariaDB container..."
        docker build -t toybox/mariadb:${mariadb_version} ${mariadb_build_dir} && echo ""
    fi
    # ---- wpclone only ----

    cat <<-EOF > ${compose_file}
${containers[0]}:
    #image: toybox/wordpress:${wordpress_version}
    image: ${images[0]}:${wordpress_version}
    links:
        - ${containers[1]}:${db_alias}
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    environment:
        - VIRTUAL_HOST=${fqdn}
        - PROXY_CACHE=true
        #- TOYBOX_WWW_DATA_UID=${wordpress_uid}
        #- TOYBOX_WWW_DATA_GID=${wordpress_gid}
        - TOYBOX_WWW_DATA_UID=${uid}
        - TOYBOX_WWW_DATA_GID=${gid}
        - WORDPRESS_DB_NAME=${db_name}
        - WORDPRESS_DB_USER=${db_user}
        - WORDPRESS_DB_PASSWORD=${db_password}
        - WORDPRESS_TABLE_PREFIX=${db_table_prefix}
    volumes:
        - ${app_path}/data/wordpress/docroot:${document_root}
    ports:
        - "80"

${containers[1]}:
    #image: toybox/mariadb:${mariadb_version}
    image: ${images[1]}:${mariadb_version}
    volumes:
        - ${app_path}/data/mariadb:/var/lib/mysql
        - ${build_dir}/wp-sync/data:/docker-entrypoint-initdb.d
    log_driver: "json-file"
    log_opt:
        max-size: "3m"
        max-file: "7"
    environment:
        - MYSQL_ROOT_PASSWORD=${db_root_password}
        - MYSQL_DATABASE=${db_name}
        - MYSQL_USER=${db_user}
        - MYSQL_PASSWORD=${db_password}
        - TERM=xterm
        #- TOYBOX_MYSQL_UID=${mysql_uid}
        #- TOYBOX_MYSQL_GID=${mysql_gid}
        - TOYBOX_MYSQL_UID=${uid}
        - TOYBOX_MYSQL_GID=${gid}

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

