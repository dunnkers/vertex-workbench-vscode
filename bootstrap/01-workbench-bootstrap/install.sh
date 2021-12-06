#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SCRIPT_DIR=`dirname $0 | xargs realpath`

apt-get update
apt-get install -y jq

mkdir -p /opt/workbench-bootstrap
cp ${SCRIPT_DIR}/workbench-bootstrap/* /opt/workbench-bootstrap/

cp ${SCRIPT_DIR}/workbench-bootstrap.service /etc/systemd/system/workbench-bootstrap.service
systemctl enable workbench-bootstrap
