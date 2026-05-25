# Terraform AWS Portfolio — Study Guide
HashiCorp Terraform Associate Certification Prep

---

## Projects Overview

| Project | Topic | Phase | Weeks |
|---------|-------|-------|-------|
| P1 | Terraform Fundamentals | Foundations | Week 1-2 |
| P2 | VPC + EC2 — Variables & Data Sources | Core Skills | Week 3-4 |
| P3 | App 3-Tier — Modules + Remote State | Core Skills | Week 5-6 |
| P4 | ECS Fargate — State Management + Workspaces | Advanced | Week 7-8 |
| P5 | Landing Zone — Multi-account + HCP Terraform | Advanced | Week 9 |

---

## P1 — Terraform Fundamentals
**Phase:** Foundations | **Week 1-2**

> Covers all HashiCorp certification language fundamentals using a simple S3 + EC2 setup. The goal is maximum Terraform language coverage, not complex architecture.

---

### Step 1 — Repo + providers.tf + Local State

> Start with local state — no backend. You'll migrate to S3 in the last step. This demonstrates the full state lifecycle.

**What to do:**
- Create repo `terraform-aws-portfolio` on GitHub
- Create folder `p1-fundamentals/`
- `providers.tf` with `hashicorp/aws ~> 5.0`, region from variable
- Do NOT add a backend block yet — let Terraform use local state (`terraform.tfstate`)
- Run `terraform init` and verify `.terraform/` and `terraform.lock.hcl` are created

**Tips:**
- Local state creates `terraform.tfstate` in the same directory after the first apply
- `terraform.lock.hcl` pins provider versions — commit it to git to ensure consistent versions across machines
- Verify provider was downloaded: `ls .terraform/providers/`
- `terraform version` shows Terraform and provider versions in use

> **Exam note:** Local state is the default when no backend is configured. It's stored in `terraform.tfstate` in the working directory — never commit it.

---

### Step 2 — variables.tf: All Types

> The exam tests all variable types. Practice declaring and using each one.

**What to do:**
- `aws_region`: `string`, default `us-east-1`
- `environment`: `string`, default `dev`, with `validation` using `contains()`
- `enable_versioning`: `bool`, default `false`
- `instance_count`: `number`, default `1`
- `allowed_cidrs`: `list(string)`, default `["0.0.0.0/0"]`
- `tags`: `map(string)` with default values
- `instance_config`: `object({ instance_type = string, volume_size = number, public_ip = bool })`
- `secret_value`: `string`, `sensitive = true`

**Tips:**
- `object()` requires all attributes to be present unless you use `optional()`: `optional(string, "default")`
- `sensitive = true` masks the value in `plan`/`apply` output but stores it in plain text in state
- Reference object attributes: `var.instance_config.instance_type`
- Reference list items: `var.allowed_cidrs[0]`
- Reference map values: `var.tags["Project"]`

> **Exam note:** Primitive types: `string`, `number`, `bool`. Complex types: `list`, `map`, `set`, `object`, `tuple`. Any type mismatch causes a validation error before plan.

---

### Step 3 — locals.tf: Built-in Functions

> Locals are computed values derived from variables or other locals. Practice the functions most tested in the exam.

**What to do:**
- `common_tags`: `merge(var.tags, { Environment = var.environment })`
- `name_prefix`: `format("%s-%s", var.tags["Project"], var.environment)`
- `bucket_name`: `lower("${local.name_prefix}-${replace(var.aws_region, "-", "")}")`
- `allowed_cidrs_str`: `join(", ", var.allowed_cidrs)`
- `instance_size_label`: `lookup(map, var.instance_config.instance_type, "unknown")`
- `cors_methods_set`: `toset(var.bucket_cors_methods)`
- `all_tags_values`: `flatten([values(var.tags), [var.environment]])`
- `monitoring_enabled`: `var.environment == "prod" ? true : false`

**Tips:**
- `locals {}` (plural) is the block name, `local.name` (singular) is the reference — easy to confuse
- `merge()` — the last map wins on duplicate keys: `merge({a="1"}, {a="2"})` → `{a="2"}`
- `lookup(map, key, default)` — safe map access, returns default if key doesn't exist
- `toset()` removes duplicates and converts to set — required for `for_each` with lists
- Test any function in `terraform console` before using it in code

> **Exam note:** `terraform console` is an interactive shell — type any expression and press Enter to see the result. Great for testing functions before using them.

