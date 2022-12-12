provider "aws" {
  region  = var.region
  profile = ""
}

variable "region" {
  type        = string
  description = "Region to deploy resources"
  default     = ""
}

variable "environment" {
  type        = string
  description = "environment resources are deployed to"
  default     = ""
}

locals {
  parameter_path = "/${var.environment}/vpc"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-1b", "us-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "${local.parameter_path}/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
}

resource "aws_ssm_parameter" "public_subnet_ids" {
  name  = "${local.parameter_path}/public_subnet_ids"
  type  = "String"
  value = jsonencode(module.vpc.public_subnets)
}

resource "aws_ssm_parameter" "private_subnet_ids" {
  name  = "${local.parameter_path}/private_subnet_ids"
  type  = "String"
  value = jsonencode(module.vpc.private_subnets)
}
