#!/bin/bash

usermod -u ${TOYBOX_UID} mysql
groupmod -g ${TOYBOX_GID} mysql

#apt-get update -y && apt-get install -y vim

maria_cnf="/etc/mysql/conf.d/mariadb.cnf"
sed -i -e "s:^#default-character-set *= *utf8:default-character-set = utf8:" ${maria_cnf}
sed -i -e "s:^#character-set-server *= *utf8:character-set-server = utf8:" ${maria_cnf}
sed -i -e "s:^#collation-server *= *utf8_general_ci:collation-server = utf8_general_ci:" ${maria_cnf}
sed -i -e "s:^#character_set_server *= *utf8:character_set_server = utf8:" ${maria_cnf}
sed -i -e "s:^#collation_server *= *utf8_general_ci:collation_server = utf8_general_ci:" ${maria_cnf}

chown -R mysql:mysql /var/log/mysql

repl_cnf="/etc/mysql/conf.d/replication.cnf"
if [ ${SERVER_TYPE} = 'master' ]; then
    cat << EOF > ${repl_cnf}
[mysqld]
server_id=1
log_bin=/var/log/mysql/mariadb-bin
binlog_format=MIXED
max_binlog_size=100M
expire_logs_days=30

#replicate-do-db=toybox
replicate-ignore-db=information_schema
replicate-ignore-db=mysql
replicate-ignore-db=performance_schema

#sync_binlogs=1
#sync_binlogs=0
innodb_support_xa=1

##[galera]
##innodb_flush_logs_at_trx_commit=1
EOF
    
    master_ini="/docker-entrypoint-initdb.d/master_ini.sh"
    cat << EOF > ${master_ini}
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT REPLICATION SLAVE ON *.* to repl@'%' identified by 'password';"
EOF

elif [ ${SERVER_TYPE} = 'slave' ]; then
    cat << EOF > ${repl_cnf}
[mysqld]
server_id=2
read_only
EOF
    binarylog=""
    binarylog_pos=""
    dumpfile="/master_db.sql"

    while [ ! -f ${dumpfile} ] || [ ! -s ${dumpfile} ]; do
        sleep 5
        mysqldump -h master -u root -p${MYSQL_ROOT_PASSWORD} \
            --all-databases \
            --events \
            --single-transaction \
            --flush-logs \
            --master-data=2 \
            --hex-blob \
            --default-character-set=utf8 > ${dumpfile} | true
    done
    
    slave_ini="/docker-entrypoint-initdb.d/slave_ini.sh"
    binarylog=$(head -n 100 master_db.sql | grep CHANGE | sed -e "s:^.*\(mariadb-bin.[0-9]*\).*$:\1:")
    binarylog_pos=$(head -n 100 master_db.sql | grep CHANGE | sed -e "s:^.*MASTER_LOG_POS=\([0-9]*\);.*$:\1:")
    cat << EOF > ${slave_ini}
mysql -u root -p${MYSQL_ROOT_PASSWORD} < ${dumpfile}
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CHANGE MASTER TO 
                             MASTER_HOST='master', 
                             MASTER_PORT=3306, 
                             MASTER_USER='repl', 
                             MASTER_PASSWORD='password', 
                             MASTER_LOG_FILE='${binarylog}', 
                             MASTER_LOG_POS=${binarylog_pos};"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "START SLAVE;"
EOF
fi

exec /docker-entrypoint.sh mysqld --user=mysql --console
