#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SRC_PATH=`dirname $0 | xargs realpath`

# Install rclone.
bash ${SRC_PATH}/install-rclone.sh

# Copy rclone-mount scripts.
mkdir -p /opt/rclone-mount
cp ${SRC_PATH}/rclone-mount.sh /opt/rclone-mount/

# Create rclone services.
cp ${SRC_PATH}/rclone-mount.service /etc/systemd/system/
cp ${SRC_PATH}/rclone-mount@.service /etc/systemd/system/
systemctl enable rclone-mount
