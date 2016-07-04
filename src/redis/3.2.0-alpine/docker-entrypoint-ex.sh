#!/bin/sh

usermod -u ${TOYBOX_UID} redis
groupmod -g ${TOYBOX_GID} redis

exec /usr/local/bin/docker-entrypoint.sh redis-server

