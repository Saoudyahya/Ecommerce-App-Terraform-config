# environments/prod/outputs.tf

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
  value       = "https://argocd.${var.domain_name}"
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
  description = "Domain name"
  value       = var.domain_name
}

output "external_dns_enabled" {
  description = "External DNS status"
  value       = var.enable_external_dns
}

# Monitoring Information
output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = var.enable_monitoring ? "https://prometheus.${var.domain_name}" : "Monitoring not enabled"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = var.enable_monitoring ? "https://grafana.${var.domain_name}" : "Monitoring not enabled"
}

output "alertmanager_url" {
  description = "Alertmanager URL"
  value       = var.enable_monitoring ? "https://alertmanager.${var.domain_name}" : "Monitoring not enabled"
}

# Load Balancer Information
output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = "Check with: kubectl get svc -n kube-system aws-load-balancer-controller"
}

# Security Information
output "security_configuration" {
  description = "Security configuration for production"
  value = {
    vpc_endpoints        = "Enabled for secure AWS service access"
    flow_logs           = "Enabled with 30-day retention"
    cluster_logging     = "Full logging enabled (api, audit, authenticator, controllerManager, scheduler)"
    network_policies    = var.enable_network_policies ? "Enabled" : "Disabled"
    pod_security_policy = var.enable_pod_security_policy ? "Enabled" : "Disabled"
    encryption_at_rest  = "Enabled for EBS volumes"
  }
}

# Security Groups
output "additional_security_group_ids" {
  description = "Additional security group IDs"
  value       = module.networking.additional_security_group_ids
}

# High Availability Configuration
output "ha_configuration" {
  description = "High availability configuration for production"
  value = {
    availability_zones   = "3 AZs for maximum availability"
    nat_gateways        = "One NAT Gateway per AZ for redundancy"
    node_groups         = "Multi-AZ node groups with auto-scaling"
    argocd_replicas     = "3 ArgoCD server replicas with HA Redis"
    controller_replicas = "2 ArgoCD controller replicas"
    monitoring_ha       = var.enable_monitoring ? "HA Prometheus, Grafana, and Alertmanager" : "Not enabled"
  }
}

# Resource Sizing
output "resource_sizing" {
  description = "Resource sizing for production environment"
  value = {
    system_nodes       = "t3.xlarge with 3-6 nodes"
    application_nodes  = "t3.2xlarge/c5.2xlarge with 3-15 nodes"
    data_nodes        = "r5.2xlarge/r5.4xlarge with 2-8 nodes"
    storage_type      = "gp3 with high IOPS (up to 16,000)"
    monitoring_retention = var.enable_monitoring ? "30 days" : "Not enabled"
    backup_retention  = "30 days"
  }
}

# Backup Information
output "backup_configuration" {
  description = "Backup configuration for production"
  value = {
    automated_backups   = var.enable_automated_backups ? "Enabled" : "Disabled"
    retention_days     = var.backup_retention_days
    ebs_snapshots      = "Automated via AWS Backup"
    etcd_backups       = "EKS managed"
  }
}

# Compliance Information
output "compliance_information" {
  description = "Compliance and governance information"
  value = {
    tagging_strategy    = "Comprehensive tagging for cost allocation and governance"
    resource_naming     = "Standardized naming convention"
    access_control      = "RBAC enabled with minimal privileges"
    audit_logging       = "Full cluster audit logging enabled"
    cost_allocation     = "Resources tagged with cost center and project"
  }
}

# Performance Metrics
output "performance_configuration" {
  description = "Performance configuration for production"
  value = {
    cluster_autoscaler  = "Enabled with production-tuned settings"
    metrics_server      = "Enabled for HPA/VPA"
    storage_performance = "gp3 volumes with optimized IOPS and throughput"
    network_performance = "Enhanced networking enabled"
    monitoring_metrics  = var.enable_monitoring ? "Comprehensive metrics collection" : "Not enabled"
  }
}

# Disaster Recovery
output "disaster_recovery_configuration" {
  description = "Disaster recovery configuration"
  value = {
    multi_az_deployment = "Resources distributed across 3 AZs"
    backup_strategy     = "Automated backups with ${var.backup_retention_days}-day retention"
    gitops_recovery     = "Infrastructure and applications defined as code"
    monitoring_alerts   = var.enable_monitoring ? "Proactive alerting enabled" : "Not enabled"
  }
}

# Operational Commands
output "operational_commands" {
  description = "Operational commands for production environment"
  value = {
    cluster_status       = "kubectl get nodes -o wide"
    argocd_applications  = "kubectl get applications -n argocd"
    system_health        = "kubectl get pods -n kube-system"
    monitoring_status    = var.enable_monitoring ? "kubectl get pods -n monitoring" : "Monitoring not enabled"
    ingress_status       = "kubectl get ingress -A"
    pvc_status          = "kubectl get pvc -A"
    get_argocd_password = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  }
}

# Cost Optimization
output "cost_optimization" {
  description = "Cost optimization features enabled"
  value = {
    spot_instances      = "Used for non-critical workloads"
    cluster_autoscaler  = "Dynamic scaling based on demand"
    resource_quotas     = "Implemented for cost control"
    monitoring_costs    = var.enable_monitoring ? "Resource usage monitoring enabled" : "Not enabled"
    rightsizing         = "Regular review of instance types recommended"
  }
}

# SLA and Service Levels
output "service_levels" {
  description = "Service level objectives for production"
  value = {
    availability_target = "99.9% uptime"
    rpo_target         = "1 hour (Recovery Point Objective)"
    rto_target         = "2 hours (Recovery Time Objective)"
    monitoring_sla     = var.enable_monitoring ? "Real-time monitoring and alerting" : "Not enabled"
    support_level      = "24/7 monitoring recommended"
  }
}