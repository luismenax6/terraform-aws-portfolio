output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.this[*].id
}

output "instance_public_ips" {
  description = "Public IPs of the EC2 instances"
  value       = aws_instance.this[*].public_ip
}

output "instance_size_label" {
  description = "Human-readable size label derived from the instance type via lookup()"
  value       = local.instance_size_label
}

output "account_id" {
  description = "AWS account ID from the caller identity data source"
  value       = data.aws_caller_identity.current.account_id
}

output "secret_output" {
  description = "Sensitive value — masked in terminal, visible with terraform output -raw secret_output"
  value       = var.secret_value
  sensitive   = true
}
