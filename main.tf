provider "aws" {
    region = "eu-west-2"
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of our EC2 instance"
}

resource "aws_instance" "example" {
    ami = "ami-04f1bbad31585405d"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.web_access.id ]

    user_data = <<EOF
        #!/bin/bash
        echo "Hello, World" > index.html
        nohup busybox httpd -f -p ${var.server_port} &
        EOF

    tags = {
        Name = "created-by-terraform"
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
    } ]
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}