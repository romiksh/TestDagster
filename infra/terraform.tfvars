# Optional overrides
region  = "us-east-1"
project = "dagster-ecs"

# Networking (defaults ok)
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

allowed_cidr_http = ["0.0.0.0/0"]

# RDS
db_instance_class = "db.t4g.micro"
db_name           = "dagster"

# Image tag (CI passes short SHA)
image_tag = "latest"

# GitHub OIDC & repo binding
github_org               = "romiksh"
github_repo              = "TestDagster"
github_branch_ref        = "refs/heads/main"
github_oidc_provider_arn = ""
