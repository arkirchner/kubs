resource "libvirt_pool" "talos_cluster" {
  name = "talos-cluster"
  type = "dir"

  target = {
    path = "~/.talos_storage_pool"
  }
}

resource "libvirt_volume" "talos" {
  name = "${var.cluster_name}.qcow2"
  pool = libvirt_pool.talos_cluster.name

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = var.talos_image_url
    }
  }
}

resource "libvirt_network" "talos" {
  name      = "talos-network"
  autostart = true

  forward = {
    mode = "nat"
  }

  domain = {
    name       = "k8s.local"
    local_only = "yes"
  }

  ips = [
    {
      family  = "ipv4"
      address = "10.17.3.1"
      prefix  = 24

      dhcp = {
        ranges = [
          {
            start = "10.17.3.2"
            end   = "10.17.3.254"
          },
        ]
      }
    },
    {
      family  = "ipv6"
      address = "2001:db8:ca2:2::1"
      prefix  = 64

      dhcp = {
        ranges = [
          {
            start = "2001:db8:ca2:2::2"
            end   = "2001:db8:ca2:2::fffe"
          },
        ]
      }
    },
  ]

  dns = {
    enable = "yes"
  }
}

resource "libvirt_domain" "talos" {
  name        = var.cluster_name
  memory      = var.memory_mb
  memory_unit = "MiB"
  vcpu        = var.vcpu
  type        = "kvm"
  running     = true

  # The provider defaults to the "qemu64" CPU model (x86-64-v1), which Talos
  # rejects: it requires microarchitecture level 2 or higher.
  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type      = "hvm"
    type_arch = "x86_64"

    boot_devices = [
      {
        dev = "hd"
      },
    ]
  }

  devices = {
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }

        source = {
          volume = {
            volume = libvirt_volume.talos.name
            pool   = libvirt_pool.talos_cluster.name
          }
        }

        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }

        source = {
          network = {
            network = libvirt_network.talos.name
          }
        }

        wait_for_ip = {
          source  = "lease"
          timeout = 300
        }
      },
    ]

    serials = [
      {
        type = "pty"

        target = {
          type = "isa-serial"
          port = 0
        }
      },
    ]

    consoles = [
      {
        type = "pty"

        target = {
          type = "serial"
          port = 0
        }
      },
    ]

    graphics = [
      {
        spice = {
          listen = "none"
        }
      },
    ]
  }
}
