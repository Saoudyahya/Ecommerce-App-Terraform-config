
# environments/stage/backend.tf
terraform {
  backend "s3" {
    bucket         = "nexus-commerce-terraform-state-stage"
    key            = "eks-cluster/stage/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "nexus-commerce-terraform-locks-stage"

    # Enable versioning and prevent accidental deletion
    versioning = true
  }
}

