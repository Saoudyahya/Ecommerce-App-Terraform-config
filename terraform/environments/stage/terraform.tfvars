# environments/stage/terraform.tfvars

# Basic Configuration
aws_region      = "us-west-2"
project_name    = "nexus-commerce"
owner           = "Platform Team"
cost_center     = "Engineering"
kubernetes_version = "1.28"

# Network Configuration - Staging Environment
vpc_cidr = "10.1.0.0/16"
private_subnet_cidrs = [
  "10.1.1.0/24",
  "10.1.2.0/24",
  "10.1.3.0/24"
]
public_subnet_cidrs = [
  "10.1.101.0/24",
  "10.1.102.0/24",
  "10.1.103.0/24"
]

# Networking settings for staging (production-like)
enable_nat_gateway = true
number_of_azs     = 3  # Full 3 AZs for better availability

# Node Group Configuration - Staging
node_groups = {
  system = {
    instance_types      = ["t3.large"]  # Larger than dev
    min_size           = 2
    max_size           = 5
    desired_size       = 2
    disk_size          = 50
    disk_type          = "gp3"
    disk_iops          = 3000
    disk_throughput    = 150
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"  # On-demand for critical components
    user_data_template_path = null
    labels = {
      "node-type" = "system"
    }
    taints = {
      dedicated = {
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }
  }

  applications = {
    instance_types      = ["t3.xlarge", "t3.2xlarge"]  # Mixed instances
    min_size           = 2
    max_size           = 8
    desired_size       = 3
    disk_size          = 80
    disk_type          = "gp3"
    disk_iops          = 3000
    disk_throughput    = 200
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"  # On-demand for staging stability
    user_data_template_path = null
    labels = {
      "node-type" = "applications"
    }
    taints = null
  }

  data = {
    instance_types      = ["r5.xlarge"]  # Consistent memory-optimized
    min_size           = 1
    max_size           = 4
    desired_size       = 2
    disk_size          = 150
    disk_type          = "gp3"
    disk_iops          = 4000
    disk_throughput    = 250
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"  # On-demand for data consistency
    user_data_template_path = null
    labels = {
      "node-type" = "data"
    }
    taints = null
  }
}

# EKS Admin Users - Add your IAM users here
eks_admin_users = [
  # {
  #   userarn  = "arn:aws:iam::123456789012:user/your-stage-user"
  #   username = "your-stage-user"
  #   groups   = ["system:masters"]
  # }
]

aws_auth_roles = []

# EKS Addon Versions (same as dev for consistency)
addon_versions = {
  vpc_cni    = "v1.15.1-eksbuild.1"
  coredns    = "v1.10.1-eksbuild.5"
  kube_proxy = "v1.28.2-eksbuild.2"
  ebs_csi    = "v1.24.0-eksbuild.1"
}

# ArgoCD Configuration
argocd_version = "5.46.8"

# ArgoCD Bootstrap Configuration
bootstrap_argocd     = true
gitops_repo_url      = "https://github.com/ZakariaRek/gitops-repo_ArgoCD"
gitops_repo_branch   = "release"  # Use release branch for staging
gitops_repo_path     = "argocd/applications"
auto_sync_prune      = true
auto_sync_self_heal  = true
use_custom_project   = true  # Use custom project for better organization

# Optional Features - Staging
enable_monitoring        = true   # Enable monitoring for staging
enable_external_dns     = false   # Can be enabled if domain is available
domain_name             = ""      # "staging.nexus-commerce.com"

# Security Groups (more restrictive than dev)
additional_security_groups = [
  {
    name        = "stage-restricted"
    description = "Restricted security group for staging"
    ingress_rules = [
      {
        description = "HTTPS from VPC"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.1.0.0/16"]  # Only from VPC
      },
      {
        description = "HTTP from VPC (internal)"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.1.0.0/16"]
      }
    ]
    egress_rules = [
      {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  },
  {
    name        = "stage-alb"
    description = "ALB security group for staging"
    ingress_rules = [
      {
        description = "HTTPS from internet"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        description = "HTTP redirect"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
    egress_rules = [
      {
        description = "All outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
]