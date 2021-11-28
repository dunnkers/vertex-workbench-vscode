#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

SRC_PATH=`dirname $0 | xargs realpath`

# Delay a moment for apt to be ready
sleep 10

# Install software + services.
bash ${SRC_PATH}/00-docker/install.sh
bash ${SRC_PATH}/01-openvscode-server/install.sh
bash ${SRC_PATH}/02-rclone-mount/install.sh
bash ${SRC_PATH}/10-pyenv/install.sh
bash ${SRC_PATH}/11-poetry/install.sh
bash ${SRC_PATH}/20-vm-startup/install.sh
