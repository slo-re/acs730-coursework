terraform {
  backend "s3" {
    key     = "lab6/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_count" {
  description = "Number of web servers"
  type        = number
  default     = 2
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "web" {
  name        = "acs730-lab6-sg"
  description = "Lab 6 web servers, HTTP only"

  # No inbound SSH. Ansible connects through SSM.
  ingress {
    from_port   = 80
    to_port     = 80
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
    Name    = "acs730-lab6-sg"
    Project = "acs730"
    Lab     = "lab6"
  }
}

resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = "LabInstanceProfile"

  # Ensure fresh AL2023 instances work with Ansible over SSM.
  user_data = <<-USERDATA
    #!/bin/bash
    grep -Fxq 'set enable-bracketed-paste off' /etc/inputrc || echo 'set enable-bracketed-paste off' >> /etc/inputrc
  USERDATA

  # Preserve already-running instances when adding this setting.
  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name    = "acs730-lab6-web-${count.index}"
    Project = "acs730"
    Lab     = "lab6"
    Role    = "web"
  }
}

output "web_public_ips" {
  value = aws_instance.web[*].public_ip
}

output "first_web_public_ip" {
  value = aws_instance.web[0].public_ip
}

output "web_instance_ids" {
  value = aws_instance.web[*].id
}

output "security_group_id" {
  value = aws_security_group.web.id
}
