#!/bin/sh
#set -eu

clone=0

containers=( ${fqdn}-${application} ${fqdn}-${application}-db )
images=(toybox/wordpress toybox/mariadb)

declare -A components=(
    ["${project_name}_${containers[0]}_1"]="apache php wordpress"
    ["${project_name}_${containers[1]}_1"]="mariadb"
)
declare -A component_version=(
    ['apache']="2.4.10"
    ['php']="5.6.21"
    ['wordpress']="4.5.2"
    ['mariadb']="10.1.14"
)

db_root_password="root"
db_name="toybox_wordpress"
db_user="toybox"
db_password="toybox"
db_table_prefix="wp_dev_"
db_alias="mysql"
docroot="/var/www/html"

declare -A params=(
    ['mariadb_mysql_root_password']=${db_root_password}
    ['mariadb_mysql_database']=${db_name}
    ['mariadb_mysql_user']=${db_user}
    ['mariadb_mysql_password']=${db_password}
    ['mariadb_db_table_prefix']=${db_table_prefix}
    ['mariadb_db_alias']=${db_alias}
    ['mariadb_term']="xterm"
    #['VIRTUAL_HOST']=${fqdn}
    ['wordpress_proxy_cache']=true
    ['wordpress_wordpress_db_name']=${db_name}
    ['wordpress_wordpress_db_user']=${db_user}
    ['wordpress_wordpress_db_password']=${db_password}
    ['wordpress_wordpress_table_prefix']=${db_table_prefix}
    ['wordpress_docroot']="/var/www/html"
    #['EXEC_REPLACE_DB']=${clone}
    #['FQDN_REPLACED']=${remote_fqdn}
    #['REMOTE_WP_DIR']=${remote_wp_dir}
)

wordpress_version="4.5.2-apache"
mariadb_version="10.1.14"

uid=""
gid=""

build_dir=${app_path}/build
remote_wp_data=${app_path}/data/wordpress/remote_wp_data
remote_wp_dir=""
remote_fqdn=""

# --------------------------------------------------------
# Build function
# --------------------------------------------------------

function __prepare_wp_data(){
    local dist=${build_dir}/wp-sync

    if [ ! -f ${dist}/data/dump.sql.tar.gz ]; then
        set -eu
        echo -n "Enter remote host: "
        read ssh_remotehost
        echo -n "Enter remote wordpress dir: "
        read remote_wp_dir
        echo -n "Enter remote FQDN: "
        read remote_fqdn
        echo "------------------------------------------------------------"
        echo "Remote Host: ${ssh_remotehost}"
        echo "Remote WordPress dir: ${remote_wp_dir}"
        echo "Remote WordPress  FQDN: ${remote_fqdn}"
        echo "------------------------------------------------------------"
        echo -n "Are you sure? (y/n): " 
        read confirm
        if [ ${confirm} != "y" ]; then
            exit 1
        fi
        echo ""

        # wp-sync 
        echo ">>> Prepare wp-sync"
        git clone https://github.com/ontheroadjp/wp-sync.git ${dist}
        cp ${build_dir}/wp-sync/.env.sample ${dist}/.env
        sed -i -e "s:^wp_host=\"example\":wp_host=\"${ssh_remotehost}\":" ${dist}/.env
        sed -i -e "s:^wp_root=\"/var/www/wordpress\":wp_root=\"${remote_wp_dir}\":" ${dist}/.env
        echo

        echo ">>> Fetch remote wordpress data"
        sh ${dist}/remote-admin.sh mysqldump        # only sqldump

        # --- temporary ---
        cp ${TOYBOX_HOME}/wp.tar.gz ${dist}/data 
        # --- temporary ---
        echo "complete!" && echo
        set +eu
    fi
}