---

### Step 4 — data.tf + main.tf: S3 + EC2

> Data sources read existing infrastructure without creating anything. Practice the most common ones.

**What to do:**
- `data "aws_caller_identity" "current" {}` — current account ID
- `data "aws_region" "current" {}` — current region
- `data "aws_ami" "amazon_linux"` — most recent Amazon Linux 2023 with filters
- `data "aws_vpc" "default"` — default VPC
- `aws_s3_bucket` using `local.bucket_name`, with versioning block driven by `var.enable_versioning`
- `aws_security_group` with ingress rules using `var.allowed_cidrs`
- `aws_instance` using the AMI from the data source and `var.instance_config`

**Tips:**
- AMI filter: `filter { name = "name" values = ["al2023-ami-*-x86_64"] }` — wildcards are valid in values
- `owners = ["amazon"]` goes **outside** the filter block — it's a direct attribute, not a filter
- Use `data.aws_caller_identity.current.account_id` to avoid hardcoding account IDs
- `count = var.instance_count` — creates multiple instances. Reference with `aws_instance.this[0].id`

> **Exam note:** `data` sources only read — Terraform never destroys a data source, even on `terraform destroy`. `resource` creates and manages the full lifecycle.

---

### Step 5 — outputs.tf: Sensitive Outputs

> Outputs expose values after apply. Sensitive outputs are masked in the terminal but visible in state.

**What to do:**
- `bucket_name`: the S3 bucket name
- `bucket_arn`: the S3 bucket ARN
- `instance_public_ip`: the EC2 public IP
- `instance_id`: the EC2 instance ID
- `account_id`: from `data.aws_caller_identity.current.account_id`
- `secret_output`: output the `var.secret_value` with `sensitive = true`

**Tips:**
- `sensitive = true` on an output masks it in terminal: `terraform output secret_output` shows `<sensitive>`
- To see the actual value: `terraform output -raw secret_output` or `terraform output -json`
- If a resource attribute is sensitive, the output referencing it must also be `sensitive = true` — Terraform enforces this
- All outputs should have a `description`

> **Exam note:** `sensitive = true` hides the value in logs but the state file stores it in plain text. Backend encryption (`encrypt = true`) protects state at rest.

---

### Step 6 — Provisioners + terraform_data

> Provisioners run scripts on resources. They are a last resort — use them only when no native Terraform resource exists. `terraform_data` replaces `null_resource` in Terraform >= 1.4.

**What to do:**
- Add a `local-exec` provisioner to the EC2 instance that writes the public IP to a local file
- Add a `remote-exec` provisioner that runs a command on the instance via SSH (use `connection` block)
- Create a `terraform_data` resource with a `triggers_replace` that forces re-run when `var.environment` changes
- Add a `local-exec` provisioner on the `terraform_data` resource

**Tips:**
- `local-exec` runs on your local machine: `command = "echo ${self.public_ip} > ip.txt"`
- `remote-exec` runs on the remote instance — requires a `connection` block with `host`, `user`, `private_key`
- Provisioners only run on `create` by default. Add `when = destroy` for destroy-time provisioners
- `on_failure = continue` skips the error and continues — `on_failure = fail` (default) stops everything
- `terraform_data` triggers: `triggers_replace = { env = var.environment }` — any change forces replacement

> **Exam note:** Provisioners are a last resort. If a provisioner fails the resource is marked as tainted and will be replaced on the next apply.

---

### Step 7 — Variable Precedence + .tfvars

> The exam heavily tests variable precedence. Practice setting the same variable in different ways and observing which one wins.

**What to do:**
- Create `dev.tfvars` with `environment = "dev"` and `instance_config` values for dev
- Create `prod.tfvars` with `environment = "prod"` and larger instance sizes
- Run `terraform plan -var-file=dev.tfvars` and observe values
- Run `terraform plan -var-file=prod.tfvars` and compare
- Override with CLI: `terraform plan -var-file=dev.tfvars -var="environment=staging"`
- Override with env var: `export TF_VAR_environment=prod && terraform plan`

**Tips:**
- `terraform.tfvars` is loaded **automatically** — no flag needed
- `*.auto.tfvars` is also loaded automatically — useful for shared defaults
- `-var` has higher precedence than `-var-file` — CLI always wins
- `TF_VAR_*` env vars have the highest precedence of all file-based methods
- `terraform console` → type `var.environment` to see the current value

