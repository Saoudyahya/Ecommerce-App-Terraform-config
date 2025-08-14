# environments/stage/outputs.tf

# General Information
output "environment" {
  description = "Environment name"
  value       = local.environment
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# VPC and Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnets
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value       = module.networking.nat_public_ips
}

# EKS Cluster Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks_cluster.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks_cluster.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks_cluster.cluster_version
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks_cluster.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.eks_cluster.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks_cluster.cluster_id}"
}

# Node Groups
output "node_groups" {
  description = "EKS managed node groups"
  value       = module.eks_cluster.eks_managed_node_groups
  sensitive   = true
}

# ArgoCD Information
output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = var.domain_name != "" ? "https://argocd.${var.domain_name}" : "https://localhost:8080 (after: kubectl port-forward svc/argocd-server -n argocd 8080:443)"
}

output "argocd_admin_password" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

# GitOps Configuration
output "gitops_repo_url" {
  description = "GitOps repository URL"
  value       = var.gitops_repo_url
}

output "gitops_repo_branch" {
  description = "GitOps repository branch"
  value       = var.gitops_repo_branch
}

# DNS and Domain Information
output "domain_name" {
  description = "Domain name (if configured)"
  value       = var.domain_name != "" ? var.domain_name : "Not configured"
}

# Monitoring Information
output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = var.enable_monitoring ? (var.domain_name != "" ? "https://prometheus.${var.domain_name}" : "http://localhost:9090 (after: kubectl port-forward svc/prometheus-server -n monitoring 9090:80)") : "Monitoring not enabled"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = var.enable_monitoring ? (var.domain_name != "" ? "https://grafana.${var.domain_name}" : "http://localhost:3000 (after: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80)") : "Monitoring not enabled"
}

# Load Balancer Information
output "load_balancer_dns" {
  description = "Load balancer DNS name (when available)"
  value       = "Check with: kubectl get svc -n ingress-nginx ingress-nginx-controller"
}

# Security Groups
output "additional_security_group_ids" {
  description = "Additional security group IDs"
  value       = module.networking.additional_security_group_ids
}

# High Availability Configuration
output "ha_configuration" {
  description = "High availability configuration for staging"
  value = {
    nat_gateways     = "Multi-AZ NAT Gateways for redundancy"
    availability_zones = "3 AZs for high availability"
    node_groups      = "Multi-AZ node groups with auto-scaling"
    argocd_replicas  = "2 ArgoCD server replicas"
    flow_logs        = "VPC Flow Logs enabled"
  }
}

# Resource Sizing
output "resource_sizing" {
  description = "Resource sizing for staging environment"
  value = {
    node_instance_types = "t3.large to t3.2xlarge"
    storage_type       = "gp3 with optimized IOPS"
    monitoring_retention = var.enable_monitoring ? "15 days" : "Not enabled"
    backup_retention   = "14 days"
  }
}

# Useful Commands
output "useful_commands" {
  description = "Useful commands for staging environment"
  value = {
    get_nodes           = "kubectl get nodes"
    get_pods_all        = "kubectl get pods -A"
    get_services        = "kubectl get svc -A"
    argocd_port_forward = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
    prometheus_port_forward = var.enable_monitoring ? "kubectl port-forward svc/prometheus-server -n monitoring 9090:80" : "Monitoring not enabled"
    grafana_port_forward = var.enable_monitoring ? "kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80" : "Monitoring not enabled"
    get_argocd_password = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    get_ingress         = "kubectl get ingress -A"
  }
}

# Performance Optimization
output "performance_notes" {
  description = "Performance optimization notes for staging"
  value = {
    node_scaling    = "Enabled cluster autoscaler for dynamic scaling"
    storage_performance = "Using gp3 volumes with optimized IOPS and throughput"
    network_performance = "Multiple AZs with dedicated subnets"
    monitoring_stack = var.enable_monitoring ? "Full monitoring stack enabled" : "Monitoring disabled"
  }
}