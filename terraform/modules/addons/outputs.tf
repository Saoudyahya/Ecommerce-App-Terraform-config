# modules/addons/outputs.tf

# AWS Load Balancer Controller
output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = var.enable_aws_load_balancer_controller ? module.aws_load_balancer_controller_irsa_role[0].iam_role_arn : null
}

output "aws_load_balancer_controller_namespace" {
  description = "Namespace where AWS Load Balancer Controller is deployed"
  value       = var.enable_aws_load_balancer_controller ? "kube-system" : null
}

output "aws_load_balancer_controller_service_account" {
  description = "Service account name for AWS Load Balancer Controller"
  value       = var.enable_aws_load_balancer_controller ? "aws-load-balancer-controller" : null
}

# Cluster Autoscaler
output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = var.enable_cluster_autoscaler ? module.cluster_autoscaler_irsa_role[0].iam_role_arn : null
}

output "cluster_autoscaler_namespace" {
  description = "Namespace where Cluster Autoscaler is deployed"
  value       = var.enable_cluster_autoscaler ? "kube-system" : null
}

output "cluster_autoscaler_service_account" {
  description = "Service account name for Cluster Autoscaler"
  value       = var.enable_cluster_autoscaler ? "cluster-autoscaler" : null
}

# External DNS
output "external_dns_role_arn" {
  description = "IAM role ARN for External DNS"
  value       = var.enable_external_dns && var.domain_name != "" ? module.external_dns_irsa_role[0].iam_role_arn : null
}

output "external_dns_namespace" {
  description = "Namespace where External DNS is deployed"
  value       = var.enable_external_dns && var.domain_name != "" ? "kube-system" : null
}

output "external_dns_service_account" {
  description = "Service account name for External DNS"
  value       = var.enable_external_dns && var.domain_name != "" ? "external-dns" : null
}

# Metrics Server
output "metrics_server_namespace" {
  description = "Namespace where Metrics Server is deployed"
  value       = var.enable_metrics_server ? "kube-system" : null
}

output "metrics_server_enabled" {
  description = "Whether Metrics Server is enabled"
  value       = var.enable_metrics_server
}

# Cert Manager
output "cert_manager_role_arn" {
  description = "IAM role ARN for Cert Manager"
  value       = var.enable_cert_manager ? module.cert_manager_irsa_role[0].iam_role_arn : null
}

output "cert_manager_namespace" {
  description = "Namespace where Cert Manager is deployed"
  value       = var.enable_cert_manager ? "cert-manager" : null
}

output "cert_manager_service_account" {
  description = "Service account name for Cert Manager"
  value       = var.enable_cert_manager ? "cert-manager" : null
}

# Ingress NGINX
output "ingress_nginx_namespace" {
  description = "Namespace where Ingress NGINX is deployed"
  value       = var.enable_ingress_nginx ? "ingress-nginx" : null
}

output "ingress_nginx_enabled" {
  description = "Whether Ingress NGINX Controller is enabled"
  value       = var.enable_ingress_nginx
}

output "ingress_nginx_service_name" {
  description = "Service name for Ingress NGINX Controller"
  value       = var.enable_ingress_nginx ? "ingress-nginx-controller" : null
}

# Summary of enabled addons
output "enabled_addons" {
  description = "List of enabled addons"
  value = {
    aws_load_balancer_controller = var.enable_aws_load_balancer_controller
    cluster_autoscaler          = var.enable_cluster_autoscaler
    external_dns                = var.enable_external_dns && var.domain_name != ""
    metrics_server              = var.enable_metrics_server
    cert_manager               = var.enable_cert_manager
    ingress_nginx              = var.enable_ingress_nginx
  }
}

# Service account annotations for IRSA
output "irsa_role_annotations" {
  description = "IRSA role annotations for enabled services"
  value = {
    aws_load_balancer_controller = var.enable_aws_load_balancer_controller ? {
      "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_irsa_role[0].iam_role_arn
    } : {}
    cluster_autoscaler = var.enable_cluster_autoscaler ? {
      "eks.amazonaws.com/role-arn" = module.cluster_autoscaler_irsa_role[0].iam_role_arn
    } : {}
    external_dns = var.enable_external_dns && var.domain_name != "" ? {
      "eks.amazonaws.com/role-arn" = module.external_dns_irsa_role[0].iam_role_arn
    } : {}
    cert_manager = var.enable_cert_manager ? {
      "eks.amazonaws.com/role-arn" = module.cert_manager_irsa_role[0].iam_role_arn
    } : {}
  }
}

# Useful commands for addon management
output "useful_commands" {
  description = "Useful commands for managing addons"
  value = {
    check_aws_load_balancer_controller = var.enable_aws_load_balancer_controller ? "kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller" : "Not enabled"
    check_cluster_autoscaler          = var.enable_cluster_autoscaler ? "kubectl get pods -n kube-system -l app.kubernetes.io/name=cluster-autoscaler" : "Not enabled"
    check_external_dns                = var.enable_external_dns && var.domain_name != "" ? "kubectl get pods -n kube-system -l app.kubernetes.io/name=external-dns" : "Not enabled"
    check_metrics_server              = var.enable_metrics_server ? "kubectl get pods -n kube-system -l k8s-app=metrics-server" : "Not enabled"
    check_cert_manager               = var.enable_cert_manager ? "kubectl get pods -n cert-manager" : "Not enabled"
    check_ingress_nginx              = var.enable_ingress_nginx ? "kubectl get pods -n ingress-nginx" : "Not enabled"
    get_load_balancer_service        = var.enable_ingress_nginx ? "kubectl get svc -n ingress-nginx ingress-nginx-controller" : (var.enable_aws_load_balancer_controller ? "kubectl get svc -A -l app.kubernetes.io/name=aws-load-balancer-controller" : "No load balancer enabled")
  }
}

# Configuration notes
output "configuration_notes" {
  description = "Configuration notes for enabled addons"
  value = {
    environment                       = var.environment
    aws_load_balancer_controller_replicas = var.enable_aws_load_balancer_controller ? (var.environment == "prod" ? "2" : "1") : "Not enabled"
    cluster_autoscaler_scale_down_delay  = var.enable_cluster_autoscaler ? (var.environment == "prod" ? "10m" : "2m") : "Not enabled"
    external_dns_policy              = var.enable_external_dns && var.domain_name != "" ? (var.environment == "prod" ? "upsert-only" : "sync") : "Not enabled"
    metrics_server_replicas          = var.enable_metrics_server ? (var.environment == "prod" ? "2" : "1") : "Not enabled"
    cert_manager_replicas            = var.enable_cert_manager ? (var.environment == "prod" ? "2" : "1") : "Not enabled"
    ingress_nginx_replicas           = var.enable_ingress_nginx ? (var.environment == "prod" ? "3" : "2") : "Not enabled"
  }
}