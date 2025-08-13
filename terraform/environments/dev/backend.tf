
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "nexus-commerce-terraform-state-dev"
    key            = "eks-cluster/dev/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "nexus-commerce-terraform-locks-dev"

    # Enable versioning and prevent accidental deletion
    versioning = true
  }
}

# -------------------------------------------------------------------
