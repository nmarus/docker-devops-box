#!/usr/bin/env bash

set -e

IMAGE=nmarus/devops-box:latest
DOCKER_HOSTNAME=devops
CONTAINER_USER=devops

if [[ -z ${CMD+x} ]]; then
  CMD="`basename \"$0\"`"
fi

# get host IP for x11 config
HOST_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

# get real path to this script
SCRIPT_PATH="$(dirname "$(readlink "$0")")"

# parse args (quote safe)
ARGS=''
for i in "$@"; do
  i="${i//\\/\\\\}"
  ARGS="$ARGS \"${i//\"/\\\"}\""
done

# default docker opts
DOCKER_OPTS="${DOCKER_OPTS} --hostname ${DOCKER_HOSTNAME}"
DOCKER_OPTS="${DOCKER_OPTS} --env DISPLAY=${HOST_IP}:0"
DOCKER_OPTS="${DOCKER_OPTS} --env HOST_USER=$(whoami)"
DOCKER_OPTS="${DOCKER_OPTS} --volume ${LOCAL_HOME}:${REMOTE_HOME}"
DOCKER_OPTS="${DOCKER_OPTS} --volume /var/run/docker.sock:/var/run/docker.sock"

# if opts are defined for cmd
if [[ -e ${SCRIPT_PATH}/opts/${CMD} ]]; then
  source ${SCRIPT_PATH}/opts/${CMD}
fi

set +e

# if run under hosts home user dir
if [[ "${PWD}" = "${HOME}"* ]]; then
  LOCAL_HOME="${HOME}"
  REMOTE_HOME="/home/$(basename ${HOME})"
  REMOTE_PWD="${REMOTE_HOME}$(echo $PWD | sed -e 's,^'"${HOME}"',,')"

  docker run -it --rm \
    ${DOCKER_OPTS} \
    --volume ${LOCAL_HOME}:${REMOTE_HOME} \
    ${IMAGE} sh -c "cd ${REMOTE_PWD} && ${CMD} ${ARGS}"
else # else is run from somewhere else in fs...
  LOCAL_HOME="/"
  REMOTE_HOME="/host"
  REMOTE_PWD="/host${PWD}"

  if [[ "$UNSAFE_WRITE_ROOT" = "true" ]]; then
    ROOT_VOL_MAP=${LOCAL_HOME}:${REMOTE_HOME}
  else
    ROOT_VOL_MAP=${LOCAL_HOME}:${REMOTE_HOME}:ro
  fi

  docker run -it --rm \
    ${DOCKER_OPTS} \
    --volume ${ROOT_VOL_MAP} \
    --volume ${PWD}:${REMOTE_PWD} \
    ${IMAGE} sh -c "cd ${REMOTE_PWD} && ${CMD} ${ARGS}"
fi

# if opts cleanup() is defined for cmd
if [[ -z ${cleanup+x} ]]; then
  $cleanup
fi
