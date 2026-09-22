build {
  name = "fbsd"
  sources = ["source.hcloud.fbsd"]

  provisioner "shell" {
    environment_vars = [
      "freebsd_url=${local.freebsd_url}"
    ]
    script           = "provisioners/flash-image.sh"
  }

  provisioner "shell" {
    script           = "provisioners/install-zfs.sh"
  }

  provisioner "shell" {
    expect_disconnect = true
    script            = "provisioners/mount-zfs.sh"
  }

  provisioner "shell" {
    pause_before        = "30s"
    start_retry_timeout = "5m"
    environment_vars    = ["ASSUME_ALWAYS_YES=yes"]
    script              = "provisioners/configure-freebsd.sh"
  }
}
