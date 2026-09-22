# Packer — FreeBSD Cloud Images for Hetzner

Automated builder for FreeBSD cloud images deployed on **Hetzner Cloud** via [Packer](https://developer.hashicorp.com/packer).

## What it does

This project provisions a temporary Debian-based Hetzner server in **linux64 rescue mode**, flashes a FreeBSD raw disk image onto it, bootstraps ZFS, reboots into FreeBSD, and configures cloud-init. The result is a custom snapshot ready to launch FreeBSD instances with ZFS root and cloud-init support.

## Requirements

- [Packer ≥ 1.16.1](https://developer.hashicorp.com/packer/downloads) (managed via [mise](https://mise.jdx.dev/) — run `mise install` to set up)
- Hetzner Cloud API token with sufficient permissions
- `jq` (optional, for API interactions)

## Plugins

| Plugin   | Version | Source                           |
| -------- | ------- | -------------------------------- |
| `hcloud` | ≥ 1.7.0 | `github.com/hetznercloud/hcloud` |

## Quick Start

```sh
# Install tooling (Packer, etc.) via mise
mise install

# Authenticate with Hetzner Cloud (required environment variable)
export HCLOUD_TOKEN="your-api-token"

# Build the default image (FreeBSD 15.1)
packer init packer/
packer build packer/fbsd.pkr.hcl
```

## Configuration

All build parameters are exposed as Packer variables with sensible defaults:

| Variable      | Default     | Description                                                                                  |
| ------------- | ----------- | -------------------------------------------------------------------------------------------- |
| `version`     | `15.1`      | FreeBSD release version                                                                      |
| `server_type` | `cpx12`     | Hetzner server type for the build server                                                     |
| `image`       | `debian-13` | Base image for the Hetzner build server                                                      |
| `location`    | `nbg1`      | Hetzner datacenter location (`nbg1` = Nuremberg, `fsn1` = Falkenstein, `hel1` = Helsinki, …) |

Example — build FreeBSD 15.0 in Falkenstein:

```sh
packer build \
  -var 'version=15.0' \
  -var 'location=fsn1' \
  packer/fbsd.pkr.hcl
```

## Build Process

The build runs through four provisioning stages:

1. **Flash FreeBSD image** — downloads the official FreeBSD VM image from `download.freebsd.org` and writes it to `/dev/sda` via `dd`.
2. **Install ZFS on rescue** — installs OpenZFS on the Debian rescue system, loads the kernel module, and refreshes the partition table.
3. **Import pool & configure** — imports the FreeBSD ZFS pool (`zroot`), mounts it under `/mnt`, injects the SSH public key, hardens `sshd_config`, enables `sshd` in `rc.conf`, exports the pool, and reboots into FreeBSD.
4. **Post-boot provisioning** — after the reboot (`expect_disconnect = true`), bootstraps the FreeBSD `pkg` package manager, installs `cloud-init` and `curl`, and enables `cloudinit` and `netwait` services via `rc.conf`.

## Snapshot Naming

Snapshots follow the pattern:

```
fbsd{version}-zfs-{YYYYMMDD-hhmm}
```

Labels attached to the snapshot:

| Label     | Value                    |
| --------- | ------------------------ |
| `os`      | `freebsd`                |
| `version` | the FreeBSD version used |

## Project Structure

```
packer/
├── fbsd.pkr.hcl    # Packer HCL template
└── mise.toml       # mise tool versions
```

## License

See the upstream [Packer](https://developer.hashicorp.com/packer) and [FreeBSD](https://www.freebsd.org/) licensing terms.
