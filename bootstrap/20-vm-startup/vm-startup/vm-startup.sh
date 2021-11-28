#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SRC_PATH=`dirname $0 | xargs realpath`

python3 ${SRC_PATH}/register-on-proxy.py
bash ${SRC_PATH}/mount-data-disk.sh
bash ${SRC_PATH}/finish-user-setup.sh
