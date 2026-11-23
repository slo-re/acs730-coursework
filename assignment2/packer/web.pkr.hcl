packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1.1"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "acs730-a2-web"
}

variable "playbook_file" {
  type    = string
  default = "../ansible/site.yml"
}

locals {
  stamp = formatdate("YYYYMMDD-hhmmss", timestamp())
}

source "amazon-ebs" "web" {
  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = "ec2-user"
  ami_name      = "${var.ami_name_prefix}-${local.stamp}"

  temporary_security_group_source_public_ip = true

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-kernel-6.1-x86_64"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  tags = {
    Name    = "${var.ami_name_prefix}-${local.stamp}"
    Project = "acs730"
    Lab     = "assignment2"
    Role    = "web"
  }
}

build {
  name    = "golden-web"
  sources = ["source.amazon-ebs.web"]

  provisioner "ansible" {
    playbook_file = var.playbook_file
    user          = "ec2-user"
    use_proxy     = false

    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]

    extra_arguments = [
      "--scp-extra-args", "'-O'",
      "--extra-vars", "ansible_connection=ssh build_tag=golden-ami"
    ]
  }

  post-processor "manifest" {
    output = "packer-manifest.json"
  }
}
