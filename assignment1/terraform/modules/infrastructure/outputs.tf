output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Public subnet IDs by name."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "web_public_ip" {
  description = "Web server public IP."
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "Web server URL, accessible only on real AWS."
  value       = "http://${aws_instance.web.public_ip}/"
}

output "artifact_bucket" {
  description = "Optional artifact bucket name."
  value       = one(aws_s3_bucket.artifacts[*].bucket)
}

output "provider_target" {
  description = "Terraform provider destination."
  value       = local.provider_target
}
