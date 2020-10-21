# Devops Environment in Docker

The purpose of this project is to create a portable DevOps environment in
Docker that can be interacted with seamlessly from the CLI.

This is to avoid the need to setup pre-requisite libraries for python or the
need to perform other OS specific modifications to run these utilities.

This container maps the current directory that you are in when executed to
allow the utilities to run as it would locally.

The container is setup to run as a non-root user to enforce permissions and
security within the files mapped into the container.

## Requirements

The Docker CLI tools and a accessible Docker daemon must be installed on the
host that is running this script.

To validate:

```bash
docker info
```

## Docker Image Setup

To build container locally from source:

```bash
docker build --rm -t nmarus/devops-box:latest .
```

To pull container from Docker Hub: (not yet active)

```bash
docker pull nmarus/devops-box:latest
```

## Setting up CLI

To interact with this container as you would locally installed utilities, you must
copy or symlink the utility executable(s) into your path. These are scripts that
launch the docker container and map the host filesystem to the container.

The container environment is setup to be friendly to CLI interaction too. The
utility `devops-shell` will drop you into the CLI of the container.

Symlink Example:

```bash
# create optional symlinks from docker-devops-box repo to local path
BIN_DIR=/usr/local/bin
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/ansible
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/ansible-doc
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/ansible-inventory
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/ansible-playbook
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/consul
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/nomad
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/packer
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/terraform
ln -s $PWD/run-in-docker.sh ${BIN_DIR}/devops-shell
```

Note: Anything that is symlinked to the `run-in-docker.sh` script will attempt
to execute in the container based on the name of the symlink. This allows any
container executable to be mapped to the local host. For example if you wanted
to access the container `vim` command, you can link `vim` from somewhere in your
local path to the `run-in-docker.sh` script. If you rather use an alias, see
example run-my-bash script in the opts folder. These will get sourced if the
symlink name matches the script name and thus can override the CMD variable.

These shell scripts create a temporary container and when exiting automatically
removes the container.

Note: When running the utility shell scripts that spawn docker containers, host
directories are mapped into the container. This will happen in 1 of 2 ways
depending on where in the local file system you executing the script.

If within your home directory, the script will map your home directory to the
container path `/home` and place you in the current sub directory when entering
the container. This is to permit navigating to files and folders that may be at
a higher folder level from where the script is ran.

If you are not within your home directory, the script will make a read-only map
of your host root to the container path `/host`. It will also map a writeable
volume to the directory from which the script is ran. This is to permit
navigating to files and folders that may be at a higher folder level from where
the script is ran, but still provide a level of protection to your hosts files.

To remove this protection and map the root fs as writable, set the ENV
variable `UNSAFE_WRITE_ROOT=true` before executing the script

## License

The MIT License (MIT)

Copyright (c) 2020 <nmarus@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