function __prepare_wp_build() {
    local dist=${build_dir}/wordpress
    mkdir -p ${dist}

    # WordPress HTML data
    if [ ! -f ${build_dir}/wp-sync/data/wp.tar.gz ]; then
        echo "error: there is no ${build_dir}/wp-sync/data/wp.tar.gz"
        exit 1;
    fi
    mkdir -p ${remote_wp_data}
    tar -xzf ${build_dir}/wp-sync/data/wp.tar.gz -C ${remote_wp_data} --strip-components 1
    rm ${build_dir}/wp-sync/data/wp.tar.gz

    # Search-Replace-DB
    #git clone https://github.com/interconnectit/Search-Replace-DB.git ${dist}/Search-Replace-DB
    cp -r ${src}/${wordpress_version}/Search-Replace-DB ${dist}

    # entrypoint-ex.sh
    #cp ${src}/wordpress/docker-entrypoint-ex.sh ${dist}
    cp ${src}/${wordpress_version}/docker-entrypoint-ex.sh ${dist}

    # Dockerfile
    cp ${src}/${wordpress_version}/Dockerfile ${dist}

    ## Dockerfile
    #local script="${docroot}/Search-Replace-DB/srdb.cli.php"
    #local h=${db_alias}
    #local u=${db_user}
    #local p=${db_password}
    #local n=${db_name}
    #local s=${remote_fqdn}
    #local r=${fqdn}
    #local replace_fqdn_cmd="php ${script} -h='${h}' -u='${u}' -p='${p}' -n='${n}' -s='${s}' -r='${r}'"

    #local ss=${remote_wp_dir}
    #local rr=${docroot}
    #local replace_docroot_cmd="php ${script} -h='${h}' -u='${u}' -p='${p}' -n='${n}' -s='${ss}' -r='${rr}'"

#    cat <<-EOF > ${dist}/Dockerfile
#FROM wordpress:${wordpress_version}
#MAINTAINER NutsProject,LLC
#
##RUN sed -i -e "$ i ${replace_fqdn_cmd}" /entrypoint.sh \
##    && sed -i -e "$ i ${replace_docroot_cmd}" /entrypoint.sh
#
#COPY Search-Replace-DB/ /usr/src/wordpress/Search-Replace-DB/
#COPY docker-entrypoint-ex.sh /entrypoint-ex.sh
#
#ENTRYPOINT ["/entrypoint-ex.sh"]
#EOF
}

#function __prepare_mariadb_build() {
#    local dist=${mariadb_build_dir}
#    mkdir -p ${dist}
#
#    # entrypoint-ex.sh
#    cp ${src}/mariadb/docker-entrypoint-ex.sh ${dist}
#
#    # Dockerfile
#    cat <<-EOF > ${dist}/Dockerfile
#FROM mariadb:${mariadb_version}
#MAINTAINER NutsProject,LLC
#
#COPY docker-entrypoint-ex.sh /entrypoint-ex.sh
#
#ENTRYPOINT ["/entrypoint-ex.sh"]
#EOF
#}

# --------------------------------------------------------
# Clone command
# --------------------------------------------------------

function _clone() {
    clone=1
    _new $@
}

# --------------------------------------------------------
# Post run
# --------------------------------------------------------

