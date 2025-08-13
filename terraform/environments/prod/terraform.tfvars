# environments/prod/terraform.tfvars

# Basic Configuration
aws_region      = "us-west-2"
project_name    = "nexus-commerce"
owner           = "Platform Team"
cost_center     = "Engineering"
kubernetes_version = "1.28"

# Network Configuration - Production Environment
vpc_cidr = "10.2.0.0/16"
private_subnet_cidrs = [
  "10.2.1.0/24",
  "10.2.2.0/24",
  "10.2.3.0/24"
]
public_subnet_cidrs = [
  "10.2.101.0/24",
  "10.2.102.0/24",
  "10.2.103.0/24"
]

# Networking settings for production (high availability)
enable_nat_gateway = true
number_of_azs     = 3  # Full 3 AZs for maximum availability

# Node Group Configuration - Production
node_groups = {
  system = {
    instance_types      = ["t3.xlarge"]  # Large instances for control plane
    min_size           = 3              # High availability
    max_size           = 6
    desired_size       = 3
    disk_size          = 100
    disk_type          = "gp3"
    disk_iops          = 4000
    disk_throughput    = 250
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"    # Always on-demand for production
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
    instance_types      = ["t3.2xlarge", "c5.2xlarge"]  # High-performance instances
    min_size           = 3              # Minimum for availability
    max_size           = 15             # High scaling capacity
    desired_size       = 5
    disk_size          = 100
    disk_type          = "gp3"
    disk_iops          = 4000
    disk_throughput    = 500
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"    # On-demand for production reliability
    user_data_template_path = null
    labels = {
      "node-type" = "applications"
    }
    taints = null
  }

  data = {
    instance_types      = ["r5.2xlarge", "r5.4xlarge"]  # Large memory-optimized
    min_size           = 2              # Always available
    max_size           = 8
    desired_size       = 3
    disk_size          = 500            # Large storage for production data
    disk_type          = "gp3"
    disk_iops          = 16000          # High IOPS for database workloads
    disk_throughput    = 1000
    ami_type           = "AL2_x86_64"
    capacity_type      = "ON_DEMAND"    # Critical data nodes on-demand
    user_data_template_path = null
    labels = {
      "node-type" = "data"
      "performance" = "high"
    }
    taints = {
      data_workload = {
        key    = "data-workload"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }
  }

  # Additional node group for compute-intensive workloads
  compute = {
    instance_types      = ["c5.4xlarge", "c5.8xlarge"]  # Compute-optimized
    min_size           = 0              # Can scale to zero when not needed
    max_size           = 10
    desired_size       = 0
    disk_size          = 100
    disk_type          = "gp3"
    disk_iops          = 4000
    disk_throughput    = 500
    ami_type           = "AL2_x86_64"
    capacity_type      = "SPOT"         # Use spot for cost optimization on batch workloads
    user_data_template_path = null
    labels = {
      "node-type" = "compute"
      "workload-type" = "batch"
    }
    taints = {
      compute_workload = {
        key    = "compute-workload"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }
  }
}

# EKS Admin Users - Production access should be limited
eks_admin_users = [
  # {
  #   userarn  = "arn:aws:iam::123456789012:user/prod-admin-1"
  #   username = "prod-admin-1"
  #   groups   = ["system:masters"]
  # },
  # {
  #   userarn  = "arn:aws:iam::123456789012:user/prod-admin-2"
  #   username = "prod-admin-2"
  #   groups   = ["system:masters"]
  # }
]

aws_auth_roles = [
  # {
  #   rolearn  = "arn:aws:iam::123456789012:role/ProductionEKSAdminRole"
  #   username = "prod-admin-role"
  #   groups   = ["system:masters"]
  # }
]

# EKS Addon Versions (latest stable for production)
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
gitops_repo_branch   = "main"        # Use main branch for production
gitops_repo_path     = "argocd/applications"
auto_sync_prune      = false         # Manual approval for production changes
auto_sync_self_heal  = false         # Manual intervention for production
use_custom_project   = true          # Use custom project for better governance

# Optional Features - Production
enable_monitoring        = true      # Full monitoring stack
enable_external_dns     = true       # Enable external DNS for production
domain_name             = "nexus-commerce.com"

# Security Groups (highly restrictive for production)
additional_security_groups = [
  {
    name        = "prod-database"
    description = "Database security group for production"
    ingress_rules = [
      {
        description = "Database access from app nodes only"
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]  # Only private subnets
      },
      {
        description = "Redis access from app nodes"
        from_port   = 6379
        to_port     = 6379
        protocol    = "tcp"
        cidr_blocks = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
      }
    ]
    egress_rules = [
      {
        description = "Limited outbound for updates"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  },
  {
    name        = "prod-alb"
    description = "Production ALB security group"
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
        description = "To application nodes"
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["10.2.0.0/16"]
      }
    ]
  },
  {
    name        = "prod-internal"
    description = "Internal services communication"
    ingress_rules = [
      {
        description = "Internal service mesh communication"
        from_port   = 15000
        to_port     = 15999
        protocol    = "tcp"
        cidr_blocks = ["10.2.0.0/16"]
      },
      {
        description = "Application ports"
        from_port   = 8000
        to_port     = 8999
        protocol    = "tcp"
        cidr_blocks = ["10.2.0.0/16"]
      }
    ]
    egress_rules = [
      {
        description = "All outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
]