output "alb_dns" {
  value = aws_lb.this.dns_name
}
output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
output "ecr_repo_url" {
  value = aws_ecr_repository.app.repository_url
}
output "vpc_id" {
  value = aws_vpc.this.id
}