function __post_run() {
    local host_docroot=${app_path}/data/wordpress/docroot
    if [ ${clone} -eq 1 ]; then

        echo ">>> Applying remote WordPress data"

        echo -n "copying wp-content dir..."
        cp -rf ${remote_wp_data}/wp-content/ ${host_docroot} && echo "done."

        echo -n "copying .htaccess file..."
        cp -f ${remote_wp_data}/.htaccess ${host_docroot} && echo "done."

        # for DB Connection
        local out=${remote_wp_data}/wp-config.php
        echo -n "modifying wp-config.php file..."
        sed -i -e "s:^define('DB_NAME', '.*');:define('DB_NAME', '${db_name}');:" ${out}
        sed -i -e "s:^define('DB_USER', '.*');:define('DB_USER', '${db_user}');:" ${out}
        sed -i -e "s:^define('DB_PASSWORD', '.*');:define('DB_PASSWORD', '${db_password}');:" ${out}
        sed -i -e "s:^define('DB_HOST', '.*');:define('DB_HOST', '${db_alias}');:" ${out}
        echo "done."

        # for wp-supercache
        local wpcachehome=${docroot}/wp-content/plugins/wp-super-cache/
        sed -i -e "s:^define( 'WPCACHEHOME', '.*' );:define( 'WPCACHEHOME', '${wpcachehome}' );:" ${out}

        # copy wp-config.php
        cp -f ${out} ${host_docroot}
    fi

    http_status=$(curl -LI http://${fqdn} -o /dev/null -w '%{http_code}\n' -s)
    while [ ${http_status} -ne 200 ] && [ ${http_status} -ne 301 ]; do
        echo "waiting(${http_status})..." && sleep 3
        http_status=$(curl -LI http://${fqdn} -o /dev/null -w '%{http_code}\n' -s)
    done

    # for SSL connection
    local out=${host_docroot}/wp-config.php
    sed -i -e "/<?php/a\if( \$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https' ){\n\
    define('FORCE_SSL_ADMIN', true);\n\
    \$_SERVER['HTTPS'] = 'on';\n\
    \$_SERVER['SERVER_PORT'] = 443;\n\
}\n" ${out}

#    sed -i -e "/<?php/a\define('FORCE_SSL_ADMIN', true);\n\
#if( \$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https' ){\n\
#    \$_SERVER['HTTPS'] = 'on';\n\
#    \$_SERVER['SERVER_PORT'] = 443;\n\
#}\n" ${out}

    echo "complete!"
    echo "---------------------------------"
    echo "URL: http://${fqdn}"
    echo "---------------------------------"
}

# --------------------------------------------------------
# Initialize
# --------------------------------------------------------

function __init() {

    # ---- wpclone only (TEMPORARY)----
    if [ ${clone} -eq 1 ] && [ ! -f $TOYBOX_HOME/wp.tar.gz ]; then
        echo "error: there is no wp.tar.gz"
        exit 1;
    fi
    # ---- wpclone only (TEMPORARY)----

    mkdir -p ${app_path}/bin
    mkdir -p ${app_path}/data/wordpress/docroot
    mkdir -p ${app_path}/data/mariadb
    mkdir -p ${app_path}/build/wp-sync

    uid=$(cat /etc/passwd | grep ^$(whoami) | cut -d : -f3)
    gid=$(cat /etc/group | grep ^$(whoami) | cut -d: -f3)

    # ---- wpclone only ----
    #if [ ${clone} -eq 1 ] && [ ! -d ${build_dir}/wp-sync/data ]; then
    if [ ${clone} -eq 1 ] && [ $(ls -la ${build_dir}/wp-sync | wc -l) -eq 3 ]; then
        __prepare_wp_data

        echo ">>> Prepare WordPress build..."
        __prepare_wp_build

        #echo ">>> Prepare MariaDB build..."
        #__prepare_mariadb_build && echo
    fi
    # ---- wpclone only ----

    echo ">>> build image: ${images[0]}:${wordpress_version} ..."
    #docker build -t toybox/wordpress:${wordpress_version} ${build_dir}/wordpress && echo
    docker build -t ${images[0]}:${wordpress_version} $TOYBOX_HOME/src/wordpress/${wordpress_version} && echo

    echo ">>> build image: ${images[1]}:${mariadb_version} ..."
    #docker build -t toybox/mariadb:${mariadb_version} ${mariadb_build_dir} && echo
    docker build -t ${images[1]}:${mariadb_version} $TOYBOX_HOME/src/mariadb/${mariadb_version} && echo

    #echo -n "SSL connection enable? (y/n):"
    #read is_ssl
    #if [ ${is_ssl} = "y" ]; then
    #    proto="https"
    #    while [ ! $(echo ${ssl_email} | egrep -e '^[a-zA-Z0-9_\.\-]+?@[A-Za-z0-9_\.\-]+$') ]; do
    #        echo -n "Enter e-mail address for SSL certificate:  "
    #        read ssl_email
    #    done
    #    echo "------------------------------------------------------------"
    #    echo "SSL: on"
    #    echo "Email for SSL certificate: ${ssl_email}"
    #    echo "------------------------------------------------------------"
    #else
    #    proto="http"
    #    echo "------------------------------------------------------------"
    #    echo "SSL: off"
    #    echo "------------------------------------------------------------"
    #fi

    #echo -n "Are you sure? (y/n): " 
    #read confirm
    #if [ ${confirm} != "y" ]; then
    #    exit 1
    #fi
    #echo ""

    cat <<-EOF > ${compose_file}
${containers[0]}:
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
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}
        - WORDPRESS_DB_NAME=${db_name}
        - WORDPRESS_DB_USER=${db_user}
        - WORDPRESS_DB_PASSWORD=${db_password}
        - WORDPRESS_TABLE_PREFIX=${db_table_prefix}
        - DOCROOT=${docroot}
        - EXEC_REPLACE_DB=${clone}
        - FQDN_REPLACED=${remote_fqdn}
        - REMOTE_WP_DIR=${remote_wp_dir}
    #    - LETSENCRYPT_HOST=${fqdn}
    #    - LETSENCRYPT_EMAIL=dev@ontheroad.jp
    volumes:
        - /etc/localtime:/etc/localtime:ro
        - ${app_path}/data/wordpress/docroot:${docroot}
    ports:
        - "80"

${containers[1]}:
    #image: toybox/mariadb:${mariadb_version}
    image: ${images[1]}:${mariadb_version}
    volumes:
        - /etc/localtime:/etc/localtime:ro
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
        - TOYBOX_UID=${uid}
        - TOYBOX_GID=${gid}

#${containers[2]}:
#    image: busybox
#    volumes:
#        - ${app_path}/data/docroot:${docroot}
#        - ${app_path}/data/mysql:/var/lib/mysql
EOF
}
