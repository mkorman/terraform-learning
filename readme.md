# Learning Terraform
I'm following Yevgeniy Brikman's book **Terraform Up And Running - Writing infrastructure as code**

## Setting up

Create an environment variable with your database password:

    export TF_VAR_db_password="(your DB password)"

Then create the S3 bucket where the backend will be stored (this needs to be created first because all other resources use this bucket as a back-end)

    cd global/s3
    terraform init
    terraform apply

This will create an S3 bucket, where all your backends will be stored

Then run:

    terraform init
    terraform apply

on every folder with a `main.tf` in it to provision those resources

To destroy those resources, run `terraform destroy` in reverse order.
