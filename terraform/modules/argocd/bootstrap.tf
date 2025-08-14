# modules/argocd/bootstrap.tf

# Create ArgoCD project for better organization (optional)
resource "kubernetes_manifest" "nexus_project" {
  count = var.bootstrap_argocd && var.use_custom_project ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "nexus-commerce"
      namespace = "argocd"
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
      namespace = "argocd"
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
      namespace = "argocd"
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
      namespace = "argocd"
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