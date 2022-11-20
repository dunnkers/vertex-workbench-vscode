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
apt-get install -y python3.8-venv

# Install poetry.
export POETRY_HOME=${USER_HOME_DIR}/.poetry
mkdir -p ${POETRY_HOME}
python3 ${SCRIPT_DIR}/install-poetry.py --version 1.2.2
chown -R ${USER}:${USER} ${POETRY_HOME}

# Setup env.
cat << 'EOF' >> ${USER_HOME_DIR}/.bashrc
export PATH="${HOME}/.poetry/bin:$PATH"
EOF
runuser --user ubuntu ${POETRY_HOME}/bin/poetry config virtualenvs.in-project true
