#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_DIR=$(dirname "$0" | xargs realpath)

# Delay a moment for apt to be ready
sleep 10

# Install critical components.
bash "${SCRIPT_DIR}/00-user-config/install.sh"
bash "${SCRIPT_DIR}/01-docker/install.sh"
bash "${SCRIPT_DIR}/02-workbench-bootstrap/install.sh"

# Install customizations.
bash "${SCRIPT_DIR}/10-openvscode-server/install.sh"
bash "${SCRIPT_DIR}/11-pyenv/install.sh"
bash "${SCRIPT_DIR}/12-poetry/install.sh"
# bash "${SCRIPT_DIR}/13-rclone-mount/install.sh"
bash "${SCRIPT_DIR}/14-github-cli/install.sh"

# Setup post-processing for configuring the user at boot.
# bash "${SCRIPT_DIR}/20-user-bootstrap/install.sh"
