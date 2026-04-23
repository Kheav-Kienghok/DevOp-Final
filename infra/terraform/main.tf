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
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────────
# Locals
# ─────────────────────────────────────────────
locals {
  ansible_server_playbook = "${path.module}/../ansible/playbooks/server.yml"
  image_full              = "${var.image_name}:${var.image_tag}"

  # Check if key pair exists
  key_exists = data.external.check_key.result.exists == "true"

  # True when we should create a new key pair
  create_key = !local.key_exists

  # Final key name passed to the compute module — whichever path was taken
  resolved_key_name = var.key_name
}

# ─────────────────────────────────────────────
# Check if key pair exists
# ─────────────────────────────────────────────
data "external" "check_key" {
  program = ["bash", "-c", "aws ec2 describe-key-pairs --key-names ${var.key_name} --region ${var.aws_region} >/dev/null 2>&1 && echo '{\"exists\": \"true\"}' || echo '{\"exists\": \"false\"}'"]
}

# ─────────────────────────────────────────────
# Path A — Create a new key pair
# ─────────────────────────────────────────────
resource "tls_private_key" "jenkins" {
  count     = local.create_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "jenkins_private_key" {
  count           = local.create_key ? 1 : 0
  content         = tls_private_key.jenkins[0].private_key_pem
  filename        = var.ssh_private_key_path
  file_permission = "0600"
}

resource "aws_key_pair" "jenkins" {
  count      = local.create_key ? 1 : 0
  key_name   = var.key_name
  public_key = tls_private_key.jenkins[0].public_key_openssh

  depends_on = [local_file.jenkins_private_key]
}

# ─────────────────────────────────────────────
# Path B — Reuse an existing key pair
# ─────────────────────────────────────────────
data "aws_key_pair" "existing" {
  count    = local.key_exists ? 1 : 0
  key_name = var.key_name
}

# ─────────────────────────────────────────────
# Compute module
# ─────────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  name_prefix   = var.name_prefix
  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = local.resolved_key_name
  my_ip_cidr    = var.my_ip_cidr
}

# ─────────────────────────────────────────────
# Ansible inventory file
# ─────────────────────────────────────────────
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    host             = module.compute.ec2_public_ip
    ssh_user         = var.ssh_user
    private_key_path = var.ssh_private_key_path
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

# ─────────────────────────────────────────────
# Wait for cloud-init before provisioning
# ─────────────────────────────────────────────
resource "null_resource" "wait_for_cloud_init" {
  count = var.provision_with_ansible ? 1 : 0

  triggers = {
    instance_id = module.compute.instance_id
  }

  connection {
    type        = "ssh"
    host        = module.compute.ec2_public_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
    ]
  }
}

# ─────────────────────────────────────────────
# Ansible provisioning
# ─────────────────────────────────────────────
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
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i ${local_file.ansible_inventory.filename} \
        ${local.ansible_server_playbook}
    EOT
  }
}