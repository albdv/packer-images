#!/usr/bin/env bash
set -euo pipefail
echo "=== Flashing FreeBSD image ==="
echo "=== Currently available block devices ==="
lsblk -l
echo "=== Download, unarchive and writing FreeBSD image on /dev/sda ==="
wget -q -O- --timeout=5 --waitretry=5 --tries=5 --retry-connrefused \
  "${freebsd_url:?}" | xzcat | dd of=/dev/sda bs=4M status=progress
sync
sleep 5
echo "=== Image flashed ==="
