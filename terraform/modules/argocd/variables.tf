# modules/argocd/bootstrap/variables.tf

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "gitops_repo_url" {
  description = "GitOps repository URL"
  type        = string
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

variable "enable_application_set" {
  description = "Enable ApplicationSet for environment-specific deployments"
  type        = bool
  default     = false
}