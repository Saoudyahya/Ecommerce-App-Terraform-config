# variables.tf

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the cluster is located."
  type        = string
}

variable "oidc_provider_arn" {
  description = "The OIDC provider ARN for the EKS cluster."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "The domain name to be managed by ExternalDNS."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "enable_aws_load_balancer_controller" {
  description = "Flag to enable the AWS Load Balancer Controller."
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller_version" {
  description = "The version of the AWS Load Balancer Controller Helm chart."
  type        = string
  default     = "1.4.8" # Specify a recent, stable version
}

variable "enable_cluster_autoscaler" {
  description = "Flag to enable the Cluster Autoscaler."
  type        = bool
  default     = false
}

variable "cluster_autoscaler_version" {
  description = "The version of the Cluster Autoscaler Helm chart."
  type        = string
  default     = "9.21.0" # Specify a recent, stable version
}

variable "enable_external_dns" {
  description = "Flag to enable ExternalDNS."
  type        = bool
  default     = false
}

variable "external_dns_version" {
  description = "The version of the ExternalDNS Helm chart."
  type        = string
  default     = "1.12.2" # Specify a recent, stable version
}

variable "enable_metrics_server" {
  description = "Flag to enable the Metrics Server."
  type        = bool
  default     = false
}

variable "metrics_server_version" {
  description = "The version of the Metrics Server Helm chart."
  type        = string
  default     = "3.8.3" # Specify a recent, stable version
}


# variable "cert_manager_version" {
#   description = "The version of the Cert-Manager Helm chart."
#   type        = string
#   default     = "v1.11.0" # Specify a recent, stable version
# }
#
# variable "enable_ingress_nginx" {
#   description = "Flag to enable the Ingress NGINX Controller."
#   type        = bool
#   default     = false
# }

variable "ingress_nginx_version" {
  description = "The version of the Ingress NGINX Helm chart."
  type        = string
  default     = "4.5.2" # Specify a recent, stable version
}

variable "enable_prometheus_monitoring" {
  description = "Flag to enable Prometheus monitoring integrations for addons."
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Flag to enable Cert-Manager."
  type        = bool
  default     = false
}

variable "cert_manager_version" {
  description = "The version of the Cert-Manager Helm chart."
  type        = string
  default     = "v1.11.0" # Specify a recent, stable version
}

variable "enable_ingress_nginx" {
  description = "Flag to enable the Ingress NGINX Controller."
  type        = bool
  default     = false
}