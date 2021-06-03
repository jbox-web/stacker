#!/usr/bin/env bash

CONTAINER_NAME="stacker"
CONTAINER_IMAGE="nicoladmin/stacker:nightly"
CONTAINER_PORT="127.0.0.1:3000:3000"
CONTAINER_VOLUME="$(pwd)/example:/home/nonroot"
CONTAINER_ARGS="--config stacker-docker.yml"

function running() {
  running=$(docker ps -a -f status=running --format='{{.Names}}' | grep ${CONTAINER_NAME})
  echo ${running}
}

function stopped() {
  stopped=$(docker ps -a -f status=exited --format='{{.Names}}' | grep ${CONTAINER_NAME})
  echo ${stopped}
}

function docker_create() {
  docker run \
        --detach \
        --name ${CONTAINER_NAME} \
        --publish ${CONTAINER_PORT} \
        --volume ${CONTAINER_VOLUME} \
        ${CONTAINER_IMAGE} \
        server \
        ${CONTAINER_ARGS}
}

function docker_run() {
  local args="$@"
  docker run \
        --rm \
        --volume ${CONTAINER_VOLUME} \
        ${CONTAINER_IMAGE} \
        fetch \
        ${CONTAINER_ARGS} \
        ${args}
}

function docker_start() {
  docker start ${CONTAINER_NAME}
}

function docker_stop() {
  docker stop ${CONTAINER_NAME}
}

function docker_top() {
  docker top ${CONTAINER_NAME}
}

function docker_kill() {
  docker kill ${CONTAINER_NAME}
}

function docker_rm() {
  docker rm ${CONTAINER_NAME}
}

function docker_logs() {
  docker logs -f ${CONTAINER_NAME}
}

case "$1" in
  start)
    stopped=$(stopped)
    if [[ "${stopped}" = "${CONTAINER_NAME}" ]]; then
      docker_start
    else
      running=$(running)
      if [[ "${running}" = "${CONTAINER_NAME}" ]]; then
        echo "Already running"
      else
        docker_create
      fi
    fi
  ;;

  stop)
    docker_stop
  ;;

  restart)
    docker_stop
    docker_start
  ;;

  status)
    docker_top
  ;;

  kill)
    docker_kill
  ;;

  clean)
    docker_rm
  ;;

  fetch)
    shift
    docker_run "$@"
  ;;

  logs)
    docker_logs
  ;;

  *)
    echo "Usage: stacker.sh {start|stop|restart|status|kill|clean|fetch|logs}" >&2
    exit 3
  ;;
esac
