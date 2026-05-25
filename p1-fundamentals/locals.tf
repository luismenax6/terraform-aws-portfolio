locals {
  # merge() — combine maps, second one wins on duplicate keys
  common_tags = merge(var.tags, { Environment = var.environment })

  # format() — string formatting
  name_prefix = format("%s-%s", var.tags["Project"], var.environment)

  # lower() + replace() — clean up strings
  bucket_name = lower(replace("${local.name_prefix}-${var.aws_region}", ".", "-"))

  # join() — list to string
  allowed_cidrs_str = join(", ", var.allowed_cidrs)

  # lookup() — safe map access with a default
  instance_size_label = lookup({
    "t3.micro"  = "small"
    "t3.small"  = "medium"
    "t3.medium" = "large"
  }, var.instance_config.instance_type, "unknown")

  # toset() — convert list to set (removes duplicates, required for for_each)
  cidrs_set = toset(var.allowed_cidrs)

  # flatten() — collapse nested lists into a single list
  all_tag_values = flatten([values(var.tags), [var.environment]])

  # Conditional expression — ternary
  monitoring_enabled = var.environment == "prod" ? true : false
}
