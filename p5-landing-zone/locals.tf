locals {
  common_tags = merge(var.tags, { Environment = "management" })

  # for expression: transform map → list of display names
  ou_names = [for key, ou in var.organizational_units : ou.name]

  # for expression: filter map → only SCPs where enabled = true
  enabled_scps = {
    for key, scp in var.service_control_policies : key => scp
    if scp.enabled
  }

  # for expression: build a map of SCP key → display name (for outputs/debugging)
  scp_name_map = {
    for key, scp in var.service_control_policies : key => scp.name
  }
}
