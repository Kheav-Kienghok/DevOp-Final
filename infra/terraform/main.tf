terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  private_key_dir         = "${path.module}/../secret/.ssh"
  private_key_path        = "${local.private_key_dir}/${var.key_name}.pem"
  ansible_server_playbook = "${path.module}/../ansible/playbooks/server.yml"
  ansible_deploy_playbook = "${path.module}/../ansible/playbooks/deploy.yml"
  image_full              = "${var.image_name}:${var.image_tag}"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "prepare_ssh_key_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.private_key_dir}"
  }
}

resource "local_sensitive_file" "ssh_private_key" {
  depends_on = [null_resource.prepare_ssh_key_dir]

  content         = tls_private_key.ssh.private_key_pem
  filename        = local.private_key_path
  file_permission = "0600"
}

resource "aws_key_pair" "generated" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh.public_key_openssh
}

module "compute" {
  source = "./modules/compute"

  name_prefix   = var.name_prefix
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated.key_name
  my_ip_cidr    = var.my_ip_cidr
}

resource "local_file" "ansible_inventory" {
  depends_on = [local_sensitive_file.ssh_private_key]

  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    host             = module.compute.ec2_public_ip
    ssh_user         = var.ssh_user
    private_key_path = local.private_key_path
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

resource "null_resource" "wait_for_cloud_init" {
  count = var.provision_with_ansible ? 1 : 0

  triggers = {
    instance_id = module.compute.instance_id
  }

  connection {
    type        = "ssh"
    host        = module.compute.ec2_public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
    ]
  }
}

resource "null_resource" "ansible_provision" {
  count = var.provision_with_ansible ? 1 : 0

  depends_on = [
    local_file.ansible_inventory,
    null_resource.wait_for_cloud_init[0],
  ]

  triggers = {
    instance_id = module.compute.instance_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${local_file.ansible_inventory.filename} ${local.ansible_server_playbook}
    EOT
  }
}

resource "null_resource" "ansible_deploy" {
  count = var.provision_with_ansible ? 1 : 0

  depends_on = [
    null_resource.ansible_provision,
  ]

  triggers = {
    instance_id = module.compute.instance_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${local_file.ansible_inventory.filename} ${local.ansible_deploy_playbook} --extra-vars "image_name=${var.image_name} image_full=${local.image_full}"
    EOT
  }
}
