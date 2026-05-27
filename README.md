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
**Deploys:** Custom VPC + public/private subnets across 2 AZs + EC2 instance

### Topics covered

| Topic | How it's practiced |
|---|---|
| `count` | Creates 2 public and 2 private subnets in separate AZs |
| Splat expressions | `aws_subnet.public[*].id` to get all subnet IDs as a list |
| Data sources | `aws_availability_zones` to dynamically resolve AZ names |
| Multi-environment | `dev.tfvars` and `staging.tfvars` with different CIDRs and instance types |
| Networking | VPC, IGW, route tables, route table associations |
| Security | IMDSv2, gp3 EBS, `vpc_security_group_ids` |

### Files

```
p2-vpc-ec2/
├── providers.tf        # AWS provider + S3 backend
├── variables.tf        # VPC CIDRs, subnet lists, instance config
├── locals.tf           # name_prefix, common_tags, az_count
├── data.tf             # aws_availability_zones, aws_ami
├── networking.tf       # VPC, subnets, IGW, route tables
├── ec2.tf              # security group + EC2 instance
├── outputs.tf          # vpc_id, subnet IDs, EC2 public IP
├── dev.tfvars          # dev overrides (gitignored)
└── staging.tfvars      # staging overrides (gitignored)
```

### Key exam notes

- `count` addresses resources by index: `aws_subnet.public[0]`, `aws_subnet.public[1]`
- Removing an item from a `count` list shifts all indexes — prefer `for_each` for stable addressing
- Splat `[*]` only works with `count`, not `for_each` (use `values()` instead)
- `aws_availability_zones` data source returns AZs dynamically — no hardcoding needed

---

## P3 — 3-Tier App: Modules + Remote State

**Folder:** `p3-3tier/`
**Deploys:** ALB + Auto Scaling Group + RDS MySQL across networking, compute, and database modules

### Topics covered

| Topic | How it's practiced |
|---|---|
| Child modules | `source = "./modules/networking"`, `"./modules/compute"`, `"./modules/database"` |
| Module inputs | Each module declares variables with no defaults — caller must pass all values |
| Module outputs | `module.networking.vpc_id`, `module.compute.instance_security_group_id` |
| Output chaining | Networking outputs feed into compute; compute outputs feed into database |
| Sensitive outputs | `db_endpoint` marked `sensitive = true` |
| SG-to-SG rules | RDS SG allows port 3306 only from the compute SG ID — no CIDR blocks |

### Files

```
p3-3tier/
├── providers.tf
├── variables.tf
├── main.tf                         # root — calls all three modules
├── outputs.tf
└── modules/
    ├── networking/
    │   ├── variables.tf            # no defaults
    │   ├── main.tf                 # VPC, subnets, IGW, route tables
    │   └── outputs.tf              # vpc_id, subnet IDs
    ├── compute/
    │   ├── variables.tf
    │   ├── main.tf                 # ALB, target group, listener, launch template, ASG
    │   └── outputs.tf              # alb_dns_name, instance_security_group_id
    └── database/
        ├── variables.tf
        ├── main.tf                 # DB subnet group, SG, RDS MySQL
        └── outputs.tf              # db_endpoint (sensitive), db_port
```

### Key exam notes

- Child module variables have no defaults — every input must be passed explicitly by the caller
- Module outputs are referenced as `module.<name>.<output>` in the root
- `sensitive = true` on an output propagates sensitivity — any root output referencing it is also sensitive
- `db_password` is never in tfvars — use `TF_VAR_db_password` environment variable

---

## P4 — ECS Fargate: State Management + Workspaces

**Folder:** `p4-ecs/`
**Deploys:** ECR repository + ECS Fargate cluster + task definition + service + CloudWatch logs

### Topics covered

| Topic | How it's practiced |
|---|---|
| `lifecycle { prevent_destroy }` | ECR repository — blocks `terraform destroy` |
| `lifecycle { ignore_changes }` | ECS service — ignores `task_definition` changes from CI/CD deploys |
| `dynamic` blocks | Security group ingress — generates one rule per port in `var.ingress_ports` |
| `templatefile()` | ECS task definition rendered from `templates/task-definition.json.tpl` |
| `jsonencode()` | IAM trust policy built from native HCL — type-safe, caught at validate time |
| Workspaces | `terraform.workspace` replaces `var.environment` — one state file per workspace |
| `moved` block | Renames `aws_security_group.ecs_tasks` → `aws_security_group.tasks` with zero destroy |
| `import` block | Brings existing `aws_cloudwatch_log_group` under Terraform management |

