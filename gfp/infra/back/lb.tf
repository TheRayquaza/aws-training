resource "aws_lb" "backend_lb" {
  name               = "backend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_backend_subnet_a.id, aws_subnet.public_backend_subnet_b.id]
}

resource "aws_lb_target_group" "backend-tg" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 5
  }

  depends_on = [ aws_lb.backend_lb ]

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend-tg.arn
  }

  depends_on = [ aws_lb.backend_lb ]
}

# Inbound to Task from ALB
resource "aws_security_group_rule" "allow_alb_to_backend" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_sg.id
  source_security_group_id = aws_security_group.lb_sg.id
}

# Outbound from ALB to Task
resource "aws_security_group_rule" "allow_alb_outbound" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lb_sg.id
  source_security_group_id = aws_security_group.backend_sg.id
}