> **Exam note:** Precedence (lowest to highest): default → `terraform.tfvars` → `*.auto.tfvars` → `-var-file` → `-var` → `TF_VAR_*`

---

### Step 8 — State Migration: Local → S3 Backend

> Migrating state from local to remote is a common real-world operation. Terraform handles it automatically with `terraform init`.

**What to do:**
- Add the `backend "s3"` block to `providers.tf` with key `p1-fundamentals/terraform.tfstate`
- Run `terraform init` — Terraform detects the new backend and asks to migrate state
- Answer `yes` — state is copied from `terraform.tfstate` to S3
- Verify: `aws s3 ls s3://luismena-terraform-state/p1-fundamentals/`
- Delete the local `terraform.tfstate` file

**Tips:**
- `terraform init -reconfigure` forces reinitialization without prompting — useful in pipelines
- `terraform init -migrate-state` explicitly migrates state (same as answering yes to the prompt)
- After migration, the local `terraform.tfstate` is stale — delete it to avoid confusion
- `terraform state list` after migration confirms all resources are in the remote state

> **Exam note:** After adding or changing the backend block always run `terraform init`. Without it Terraform still uses the old backend.

---

### Step 9 — terraform console + taint + -replace

> Practice the operational commands most tested in the exam.

**What to do:**
- Open `terraform console` and test expressions: `var.tags`, `local.name_prefix`, `merge(var.tags, {Env="test"})`
- Use `terraform state list` to see all resources
- Use `terraform state show aws_s3_bucket.this` to inspect a resource
- Force recreation with: `terraform apply -replace=aws_instance.this`
- Use `terraform taint aws_instance.this` (deprecated but still in the exam) and then `terraform untaint`

**Tips:**
- `terraform console` loads current state and variables — expressions evaluate against real values
- Exit `terraform console` with `Ctrl+C` or `exit`
- `-replace` is the modern way to force resource recreation — `taint` is deprecated since Terraform 1.0
- `terraform state mv` renames a resource in state without destroying it (the CLI alternative to the `moved` block)
- `terraform state rm` removes a resource from state without destroying the real infrastructure

> **Exam note:** `terraform taint` is deprecated — use `terraform apply -replace=RESOURCE` instead. Both appear in the exam. `-replace` is the recommended approach.

---

## P2 — VPC + EC2: Variables & Data Sources
**Phase:** Core Skills | **Week 6-7**

> Custom VPC with public and private subnets across multiple AZs using `count`. EC2 with AMI data source. Multi-environment setup with `.tfvars` files.

---

### Step 1 — Repo + providers.tf + Backend

**What to do:**
- Create folder `p2-vpc-ec2/` in the repo
- `providers.tf` with `hashicorp/aws ~> 5.0`
- Backend S3 with `key = "p2-vpc-ec2/terraform.tfstate"`, same bucket
- `aws` provider with region from variable
- Run `terraform init` and verify connection to S3

**Tips:**
- Only change the `key` attribute — the bucket is always `luismena-terraform-state`
- The key acts as a virtual path in S3: no need to create folders manually
- Verify state after first apply: `aws s3 ls s3://luismena-terraform-state/p2-vpc-ec2/`
- `terraform init -reconfigure` forces reinitialization if you already have a different backend

> **Exam note:** Each workspace uses a different key in S3. The default workspace uses the exact key, others use `env:/NAME/key`.

---

### Step 2 — variables.tf: Complex Types and Validation

**What to do:**
- `aws_region`, `environment` with `contains()` validation
- `vpc_cidr`: `string`, default `10.0.0.0/16`
- `public_subnet_cidrs`: `list(string)` with two CIDRs
- `private_subnet_cidrs`: `list(string)` with two CIDRs
- `instance_type`: `string`, default `t3.micro`
- `tags`: `map(string)` with defaults

**Tips:**
- `list(string)`: `type = list(string)` and `default = ["10.0.1.0/24", "10.0.2.0/24"]`
- `map(string)` default: no commas between key-value pairs in HCL
- You can have multiple `validation` blocks on the same variable
- Run `terraform validate` after creating `variables.tf`

> **Exam note:** `list` is indexed numerically `[0]`, `map` is indexed by key `["name"]`. Both are complex types distinct from primitives.

---

### Step 3 — locals.tf + networking.tf