### Files

```
p4-ecs/
├── providers.tf                        # S3 backend
├── variables.tf                        # cpu, memory, ingress_ports (list), etc.
├── locals.tf                           # name_prefix uses terraform.workspace
├── data.tf                             # default VPC + subnets
├── main.tf                             # ECR, ECS cluster, SG (dynamic), task def, service
├── iam.tf                              # ECS task execution role + policy attachment
├── logs.tf                             # CloudWatch log group
├── moved.tf                            # moved block — safe rename
├── import.tf                           # import block — adopt existing log group
├── outputs.tf
└── templates/
    └── task-definition.json.tpl        # templatefile() template
```

### Key exam notes

- `terraform.workspace` returns `"default"` unless you switch — always create `dev` workspace before applying
- `moved` block: without it, a rename = destroy + recreate; with it = state update only, zero downtime
- `import` block requires the matching `resource` block to already exist in code
- `dynamic` block iterator variable name matches the block label: `dynamic "ingress" { content { ingress.value } }`
- `lifecycle` blocks are evaluated before plan — `prevent_destroy` errors at plan time, not apply

### Workspace commands

```bash
terraform workspace new dev       # create + switch to dev
terraform workspace new staging   # create + switch to staging
terraform workspace select dev    # switch to existing workspace
terraform workspace list          # show all workspaces (* = current)
terraform workspace show          # print current workspace name
```

---

## P5 — Landing Zone: Multi-account + HCP Terraform

**Folder:** `p5-landing-zone/`
**Deploys:** AWS Organizations OUs + SCPs + shared services VPC (public module)

### Topics covered

| Topic | How it's practiced |
|---|---|
| `map(object)` variable | `var.organizational_units` and `var.service_control_policies` are typed maps |
| `for_each` over `map(object)` | Creates one OU per key; `each.key` = logical name, `each.value` = object |
| `for` expressions — list | `[for key, ou in var.organizational_units : ou.name]` |
| `for` expressions — map | `{ for key, scp in var.service_control_policies : key => scp.name }` |
| `for` expressions — filter | `{ for k, v in var.service_control_policies : k => v if v.enabled }` |
| Conditional resource | `aws_organizations_policy_attachment` uses `local.enabled_scps` — only attaches enabled SCPs |
| Public registry module | `terraform-aws-modules/vpc/aws` — source format, version constraint, module outputs |
| HCP Terraform | `cloud {}` block, `terraform login`, `-migrate-state`, remote operations |

### Files

```
p5-landing-zone/
├── providers.tf        # S3 backend + commented-out cloud {} block with migration steps
├── variables.tf        # map(object) for OUs and SCPs
├── locals.tf           # for expressions: ou_names, enabled_scps, scp_name_map
├── data.tf             # aws_caller_identity, aws_organizations_organization
├── organizations.tf    # aws_organizations_organizational_unit (for_each)
├── scp.tf              # aws_organizations_policy + conditional attachment (for_each + filter)
├── vpc.tf              # public module: terraform-aws-modules/vpc/aws
└── outputs.tf          # for expressions in outputs
```

### Key exam notes

- `for_each` with a map gives stable string keys in state: `this["security"]`, `this["workloads"]` — safe to remove any item without shifting indexes
- `for` expression filter syntax: `{ for k, v in map : k => v if condition }`
- Public module source format: `"<namespace>/<module>/<provider>"` — downloaded from `registry.terraform.io`
- `cloud {}` block and `backend {}` block cannot coexist — comment out one before adding the other
- HCP Terraform workspaces are separate from CLI workspaces (`terraform workspace`) — they cannot be used together
- `terraform login` saves a token to `~/.terraform.d/credentials.tfrc.json`

### HCP Terraform migration

```bash
terraform login                    # authenticate to app.terraform.io
# swap backend "s3" for cloud {} in providers.tf
terraform init -migrate-state      # copies state from S3 to HCP automatically
```

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
