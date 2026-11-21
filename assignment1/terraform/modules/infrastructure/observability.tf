# The SecureString is created outside Terraform.
# Terraform only reads it; it never creates the secret.
data "aws_ssm_parameter" "app_secret" {
  name = "/acs730/assignment1/${var.environment}/app-secret"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name}-cpu-high"
  alarm_description   = "High EC2 CPU utilization in ${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name = "${local.name}-cpu-high"
  })
}

output "app_secret_parameter_name" {
  description = "Name of the application secret read from SSM."
  value       = data.aws_ssm_parameter.app_secret.name
}

output "app_secret_parameter_version" {
  description = "Version read from SSM, not the secret value."
  value       = data.aws_ssm_parameter.app_secret.version
}

output "cpu_alarm_name" {
  description = "CloudWatch CPU utilization alarm."
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}
