#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SCRIPT_DIR=`dirname $0 | xargs realpath`

# Install OpenVSCode server
OPENVSCODE_SERVER_VERSION=1.90.0
curl -fOL https://github.com/gitpod-io/openvscode-server/releases/download/openvscode-server-v${OPENVSCODE_SERVER_VERSION}/openvscode-server-v${OPENVSCODE_SERVER_VERSION}-linux-x64.tar.gz && \
mkdir -p /opt/openvscode-server && \
tar -xvf openvscode-server-v${OPENVSCODE_SERVER_VERSION}-linux-x64.tar.gz -C /opt/openvscode-server --strip-components=1 && \
chown -R root:root /opt/openvscode-server && \
rm openvscode-server-v${OPENVSCODE_SERVER_VERSION}-linux-x64.tar.gz

# Install + enable service to start on boot.
cp ${SCRIPT_DIR}/openvscode-server.service /etc/systemd/system/openvscode-server.service
systemctl enable openvscode-server

# Install extensions.
runuser --user ubuntu -- /opt/openvscode-server/bin/openvscode-server --install-extension ms-python.python
runuser --user ubuntu -- /opt/openvscode-server/bin/openvscode-server --install-extension tamasfe.even-better-toml
runuser --user ubuntu -- /opt/openvscode-server/bin/openvscode-server --install-extension akamud.vscode-theme-onedark
