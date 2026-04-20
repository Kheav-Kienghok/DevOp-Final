provider "aws" {
  region = var.aws_region
}

locals {
  instances = {
    jenkins = {
      name         = "Jenkins"
      hostname     = "jenkins"
      service_port = 8080
    }
    sonarqube = {
      name         = "SonarQube"
      hostname     = "sonarqube"
      service_port = 9000
    }
  }
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_security_group" "this" {
  for_each = local.instances

  name        = "${each.key}-sg"
  description = "Allow SSH and service access for ${each.value.name}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = each.value.name
    from_port   = each.value.service_port
    to_port     = each.value.service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${each.value.name}-sg"
  }
}

resource "aws_instance" "this" {
  for_each = local.instances

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.this[each.key].id]
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname = each.value.hostname
  })

  tags = {
    Name = each.value.name
  }
}

resource "local_file" "ansible_inventory" {
  count = var.provision_with_ansible ? 1 : 0

  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    jenkins_host   = aws_instance.this["jenkins"].public_ip
    sonarqube_host = aws_instance.this["sonarqube"].public_ip
    ssh_user       = var.ssh_user
  })

  filename = "${path.module}/ansible/inventory.ini"
}

resource "null_resource" "wait_for_cloud_init" {
  for_each = var.provision_with_ansible ? local.instances : {}

  triggers = {
    instance_id = aws_instance.this[each.key].id
  }

  connection {
    type        = "ssh"
    host        = aws_instance.this[each.key].public_ip
    user        = var.ssh_user
    private_key = file(var.private_key_path)
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
    null_resource.wait_for_cloud_init,
  ]

  triggers = {
    jenkins_instance_id   = aws_instance.this["jenkins"].id
    sonarqube_instance_id = aws_instance.this["sonarqube"].id
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key ${var.private_key_path} -i ${local_file.ansible_inventory[0].filename} ${path.module}/ansible/playbooks/server.yml"
  }
}