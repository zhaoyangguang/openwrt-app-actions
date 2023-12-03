#!/bin/sh

ACTION=${1}
shift 1

IMAGE_NAME='zhaoyangguang/rebatedog:latest'


do_install() {
  local http_port=`uci get rebatedog.@rebatedog[0].port 2>/dev/null`
  local path=`uci get rebatedog.@rebatedog[0].data_path 2>/dev/null`
  [ -z $http_port ] || http_port=15888

  get_image
  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f rebatedog

  local cmd="docker run --restart=unless-stopped -d \
    --dns=172.17.0.1 \
    --dns=114.114.114.114 \
	--network=host \
	-v \"$path:/app/data\" \
    -p ${http_port}:15888 \

  local tz="`uci get system.@system[0].zonename`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"
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
  echo "      status                 rebatedog status"
  echo "      port                   rebatedog port"
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
    docker ps --all -f 'name=rebatedog' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
