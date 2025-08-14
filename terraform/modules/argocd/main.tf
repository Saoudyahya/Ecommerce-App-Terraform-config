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
          tag = var.argocd_image_tag != "" ? var.argocd_image_tag : null
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
      redis = var.enable_redis_ha || var.environment == "prod" ? {
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

# ================================================================
# BOOTSTRAP RESOURCES (Previously in separate bootstrap module)
# ================================================================

# Create ArgoCD project for better organization (optional)
resource "kubernetes_manifest" "nexus_project" {
  count = var.bootstrap_argocd && var.use_custom_project ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "nexus-commerce"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      description = "Nexus Commerce microservices project for ${var.environment}"

      sourceRepos = [
        var.gitops_repo_url,
        "https://charts.helm.sh/stable",
        "https://prometheus-community.github.io/helm-charts",
        "https://grafana.github.io/helm-charts",
        "https://istio-release.storage.googleapis.com/charts",
        "https://kubernetes-sigs.github.io/metrics-server/",
        "https://aws.github.io/eks-charts"
      ]

      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]

      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]

      namespaceResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]

      # Environment-specific roles and policies
      roles = var.environment == "prod" ? [
        {
          name = "admin"
          description = "Admin role for production"
          policies = [
            "p, proj:nexus-commerce:admin, applications, *, nexus-commerce/*, allow",
            "p, proj:nexus-commerce:admin, repositories, *, *, allow"
          ]
          groups = [
            "nexus-commerce:admin"
          ]
        },
        {
          name = "developer"
          description = "Developer role for production (read-only)"
          policies = [
            "p, proj:nexus-commerce:developer, applications, get, nexus-commerce/*, allow",
            "p, proj:nexus-commerce:developer, applications, sync, nexus-commerce/*, deny"
          ]
          groups = [
            "nexus-commerce:developer"
          ]
        }
      ] : [
        {
          name = "admin"
          description = "Admin role for ${var.environment}"
          policies = [
            "p, proj:nexus-commerce:admin, applications, *, nexus-commerce/*, allow",
            "p, proj:nexus-commerce:admin, repositories, *, *, allow"
          ]
          groups = [
            "nexus-commerce:admin"
          ]
        }
      ]

      # Sync windows for production
      syncWindows = var.environment == "prod" ? [
        {
          kind = "allow"
          schedule = "0 2 * * 1-5"  # Monday to Friday, 2 AM
          duration = "2h"
          applications = ["*"]
          manualSync = true
        }
      ] : []
    }
  }

  depends_on = [time_sleep.wait_for_argocd]
}

# Bootstrap the app-of-apps application with default project
resource "kubernetes_manifest" "app_of_apps_default" {
  count = var.bootstrap_argocd && !var.use_custom_project ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "${var.cluster_name}-app-of-apps"
      namespace = kubernetes_namespace.argocd.metadata[0].name
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
      labels = {
        environment = var.environment
        tier = "platform"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_branch
        path           = var.gitops_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = var.auto_sync_prune || var.auto_sync_self_heal ? {
          prune    = var.auto_sync_prune
          selfHeal = var.auto_sync_self_heal
        } : null
        syncOptions = [
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]
        retry = {
          limit = var.environment == "prod" ? 10 : 5
          backoff = {
            duration = "30s"
            factor = 2
            maxDuration = var.environment == "prod" ? "10m" : "5m"
          }
        }
      }
      info = [
        {
          name  = "Environment"
          value = var.environment
        },
        {
          name  = "Deployment Order"
          value = <<-EOT
            Wave 0: Istio Service Mesh (Base, Istiod, Gateway)
            Wave 1: Infrastructure (Config Server, Eureka, etc.)
            Wave 2: Data Layer (Databases, Kafka, Redis)
            Wave 3: Microservices
            Wave 4: Observability
            Wave 5: Ingress
          EOT
        }
      ]
    }
  }

  depends_on = [time_sleep.wait_for_argocd]
}

# Bootstrap the app-of-apps application with custom project
resource "kubernetes_manifest" "app_of_apps_custom" {
  count = var.bootstrap_argocd && var.use_custom_project ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "${var.cluster_name}-app-of-apps"
      namespace = kubernetes_namespace.argocd.metadata[0].name
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
      labels = {
        environment = var.environment
        tier = "platform"
      }
    }
    spec = {
      project = "nexus-commerce"  # Use custom project
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_branch
        path           = var.gitops_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = var.auto_sync_prune || var.auto_sync_self_heal ? {
          prune    = var.auto_sync_prune
          selfHeal = var.auto_sync_self_heal
        } : null
        syncOptions = [
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]
        retry = {
          limit = var.environment == "prod" ? 10 : 5
          backoff = {
            duration = "30s"
            factor = 2
            maxDuration = var.environment == "prod" ? "10m" : "5m"
          }
        }
      }
      info = [
        {
          name  = "Environment"
          value = var.environment
        },
        {
          name  = "Project"
          value = "nexus-commerce"
        },
        {
          name  = "Deployment Order"
          value = <<-EOT
            Wave 0: Istio Service Mesh (Base, Istiod, Gateway)
            Wave 1: Infrastructure (Config Server, Eureka, etc.)
            Wave 2: Data Layer (Databases, Kafka, Redis)
            Wave 3: Microservices
            Wave 4: Observability
            Wave 5: Ingress
          EOT
        }
      ]
    }
  }

  depends_on = [time_sleep.wait_for_argocd, kubernetes_manifest.nexus_project]
}

# Create initial application set for environment-specific deployments (optional)
resource "kubernetes_manifest" "environment_app_set" {
  count = var.bootstrap_argocd && var.enable_application_set ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "${var.cluster_name}-environment-apps"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      generators = [
        {
          list = {
            elements = [
              {
                cluster = var.cluster_name
                environment = var.environment
                url = "https://kubernetes.default.svc"
              }
            ]
          }
        }
      ]
      template = {
        metadata = {
          name = "{{cluster}}-{{environment}}-apps"
        }
        spec = {
          project = var.use_custom_project ? "nexus-commerce" : "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.gitops_repo_branch
            path           = "environments/{{environment}}"
          }
          destination = {
            server    = "{{url}}"
            namespace = "default"
          }
          syncPolicy = {
            automated = {
              prune    = var.auto_sync_prune
              selfHeal = var.auto_sync_self_heal
            }
            syncOptions = [
              "CreateNamespace=true"
            ]
          }
        }
      }
    }
  }

  depends_on = [time_sleep.wait_for_argocd]
}

# ================================================================
# ADDITIONAL RESOURCES
# ================================================================

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