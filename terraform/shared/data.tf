
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Get the latest EKS optimized AMI
data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${var.kubernetes_version}/amazon-linux-2/recommended/release_version"
}

# Get latest ArgoCD version if not specified
data "http" "argocd_latest_version" {
  url = "https://api.github.com/repos/argoproj/argo-helm/releases/latest"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  argocd_latest_version = jsondecode(data.http.argocd_latest_version.response_body).tag_name
}

# Common outputs for use by environments
output "common_data" {
  value = {
    aws_account_id = data.aws_caller_identity.current.account_id
    aws_region = data.aws_region.current.name
    availability_zones = data.aws_availability_zones.available.names
    eks_ami_release_version = data.aws_ssm_parameter.eks_ami_release_version.value
    argocd_latest_version = local.argocd_latest_version
  }
}