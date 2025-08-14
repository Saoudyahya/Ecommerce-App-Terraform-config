# modules/argocd/outputs.tf

# ArgoCD Basic Information
output "argocd_namespace" {
  description = "Namespace where ArgoCD is deployed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service_name" {
  description = "ArgoCD server service name"
  value       = "argocd-server"
}

output "argocd_server_port" {
  description = "ArgoCD server port"
  value       = "443"
}

# ArgoCD Access Information
output "argocd_admin_password_command" {
  description = "Command to retrieve ArgoCD admin password"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

output "argocd_server_url_local" {
  description = "Local URL to access ArgoCD server (requires port-forward)"
  value       = "https://localhost:8080"
}

output "argocd_port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = "kubectl port-forward svc/argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name} 8080:443"
}

# ArgoCD Configuration
output "argocd_server_replicas" {
  description = "Number of ArgoCD server replicas"
  value       = var.server_replicas
}

output "argocd_controller_replicas" {
  description = "Number of ArgoCD controller replicas"
  value       = var.controller_replicas
}

output "argocd_repo_server_replicas" {
  description = "Number of ArgoCD repo server replicas"
  value       = var.repo_server_replicas
}

output "argocd_version" {
  description = "ArgoCD version installed"
  value       = var.argocd_version
}

# Bootstrap Information
output "bootstrap_enabled" {
  description = "Whether ArgoCD bootstrap is enabled"
  value       = var.bootstrap_argocd
}

output "gitops_repository_url" {
  description = "GitOps repository URL"
  value       = var.bootstrap_argocd ? var.gitops_repo_url : null
}

output "gitops_repository_branch" {
  description = "GitOps repository branch"
  value       = var.bootstrap_argocd ? var.gitops_repo_branch : null
}

output "gitops_repository_path" {
  description = "GitOps repository path"
  value       = var.bootstrap_argocd ? var.gitops_repo_path : null
}

output "app_of_apps_name" {
  description = "Name of the app-of-apps application"
  value       = var.bootstrap_argocd ? "${var.cluster_name}-app-of-apps" : null
}

# Project Information
output "argocd_project_name" {
  description = "ArgoCD project name"
  value       = var.use_custom_project ? "nexus-commerce" : "default"
}

output "custom_project_enabled" {
  description = "Whether custom ArgoCD project is enabled"
  value       = var.use_custom_project
}

# Sync Policy Information
output "auto_sync_configuration" {
  description = "Auto sync configuration"
  value = {
    prune     = var.auto_sync_prune
    self_heal = var.auto_sync_self_heal
    enabled   = var.auto_sync_prune || var.auto_sync_self_heal
  }
}

# High Availability Configuration
output "ha_configuration" {
  description = "High availability configuration"
  value = {
    server_replicas    = var.server_replicas
    controller_replicas = var.controller_replicas
    repo_server_replicas = var.repo_server_replicas
    redis_ha_enabled   = var.enable_redis_ha
    environment        = var.environment
  }
}

# Resource Configuration
output "resource_configuration" {
  description = "Resource configuration for ArgoCD components"
  value = {
    server_resources = var.server_resources
    controller_resources = var.controller_resources
    repo_server_resources = var.repo_server_resources
  }
  sensitive = true
}

# Storage Configuration
output "storage_configuration" {
  description = "Storage configuration for ArgoCD"
  value = {
    storage_classes_created = var.create_storage_classes
    fast_storage_class     = var.create_storage_classes ? "argocd-fast" : null
    network_policies_enabled = var.enable_network_policies
  }
}

# Monitoring and Observability
output "metrics_configuration" {
  description = "Metrics and monitoring configuration"
  value = {
    metrics_enabled = var.enable_metrics
    server_metrics  = "http://argocd-server-metrics.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8083/metrics"
    controller_metrics = "http://argocd-metrics.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8082/metrics"
    repo_server_metrics = "http://argocd-repo-server.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8084/metrics"
  }
}

# Useful Commands
output "useful_commands" {
  description = "Useful commands for ArgoCD management"
  value = {
    get_admin_password    = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    port_forward_server   = "kubectl port-forward svc/argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name} 8080:443"
    get_applications      = "kubectl get applications -n ${kubernetes_namespace.argocd.metadata[0].name}"
    get_app_projects      = "kubectl get appprojects -n ${kubernetes_namespace.argocd.metadata[0].name}"
    check_server_status   = "kubectl get pods -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/component=server"
    check_controller_status = "kubectl get pods -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/component=application-controller"
    check_repo_server_status = "kubectl get pods -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/component=repo-server"
    get_all_resources     = "kubectl get all -n ${kubernetes_namespace.argocd.metadata[0].name}"
  }
}

# ArgoCD CLI Information
output "argocd_cli_commands" {
  description = "ArgoCD CLI commands for interaction"
  value = {
    login_command    = "argocd login localhost:8080 --username admin --password $(kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d) --insecure"
    list_apps        = "argocd app list"
    sync_app         = "argocd app sync <app-name>"
    get_app_status   = "argocd app get <app-name>"
    app_history      = "argocd app history <app-name>"
    app_diff         = "argocd app diff <app-name>"
  }
}

# Security Information
output "security_configuration" {
  description = "Security configuration for ArgoCD"
  value = {
    namespace_isolation   = "ArgoCD deployed in dedicated namespace"
    rbac_enabled         = "RBAC enabled with custom project configuration"
    network_policies     = var.enable_network_policies ? "Enabled" : "Disabled"
    service_accounts     = "Dedicated service accounts for each component"
    tls_enabled          = "TLS enabled for all communications"
  }
}

# Backup and Recovery
output "backup_recovery_notes" {
  description = "Backup and recovery information"
  value = {
    gitops_backup       = "All configurations stored in Git repository"
    cluster_state       = "Applications and configuration recoverable via GitOps"
    secret_management   = "Consider external secret management for production"
    disaster_recovery   = "Full recovery possible by re-running Terraform and ArgoCD sync"
  }
}

# Environment-specific Configuration
output "environment_configuration" {
  description = "Environment-specific configuration summary"
  value = {
    environment          = var.environment
    cluster_name        = var.cluster_name
    production_ready    = var.environment == "prod" ? "Yes - HA configuration enabled" : "Development/Staging configuration"
    auto_sync_policy    = var.auto_sync_prune || var.auto_sync_self_heal ? "Enabled" : "Manual sync required"
    git_branch          = var.gitops_repo_branch
    custom_project      = var.use_custom_project ? "nexus-commerce project" : "default project"
  }
}