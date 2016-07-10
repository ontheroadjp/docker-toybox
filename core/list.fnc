#!/bin/bash

function __print_header() {
    echo ''
    echo '  _____         ___          '
    echo ' |_   _|__ _  _| _ ) _____ __'
    echo '   | |/ _ \ || | _ \/ _ \ \ /'
    echo '   |_|\___/\_, |___/\___/_\_\'
    echo '           |__/  Nuts Project,LLC'
    echo ''
}

function __list() {

    __print_header

    # --------------------------------------------
    # print proxy
    # --------------------------------------------
    application="proxy"
    . $TOYBOX_HOME/lib/${application}.fnc
    for container in ${containers[@]}; do
        __is_container_exist ${container}; local exist=$(( ${exist} + $? ))
        __is_container_running ${container}; local running=$(( ${running} + $? ))
    done
 
    printf "${application} is "
    if [ ${exist} -eq 0 ] && [ ${running} -eq 0 ]; then
        printf "\033[1;32m%-10s\033[0m" "running"
        printf "\n"
        files=${TOYBOX_HOME}/stack/proxy/80/data/nginx/certs/*
        for file in $files; do
            if [ -h ${file} ] && [[ ${file} =~ .crt$ ]]; then
                echo " - $(echo $(basename ${file}) | sed 's:.crt::') is SSL Connection ready!"
            fi
        done
    else
        printf "\033[1;31m%-10s\033[0m" "stopped"
    fi
    #printf "\n"

    # --------------------------------------------
    # print applications
    # --------------------------------------------

    app_root="$TOYBOX_HOME/stack"
    stack="${app_root}/*"
    for dom in ${stack}; do
        if [ -d ${dom} ]; then
            domain=$(echo ${dom} | sed "s:${app_root}/::")
            if [ ${domain} != "proxy" ]; then
                echo
                echo "[${domain}]"
                printf "%-10s" "ID"
                printf "%-42s" "URL"
                printf "%-20s" "Application"
                echo "Status"
                echo "-----------------------------------------------------------------------------"

            fi
            subs="${dom}/*"
            for sub in ${subs}; do
                if [ -d ${sub} ]; then
                    sub_domain=$(echo ${sub} | sed "s:${app_root}/${domain}/::")

                    fqdn=${sub_domain}.${domain}
                    applist_grep_key=${fqdn}
                    app_path=$TOYBOX_HOME/stack/${domain}/${sub_domain}
                    application=$(__get_app_env TOYBOX_APPLICATION)
                    compose_file="${app_path}/bin/docker-compose.yml"
                    src="$TOYBOX_HOME/src/${application}"

                    . $TOYBOX_HOME/lib/${application}.fnc

                    if [ ${application} = 'proxy' ]; then
                        continue
                    else
                        printf "%-10s" $(__get_app_env TOYBOX_APP_ID)
                        if [ -h ${TOYBOX_HOME}/stack/proxy/80/data/nginx/certs/${fqdn}.crt ]; then
                            printf "\033[1;32m%-42s\033[0m" "https://${fqdn}"
                            #printf "https://%-34s" "${fqdn}"
                        else
                            printf "http://%-35s" ${fqdn}
                        fi
                    fi

                    local ver=$(echo ${app_version} | sed 's:-apache::')
                    printf "%-20s" ${application}:${ver}

                    local exist=0
                    local running=0

                    for container in ${containers[@]}; do
                        __is_container_exist ${container}; exist=$(( ${exist} + $? ))
                        __is_container_running ${container}; running=$(( ${running} + $? ))
                    done

                    if [ ${exist} -eq ${#containers[@]} ]; then
                        printf "%-10s" "removed"
                    elif [ ${exist} -eq 0 ] && [ ${running} -eq 0 ]; then
                        printf "\033[1;32m%-10s\033[0m" "running"
                    elif [ ${exist} -eq 0 ] && [ ${running} -eq ${#containers[@]} ]; then
                        printf "\033[1;31m%-10s\033[0m" "stopped"
                    else
                        printf "\033[1;31m%-10s\033[0m" "error"
                    fi
                    printf "\n"
                fi
            done
        fi
    done
}

#function __applist() {
#    if [ -f ${applist} ]; then
#        cat ${applist} | awk 'BEGIN{ OFS=" " }
#            function red(s) { printf "\033[1;31m%s\033[0m",s }
#            function green(s) { printf "\033[1;32m%s\033[0m",s }
#            function blue(s) { printf "\033[1;34m%s\033[0m",s }
#            function app(s) { printf "%-15s",s }
#            function status(s) { 
#                if(s == "running")
#                    printf "\033[1;32m%s\033[0m",s
#                else if(s == "stopped")
#                    printf "\033[1;31m%s\033[0m",s
#                else
#                    printf "%s",s
#            }
#            { printf "%2s",NR } { printf ": http://%-35s",$1 }
#            { app($2) }
#            { status($3) }
#            { printf "\n" }'
#    else
#        echo 'no application available.'
#    fi
#}

#function __list() {
#
#    __print_header
#
#    if [ ! -f ${applist} ]; then
#        echo 'no application available.'
#
#    else
#        application="proxy"
#        . $TOYBOX_HOME/lib/proxy.fnc
#        for container in ${containers[@]}; do
#            __is_container_exist ${container}; local exist=$(( ${exist} + $? ))
#            __is_container_running ${container}; local running=$(( ${running} + $? ))
#        done
#
#        if [ ${exist} -eq 0 ] && [ ${running} -eq 0 ]; then
#            printf "proxy is "
#            printf "\033[1;32m%-10s\033[0m" "running"
#        else
#            printf "you must start proxy"
#        fi
#        printf "\n"
#
#        cat ${applist} | while read line; do
#
#            fqdn=$(echo ${line} | awk '{print $1}')
#            applist_grep_key=${fqdn}
#            application=$(echo ${line} | awk '{print $2}')
#            app_path=$(echo ${line} | awk '{print $4}')
#            compose_file="${app_path}/bin/docker-compose.yml"
#            src="$TOYBOX_HOME/src/${application}"
#            . $TOYBOX_HOME/lib/${application}.fnc
#
#
#            if [ ${application} = 'proxy' ]; then
#                continue
#            else
#                printf "http://%-35s" ${fqdn}
#            fi
#
#            printf "%-15s" ${application}:${app_version}
#
#            local exist=0
#            local running=0
#
#            for container in ${containers[@]}; do
#                __is_container_exist ${container}; exist=$(( ${exist} + $? ))
#                __is_container_running ${container}; running=$(( ${running} + $? ))
#            done
#
#            if [ ${exist} -eq ${#containers[@]} ]; then
#                printf "%-10s" "removed"
#            elif [ ${exist} -eq 0 ] && [ ${running} -eq 0 ]; then
#                printf "\033[1;32m%-10s\033[0m" "running"
#            elif [ ${exist} -eq 0 ] && [ ${running} -eq ${#containers[@]} ]; then
#                printf "\033[1;31m%-10s\033[0m" "stopped"
#            else
#                printf "\033[1;31m%-10s\033[0m" "error"
#            fi
#            printf "\n"
#
#        done
#    fi
#}

