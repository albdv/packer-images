#!/usr/bin/env sh
set -eu
echo "=== Bootstrapping FreeBSD package manager ==="
pkg bootstrap -f
echo "=== Verifying pkg is operational ==="
pkg -N
echo "=== Installing cloud-init and curl ==="
pkg install net/cloud-init curl
echo "=== Verifying package installation ==="
pkg info -x cloud-init
pkg info -x curl
echo "=== Configuring system services (rc.conf) ==="
sysrc cloudinit_enable=YES
sysrc netwait_enable=YES
sysrc netwait_timeout="60"
sysrc netwait_ip="1.1.1.1"
echo "=== Verifying rc.conf values ==="
sysrc -c cloudinit_enable=YES
sysrc -c netwait_enable=YES
sysrc -c netwait_timeout="60"
sysrc -c netwait_ip="1.1.1.1"
echo "=== Cleaning up ==="
pkg clean -a -y
cloud-init clean --logs
rm -rf /var/lib/cloud/*
rm -f /var/log/cloud-init*.log
rm -rf /tmp/* /var/tmp/*
cat /dev/null >/var/log/messages
cat /dev/null >/var/log/auth.log
rm -f /etc/ssh/ssh_host_*
rm -rf /root/.ssh
rm -f /root/.history /root/.sh_history /root/.cshrc.history
echo "=== Cleanup completed successfully, image is ready for snapshot ==="
echo "=== Provisioning completed successfully! ==="
