# modules/argocd/main.tf

# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
      "istio-injection" = "disabled"  # Disable Istio injection for ArgoCD
      environment = var.environment
    }
  }
}

# ArgoCD Installation via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = var.argocd_version

  # Environment-specific values
  values = [
    yamlencode({
      global = {
        image = {
          tag = var.argocd_image_tag
        }
      }

      server = {
        replicas = var.server_replicas

        service = {
          type = var.server_service_type
          annotations = var.server_service_annotations
        }

        extraArgs = var.server_extra_args

        # Environment-specific server configuration
        config = merge(
          var.server_config,
          {
            "application.instanceLabelKey" = "argocd.argoproj.io/instance"
            "server.rbac.log.enforce.enable" = "false"
            "exec.enabled" = "true"
            "admin.enabled" = "true"
            "timeout.hard.reconciliation" = "0"
            "timeout.reconciliation" = var.environment == "prod" ? "300s" : "180s"
            "application.resourceTrackingMethod" = "annotation"
          }
        )

        # Resource allocation based on environment
        resources = var.server_resources

        # Additional server configuration for production
        autoscaling = var.environment == "prod" ? {
          enabled = true
          minReplicas = var.server_replicas
          maxReplicas = var.server_replicas * 2
          targetCPUUtilizationPercentage = 80
        } : {}

        # Metrics and monitoring
        metrics = {
          enabled = var.enable_metrics
          serviceMonitor = {
            enabled = var.enable_metrics
          }
        }
      }

      controller = {
        replicas = var.controller_replicas

        # Resource allocation
        resources = var.controller_resources

        # Controller-specific configuration
        env = [
          {
            name = "ARGOCD_CONTROLLER_REPLICAS"
            value = tostring(var.controller_replicas)
          }
        ]

        # Metrics
        metrics = {
          enabled = var.enable_metrics
          serviceMonitor = {
            enabled = var.enable_metrics
          }
        }
      }

      repoServer = {
        replicas = var.repo_server_replicas

        # Resource allocation
        resources = var.repo_server_resources

        env = [
          {
            name = "ARGOCD_EXEC_TIMEOUT"
            value = var.environment == "prod" ? "10m" : "5m"
          }
        ]

        # Metrics
        metrics = {
          enabled = var.enable_metrics
          serviceMonitor = {
            enabled = var.enable_metrics
          }
        }
      }

      applicationSet = {
        enabled = var.enable_application_set
        replicas = var.environment == "prod" ? 2 : 1
      }

      notifications = {
        enabled = var.enable_notifications
      }

      # Redis configuration for high availability
      redis = var.environment == "prod" ? {
        enabled = true
        ha = {
          enabled = true
          replicas = 3
        }
      } : {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# Wait for ArgoCD to be ready before bootstrapping
resource "time_sleep" "wait_for_argocd" {
  count = var.bootstrap_argocd ? 1 : 0
  depends_on = [helm_release.argocd]
  create_duration = var.bootstrap_wait_time
}

# Bootstrap ArgoCD with app-of-apps pattern
module "argocd_bootstrap" {
  count = var.bootstrap_argocd ? 1 : 0
  source = "./bootstrap"

  cluster_name        = var.cluster_name
  environment         = var.environment
  gitops_repo_url     = var.gitops_repo_url
  gitops_repo_branch  = var.gitops_repo_branch
  gitops_repo_path    = var.gitops_repo_path
  auto_sync_prune     = var.auto_sync_prune
  auto_sync_self_heal = var.auto_sync_self_heal
  use_custom_project  = var.use_custom_project

  depends_on = [time_sleep.wait_for_argocd]
}

# Storage classes for ArgoCD (if custom storage needed)
resource "kubernetes_storage_class" "argocd_fast" {
  count = var.create_storage_classes ? 1 : 0

  metadata {
    name = "argocd-fast"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"  # Retain for ArgoCD data
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type       = "gp3"
    iops       = "4000"
    throughput = "250"
    encrypted  = "true"
  }
}

# Network Policies for ArgoCD (if required)
resource "kubernetes_network_policy" "argocd_network_policy" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "argocd-network-policy"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/part-of" = "argocd"
      }
    }

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from ALB/NLB
    ingress {
      from {
        namespace_selector {}
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
      ports {
        port     = "8083"
        protocol = "TCP"
      }
    }

    # Allow all egress (ArgoCD needs to reach git repos, registries, etc.)
    egress {}
  }
}