# -------------------------------------------------------------------

# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "nexus-commerce-terraform-state-prod"
    key            = "eks-cluster/prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "nexus-commerce-terraform-locks-prod"

    # Enable versioning and prevent accidental deletion
    versioning = true

    # Additional production safeguards
    force_destroy       = false
    object_lock_enabled = true
  }
}