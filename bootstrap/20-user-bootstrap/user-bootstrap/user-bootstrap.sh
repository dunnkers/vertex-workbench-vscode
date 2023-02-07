#!/usr/bin/env bash

# This script handles any specific user configuration that can't be done
# when the image has been built and therefore needs to be done at boot time.
#
# For example, here we copy + set up pyenv + poetry in the users home directory.
# This can't be done at build time because the users home directory may be mounted
# on the data disk, which isn't available at that time. Also, we can't keep
# poetry/pyenv on the boot disk, as that would mean that anything the user changes
# (e.g. updating poetry, installing a Python env) would be lost as soon as the
# boot disk is replaced due to an image update, VM replacement, etc.

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

USER=ubuntu
USER_HOME_DIR=/home/ubuntu

# Setup pyenv for the user.
if [ ! -d "${USER_HOME_DIR}/.pyenv" ]; then
    # Copy pyenv to the home dir so it can be managed by the user and
    # will not dissappear/downgrade on boot disk updates.
    cp -r /opt/pyenv ${USER_HOME_DIR}/.pyenv
    chown -R ${USER}:${USER} ${USER_HOME_DIR}/.pyenv

    # Setup bashrc to include pyenv inits.
    if ! grep -q ".pyenv" ${USER_HOME_DIR}/.bashrc; then
        cat << 'EOF' >> ${USER_HOME_DIR}/.bashrc
export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
EOF
    fi

    # Rehash and set global Python version to fix stuck Python issue.
    # TODO: Generate Python version from `pyenv versions`.
    su ${USER} -c "${USER_HOME_DIR}/.pyenv/bin/pyenv rehash"
    su ${USER} -c "${USER_HOME_DIR}/.pyenv/bin/pyenv global 3.9.14"
fi

# Setup poetry for the user.
if [ ! -d "${USER_HOME_DIR}/.poetry" ]; then
    # Also copy Poetry to the home dir.
    cp -r /opt/poetry ${USER_HOME_DIR}/.poetry
    chown -R ${USER}:${USER} ${USER_HOME_DIR}/.poetry

    # Add poetry to bashrc.
    if ! grep -q ".poetry/bin" ${USER_HOME_DIR}/.bashrc; then
        echo 'export PATH="${HOME}/.poetry/bin:$PATH"' >> ${USER_HOME_DIR}/.bashrc
        su ${USER} -c "${USER_HOME_DIR}/.poetry/bin/poetry config virtualenvs.in-project true"
    fi
fi

# Pre-create the openvscode-server extensions dir to avoid extension installation issues.
if [ ! -d "${USER_HOME_DIR}/.openvscode-server/extensions" ]; then
    mkdir -p ${USER_HOME_DIR}/.openvscode-server/extensions
    chown -R ${USER}:${USER} ${USER_HOME_DIR}/.openvscode-server
fi
