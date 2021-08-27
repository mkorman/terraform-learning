provider "aws" {
    region = "eu-west-2"
}

terraform {
    backend "s3" {
        bucket = "mk-terraform-bucket"
        key = "stage/services/webserver-cluster/terraform.tfstate"
        region = "eu-west-2"
        encrypt = true
    }
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
}

variable "ssh_port" {
    description = "The port the server will use for ssh"
    type = number
    default = 22
}

output "alb_dns_name" {
  value = aws_alb.example_alb.dns_name
  description = "The domain name of the load balancer"
}

resource "aws_alb" "example_alb" {
    name = "terraformed-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_alb.example_alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_lb_target_group" "asg" {
    name = "terraform-target-group"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_launch_configuration" "example_launch_config" {
    image_id = "ami-04f1bbad31585405d"
    instance_type = "t2.micro"
    security_groups = [ aws_security_group.web_access.id ]
    user_data = data.template_file.user_data.rendered

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example_autoscaling_grop" {
    launch_configuration = aws_launch_configuration.example_launch_config.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
}

resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

resource "aws_security_group" "web_access" {
    name = "terraform-example-security-group"   

    ingress = [ {
      from_port = var.server_port
      to_port = var.server_port
      cidr_blocks = [ "0.0.0.0/0" ]
      protocol = "tcp"
      description = "Allows incoming TCP connections on the configured server port"
      ipv6_cidr_blocks = [  ]
      prefix_list_ids = [  ]
      security_groups = [  ]
      self = false
    },
    {
      from_port = 22
      to_port = 22
      cidr_blocks = [ "0.0.0.0/0" ]
      protocol = "tcp"
      description = "Allows incoming TCP connections for ssh"
      ipv6_cidr_blocks = [  ]
      prefix_list_ids = [  ]
      security_groups = [  ]
      self = false
    }  ]

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "alb" {
    name = "terraform-alb-security-group"   

    ingress = [ {
      from_port = 80
      to_port = 80
      cidr_blocks = [ "0.0.0.0/0" ]
      protocol = "tcp"
      description = "Allows incoming TCP connections on the configured server port"
      ipv6_cidr_blocks = [  ]
      prefix_list_ids = [  ]
      security_groups = [  ]
      self = false
    } ]

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
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
        bucket = "mk-terraform-bucket"
        key = "stage/data-stores/mysql/terraform.tfstate"
        region = "eu-west-2"
    }
}


data "template_file" "user_data" {
    template = file ("user-data.sh")

    vars = {
        server_port = var.server_port
        db_address  = data.terraform_remote_state.db.outputs.address
        db_port  = data.terraform_remote_state.db.outputs.port
    }
}