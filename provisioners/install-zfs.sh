#!/usr/bin/env bash
set -euo pipefail
echo "=== Install ZFS on Debian ==="
yes | bash /root/.oldroot/nfs/tools/install_openzfs.sh
echo "=== ZFS Kernel Module Load ==="
modprobe zfs
echo "=== Force Kernel to update on partition table changes ==="
partprobe -s
echo "=== List Block devices available ==="
lsblk -l
