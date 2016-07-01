#!/bin/sh

if [ ${GITBUCKET_DB} = "mysql" ]; then
    cat << EOF > /gitbucket/database.conf
db {
    url = "jdbc:mysql://mysql/toybox_gitbucket?useUnicode=true&characterEncoding=utf8"
    user = "toybox"
    password = "toybox"
}
EOF
fi

exec $@
