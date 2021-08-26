provider "aws" {
    region = "eu-west-2"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "mk-terraform-bucket"

    # Prevent accidental deletion of this bucket
    lifecycle {
        prevent_destroy = true
    }

    # Enable versioning
    versioning {
        enabled = true
    }

    # Enable encryption
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}