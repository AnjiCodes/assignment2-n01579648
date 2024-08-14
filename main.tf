module "resource_group" {
  source    = "./modules/rgroup-n01579648"
  humber_id = var.humber_id
  location  = var.location
  tags      = var.tags
}

module "network" {
  source              = "./modules/network-n01579648"
  humber_id           = var.humber_id
  location            = var.location
  resource_group_name = module.resource_group.rg_name
  tags                = var.tags
}

module "common_services" {
  source              = "./modules/common_services-n01579648"
  humber_id           = var.humber_id
  location            = var.location
  resource_group_name = module.resource_group.rg_name
  tags                = var.tags
}

module "linux_vms" {
  source                     = "./modules/vmlinux-n01579648"
  humber_id                  = var.humber_id
  location                   = var.location
  resource_group_name        = module.resource_group.rg_name
  subnet_id                  = module.network.subnet_id
  storage_account_uri        = module.common_services.storage_account_uri
  admin_username             = var.admin_username
  public_key_path            = var.public_key_path
  private_key_path           = var.private_key_path
  tags                       = var.tags
  linux_vm_names             = var.linux_vm_names
  linux_vm_size              = var.linux_vm_size
  log_analytics_workspace_id = var.log_analytics_workspace_id
}

module "windows_vms" {
  source                     = "./modules/vmwindows-n01579648"
  humber_id                  = var.humber_id
  location                   = var.location
  resource_group_name        = module.resource_group.rg_name
  subnet_id                  = module.network.subnet_id
  storage_account_uri        = module.common_services.storage_account_uri
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  windows_vm_count           = var.windows_vm_count
  windows_vm_size            = var.windows_vm_size
  tags                       = var.tags
  log_analytics_workspace_id = var.log_analytics_workspace_id
}

module "data_disks" {
  source              = "./modules/datadisk-n01579648"
  humber_id           = var.humber_id
  location            = var.location
  resource_group_name = module.resource_group.rg_name
  linux_vm_ids        = module.linux_vms.linux_vm_ids
  windows_vm_ids      = module.windows_vms.windows_vm_ids
}

module "load_balancer" {
  source              = "./modules/loadbalancer-n01579648"
  humber_id           = var.humber_id
  location            = var.location
  resource_group_name = module.resource_group.rg_name
  tags                = var.tags
}

module "database" {
  source                  = "./modules/database-n01579648"
  humber_id               = var.humber_id
  location                = var.location
  resource_group_name     = module.resource_group.rg_name
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  tags                    = var.tags
  postgresql_version      = var.postgresql_version
  ssl_enforcement_enabled = var.ssl_enforcement_enabled
}

# Ansible provisioner to run playbook after the infrastructure is provisioned
resource "null_resource" "ansible_provisioner" {
  count = length(module.linux_vms.linux_vm_fqdns)

  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file(var.private_key_path)
    host        = element(module.linux_vms.linux_vm_fqdns, count.index)
  }
  

  provisioner "remote-exec" {
    inline = [
      "echo 'Provisioning with Ansible...' > /tmp/provisioner.log 2>&1",
      "sudo yum install -y python3 >> /tmp/provisioner.log 2>&1",
    ]
  }
   depends_on = [module.linux_vms]
}
#   provisioner "local-exec" {
#     command = <<EOT
#       ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vvvv \
#       -i ${element(module.linux_vms.linux_vm_fqdns, count.index)}, \
#       -u ${var.admin_username} \
#       --private-key ${var.private_key_path} \
#       /path/to/your/ansible/playbook/n01579648-playbook.yml
#     EOT
#   }

#   depends_on = [module.linux_vms]
# }
