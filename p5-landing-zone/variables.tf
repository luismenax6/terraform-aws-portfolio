variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "terraform-aws-portfolio"
    Owner     = "Luis Mena"
    ManagedBy = "Terraform"
  }
}

# map(object): each key is a logical OU name, value is a typed object
variable "organizational_units" {
  description = "Organizational Units to create under the root"
  type = map(object({
    name = string
  }))
  default = {
    security  = { name = "Security" }
    workloads = { name = "Workloads" }
    sandbox   = { name = "Sandbox" }
  }
}

# map(object) with an enabled flag — used to demonstrate conditional resources
variable "service_control_policies" {
  description = "SCPs to create and optionally attach to the root"
  type = map(object({
    name        = string
    description = string
    enabled     = bool
  }))
  default = {
    deny_root_access = {
      name        = "DenyRootAccess"
      description = "Denies use of the root user in member accounts"
      enabled     = true
    }
    deny_expensive_regions = {
      name        = "DenyExpensiveRegions"
      description = "Restricts resource creation to approved regions"
      enabled     = false
    }
  }
}
