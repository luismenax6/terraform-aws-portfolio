locals {
  scp_policies = {
    deny_root_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect    = "Deny"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }]
    })
    deny_expensive_regions = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["us-east-1", "us-west-2"]
          }
        }
      }]
    })
  }
}

# creates every SCP — enabled or not
resource "aws_organizations_policy" "this" {
  for_each = var.service_control_policies

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = local.scp_policies[each.key]

  tags = local.common_tags
}

# conditional resource: for_each over local.enabled_scps (filtered map)
# only SCPs with enabled = true get attached to the root
resource "aws_organizations_policy_attachment" "this" {
  for_each = local.enabled_scps

  policy_id = aws_organizations_policy.this[each.key].id
  target_id = data.aws_organizations_organization.this.roots[0].id
}