**What to do:**
- `locals.tf`: `common_tags` with `merge()`, `name_prefix`, `az_count`
- `data.tf`: `data "aws_availability_zones"` with `state = "available"`
- `aws_vpc` with `enable_dns_hostnames = true` and `enable_dns_support = true`
- `aws_subnet` public with `count = length(var.public_subnet_cidrs)`
- `aws_subnet` private with `count`
- IGW + public route table + associations with `count`

**Tips:**
- `locals` (plural) block, `local.name` (singular) reference
- `merge(var.tags, { Environment = var.environment })` — second map overwrites duplicate keys
- `count.index` starts at 0. For AZ: `availability_zone = element(data.aws_availability_zones.available.names, count.index)`
- Route table association needs same count as subnets: `subnet_id = aws_subnet.public[count.index].id`

> **Exam note:** Splat expression `aws_subnet.public[*].id` returns a list of all IDs. Equivalent to `[for s in aws_subnet.public : s.id]`.

---

### Step 4 — data.tf + ec2.tf: Data Sources and EC2

**What to do:**
- `data "aws_ami"` for Amazon Linux 2023, `most_recent = true`, filters by name and owner
- `aws_security_group` with ingress 80/443/22 and egress all
- `aws_instance` in public subnet using the AMI from the data source
- `outputs.tf` with `vpc_id`, `public_subnet_ids` (splat), `ec2_public_ip`, `ec2_instance_id`

**Tips:**
- AMI filter: `filter { name = "name" values = ["al2023-ami-*-x86_64"] }` — wildcards valid in values
- `owners = ["amazon"]` goes **outside** the filter block
- Egress all: `from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"]`
- `associate_public_ip_address = true` on the instance for SSH access

> **Exam note:** `resource` creates and manages the lifecycle. `data` only reads — Terraform never destroys a data source even on `terraform destroy`.

---

### Step 5 — Multi-environment with .tfvars

**What to do:**
- Create `dev.tfvars` with `instance_type = "t3.micro"` and `environment = "dev"`
- Create `staging.tfvars` with `instance_type = "t3.small"` and `environment = "staging"`
- Run `terraform plan -var-file=dev.tfvars` and observe values
- Compare with `terraform plan -var-file=staging.tfvars`

**Tips:**
- `terraform.tfvars` is loaded automatically. Other files need explicit `-var-file`
- Combine files: `terraform plan -var-file=common.tfvars -var-file=dev.tfvars`
- `terraform console` → type `var.instance_type` to see the current value

> **Exam note:** `*.auto.tfvars` is loaded automatically with higher precedence than `terraform.tfvars`.

---

## P3 — App 3-Tier: Modules + Remote State
**Phase:** Core Skills | **Week 8-9**

> Three-tier architecture (networking, compute, database) built with reusable child modules. ALB + ASG + RDS MySQL.

---

### Step 1 — Repo + Module Folder Structure

**What to do:**
- Create folder `p3-3tier/` in the repo
- Root: `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `terraform.tfvars`
- `modules/networking/` with `main.tf`, `variables.tf`, `outputs.tf`
- `modules/compute/` with `main.tf`, `variables.tf`, `outputs.tf`
- `modules/database/` with `main.tf`, `variables.tf`, `outputs.tf`

**Tips:**
- Create the full structure at once: `mkdir -p modules/{networking,compute,database} && touch modules/{networking,compute,database}/{main,variables,outputs}.tf`
- Child modules must NOT have `providers.tf` or backend config — only the root module has those
- Start with empty files and fill them one module at a time

> **Exam note:** Module sources — local: `./modules/networking` | Registry: `terraform-aws-modules/vpc/aws` | Git: `git::https://github.com/...` Each source requires `terraform init`.

---

### Step 2 — modules/networking

**What to do:**
- `variables.tf`: `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`, `environment`, `tags`
- `main.tf`: VPC, subnets with `count`, IGW, route tables — no `provider` block
- AZ data source can go inside the module
- `outputs.tf`: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `vpc_cidr_block`

**Tips:**
- The module only knows what you pass as variables — don't use variables you haven't declared
- `public_subnet_ids` output: `value = aws_subnet.public[*].id` — returns the full list
- Be generous with outputs — expose more than you think you'll need

> **Exam note:** A child module inherits the root provider automatically. For aliased providers you must pass them explicitly using the `providers` block in the module call.

---

### Step 3 — modules/compute: ASG + ALB

