variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "use_localstack" {
  description = "Use LocalStack instead of real AWS."
  type        = bool
  default     = false
}

variable "localstack_endpoint" {
  description = "LocalStack API endpoint."
  type        = string
  default     = "http://localhost:4566"
}

variable "project" {
  description = "Resource name prefix."
  type        = string
  default     = "acs730-lab5"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.project))
    error_message = "Project must be 3-24 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "owner" {
  description = "Seneca username used for resource tagging."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR block."
  type        = string
  default     = "10.42.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Enter a valid IPv4 CIDR."
  }
}

variable "public_subnets" {
  description = "Public subnets with stable keys."
  type = map(object({
    cidr_block = string
    az_index   = number
  }))
  default = {
    a = { cidr_block = "10.42.1.0/24", az_index = 0 }
    b = { cidr_block = "10.42.2.0/24", az_index = 1 }
  }
}

variable "ingress_rules" {
  description = "Rules for the web security group."
  type = list(object({
    description = string
    port        = number
    cidr_blocks = list(string)
  }))
  default = [
    { description = "HTTP from anywhere", port = 80, cidr_blocks = ["0.0.0.0/0"] }
  ]
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "Use t3.micro or t3.small."
  }
}

variable "localstack_ami_id" {
  description = "Placeholder AMI used only for LocalStack."
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "create_artifact_bucket" {
  description = "Create the optional S3 artifact bucket."
  type        = bool
  default     = false
}
