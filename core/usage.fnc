#!/bin/sh

function __usage() {
  cat <<-EOF
Usage: 
    ${project_name} 
    ${project_name} env|version|help
    ${project_name} [-s|-d] <application> new
    ${project_name} <URL> <command>

option:
    -d              Assigning specific domain name
    -s              Assigning specific sub domain name

application:
    proxy           Http dinamic proxy server based on nginx 
    php5            LAMP(Apache2 + MySQL5.6 + PHP5.6)
    php7            LAMP(Apache2 + MySQL5.6 + PHP7.0)
    wordpress       CMS 
    owncloud        Personal cloud strage like a Dropbox
    lychee          Photo management system
    reichat         Paint chat

command:
    start           Start ${app_name} containers
    stop            Stop ${app_name} containers
    restart         Restart ${app_name} containers
    down            Stop and remove ${app_name} containers
    ps              Show ${app_name} containers status
    config          Show ${app_name} containers configuration
    clear           Remove ${app_name} application
    #backup          Backup DB data
    #source          get source code of containers

EOF
}

