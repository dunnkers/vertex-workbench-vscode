#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

USER=ubuntu
USER_HOME_DIR=/home/ubuntu

SCRIPT_DIR=`dirname $0 | xargs realpath`

# Install dependencies.
apt-get update
apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev

# Install pyenv.
export PYENV_ROOT=${USER_HOME_DIR}/.pyenv
bash ${SCRIPT_DIR}/pyenv-installer.sh
chown -R ${USER}:${USER} ${PYENV_ROOT}

# Setup env.
cat << 'EOF' >> ${USER_HOME_DIR}/.bashrc
export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
EOF

# Install a base Python version.
${PYENV_ROOT}/bin/pyenv install 3.9.14
runuser --user ${USER} -- ${PYENV_ROOT}/bin/pyenv global 3.9.14
