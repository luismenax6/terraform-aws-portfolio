data "aws_caller_identity" "current" {}

# reads the existing Organization — must be already enabled in the management account
data "aws_organizations_organization" "this" {}
