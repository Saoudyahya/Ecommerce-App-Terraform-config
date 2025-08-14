# modules/eks-cluster/variables.tf

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_enabled_log_types" {
  description = "List of log types to enable for EKS cluster"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "node_groups" {
  description = "Node group configurations"
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


variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "Additional tags for the EKS cluster"
  type        = map(string)
  default     = {}
}