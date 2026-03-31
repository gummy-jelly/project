# ── ALB (퍼블릭 서브넷 2개에 배치) ──────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [
    aws_subnet.public_a.id,
    aws_subnet.public_c.id
  ]

  tags = {
    Name    = "${var.project}-alb"
    Project = var.project
  }
}

# ── 대상 그룹 (EC2 4000 포트) ─────────────────────────────────────
resource "aws_lb_target_group" "ec2" {
  name     = "${var.project}-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name    = "${var.project}-tg"
    Project = var.project
  }
}

# ── EC2를 대상 그룹에 등록 ───────────────────────────────────────
resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.ec2.arn
  target_id        = aws_instance.main.id
  port             = 4000
}

# ── 리스너 (HTTP 80 → 대상 그룹) ─────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2.arn
  }
}
