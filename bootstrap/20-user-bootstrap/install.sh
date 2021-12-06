#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SCRIPT_DIR=`dirname $0 | xargs realpath`

mkdir -p /opt/user-bootstrap
cp ${SCRIPT_DIR}/user-bootstrap/* /opt/user-bootstrap/

cp ${SCRIPT_DIR}/user-bootstrap.service /etc/systemd/system/user-bootstrap.service
systemctl enable user-bootstrap
