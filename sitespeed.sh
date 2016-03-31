#docker run --privileged --rm -v $(pwd)/data:/sitespeed.io sitespeedio/sitespeed.io sitespeed.io -u http://dev.ontheroad.jp -b firefox -n 3 --connection cable --graphiteHost 172.17.2.98 --graphiteData summary,rules,pagemetrics,timings,timings
#docker run     \
#    --privileged \ # 権限を与える
#    --rm         \ # 実行したらコンテナを消す
#    -v $(pwd)/data:/sitespeed.io \ # ディレクトリを共有
#    sitespeedio/sitespeed.io \ # コンテナ名
#    sitespeed.io             \ # ここからはコマンド実行
#    -u http://dev.ontheroad.jp       \ # ターゲット URL
#    -b firefox               \ # ブラウザ
#    -n 3                     \ # 回数
#    --connection cable       \ # 回線エミュレート
#    --graphiteHost 160.16.229.167 \ # ここはホストを IP で指定 2003 ポートに送られる
#    --graphiteData summary,rules,pagemetrics,timings,timings \ # 全ての情報を graphite に送る


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
echo "sitespeed.io perforRef man ce tracking"
echo "==================================================="

docker run \
  --privileged \
  --rm \
  --link toybox_graphite_1:graphite \
  -v ${TOYBOX_HOME}/data/sitespeed.io:/sitespeed.io \
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
