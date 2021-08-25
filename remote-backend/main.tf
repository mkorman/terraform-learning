provider "aws" {
    region = "eu-west-2"
}

terraform {
    backend "s3" {
        bucket = "mk-terraform-bucket"
        key = "global/s3/terraform.tfstate"
        region = "eu-west-2"
        dynamodb_table = "mk-terraform-up-and-running-locks"
        encrypt = true
    }
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

resource "aws_dynamodb_table" "terraform_locks" {
    name = "mk-terraform-up-and-running-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

output "s3_bucket_arn" {
    value = aws_s3_bucket.terraform_state.arn
    description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.terraform_locks.name
    description = "The name of the DynamoDB table"
}