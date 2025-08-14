# environments/dev/variables.tf

# General Configuration
variable "aws_region" {
  description = "AWS region for the dev environment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-project"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "development"
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "number_of_azs" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2
}

variable "additional_security_groups" {
  description = "Additional security groups to create"
  type        = list(object({
    name        = string
    description = string
    ingress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  }))
  default = []
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "EKS node groups configuration"
  type = map(object({
    instance_types         = list(string)
    min_size              = number
    max_size              = number
    desired_size          = number
    disk_size             = number
    disk_type             = string
    disk_iops             = number
    disk_throughput       = number
    ami_type              = string
    capacity_type         = string
    user_data_template_path = optional(string)
    labels                = optional(map(string))
    taints = optional(map(object({
      key    = string
      value  = string
      effect = string
    })))
  }))
  default = {
    general = {
      instance_types      = ["t3.medium"]
      min_size           = 2
      max_size           = 4
      desired_size       = 2
      disk_size          = 30
      disk_type          = "gp3"
      disk_iops          = 3000
      disk_throughput    = 125
      ami_type           = "AL2_x86_64"
      capacity_type      = "ON_DEMAND"
      user_data_template_path = null
      labels = {
        "node-type" = "general"
      }
      taints = null
    }
  }
}

variable "eks_admin_users" {
  description = "List of IAM users to grant admin access to EKS cluster"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_roles" {
  description = "List of IAM roles to add to aws-auth ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "addon_versions" {
  description = "Versions of EKS addons"
  type = object({
    vpc_cni    = string
    coredns    = string
    kube_proxy = string
    ebs_csi    = string
  })
  default = {
    vpc_cni    = "v1.15.1-eksbuild.1"
    coredns    = "v1.10.1-eksbuild.5"
    kube_proxy = "v1.28.2-eksbuild.2"
    ebs_csi    = "v1.24.0-eksbuild.1"
  }
}

variable "domain_name" {
  description = "Domain name for the cluster (used for external DNS and ingress)"
  type        = string
  default     = ""
}

# ArgoCD Configuration
variable "argocd_version" {
  description = "ArgoCD version to install"
  type        = string
  default     = "5.46.8"
}

variable "bootstrap_argocd" {
  description = "Whether to bootstrap ArgoCD with app-of-apps pattern"
  type        = bool
  default     = true
}

variable "gitops_repo_url" {
  description = "GitOps repository URL for ArgoCD"
  type        = string
  default     = ""
}

variable "gitops_repo_branch" {
  description = "GitOps repository branch"
  type        = string
  default     = "main"
}

variable "gitops_repo_path" {
  description = "Path within the GitOps repository"
  type        = string
  default     = "environments/dev"
}

variable "auto_sync_prune" {
  description = "Enable auto sync prune for ArgoCD applications"
  type        = bool
  default     = false
}

variable "auto_sync_self_heal" {
  description = "Enable auto sync self heal for ArgoCD applications"
  type        = bool
  default     = false
}

variable "use_custom_project" {
  description = "Use custom ArgoCD project instead of default"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana, Alertmanager)"
  type        = bool
  default     = false
}

# External DNS Configuration
variable "enable_external_dns" {
  description = "Enable external DNS"
  type        = bool
  default     = false
}