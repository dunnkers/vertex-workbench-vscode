#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SRC_PATH=`dirname $0 | xargs realpath`

apt-get update
apt-get install -y jq

mkdir -p /opt/vm-startup
cp ${SRC_PATH}/vm-startup/* /opt/vm-startup/

cp ${SRC_PATH}/vm-startup.service /etc/systemd/system/vm-startup.service
systemctl enable vm-startup
