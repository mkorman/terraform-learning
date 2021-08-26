provider "aws" {
    region = "eu-west-2"
}

terraform {
    backend "s3" {
        bucket = "mk-terraform-bucket"
        key = "stage/data-stores/mysql/terraform.tfstate"
        region = "eu-west-2"
        encrypt = true
    }
}

resource "aws_db_instance" "terraformed-db" {
    identifier_prefix = "terraform-up-and-running"
    engine            = "mysql"
    allocated_storage = 10
    instance_class    = "db.t2.micro"
    name              = "example_database"
    username          = "admin"

    password = var.db_password
}