# shared/locals.tf
# Common local values used across all environments

locals {
  # Common naming conventions
  naming = {
    separator = "-"
    prefix    = var.project_name
  }

  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Repository  = "gitops-repo_ArgoCD"
    Team        = "Platform"
  }

  # Environment-specific resource sizing
  resource_sizing = {
    dev = {
      instance_classes = {
        small  = ["t3.small", "t3.medium"]
        medium = ["t3.large", "t3.xlarge"]
        large  = ["t3.xlarge", "t3.2xlarge"]
      }
      storage = {
        small  = 20
        medium = 50
        large  = 100
      }
      replicas = {
        min = 1
        max = 3
        desired = 1
      }
    }
    stage = {
      instance_classes = {
        small  = ["t3.medium", "t3.large"]
        medium = ["t3.xlarge", "t3.2xlarge"]
        large  = ["t3.2xlarge", "c5.2xlarge"]
      }
      storage = {
        small  = 50
        medium = 100
        large  = 200
      }
      replicas = {
        min = 2
        max = 6
        desired = 2
      }
    }
    prod = {
      instance_classes = {
        small  = ["t3.large", "t3.xlarge"]
        medium = ["t3.2xlarge", "c5.2xlarge"]
        large  = ["c5.2xlarge", "c5.4xlarge"]
      }
      storage = {
        small  = 100
        medium = 200
        large  = 500
      }
      replicas = {
        min = 3
        max = 15
        desired = 5
      }
    }
  }

  # Network CIDR allocations
  network_cidrs = {
    dev = {
      vpc = "10.0.0.0/16"
      private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    }
    stage = {
      vpc = "10.1.0.0/16"
      private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
      public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
    }
    prod = {
      vpc = "10.2.0.0/16"
      private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
      public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]
    }
  }

  # Security configurations per environment
  security_settings = {
    dev = {
      enable_flow_logs = false
      enable_vpc_endpoints = false
      cluster_endpoint_public_access = true
      cluster_logging = ["api", "audit"]
      backup_retention_days = 7
    }
    stage = {
      enable_flow_logs = true
      enable_vpc_endpoints = false
      cluster_endpoint_public_access = true
      cluster_logging = ["api", "audit", "authenticator"]
      backup_retention_days = 14
    }
    prod = {
      enable_flow_logs = true
      enable_vpc_endpoints = true
      cluster_endpoint_public_access = true  # Can be false for private clusters
      cluster_logging = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
      backup_retention_days = 30
    }
  }

  # ArgoCD configuration per environment
  argocd_settings = {
    dev = {
      server_replicas = 1
      controller_replicas = 1
      repo_server_replicas = 1
      auto_sync_prune = true
      auto_sync_self_heal = true
      git_branch = "develop"
    }
    stage = {
      server_replicas = 2
      controller_replicas = 1
      repo_server_replicas = 2
      auto_sync_prune = true
      auto_sync_self_heal = true
      git_branch = "release"
    }
    prod = {
      server_replicas = 3
      controller_replicas = 2
      repo_server_replicas = 3
      auto_sync_prune = false  # Manual approval for production
      auto_sync_self_heal = false
      git_branch = "main"
    }
  }

  # Monitoring and observability settings
  monitoring_settings = {
    dev = {
      enabled = false
      prometheus_retention = "7d"
      prometheus_storage = "20Gi"
      grafana_storage = "5Gi"
      log_retention_days = 7
    }
    stage = {
      enabled = true
      prometheus_retention = "15d"
      prometheus_storage = "50Gi"
      grafana_storage = "10Gi"
      log_retention_days = 14
    }
    prod = {
      enabled = true
      prometheus_retention = "30d"
      prometheus_storage = "100Gi"
      grafana_storage = "20Gi"
      log_retention_days = 30
    }
  }
}

# -------------------------------------------------------------------

# -------------------------------------------------------------------

# shared/data.tf
# Common data sources used across environments
