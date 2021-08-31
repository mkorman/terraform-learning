provider "aws" {
    region = "eu-west-2"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name           = "webservers-staging"
    db_remote_state_bucket = "mk-terraform-bucket"
    db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"
    instance_type          = "t2.micro"
    min_size               = 2
    max_size               = 2
}