variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "portfolio-app"
}

variable "container_port" {
  description = "Port the container listens on (used in the task definition)"
  type        = number
  default     = 80
}

variable "ingress_ports" {
  description = "List of ports to open in the ECS tasks security group"
  type        = list(number)
  default     = [80, 443]
}

variable "cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
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
