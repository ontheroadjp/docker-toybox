#!/bin/sh

function __usage() {
  cat <<-EOF
Usage: 
    ${project_name} 
    ${project_name} [-s|-d] <application> new
    ${project_name} [URL] <command>
    ${project_name} [-e|-v|-h]

option:
    -d              Assigning specific sub domain name
    -s              Assigning specific sub domain name
    -e              Show the environment variables
    -v              Show the version of ${project_name}
    -h              Show this message

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
    ps              Show ${app_name} containers status
    restart         Show ${app_name} containers status
    clear           Stop and Remove all of ${app_name} containers
    # backup          Backup DB data
    #source          get source code of containers

EOF
}

