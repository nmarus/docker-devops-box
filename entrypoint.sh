#!/usr/bin/env bash

# fix docker socket permissions in container
sudo chown root:docker /var/run/docker.sock &> /dev/null
sudo chmod 775 /var/run/docker.sock &> /dev/null

# link files from host user home volume into container user home volume
HOME_FILES=$(ls -a1 /home/${HOST_USER})
for homepath in ${HOME_FILES}; do
  # dont link '.' and '..'
  if [ "${homepath}" != "." ] && [ "${homepath}" != ".." ]; then
    # dont link files that already exist in home directory of container
    if [[ ! -e /home/${CONTAINER_USER}/${homepath} ]]; then
      ln -s /home/${HOST_USER}/${homepath} /home/${CONTAINER_USER}/${homepath} &> /dev/null
    fi
  fi
done

exec "$@"
