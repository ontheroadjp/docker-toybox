#!/bin/sh

. $TOYBOX_HOME/lib/wordpress.fnc

process=(
    "apache2 -DFOREG"
    "mysqld --user=m"
)
process_user=(
    "www-data"
    "mysql"
)
files=(
    /entrypoint-ex.sh
    ${app_path}/data/wordpress/docroot/.htaccess
    ${app_path}/data/wordpress/docroot/index.php
    ${app_path}/data/wordpress/docroot/license.txt
    ${app_path}/data/wordpress/docroot/readme.html
    ${app_path}/data/wordpress/docroot/wp-activate.php
    ${app_path}/data/wordpress/docroot/wp-blog-header.php
    ${app_path}/data/wordpress/docroot/wp-comments-post.php
    ${app_path}/data/wordpress/docroot/wp-config.php
    ${app_path}/data/wordpress/docroot/wp-config-sample.php
    ${app_path}/data/wordpress/docroot/wp-cron.php
    ${app_path}/data/wordpress/docroot/wp-links-opml.php
    ${app_path}/data/wordpress/docroot/wp-load.php
    ${app_path}/data/wordpress/docroot/wp-login.php
    ${app_path}/data/wordpress/docroot/wp-mail.php
    ${app_path}/data/wordpress/docroot/wp-settings.php
    ${app_path}/data/wordpress/docroot/wp-signup.php
    ${app_path}/data/wordpress/docroot/wp-trackback.php
    ${app_path}/data/wordpress/docroot/xmlrpc.php
    ${app_path}/data/mariadb/toybox_wordpress/db.opt
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_commentmeta.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_commentmeta.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_comments.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_comments.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_links.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_links.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_options.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_options.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_postmeta.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_postmeta.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_posts.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_posts.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_css.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_css.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_layer_animations.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_layer_animations.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_navigations.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_navigations.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_sliders.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_sliders.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_slides.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_slides.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_static_slides.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_revslider_static_slides.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_termmeta.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_termmeta.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_term_relationships.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_term_relationships.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_terms.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_terms.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_term_taxonomy.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_term_taxonomy.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_usermeta.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_usermeta.ibd
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_users.frm
    ${app_path}/data/mariadb/toybox_wordpress/wp_dev_users.ibd
)
dirs=(
    ${app_path}/data/wordpress/docroot/Search-Replace-DB
    ${app_path}/data/wordpress/docroot/wp-admin
    ${app_path}/data/wordpress/docroot/wp-content
    ${app_path}/data/wordpress/docroot/wp-content/themes
    ${app_path}/data/wordpress/docroot/wp-includes
    ${app_path}/data/mariadb
    ${app_path}/data/mariadb/toybox_wordpress
)


function __test_links() {
    local id=$(docker ps | grep "toybox_${containers[0]}_" | cut -d " " -f1)
    echo ">>> TEST links"
    printf "${db_alias}..." && (( tests++ ))
    docker exec -t ${id} cat /etc/hosts | grep ${db_alias} > /dev/null 2>&1 && {
        if [ $? -eq 0 ]; then
            printf "\033[1;32m%-10s\033[0m" "OK" && printf "\n" && (( success++ ))
        else
            printf "\033[1;31m%-10s\033[0m" "NG" && printf "\n" && (( failed++ ))
        fi
    }
}

