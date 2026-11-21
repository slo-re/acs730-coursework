data "aws_vpc" "default" {
  default = true
}

# Customer-managed key used by the bucket and scratch volume.
resource "aws_kms_key" "artifacts" {
  description         = "ACS730 Lab 8 customer-managed key"
  enable_key_rotation = true
}

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
  encrypted         = false

  tags = {
    Name = "acs730-lab8-scratch"
  }
}

resource "aws_security_group" "admin" {
  name        = "acs730-lab8-admin"
  description = "ACS730 Lab 8 administrative access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH, temporarily open so the TA can get in"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS inside the VPC only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
}
