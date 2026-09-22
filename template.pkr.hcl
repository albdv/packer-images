source "hcloud" "fbsd" {
  server_type   = var.server_type
  image         = var.image
  location      = var.location
  ssh_username  = "root"
  rescue        = "linux64"
  snapshot_name = "fbsd-zfs-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  snapshot_labels = {
    os      = "freebsd"
    version = var.version
  }
}
