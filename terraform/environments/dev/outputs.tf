# environments/dev/outputs.tf

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
  description = "ArgoCD server URL (kubectl port-forward required)"
  value       = "https://localhost:8080 (after: kubectl port-forward svc/argocd-server -n argocd 8080:443)"
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

# Monitoring (if enabled)
output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "prometheus_url" {
  description = "Prometheus URL (kubectl port-forward required)"
  value       = var.enable_monitoring ? "http://localhost:9090 (after: kubectl port-forward svc/prometheus-server -n monitoring 9090:80)" : "Monitoring not enabled"
}

output "grafana_url" {
  description = "Grafana URL (kubectl port-forward required)"
  value       = var.enable_monitoring ? "http://localhost:3000 (after: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80)" : "Monitoring not enabled"
}

# Security Groups
output "additional_security_group_ids" {
  description = "Additional security group IDs"
  value       = module.networking.additional_security_group_ids
}

# Cost Optimization Notes
output "cost_optimization_notes" {
  description = "Cost optimization notes for development environment"
  value = {
    nat_gateway   = "Single NAT Gateway used for cost optimization"
    node_groups   = "Using smaller instance types and spot instances where appropriate"
    monitoring    = var.enable_monitoring ? "Monitoring enabled" : "Monitoring disabled for cost savings"
    flow_logs     = "VPC Flow Logs disabled for cost savings"
    vpc_endpoints = "VPC Endpoints disabled for cost savings"
  }
}

# Quick Access Commands
output "useful_commands" {
  description = "Useful commands for development environment"
  value = {
    get_nodes         = "kubectl get nodes"
    get_pods          = "kubectl get pods -A"
    argocd_port_forward = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
    prometheus_port_forward = var.enable_monitoring ? "kubectl port-forward svc/prometheus-server -n monitoring 9090:80" : "Monitoring not enabled"
    grafana_port_forward = var.enable_monitoring ? "kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80" : "Monitoring not enabled"
    get_argocd_password = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  }
}