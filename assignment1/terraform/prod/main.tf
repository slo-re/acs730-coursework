
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  backend "s3" {
    key     = "assignment1/prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Course      = "ACS730"
      Assignment  = "assignment1"
      Environment = "prod"
      Owner       = "slo-re"
    }
  }
}

module "site" {
  source = "../modules/infrastructure"

  project                = "acs730-a1"
  owner                  = "slo-re"
  environment            = "prod"
  aws_region             = "us-east-1"
  use_localstack         = false
  instance_type          = "t3.micro"
  vpc_cidr               = "10.53.0.0/16"
  create_artifact_bucket = false

  public_subnets = {
    a = { cidr_block = "10.53.1.0/24", az_index = 0 }
    b = { cidr_block = "10.53.2.0/24", az_index = 1 }
  }

  ingress_rules = [
    {
      description = "HTTP only"
      port        = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

output "vpc_id" {
  value = module.site.vpc_id
}

output "web_public_ip" {
  value = module.site.web_public_ip
}

output "web_url" {
  value = module.site.web_url
}

output "cpu_alarm_name" {
  value = module.site.cpu_alarm_name
}

output "ssm_parameter_name" {
  value = module.site.app_secret_parameter_name
}

output "ssm_parameter_version" {
  value = module.site.app_secret_parameter_version
}
