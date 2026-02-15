output "talos_vm_name" {
  value = libvirt_domain.talos.name
}

output "talos_vm_addresses" {
  value = libvirt_domain.talos.network_interface[0].addresses
}
