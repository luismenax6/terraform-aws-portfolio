locals {
  name_prefix = "p4-${terraform.workspace}"
  common_tags = merge(var.tags, { Environment = terraform.workspace })
}
