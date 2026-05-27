output "organization_id" {
  description = "ID of the AWS Organization"
  value       = data.aws_organizations_organization.this.id
}

output "organizational_unit_ids" {
  description = "Map of OU name to OU ID"
  value       = { for key, ou in aws_organizations_organizational_unit.this : key => ou.id }
}

output "attached_scp_names" {
  description = "Names of SCPs currently attached to the root"
  value       = [for key, scp in local.enabled_scps : scp.name]
}

output "shared_services_vpc_id" {
  description = "ID of the shared services VPC"
  value       = module.shared_services_vpc.vpc_id
}

output "shared_services_private_subnets" {
  description = "Private subnet IDs from the shared services VPC"
  value       = module.shared_services_vpc.private_subnets
}
