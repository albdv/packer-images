#!/usr/bin/env bash
set -euo pipefail
echo "=== Finding disks in the pool, do not mount but alternate root ==="
zpool import -N -R /mnt zroot
echo "=== Check zpool status ==="
zpool status zroot
echo "=== ZFS Mount zroot ==="
zfs mount zroot/ROOT/default
echo "=== List ZFS mounts ==="
zfs mount
echo "=== Make .ssh directory ==="
mkdir -p /mnt/root/.ssh
echo "=== Writing authorized_keys to bsd root ==="
cat /root/.ssh/authorized_keys >>/mnt/root/.ssh/authorized_keys
chmod 700 /mnt/root/.ssh
chmod 600 /mnt/root/.ssh/authorized_keys
sed -i "s/.*PermitRootLogin.*/PermitRootLogin prohibit-password/" /mnt/etc/ssh/sshd_config
echo "=== Enabling SSH daemon in rc.conf ==="
echo "sshd_enable=\"YES\"" >>/mnt/etc/rc.conf
echo "=== Exporting zfs pool ==="
zpool export zroot
echo "=== Check if no pool left ==="
zpool status
echo "=== Disconnect session from console and reboot ==="
nohup sh -c "sleep 3 && reboot" >/dev/null 2>&1 &
