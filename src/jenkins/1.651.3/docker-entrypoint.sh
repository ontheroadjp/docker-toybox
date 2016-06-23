#!/bin/bash

usermod -u ${TOYBOX_UID} jenkins
groupmod -g ${TOYBOX_GID} jenkins

exec "$@"
