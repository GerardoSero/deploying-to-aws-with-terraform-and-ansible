resource "aws_lb" "application_lb" {
  provider           = aws.region_main
  name               = "jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  tags = {
    "Name" = "Jenkins-LB"
  }
}

resource "aws_lb_target_group" "app_lb_tg" {
  provider    = aws.region_main
  name        = "app-lb-tg"
  port        = var.webserver_port
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_main.id
  protocol    = "HTTP"
  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = var.webserver_port
    protocol = "HTTP"
    matcher  = "200-299"
  }

  tags = {
    "Name" = "jenkins-target-group"
  }
}

resource "aws_lb_listener" "jenkins_listener_http" {
  provider          = aws.region_main
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_tg.id
  }
}

#Create new listener on tcp/443 HTTPS
resource "aws_lb_listener" "jenkins_listener_https" {
  provider          = aws.region_main
  load_balancer_arn = aws_lb.application_lb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.jenkins_lb_https.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "jenkins_master_attach" {
  provider         = aws.region_main
  target_group_arn = aws_lb_target_group.app_lb_tg.arn
  target_id        = aws_instance.jenkins_main.id
  port             = var.webserver_port
}