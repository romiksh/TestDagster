resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public["a"].id, aws_subnet.public["b"].id]
  tags               = local.tags
}
resource "aws_lb_target_group" "dagit" {
  name        = "${local.name}-tg"
  port        = local.dagit_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id
  health_check {
    path = "/server_info"
    port = local.dagit_port
  }
  tags = local.tags
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dagit.arn
  }
}
