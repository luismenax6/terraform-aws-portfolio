resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name      = each.value.name
  parent_id = data.aws_organizations_organization.this.roots[0].id

  tags = local.common_tags
}
