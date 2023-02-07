#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

USER=ubuntu
HOME_DIR=/home
USER_HOME_DIR=${HOME_DIR}/${USER}

if mount -o discard,defaults /dev/sdb "/${USER_HOME_DIR}" ; then
  echo "Successfully mounted existing data disk"
else
  if mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb ; then
    echo "Mounting and formatting new data disk"
    mount -o discard,defaults /dev/sdb ${USER_HOME_DIR}

    # Copy over contents of original home folder.
    echo "Copying over files from original home directory"
    mkdir -p /tmp/home-orig
    mount --bind ${HOME_DIR} /tmp/home-orig
    cp -rT /tmp/home-orig/${USER} ${USER_HOME_DIR}
    umount /tmp/home-orig

    echo "Successfully formatted and mounted new data disk"
  else
    echo "WARNING: failed to format data disk, please ignore if this is a single disk instance"
  fi
fi

chown -R ${USER}:${USER} ${USER_HOME_DIR}
rm -rf "${USER_HOME_DIR}/lost+found/"
