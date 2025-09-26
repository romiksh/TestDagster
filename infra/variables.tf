variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project/name prefix for resources"
  type        = string
  default     = "dagster-ecs"
}

variable "vpc_cidr" {
  description = "CIDR for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "allowed_cidr_http" {
  description = "CIDR blocks allowed to reach the ALB on port 80"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# RDS
variable "db_instance_class" {
  description = "RDS instance class for Postgres"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Database name for Dagster"
  type        = string
  default     = "dagster"
}

# Image tag passed from CI
variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}

# GitHub OIDC & repo binding
variable "github_org" {
  description = "GitHub organization or user that owns the repository"
  type        = string
  default     = "your-org-or-user"
}

variable "github_repo" {
  description = "GitHub repository name (without org)"
  type        = string
  default     = "your-repo"
}

variable "github_branch_ref" {
  description = "Git ref allowed to assume the deploy role (e.g., refs/heads/main)"
  type        = string
  default     = "refs/heads/main"
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN (leave empty to create one)"
  type        = string
  default     = ""
}