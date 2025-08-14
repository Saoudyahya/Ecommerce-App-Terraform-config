# modules/argocd/variables.tf

# Basic Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
  default     = ""
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ArgoCD Version and Image Configuration
variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.46.8"
}

variable "argocd_image_tag" {
  description = "ArgoCD image tag"
  type        = string
  default     = ""
}

# Server Configuration
variable "server_replicas" {
  description = "Number of ArgoCD server replicas"
  type        = number
  default     = 1
}

variable "server_service_type" {
  description = "ArgoCD server service type"
  type        = string
  default     = "ClusterIP"
}

variable "server_service_annotations" {
  description = "Annotations for ArgoCD server service"
  type        = map(string)
  default     = {}
}

variable "server_extra_args" {
  description = "Extra arguments for ArgoCD server"
  type        = list(string)
  default     = []
}

variable "server_config" {
  description = "ArgoCD server configuration"
  type        = map(string)
  default     = {}
}

variable "server_resources" {
  description = "Resource requests and limits for ArgoCD server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

# Controller Configuration
variable "controller_replicas" {
  description = "Number of ArgoCD controller replicas"
  type        = number
  default     = 1
}

variable "controller_resources" {
  description = "Resource requests and limits for ArgoCD controller"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }
}

# Repo Server Configuration
variable "repo_server_replicas" {
  description = "Number of ArgoCD repo server replicas"
  type        = number
  default     = 1
}

variable "repo_server_resources" {
  description = "Resource requests and limits for ArgoCD repo server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "1Gi"
    }
  }
}

# Feature Toggles
variable "enable_application_set" {
  description = "Enable ApplicationSet controller"
  type        = bool
  default     = true
}

variable "enable_notifications" {
  description = "Enable ArgoCD notifications"
  type        = bool
  default     = false
}

variable "enable_metrics" {
  description = "Enable ArgoCD metrics"
  type        = bool
  default     = true
}

variable "enable_redis_ha" {
  description = "Enable Redis high availability"
  type        = bool
  default     = false
}

# Bootstrap Configuration
variable "bootstrap_argocd" {
  description = "Whether to bootstrap ArgoCD with app-of-apps pattern"
  type        = bool
  default     = true
}

variable "bootstrap_wait_time" {
  description = "Time to wait for ArgoCD to be ready before bootstrapping"
  type        = string
  default     = "60s"
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

# Storage Configuration
variable "create_storage_classes" {
  description = "Create custom storage classes for ArgoCD"
  type        = bool
  default     = false
}

# Network Security
variable "enable_network_policies" {
  description = "Enable Kubernetes network policies for ArgoCD"
  type        = bool
  default     = false
}