**What to do:**
- `variables.tf`: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `instance_type`, `min_size`, `max_size`, `desired_capacity`, `environment`, `tags`
- ALB on `public_subnet_ids` with target group and listener on port 80
- Launch Template with AMI data source
- ASG on `private_subnet_ids` referencing the ALB target group
- `outputs.tf`: `alb_dns_name`, `alb_arn`, `asg_name`, `instance_security_group_id`

**Tips:**
- ALB needs at least two subnets in different AZs
- Launch Template in ASG: `launch_template { id = aws_launch_template.app.id version = "$Latest" }`
- Expose `instance_security_group_id` — the database module needs it to restrict RDS access

> **Exam note:** Instances go in private subnets, ALB in public subnets. The ALB receives external traffic and routes it to private instances.

---

### Step 4 — modules/database: RDS

**What to do:**
- `variables.tf`: `vpc_id`, `private_subnet_ids`, `db_username`, `db_password` (`sensitive = true`), `db_name`, `instance_class`, `environment`, `tags`, `allowed_security_group_id`
- `aws_db_subnet_group` with `private_subnet_ids`
- RDS Security Group with ingress on port 3306 only from `allowed_security_group_id`
- `aws_db_instance` with `engine = "mysql"`, `skip_final_snapshot = true`
- `outputs.tf`: `db_endpoint` (`sensitive = true`), `db_port`, `db_name`

**Tips:**
- `aws_db_subnet_group` needs at least two subnets in different AZs
- RDS SG ingress uses `source_security_group_id` — only allows traffic from ASG instances
- Pass `db_password` in pipeline as GitHub Secret named `TF_VAR_db_password`
- `skip_final_snapshot = true` is for labs only

> **Exam note:** `sensitive = true` on a variable or output hides the value in plan/apply. The state file stores it in plain text — `encrypt = true` on the backend protects it at rest.

---

### Step 5 — Root main.tf: Composing Modules

**What to do:**
- `module "networking"` with `source = "./modules/networking"` and its variables
- `module "compute"` receiving outputs from `module.networking`
- `module "database"` receiving subnet IDs from networking and SG from compute
- Root `outputs.tf` exposing `alb_dns_name` and `db_endpoint`
- `terraform init → plan → apply`

**Tips:**
- Pass outputs between modules: `subnet_ids = module.networking.public_subnet_ids`
- `terraform init` downloads local modules to `.terraform/modules/` — run after adding or changing a module source
- `terraform providers` shows the provider and module tree

> **Exam note:** After adding a new module always run `terraform init`. Without it Terraform doesn't recognize the module and fails.

---

## P4 — ECS Fargate: State Management + Workspaces
**Phase:** Advanced | **Week 10-11**

> Containerized app on ECS Fargate. Covers lifecycle meta-arguments, dynamic blocks, workspaces, moved block, and import block.

---

### Step 1 — Repo + ECR + ECS Cluster

**What to do:**
- Create folder `p4-ecs/` in the repo
- `providers.tf` with backend `key = "p4-ecs/terraform.tfstate"`
- `aws_ecr_repository` with `prevent_destroy = true` and `scan_on_push = true`
- `aws_ecs_cluster` with Container Insights enabled
- `aws_ecs_cluster_capacity_providers` with `FARGATE` and `FARGATE_SPOT`
- Test `terraform destroy` to confirm `prevent_destroy` blocks it

**Tips:**
- `lifecycle` is a meta-argument — goes inside the resource block: `lifecycle { prevent_destroy = true }`
- Container Insights: `setting { name = "containerInsights" value = "enabled" }` inside `aws_ecs_cluster`
- `FARGATE_SPOT` can be up to 70% cheaper but tasks can be interrupted — fine for labs

