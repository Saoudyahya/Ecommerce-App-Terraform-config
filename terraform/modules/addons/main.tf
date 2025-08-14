# modules/addons/main.tf

# AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa_role" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.common_tags
}

resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.aws_load_balancer_controller_version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = try(module.aws_load_balancer_controller_irsa_role[0].iam_role_arn, "")
  }

  # Environment-specific configuration
  set {
    name  = "replicaCount"
    value = var.environment == "prod" ? "2" : "1"
  }

  set {
    name  = "resources.requests.cpu"
    value = var.environment == "prod" ? "200m" : "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = var.environment == "prod" ? "500Mi" : "200Mi"
  }
}

# Cluster Autoscaler
module "cluster_autoscaler_irsa_role" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                        = "${var.cluster_name}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.cluster_name]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = var.common_tags
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.cluster_autoscaler_version

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = try(module.cluster_autoscaler_irsa_role[0].iam_role_arn, "")
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "cluster-autoscaler"
  }

  # Environment-specific autoscaler configuration
  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = var.environment == "prod" ? "10m" : "2m"
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = var.environment == "prod" ? "10m" : "5m"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-delete"
    value = var.environment == "prod" ? "10s" : "5s"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-failure"
    value = var.environment == "prod" ? "3m" : "1m"
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  # Resource allocation
  set {
    name  = "resources.requests.cpu"
    value = var.environment == "prod" ? "200m" : "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = var.environment == "prod" ? "300Mi" : "200Mi"
  }
}

# External DNS
module "external_dns_irsa_role" {
  count = var.enable_external_dns && var.domain_name != "" ? 1 : 0

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "${var.cluster_name}-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/*"]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = var.common_tags
}

resource "helm_release" "external_dns" {
  count = var.enable_external_dns && var.domain_name != "" ? 1 : 0

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = var.external_dns_version

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = try(module.external_dns_irsa_role[0].iam_role_arn, "")
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "domainFilters[0]"
    value = var.domain_name
  }

  set {
    name  = "policy"
    value = var.environment == "prod" ? "upsert-only" : "sync"
  }

  set {
    name  = "txtOwnerId"
    value = "${var.cluster_name}-${var.environment}"
  }
}

# Metrics Server
resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.metrics_server_version

  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "serviceMonitor.enabled"
    value = var.enable_prometheus_monitoring ? "true" : "false"
  }

  # High availability for production
  set {
    name  = "replicas"
    value = var.environment == "prod" ? "2" : "1"
  }

  # Resource allocation
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "200Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = var.environment == "prod" ? "500m" : "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = var.environment == "prod" ? "500Mi" : "300Mi"
  }
}

# # Cert-Manager (optional)
# module "cert_manager_irsa_role" {
#   count = var.enable_cert_manager ? 1 : 0
#
#   source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "~> 5.0"
#
#   role_name = "${var.cluster_name}-cert-manager"
#
#   # Create custom policy for cert-manager Route53 access
#   role_policy_arns = [
#     aws_iam_policy.cert_manager_route53[0].arn
#   ]
#
#   oidc_providers = {
#     ex = {
#       provider_arn               = var.oidc_provider_arn
#       namespace_service_accounts = ["cert-manager:cert-manager"]
#     }
#   }
#
#   tags = var.common_tags
# }

resource "aws_iam_policy" "cert_manager_route53" {
  count = var.enable_cert_manager ? 1 : 0

  name_prefix = "${var.cluster_name}-cert-manager-route53"
  description = "IAM policy for cert-manager to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange"
        ]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = var.cert_manager_version

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = try(module.cert_manager_irsa_role[0].iam_role_arn, "")
  }

  # Enable Prometheus monitoring if available
  set {
    name  = "prometheus.enabled"
    value = var.enable_prometheus_monitoring ? "true" : "false"
  }

  # Resource allocation
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  # High availability for production
  set {
    name  = "replicaCount"
    value = var.environment == "prod" ? "2" : "1"
  }
}

# Ingress NGINX Controller (alternative to ALB)
resource "helm_release" "ingress_nginx" {
  count = var.enable_ingress_nginx ? 1 : 0

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = var.ingress_nginx_version

  create_namespace = true

  # Use NLB for better performance
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  # Enable Prometheus metrics
  set {
    name  = "controller.metrics.enabled"
    value = var.enable_prometheus_monitoring ? "true" : "false"
  }

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = var.enable_prometheus_monitoring ? "true" : "false"
  }

  # High availability for production
  set {
    name  = "controller.replicaCount"
    value = var.environment == "prod" ? "3" : "2"
  }

  # Resource allocation based on environment
  set {
    name  = "controller.resources.requests.cpu"
    value = var.environment == "prod" ? "500m" : "200m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = var.environment == "prod" ? "1Gi" : "512Mi"
  }
}


# Cert-Manager (optional)
module "cert_manager_irsa_role" {
  count = var.enable_cert_manager ? 1 : 0

  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-cert-manager"

  # Create custom policy for cert-manager Route53 access
  role_policy_arns = {
    cert_manager_route53 = aws_iam_policy.cert_manager_route53[0].arn
  }

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }

  tags = var.common_tags
}