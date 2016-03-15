#!/bin/sh

# -------------------------------------------------------
# build nutsp/Lychee
docker build -t nutsp/supervisord ./docker-supervisor
docker build -t nutsp/lychee ./docker-lychee
