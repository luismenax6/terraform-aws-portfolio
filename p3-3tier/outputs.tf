output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the ALB — use this to access the application"
  value       = module.compute.alb_dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.asg_name
}

output "db_endpoint" {
  description = "RDS connection endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_name" {
  description = "Name of the database"
  value       = module.database.db_name
}
