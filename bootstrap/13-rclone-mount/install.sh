#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SCRIPT_DIR=`dirname $0 | xargs realpath`

# Install rclone.
bash ${SCRIPT_DIR}/install-rclone.sh

# Copy rclone-mount scripts.
mkdir -p /opt/rclone-mount
cp ${SCRIPT_DIR}/rclone-mount.sh /opt/rclone-mount/

# Create rclone services.
cp ${SCRIPT_DIR}/rclone-mount.service /etc/systemd/system/
cp ${SCRIPT_DIR}/rclone-mount@.service /etc/systemd/system/
systemctl enable rclone-mount
