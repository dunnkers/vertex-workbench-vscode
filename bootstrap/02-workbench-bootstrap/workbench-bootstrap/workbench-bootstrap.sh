#!/usr/bin/env bash

# This script performs any setup needed for the VM to cleanly
# integrate with Vertex Workbench.
#
# Examples of tasks include
# - Registering the VM on the inverting proxy so that it can
#   be reached using the browser from the GCP console.
# - Mounting the data disk if provided.

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

SCRIPT_DIR=`dirname $0 | xargs realpath`

bash ${SCRIPT_DIR}/mount-data-disk.sh
python3 ${SCRIPT_DIR}/register-on-proxy.py
