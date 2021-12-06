#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

USER=ubuntu
USER_HOME=/home/ubuntu

if mount -o discard,defaults /dev/sdb "/${USER_HOME}" ; then
  echo "Successfully mounted existing data disk"
else
  if mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb ; then
    mount -o discard,defaults /dev/sdb "/${USER_HOME}"
    cp /etc/skel/.bashrc $USER_HOME/.bashrc
    chown $USER:$USER $USER_HOME/.bashrc
    echo "Successfully formatted and mounted new data disk"
  else
    echo "WARNING: failed to format data disk, please ignore if this is a single disk instance"
  fi
fi

chown ${USER}:${USER} ${USER_HOME}
rm -rf "${USER_HOME}/lost+found/"
