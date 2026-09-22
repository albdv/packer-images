packer {
  required_plugins {
    hcloud = {
      version = ">= 1.7.0"
      source  = "github.com/hetznercloud/hcloud"
    }
  }
}

variable "version" {
  type    = string
  default = "15.1"
}

variable "server_type" {
  type    = string
  default = "cpx12"
}

variable "image" {
  type    = string
  default = "debian-13"
}

variable "location" {
  type    = string
  default = "nbg1"
}

// hcloud source block defines the builder configuration
source "hcloud" "fbsd" {
  server_type   = var.server_type
  image         = var.image
  location      = var.location
  ssh_username  = "root"
  rescue        = "linux64"
  snapshot_name = "fbsd${var.version}-zfs-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  snapshot_labels = {
    os      = "freebsd",
    version = var.version,
  }
}

// build block for image
build {
  name = "fbsd"
  sources = [
    "source.hcloud.fbsd"
  ]

  provisioner "shell" {
    inline = [
      "set -eu",
      "echo '=== Starting disk image deploying ==='",
      "echo '=== Currently available block devices ==='",
      "lsblk -l",
      "echo '=== Download, unarchive and writing FreeBSD image on /dev/sda ==='",
      "wget -q -O- --timeout=5 --waitretry=5 --tries=5 --retry-connrefused https://download.freebsd.org/releases/VM-IMAGES/${var.version}-RELEASE/amd64/Latest/FreeBSD-${var.version}-RELEASE-amd64-zfs.raw.xz | xzcat | dd of=/dev/sda bs=4M status=progress",
      "echo '=== Sync buffers to disk ==='",
      "sync",
      "sleep 5",
      "echo '=== Image deploying done ==='"
    ]
  }
  provisioner "shell" {
    inline = [
      "set -eu",
      "echo '=== Install ZFS on Debian ==='",
      "yes | bash /root/.oldroot/nfs/tools/install_openzfs.sh",
      "echo '=== ZFS Kernel Module Load ==='",
      "modprobe zfs",
      "echo '=== Force Kernel to update on partition table changes ==='",
      "partprobe -s",
      "echo '=== List Block devices available ==='",
      "lsblk -l",
    ]
  }
  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "set -eu",
      "echo '=== Finding disks in the pool, do not mount but alternate root ==='",
      "zpool import -N -R /mnt zroot",
      "echo '=== Check zpool status ==='",
      "zpool status zroot",
      "echo '=== ZFS Mount zroot ==='",
      "zfs mount zroot/ROOT/default",
      "echo '=== List ZFS mounts ==='",
      "zfs mount",
      "echo '=== Make .ssh directory ==='",
      "mkdir -p /mnt/root/.ssh",
      "echo '=== Writing authorized_keys to bsd root ==='",
      "cat /root/.ssh/authorized_keys >> /mnt/root/.ssh/authorized_keys",
      "chmod 700 /mnt/root/.ssh",
      "chmod 600 /mnt/root/.ssh/authorized_keys",
      "sed -i 's/.*PermitRootLogin.*/PermitRootLogin prohibit-password/' /mnt/etc/ssh/sshd_config",
      "echo '=== Enabling SSH daemon in rc.conf ==='",
      "echo 'sshd_enable=\"YES\"' >> /mnt/etc/rc.conf",
      "echo '=== Exporting zfs pool ==='",
      "zpool export zroot",
      "echo '=== Check if no pool left ==='",
      "zpool status",
      "echo '=== Disconnect session from console and reboot ==='",
      "nohup sh -c 'sleep 3 && reboot' > /dev/null 2>&1 &"
    ]
  }
  provisioner "shell" {
    pause_before        = "30s"
    start_retry_timeout = "5m"
    environment_vars = [
      "ASSUME_ALWAYS_YES=yes"
    ]
    inline = [
      "set -eu",
      "echo '=== Bootstrapping FreeBSD package manager ==='",
      "pkg bootstrap -f",
      "echo '=== Verifying pkg is operational ==='",
      "pkg -N",
      "echo '=== Installing cloud-init and curl ==='",
      "pkg install -y net/cloud-init curl",
      "echo '=== Verifying package installation ==='",
      "pkg info -x cloud-init",
      "pkg info -x curl",
      "echo '=== Configuring system services (rc.conf) ==='",
      "sysrc cloudinit_enable=YES",
      "sysrc netwait_enable=YES",
      "sysrc netwait_timeout='60'",
      "sysrc netwait_ip='1.1.1.1'",
      "echo '=== Verifying rc.conf values ==='",
      "sysrc -c cloudinit_enable=YES",
      "sysrc -c netwait_enable=YES",
      "sysrc -c netwait_timeout='60'",
      "sysrc -c netwait_ip='1.1.1.1'",
      "echo '=== Provisioning completed successfully! ==='"
    ]
  }
}
