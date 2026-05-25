variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count > 0
    error_message = "instance_count must be greater than zero."
  }
}

variable "allowed_cidrs" {
  description = "List of allowed CIDR blocks for security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default = {
    Project   = "terraform-aws-portfolio"
    Owner     = "Luis Mena"
    ManagedBy = "Terraform"
  }
}

variable "instance_config" {
  description = "Configuration for EC2 instances"
  type = object({
    instance_type = string
    volume_size   = number
    public_ip     = bool
  })
  default = {
    instance_type = "t3.micro"
    volume_size   = 30
    public_ip     = false
  }
}

variable "secret_value" {
  description = "A sensitive value demonstrating sensitive = true masking"
  type        = string
  sensitive   = true
  default     = "change-me"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access (required for remote-exec provisioner)"
  type        = string
  default     = null
}
