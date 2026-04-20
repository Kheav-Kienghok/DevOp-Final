variable "aws_region" {
  description = "AWS region for the EC2 instances"
  type        = string
  default     = "ap-southeast-1"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format, used for SSH access"
  type        = string
}

variable "ssh_user" {
  description = "SSH user for the Ubuntu AMI"
  type        = string
  default     = "ubuntu"
}

variable "private_key_path" {
  description = "Path to the SSH private key that matches key_name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for both servers"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root volume size in GiB"
  type        = number
  default     = 30
}

variable "provision_with_ansible" {
  description = "Run Ansible after the instances are created"
  type        = bool
  default     = true
}