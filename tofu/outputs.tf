data "libvirt_domain_interface_addresses" "talos" {
  domain = libvirt_domain.talos.uuid
  source = "lease"
}

output "talos_vm_name" {
  value = libvirt_domain.talos.name
}

output "talos_vm_addresses" {
  value = flatten([
    for iface in data.libvirt_domain_interface_addresses.talos.interfaces : [
      for addr in iface.addrs : addr.addr
    ]
  ])
}
