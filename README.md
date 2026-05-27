# Terraform AWS Portfolio

Hands-on study portfolio for the **HashiCorp Terraform Associate** certification.
Each project builds on the previous one, covering all exam topics through real AWS deployments.

---

## Projects

| Project | Topic | Status |
|---------|-------|--------|
| [P1 — Terraform Fundamentals](#p1--terraform-fundamentals) | Language core | ✅ Done |
| [P2 — VPC + EC2](#p2--vpc--ec2-variables--data-sources) | Variables & data sources | ✅ Done |
| [P3 — 3-Tier App](#p3--3-tier-app-modules--remote-state) | Modules + remote state | ✅ Done |
| [P4 — ECS Fargate](#p4--ecs-fargate-state-management--workspaces) | State management + workspaces | ✅ Done |
| [P5 — Landing Zone](#p5--landing-zone-multi-account--hcp-terraform) | Multi-account + HCP Terraform | ✅ Done |

---

## Prerequisites

- Terraform >= 1.15.3
- AWS CLI configured (`aws sts get-caller-identity`)
- AWS account with permissions to create EC2, S3, VPC, IAM resources
- S3 bucket `luismena-terraform-state` (shared state backend)

---

## How to run each project

```bash
cd p1-fundamentals/

terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
terraform destroy -var-file=dev.tfvars   # always destroy when done — avoid costs
```

---

## P1 — Terraform Fundamentals

**Folder:** `p1-fundamentals/`
**Deploys:** S3 bucket + EC2 instance (default VPC)

Covers the full Terraform language — all topics tested in the Associate exam.

### Topics covered

| Topic | How it's practiced |
|---|---|
| Variable types | `string`, `bool`, `number`, `list`, `map`, `object`, `sensitive` |
| Variable validation | `contains()` on `environment` variable |
| Variable precedence | `terraform.tfvars` vs `dev.tfvars` vs `-var` vs `TF_VAR_*` |
| Locals + functions | `merge`, `format`, `lower`, `replace`, `join`, `lookup`, `toset`, `flatten` |
| Conditional expression | `var.environment == "prod" ? true : false` |
| Data sources | `aws_caller_identity`, `aws_region`, `aws_ami`, `aws_vpc`, `aws_subnets` |
| Resources | `aws_s3_bucket`, `aws_s3_bucket_versioning`, `aws_security_group`, `aws_instance` |
| Outputs | Splat `[*]`, sensitive output, data source output |
| Provisioners | `local-exec`, `terraform_data` with `triggers_replace` |
| `on_failure` | `continue` vs `fail` (default) |
| Lifecycle | `create_before_destroy` |
| Security | IMDSv2 (`http_tokens = "required"`), EBS encryption, `gp3` |
| State migration | Local → S3 backend |
| Console practice | `terraform console`, `state list`, `state show`, `-replace`, `taint` |

### Files

```
p1-fundamentals/
├── providers.tf        # AWS provider + S3 backend
├── variables.tf        # all variable types with validation
├── locals.tf           # built-in functions
├── data.tf             # data sources
├── main.tf             # S3 + security group + EC2 with provisioners
├── outputs.tf          # splat outputs + sensitive output
├── terraform.tfvars    # default values (gitignored)
├── dev.tfvars          # dev environment overrides (gitignored)
└── prod.tfvars         # prod environment overrides (gitignored)
```

### Key exam notes

- `locals {}` (plural) block, `local.name` (singular) reference
- `sensitive = true` masks value in plan/apply but stores in plain text in state
- `data` sources only read — never destroyed by `terraform destroy`
- Provisioner failure = resource **tainted** = replaced on next apply
- `terraform apply -replace=RESOURCE` is the modern replacement for `terraform taint`
- Variable precedence (lowest → highest): `default` → `terraform.tfvars` → `*.auto.tfvars` → `-var-file` → `-var` → `TF_VAR_*`

---

## P2 — VPC + EC2: Variables & Data Sources

**Folder:** `p2-vpc-ec2/`
**Deploys:** Custom VPC + public/private subnets + EC2

### Topics covered
- Custom VPC with public and private subnets across multiple AZs
- `count` for multiple subnets and instances
- Splat expressions `[*]`
- `aws_availability_zones` data source
- Multi-environment with `dev.tfvars` and `staging.tfvars`

---

## P3 — 3-Tier App: Modules + Remote State

**Folder:** `p3-3tier/`
**Deploys:** ALB + ASG + RDS MySQL

### Topics covered
- Child modules with `source = "./modules/networking"`
- Module inputs (variables) and outputs
- Passing outputs between modules
- Remote state with `terraform_remote_state`
- Sensitive outputs (`db_endpoint`)

---

## P4 — ECS Fargate: State Management + Workspaces

**Folder:** `p4-ecs/`
**Deploys:** ECR + ECS Fargate cluster + service

### Topics covered
- `lifecycle` meta-arguments: `prevent_destroy`, `create_before_destroy`, `ignore_changes`
- `dynamic` blocks for repeated nested blocks
- `templatefile()` for task definitions
- Terraform workspaces (`dev`, `staging`, `prod`)
- `moved` block for safe refactoring
- `import` block + `-generate-config-out` for existing resources

---

## P5 — Landing Zone: Multi-account + HCP Terraform

**Folder:** `p5-landing-zone/`
**Deploys:** AWS Organizations + OUs + SCPs

### Topics covered
- Multi-account provider aliases with `assume_role`
- `for_each` with `map(object)`
- `for` expressions (list, map, filter)
- Conditional resources with `count = var.create ? 1 : 0`
- AWS Organizations, OUs, SCPs
- Public Registry module (`terraform-aws-modules/vpc/aws`)
- HCP Terraform `cloud` block + remote operations

---

## Common commands

```bash
terraform init                          # initialize + connect to backend
terraform init -migrate-state          # migrate state to new backend
terraform fmt                           # format code
terraform validate                      # validate syntax
terraform plan -var-file=dev.tfvars    # preview with dev values
terraform apply -var-file=dev.tfvars   # apply with dev values
terraform destroy -var-file=dev.tfvars # destroy all resources
terraform output                        # show outputs
terraform state list                    # list all resources in state
terraform state show RESOURCE           # inspect a resource
terraform apply -replace=RESOURCE      # force resource recreation
terraform workspace new dev             # create and select workspace
terraform console                       # interactive expression shell
```

---

## Study guide

See [STUDY_GUIDE.md](./STUDY_GUIDE.md) for step-by-step instructions, tips, and exam notes for every project.
