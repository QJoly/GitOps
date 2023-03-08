﻿
resource "libvirt_pool" "cluster" {
  name = var.hypervisor_libvirt_pool_name
  type = "dir"
  path = var.hypervisor_libvirt_pool_dir
}

module "node" {
  count             = 3
  source            = "./modules/libvirt-qemu"
  node_name         = "kube-${count.index}-tf"
  node_memory       = var.provisionning_debian_memory
  node_vcpu         = var.provisionning_debian_cpu
  source_file       = var.source_file
  pool_name         = var.hypervisor_libvirt_pool_name
  depends_on = [
    libvirt_pool.cluster
  ]
}


resource "local_file" "inventory" {
  filename = "./inventory.ini"
  content = <<_EOF
[master]
${module.node[0].node_name} ansible_host=${module.node[0].node_ip}
%{if length(module.node) > 1}
[node]
%{for item in slice(module.node.*, 1, length(module.node))~}
${item.node_name} ansible_host=${item.node_ip}
%{endfor}
%{endif}
_EOF

  depends_on = [module.node]
}