data "aws_vpc" "default" {
  default = true
}

# Customer-managed key used by the bucket and scratch volume.
resource "aws_kms_key" "artifacts" {
  description         = "ACS730 Lab 8 customer-managed key"
  enable_key_rotation = true
}

# Accepted risk: this bucket stores regenerable tfsec and gitleaks reports.
# Versioning would retain additional copies of reports that CI can rebuild.
# Reconsider this exception if the bucket stores unique or audit-critical data.
# Author: Stefano Lo Re. Date: 2026-11-21.
# tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "artifacts" {
  bucket = "acs730-lab8-${var.owner}-artifacts"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.artifacts.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ebs_volume" "scratch" {
  availability_zone = "${var.region}a"
  size              = 1
  encrypted         = true
  kms_key_id        = aws_kms_key.artifacts.arn

  tags = {
    Name = "acs730-lab8-scratch"
  }
}

resource "aws_security_group" "admin" {
  name        = "acs730-lab8-admin"
  description = "ACS730 Lab 8 administrative access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from one address only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "HTTPS inside the VPC only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
}
