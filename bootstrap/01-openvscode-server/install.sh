#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SRC_PATH=`dirname $0 | xargs realpath`

# Can't upgrade to newer versions until this issue has been addressed: https://github.com/microsoft/vscode/issues/136615.
OPENVSCODE_SERVER_VERSION=1.61.0

curl --retry 5 -fOL https://github.com/gitpod-io/openvscode-server/releases/download/openvscode-server-v${OPENVSCODE_SERVER_VERSION}/openvscode-server-v${OPENVSCODE_SERVER_VERSION}-linux-x64.tar.gz

mkdir -p /opt/openvscode-server
tar -xvf openvscode-server-v${OPENVSCODE_SERVER_VERSION}-linux-x64.tar.gz -C /opt/openvscode-server --strip-components=1
chown -R root:root /opt/openvscode-server

rm openvscode-server-v${OPENVSCODE_SERVER_VERSION}-linux-x64.tar.gz

cp ${SRC_PATH}/openvscode-server.service /etc/systemd/system/openvscode-server.service
systemctl enable openvscode-server
