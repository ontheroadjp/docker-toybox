#!/bin/bash

function __usage() {
  cat <<-EOF
Usage: 
    ${project_name} 
    ${project_name} [ env | --help | -v | --version ]
    ${project_name} [OPTIONS] <application> COMMAND
    ${project_name} <URL> COMMAND

Option:
    -s, --sub-domain    Assigning specific sub domain name
    -d, --domain        Assigning specific domain name

Application:
    apache2             Web-Application: Http web server
    nginx               Web-Application: Http web server
    proxy               Web-Application: Http dinamic proxy server based on nginx 
    php5                Web-Application: LAMP(Apache2 + MariaDB + PHP5)
    php7                Web-Application: LAMP(Apache2 + MariaDB + PHP7)
    wordpress           Web-Application: CMS 
    owncloud            Web-Application: Personal cloud strage like a Dropbox
    lychee              Web-Application: Photo management system
    reichat             Web-Application: Paint chat
    jenkins
    gitbucket

Command:
    start               Start ${app_name} containers
    stop                Stop ${app_name} containers
    restart             Restart ${app_name} containers
    down                Stop and remove ${app_name} containers
    ps                  Show ${app_name} containers status
    config              Show ${app_name} containers configuration
    clear               Remove ${app_name} application
    #backup              Backup DB data
    #source              get source code of containers
EOF
}

