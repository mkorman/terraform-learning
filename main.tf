provider "aws" {
    region = "eu-west-2"
}

resource "aws_instance" "example" {
    ami = "ami-04f1bbad31585405d"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.web_access.id ]

    user_data = <<-EOF
        #!/bin/bash
        echo "Hello, World" > index.html
        nohup busybox httpd -f -p 8080 &
        EOF

    tags = {
        Name = "created-by-terraform"
    }
}

resource "aws_security_group" "web_access" {
    name = "terraform-example-security-group"   

    ingress = [ {
      from_port = 8080
      to_port = 8080
      cidr_blocks = [ "0.0.0.0/0" ]
      protocol = "tcp"
      description = "Allows connections on port 8080"
      ipv6_cidr_blocks = [  ]
      prefix_list_ids = [  ]
      security_groups = [  ]
      self = false
    } ]
}