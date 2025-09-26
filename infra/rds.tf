resource "random_password" "db" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "db" {
  name = "${local.name}/rds-postgres"
  tags = local.tags
}
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({ username = "dagster", password = random_password.db.result })
}
resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnets"
  subnet_ids = [aws_subnet.private["a"].id, aws_subnet.private["b"].id]
  tags       = local.tags
}
resource "aws_db_instance" "postgres" {
  identifier             = "${local.name}-pg"
  engine                 = "postgres"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = jsondecode(aws_secretsmanager_secret_version.db.secret_string)["username"]
  password               = jsondecode(aws_secretsmanager_secret_version.db.secret_string)["password"]
  allocated_storage      = 20
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  deletion_protection    = false
  tags                   = local.tags
}
