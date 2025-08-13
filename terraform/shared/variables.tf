
# shared/variables.tf
# Common variables used across all modules and environments

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "nexus-commerce"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "Platform Team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Engineering"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-central-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1"
    ], var.aws_region)
    error_message = "AWS region must be a valid region."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[4-9]|[3-9][0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.24 or higher."
  }
}

# Networking variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "number_of_azs" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 3

  validation {
    condition     = var.number_of_azs >= 2 && var.number_of_azs <= 6
    error_message = "Number of AZs must be between 2 and 6."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# Node group configuration
variable "node_groups" {
  description = "EKS node group configurations"
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
}

# IAM and access control
variable "eks_admin_users" {
  description = "List of IAM users to give cluster admin access"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_roles" {
  description = "List of IAM roles to add to aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

# Add-on versions
variable "addon_versions" {
  description = "Versions for EKS addons"
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

# ArgoCD configuration
variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.46.8"
}

variable "bootstrap_argocd" {
  description = "Whether to bootstrap ArgoCD with app-of-apps"
  type        = bool
  default     = true
}

variable "gitops_repo_url" {
  description = "GitOps repository URL"
  type        = string
  default     = "https://github.com/ZakariaRek/gitops-repo_ArgoCD"
}

variable "gitops_repo_branch" {
  description = "GitOps repository branch"
  type        = string
  default     = "HEAD"
}

variable "gitops_repo_path" {
  description = "Path to ArgoCD applications in GitOps repo"
  type        = string
  default     = "argocd/applications"
}

variable "auto_sync_prune" {
  description = "Enable auto-sync prune for app-of-apps"
  type        = bool
  default     = true
}

variable "auto_sync_self_heal" {
  description = "Enable auto-sync self-heal for app-of-apps"
  type        = bool
  default     = true
}

variable "use_custom_project" {
  description = "Use custom ArgoCD project instead of default"
  type        = bool
  default     = false
}

# Optional features
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = false
}

variable "enable_external_dns" {
  description = "Enable external DNS"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for external DNS (if enabled)"
  type        = string
  default     = ""
}

# Security groups
variable "additional_security_groups" {
  description = "Additional security groups to create"
  type = list(object({
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
