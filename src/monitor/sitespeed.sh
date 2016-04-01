#!/bin/bash

YOU=`whoami`
HELP=
BROWSER="firefox"
IMAGE="sitespeed.io"

while getopts d: OPT; do
    case $OPT in
        d) BROWSER=$OPTARG
           ;;
    esac
done

usage_exit() {
    echo "Measurement URL must be supplied!"
    echo "Usage: "
    echo "    ./sitespeedio.sh [-b browser] [URL]"
    exit 1
}

if [ "$1" = "" ];then
    usage_exit
fi

if [ ! "$BROWSER" = "chrome" -a ! "$BROWSER" = "firefox" ]; then
    echo "[ERROR] Invalid target browser."
    usage_exit
fi

if [ "$BROWSER" = "chrome" ]; then
    IMAGE="sitespeed.io-chrome"
fi

echo "==================================================="
echo "sitespeed.io performance tracking"
echo "==================================================="

selfpath=$(cd $(dirname $0);pwd)

docker run \
    --privileged \
    --rm \
    --link toybox_graphite_1:graphite \
    -v ${selfpath}/../data/sitespeed.io:/sitespeed.io \
    sitespeedio/${IMAGE} \
    ${IMAGE} \
    -u $1 \
    -b ${BROWSER} \
    -n 5 \
    -d 0 \
    -r /tmp \
    --graphiteHost graphite \
    --graphiteNamespace sitespeed.io \
    --graphiteDate summary,rules,pagemetrics,timings \
