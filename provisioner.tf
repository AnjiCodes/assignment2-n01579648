resource "null_resource" "ansible_provision" {
  depends_on = [module.linux_vms]

  provisioner "local-exec" {
    environment = {
      ANSIBLE_CONFIG = "/home/N01579648/automation/ansible/ansible.cfg"
    }
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/n01579648/automation/ansible/hosts /home/N01579648/automation/ansible/n01579648-playbook.yml --private-key=/home/n01579648/.ssh/id_rsa"
  }
}