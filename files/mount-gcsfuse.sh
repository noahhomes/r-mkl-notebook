#!/bin/bash
set -e

GCS_BUCKET=${1:-my-data-science-workspace}

# need this for fusermount -u to work
if [ ! -f /etc/mtab ]; then
  sudo ln -sv /proc/self/mounts /etc/mtab
fi

sudo -u jovyan mkdir -p /home/jovyan/${GCS_BUCKET}
sudo -u jovyan gcsfuse --implicit-dirs ${GCS_BUCKET} /home/jovyan/${GCS_BUCKET}
