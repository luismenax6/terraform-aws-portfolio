terraform {
  required_version = ">= 1.15.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "luismena-terraform-state"
    key          = "p2-vpc-ec2/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

}

provider "aws" {
  region = var.aws_region
}