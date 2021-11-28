#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SRC_PATH=`dirname $0 | xargs realpath`

# Install dependencies.
apt-get update
apt-get install -y python3.8-venv

# Install poetry.
export POETRY_HOME=/opt/poetry
mkdir -p $POETRY_HOME
python3 ${SRC_PATH}/install-poetry.py
