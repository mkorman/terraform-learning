provider "aws" {
    region = "eu-west-2"
}

resource "aws_instance" "example" {
    ami = "ami-04f1bbad31585405d"
    instance_type = "t2.micro"

    tags = {
        Name = "created-by-terraform"
    }
}