> **Exam note:** `lifecycle` has four arguments: `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `replace_triggered_by`. All are frequent in the exam.

---

### Step 2 — Task Definition + ECS Service

**What to do:**
- IAM role for ECS task execution with trust policy for `ecs-tasks.amazonaws.com`
- CloudWatch log group for container logs
- `task-definition.json.tpl` file with `${variable}` placeholders
- `aws_ecs_task_definition` using `templatefile()` to load the template
- Security group with `dynamic` block for ingress ports
- `aws_ecs_service` with `launch_type = "FARGATE"` and `network_configuration`

**Tips:**
- `templatefile("task-definition.json.tpl", { image_url = var.image_url, cpu = var.cpu })` — second arg is a map
- In `.tpl` files use `${variable}` for placeholders — same syntax as HCL interpolation
- Dynamic block: `dynamic "ingress" { for_each = var.ports content { from_port = ingress.value to_port = ingress.value } }`

> **Exam note:** The dynamic block label is the iterator. For a custom name: `dynamic "ingress" { iterator = port }` — access with `port.value`.

---

### Step 3 — Workspaces: Dev / Staging / Prod

**What to do:**
- Create a `locals` block with a config map per environment using `terraform.workspace` as the key
- `terraform workspace new dev`
- `terraform workspace new staging`
- `terraform workspace new prod`
- `terraform workspace select dev → terraform plan`
- `terraform workspace list`

**Tips:**
- `terraform workspace new NAME` creates AND selects the workspace
- Use `terraform.workspace` as the map key: `local.config[terraform.workspace]`
- Each workspace state in S3: `env:/NAME/p4-ecs/terraform.tfstate`
- `terraform workspace list` shows all workspaces with `*` on the active one

> **Exam note:** When NOT to use workspaces: large differences between environments, strict compliance, large teams. For those cases use separate directories with their own state.

---

### Step 4 — moved Block: Refactoring Without Destroy

**What to do:**
- Rename a resource in code (e.g. `aws_ecs_service.main` → `aws_ecs_service.app`)
- Create `refactor.tf` with a `moved` block: `moved { from = aws_ecs_service.main  to = aws_ecs_service.app }`
- `terraform plan` — should show "has moved to" with **zero destroys**
- `terraform apply`
- Delete the `moved` block after apply

**Tips:**
- No quotes on the references in the `moved` block
- If plan shows destroy+create instead of moved — the names in `from`/`to` don't exactly match the code
- `terraform state list` before and after apply to confirm the rename

> **Exam note:** Old CLI method: `terraform state mv`. New declarative method: `moved` block. The `moved` block appears in the plan — you can review it before applying.

---

### Step 5 — import Block: Importing Existing Resources

**What to do:**
- Create a Security Group manually in the AWS console — note its ID
- Create `imports.tf` with `import { to = aws_security_group.imported  id = "sg-xxxx" }`
- Run `terraform plan -generate-config-out=generated.tf`
- Review and clean `generated.tf` removing unnecessary computed attributes
- Move clean code to `main.tf` and delete `imports.tf`
- `terraform plan` should show 0 changes

**Tips:**
- The import ID depends on the resource — for Security Groups it's `sg-xxxxxxxxx`
- `generated.tf` includes computed attributes like `arn` and `owner_id` — you can remove them
- `-generate-config-out` requires Terraform >= 1.5

> **Exam note:** Old method: `terraform import` (you write the code first). New method: `import` block with `-generate-config-out` (Terraform generates the code). Both appear in the exam.

---

## P5 — Landing Zone: Multi-account + HCP Terraform
**Phase:** Advanced | **Week 12**

> Enterprise AWS Landing Zone with Organizations, SCPs, and OUs. `for_each`, `for` expressions, HCP Terraform.

---

### Step 1 — Repo + Multi-account Provider Aliases

**What to do:**
- Create folder `p5-landing-zone/` in the repo
- Main `aws` provider for the management account
- `aws` provider with `alias` for each additional account using `assume_role`
- Backend S3 with `key = "p5-landing-zone/terraform.tfstate"`
- Run `terraform init`

**Tips:**
- Provider with alias: `provider "aws" { alias = "security"  region = "us-east-1"  assume_role { role_arn = "arn:..." } }`
- `OrganizationAccountAccessRole` is the role AWS automatically creates in new Organizations accounts
- In resources: add `provider = aws.security` inside the resource block
- Verify role assumption: `aws sts assume-role --role-arn ARN --role-session-name test`

> **Exam note:** The `provider` attribute in a resource only accepts references of the same provider type. Syntax: `provider = aws.alias_name` (no quotes).

---

### Step 2 — for_each with map(object)

**What to do:**
- Define variable `iam_users` as `map(object({ group = string, admin = bool }))`
- `aws_iam_user` with `for_each = var.iam_users`
- Group memberships using `each.key` and `each.value.group`
- `terraform state list` to see how resources are named with `for_each`

**Tips:**
- With `for_each` resources are named `resource.name["key"]` in state: e.g. `aws_iam_user.users["alice"]`
- `each.key` is the map key (username), `each.value` is the full object
- To use `for_each` with a list: `for_each = toset(var.list)`

> **Exam note:** `for_each` accepts `map(any)` or `set(string)`. For a list of strings use `toset()`. `for_each` resources are referenced with `["key"]`, `count` resources with `[index]`.

---

### Step 3 — for Expressions + Conditional

**What to do:**
- List `for`: `[for s in var.list : upper(s)]`
- Map `for`: `{for k, v in var.map : k => upper(v)}`
- For with filter: `[for s in var.list : s if s != "exclude"]`
- Conditional: `count = var.create_resource ? 1 : 0` for optional resources
- Test everything in `terraform console` before using in code

**Tips:**
- `[for ...]` returns a list, `{for ...}` returns a map
- `terraform console` is the best tool for testing expressions
- `count = var.create_bastion ? 1 : 0` — standard pattern for optional resources

> **Exam note:** `for` expressions can go anywhere a value is expected — locals, resource attributes, outputs.

---

### Step 4 — AWS Organizations + SCPs

**What to do:**
- `aws_organizations_organization` to enable Organizations
- `aws_organizations_organizational_unit` for OUs: Workloads and Security
- `aws_organizations_policy` with JSON SCP restricting actions or regions
- `aws_organizations_policy_attachment` associating the SCP to the Workloads OU

**Tips:**
- SCP uses the same JSON format as an IAM policy but `Effect = Deny` restricts the entire OU
- To restrict to `us-east-1`: Deny all actions with condition `StringNotEquals aws:RequestedRegion us-east-1`
- SCPs do **not** apply to the management account — only member accounts

> **Exam note:** SCPs don't grant permissions, they only limit them. An action requires an IAM Allow AND the absence of a restrictive SCP.

---

### Step 5 — Terraform Registry Module

**What to do:**
- Replace your local networking module with `terraform-aws-modules/vpc/aws` from the Registry
- Specify version constraint `~> 5.0`
- `terraform init` — downloads the module from the Registry
- Check `.terraform/modules/` to see the downloaded module

**Tips:**
- On `registry.terraform.io` open the module → Inputs tab to see all available variables
- `~> 5.0` accepts `5.x` but not `6.0`
- Check `.terraform/modules/modules.json` for the exact version downloaded
- Only pass the variables you need — others use defaults

> **Exam note:** Without a version in a Registry module, `terraform init` takes the latest version. In production always pin the version.

---

### Step 6 — HCP Terraform: Remote Operations

**What to do:**
- Create a free account at `app.terraform.io`
- Create organization and workspace `p5-landing-zone`
- Replace the `backend "s3"` block with the `cloud` block with `organization` and `workspace`
- `terraform login → terraform init` (migrates state from S3 to HCP Terraform)
- `terraform plan` — observe remote execution in `app.terraform.io`

**Tips:**
- `terraform login` opens the browser automatically. Token saved in `~/.terraform.d/credentials.tfrc.json`
- The `cloud` block completely replaces the backend — you can't have both in the same file
- Terraform variables are configured in HCP Terraform → workspace → Variables

> **Exam note:** `cloud` block vs `backend "s3"` — `cloud` runs plan+apply remotely. `backend "s3"` only stores state, plan+apply run locally.

---

## Quick Reference

### Common Commands
```bash
terraform init                        # initialize and connect to backend
terraform init -reconfigure           # force reinitialization
terraform init -migrate-state         # migrate state to new backend
terraform fmt                         # format code
terraform fmt -check                  # check formatting (CI)
terraform validate                    # validate syntax
terraform plan                        # preview changes
terraform plan -var-file=dev.tfvars   # plan with specific vars file
terraform plan -out=tfplan            # save plan to file
terraform apply                       # apply changes
terraform apply tfplan                # apply saved plan
terraform apply -replace=RESOURCE     # force recreation
terraform destroy                     # destroy all resources
terraform output                      # show outputs
terraform output -raw NAME            # show raw output value
terraform state list                  # list all resources in state
terraform state show RESOURCE         # inspect a resource in state
terraform state mv FROM TO            # rename resource in state
terraform state rm RESOURCE           # remove from state (not destroy)
terraform workspace list              # list workspaces
terraform workspace new NAME          # create and select workspace
terraform workspace select NAME       # switch workspace
terraform console                     # interactive expression shell
```

### Variable Precedence (lowest → highest)
1. Variable `default` value
2. `terraform.tfvars`
3. `*.auto.tfvars`
4. `-var-file` flag
5. `-var` flag
6. `TF_VAR_*` environment variables
