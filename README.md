# Dagster on AWS ECS (Fargate) — GitHub Actions Starter (with VPC)
This repo builds a Dagster image, pushes it to **ECR**, and deploys **ECS Fargate + ALB + RDS Postgres + S3 + IAM** via Terraform.
It **also creates the full VPC networking** (VPC, 2× public + 2× private subnets across AZs, IGW, NAT, routes).

## What you'll need
- An AWS account.
- Create two GitHub Actions secrets:
  - `AWS_ROLE_TO_ASSUME` — IAM Role ARN Terraform will create (see outputs after first local apply) or create manually then paste here.
  - `AWS_REGION` — e.g., `us-east-1`.

> Bootstrap once: run `terraform apply` locally from `infra/` to create the GitHub OIDC provider (if missing) and the GitHub deploy role.
> Copy the `github_actions_role_arn` output to your repo secret `AWS_ROLE_TO_ASSUME`. After that, CI can deploy end-to-end.
