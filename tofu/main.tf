resource "libvirt_pool" "talos_cluster" {
  name = "talos-cluster"
  type = "dir"
  path = "~/.talos_storage_pool"
}

resource "libvirt_volume" "talos" {
  name   = "${var.cluster_name}.qcow2"
  pool   = libvirt_pool.talos_cluster.name
  source = var.talos_image_url
  format = "qcow2"
}

resource "libvirt_network" "talos" {
  name = "talos-network"
  mode = "nat"

  domain    = "k8s.local"
  addresses = ["10.17.3.0/24", "2001:db8:ca2:2::/64"]

  dns {
    enabled    = true
    local_only = true
  }

  dhcp {
    enabled = true
  }
}

resource "libvirt_domain" "talos" {
  name   = var.cluster_name
  memory = var.memory_mb
  vcpu   = var.vcpu

  # The provider defaults to the "qemu64" CPU model (x86-64-v1), which Talos
  # rejects: it requires microarchitecture level 2 or higher.
  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.talos.id
  }

  network_interface {
    network_name   = libvirt_network.talos.name
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "none"
  }
}
