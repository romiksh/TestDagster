resource "aws_ecs_cluster" "this" {
  name = local.name
  tags = local.tags
}
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name}"
  retention_in_days = 14
}
locals {
  account_id = data.aws_caller_identity.current.account_id
  image_uri  = "${local.account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.app.name}:${var.image_tag}"
}

resource "aws_ecs_task_definition" "dagster" {
  family                   = "${local.name}-task"
  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }


  container_definitions = jsonencode([
    { "name" : "web", "image" : local.image_uri, "essential" : true,
      "command" : ["dagster-webserver", "-h", "0.0.0.0", "-p", "3000", "-w", "/opt/dagster/dagster_home/workspace.yaml"],
      "portMappings" : [{ "containerPort" : 3000, "protocol" : "tcp" }],
      "environment" : [{ "name" : "DAGSTER_HOME", "value" : "/opt/dagster/dagster_home" }, { "name" : "DAGSTER_POSTGRES_HOST", "value" : aws_db_instance.postgres.address }, { "name" : "DAGSTER_POSTGRES_DB", "value" : var.db_name }],
      "secrets" : [{ "name" : "DAGSTER_POSTGRES_USER", "valueFrom" : aws_secretsmanager_secret.db.arn }, { "name" : "DAGSTER_POSTGRES_PASSWORD", "valueFrom" : aws_secretsmanager_secret.db.arn }],
      "logConfiguration" : { "logDriver" : "awslogs", "options" : { "awslogs-group" : aws_cloudwatch_log_group.this.name, "awslogs-region" : var.region, "awslogs-stream-prefix" : "web" } }
    },
    { "name" : "daemon", "image" : local.image_uri, "essential" : true,
      "command" : ["dagster-daemon", "run"],
      "environment" : [{ "name" : "DAGSTER_HOME", "value" : "/opt/dagster/dagster_home" }, { "name" : "DAGSTER_POSTGRES_HOST", "value" : aws_db_instance.postgres.address }, { "name" : "DAGSTER_POSTGRES_DB", "value" : var.db_name }],
      "secrets" : [{ "name" : "DAGSTER_POSTGRES_USER", "valueFrom" : aws_secretsmanager_secret.db.arn }, { "name" : "DAGSTER_POSTGRES_PASSWORD", "valueFrom" : aws_secretsmanager_secret.db.arn }],
      "logConfiguration" : { "logDriver" : "awslogs", "options" : { "awslogs-group" : aws_cloudwatch_log_group.this.name, "awslogs-region" : var.region, "awslogs-stream-prefix" : "daemon" } }
    }
  ])
  tags = local.tags
}
resource "aws_ecs_service" "dagster" {
  name            = "${local.name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.dagster.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private["a"].id, aws_subnet.private["b"].id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dagit.arn
    container_name   = "web"
    container_port   = 3000
  }
  depends_on = [aws_lb_listener.http]
  tags       = local.tags
}
