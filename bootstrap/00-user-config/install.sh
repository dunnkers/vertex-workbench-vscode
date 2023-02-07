#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

USER=ubuntu
USER_HOME_DIR=/home/ubuntu

# Make sure bashrc is setup with the right permissions.
touch ${USER_HOME_DIR}/.bashrc
chown ${USER}:${USER} ${USER_HOME_DIR}/.bashrc

# Allow passwordless sudo.
echo "${USER} ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
