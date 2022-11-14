#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SCRIPT_DIR=`dirname $0 | xargs realpath`

# Install dependencies.
apt-get update
apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev

# Install pyenv.
export PYENV_ROOT=/opt/pyenv
bash ${SCRIPT_DIR}/pyenv-installer.sh

# Install a base Python version.
${PYENV_ROOT}/bin/pyenv install 3.9.14
