locals {
  node_ips = merge(
    { for index, ip in var.controlplane_ips : "cp-${index}" => ip },
    { for index, ip in var.worker_ips : "worker-${index}" => ip },
  )
  # The network needs each MAC before libvirt can boot a guest with a reserved lease.
  node_macs = {
    for node in keys(local.node_ips) :
    node => "02:${join(":", regexall("..", substr(sha256("${var.cluster_name}-${node}"), 0, 10)))}"
  }

  talos_image_url = "https://factory.talos.dev/image/${module.cluster.schematic_id}/${var.talos_version}/metal-amd64.raw.zst"
  talos_image_dir = abspath("${path.module}/.talos_image")
  talos_image_raw = "${local.talos_image_dir}/metal-amd64.raw"
}

resource "terraform_data" "talos_image" {
  triggers_replace = [var.talos_version, module.cluster.schematic_id]

  provisioner "local-exec" {
    command = <<-EOT
      set -eu
      mkdir -p "${local.talos_image_dir}"
      curl --fail --location --retry 2 --connect-timeout 15 --max-time 300 \
        --output "${local.talos_image_raw}.zst" "${local.talos_image_url}"
      zstd -d -f "${local.talos_image_raw}.zst" -o "${local.talos_image_raw}"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf -- \"${path.module}/.talos_image\""
  }
}

resource "libvirt_pool" "talos" {
  name = "${var.cluster_name}-pool"
  type = "dir"

  target = {
    path = abspath("${path.module}/.libvirt-pool")
  }
}

resource "libvirt_network" "talos" {
  name      = "${var.cluster_name}-network"
  autostart = true

  forward = {
    mode = "nat"
  }

  domain = {
    name = "${var.cluster_name}.local"
  }

  ips = [{
    family  = "ipv4"
    address = cidrhost(var.libvirt_network_cidr, 1)
    prefix  = tonumber(split("/", var.libvirt_network_cidr)[1])
    dhcp = {
      hosts = [
        for node, ip in local.node_ips : {
          ip   = ip
          mac  = local.node_macs[node]
          name = "${var.cluster_name}-${node}"
        }
      ]
    }
  }]
}

resource "libvirt_volume" "talos_base" {
  name = "${var.cluster_name}-talos-base"
  pool = libvirt_pool.talos.name

  target = {
    format = { type = "raw" }
  }

  create = {
    content = { url = local.talos_image_raw }
  }

  depends_on = [terraform_data.talos_image]
}

resource "libvirt_volume" "node" {
  for_each = local.node_ips
  name     = "${var.cluster_name}-${each.key}.qcow2"
  pool     = libvirt_pool.talos.name
  capacity = 30 * 1024 * 1024 * 1024

  target = {
    format = { type = "qcow2" }
  }

  backing_store = {
    path   = libvirt_volume.talos_base.path
    format = { type = "raw" }
  }
}

resource "libvirt_domain" "node" {
  for_each    = local.node_ips
  name        = "${var.cluster_name}-${each.key}"
  type        = "kvm"
  running     = true
  autostart   = true
  memory      = 2048
  memory_unit = "MiB"
  vcpu        = 2

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    boot_devices = [{ dev = "hd" }]
  }

  devices = {
    disks = [{
      driver = { name = "qemu", type = "qcow2" }
      source = {
        volume = {
          volume = libvirt_volume.node[each.key].name
          pool   = libvirt_pool.talos.name
        }
      }
      target = { dev = "vda", bus = "virtio" }
    }]

    interfaces = [{
      mac   = { address = local.node_macs[each.key] }
      model = { type = "virtio" }
      source = {
        network = { network = libvirt_network.talos.name }
      }
      wait_for_ip = { source = "lease", timeout = 300 }
    }]

    serials = [{
      type   = "pty"
      target = { type = "isa-serial", port = 0 }
    }]

    consoles = [{
      type   = "pty"
      target = { type = "serial", port = 0 }
    }]

    graphics = [{
      vnc = {
        auto_port = true
        listen    = "127.0.0.1"
      }
    }]
  }
}
