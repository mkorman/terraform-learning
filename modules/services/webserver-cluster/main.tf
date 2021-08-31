terraform {
  backend "s3" {
    bucket  = var.db_remote_state_bucket
    key     = var.db_remote_state_key
    region  = "eu-west-2"
    encrypt = true
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "ssh_port" {
  description = "The port the server will use for ssh"
  type        = number
  default     = 22
}

locals {
  ssh_port     = 22
  http_port    = 80
  any_port     = 0
  any_protocol = -1
  tcp_protocol = "tcp"
  http_protocol = "HTTP"
  all_ips       = ["0.0.0.0/0"]
}

resource "aws_alb" "example_alb" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.example_alb.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name     = "terraform-target-group"
  port     = var.server_port
  protocol = local.http_protocol
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = local.http_protocol
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_launch_configuration" "example_launch_config" {
  image_id        = "ami-04f1bbad31585405d"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.alb.id]
  user_data       = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example_autoscaling_grop" {
  launch_configuration = aws_launch_configuration.example_launch_config.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id
    from_port        = local.http_port
    to_port          = local.http_port
    cidr_blocks      = local.all_ips
    protocol         = local.tcp_protocol
    description      = "Allows incoming TCP connections on the configured server port"
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id
    from_port        = local.ssh_port
    to_port          = local.ssh_port
    cidr_blocks      = local.all_ips
    protocol         = local.tcp_protocol
    description      = "Allows incoming TCP connections on the configured server port"
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
}

resource "aws_security_group_rule" "allow_all_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id
    from_port   = local.any_port
    to_port     = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Read data from the Terraform backend from the DB
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "eu-west-2"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}