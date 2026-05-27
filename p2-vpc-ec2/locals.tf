locals {
  # merge() — combine common tags with environment tag
  common_tags = merge(var.tags, { Environment = var.environment })

  # format() — build a consistent name prefix for all resources
  name_prefix = format("%s-%s", var.tags["Project"], var.environment)

  # length() — count AZs from the subnet list, drives count on subnet resources
  az_count = length(var.public_subnet_cidrs)
}
