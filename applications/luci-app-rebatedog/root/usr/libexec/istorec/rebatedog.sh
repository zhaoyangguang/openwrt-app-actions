#!/bin/sh
# Author zhaoyangguang@gmail.com
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

IMAGE_NAME='default'

get_image() {
      IMAGE_NAME="zhaoyangguang/rebatedog:latest"
}

do_install() {
  get_image
  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f rebatedog

  do_install_detail
}

do_install_detail() {
  local hostnet=`uci get rebatedog.@rebatedog[0].hostnet 2>/dev/null`
  local config=`uci get rebatedog.@rebatedog[0].config_path 2>/dev/null`
  local port=`uci get rebatedog.@rebatedog[0].port 2>/dev/null`
  local dev

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi

  [ -z "$port" ] && port=15888

  local cmd="docker run --restart=unless-stopped -d -v \"$config:/app/data\" "

  if [ "$hostnet" = 1 ]; then
    cmd="$cmd\
    --dns=114.114.114.114 \
    --network=host "
  else
    cmd="$cmd\
    --dns=114.114.114.114 \
    -p $port:15888 "
  fi

  local tz="`uci get system.@system[0].zonename`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd --name rebatedog \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the rebatedog"
  echo "      upgrade                Upgrade the rebatedog"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the rebatedog"
  echo "      status                 Jellyfin status"
  echo "      port                   Jellyfin port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f rebatedog
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} rebatedog
  ;;
  "status")
    docker ps --all -f 'name=rebatedog' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=rebatedog' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*->15888/tcp' | sed 's/0.0.0.0:\([0-9]*\)->.*/\1/'
  ;;
  *)
    usage
    exit 1
  ;;
esac