variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for the RDS subnet group"
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group ID allowed to connect to RDS (instances SG from compute module)"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
}
