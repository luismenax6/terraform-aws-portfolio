terraform {
  required_version = ">= 1.15.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # S3 backend — consistent with P1–P4
  backend "s3" {
    bucket       = "luismena-terraform-state"
    key          = "p5-landing-zone/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  # HCP Terraform alternative — replaces the backend "s3" block above.
  # Steps to migrate:
  #   1. Sign up at app.terraform.io (free tier available)
  #   2. Create an organization and a workspace named "p5-landing-zone"
  #   3. Run: terraform login
  #   4. Comment out backend "s3" above and uncomment this block
  #   5. Run: terraform init -migrate-state
  #
  # cloud {
  #   organization = "your-hcp-org-name"
  #   workspaces {
  #     name = "p5-landing-zone"
  #   }
  # }
}

provider "aws" {
  region = var.aws_region
}
