#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

set +o errexit
RCLONE_BUCKETS=$(curl --fail "http://metadata.google.internal/computeMetadata/v1/instance/attributes/rclone-mount-buckets" -H "Metadata-Flavor: Google")
RCLONE_BUCKETS_SET=$?
set -o errexit

if [ $RCLONE_BUCKETS_SET -eq 0 ]; then
    IFS=';' read -ra BUCKETS <<< "$RCLONE_BUCKETS"
    for BUCKET in "${BUCKETS[@]}"; do
        echo $BUCKET
        sudo mkdir -p /gcs/${BUCKET}
        sudo chown ubuntu:ubuntu /gcs/${BUCKET}
        sudo systemctl start rclone-mount@${BUCKET}
    done
fi
