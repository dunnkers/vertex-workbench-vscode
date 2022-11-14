#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SCRIPT_DIR=`dirname $0 | xargs realpath`

# Install dependencies.
apt-get update
apt-get install -y python3.8-venv

# Install poetry.
export POETRY_HOME=/opt/poetry
mkdir -p $POETRY_HOME
python3 ${SCRIPT_DIR}/install-poetry.py --version 1.2.2
