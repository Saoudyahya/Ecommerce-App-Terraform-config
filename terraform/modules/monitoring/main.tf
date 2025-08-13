# modules/monitoring/main.tf

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
      "istio-injection" = "enabled"  # Enable Istio injection for monitoring
      environment = var.environment
    }
  }
}

# Prometheus Operator (kube-prometheus-stack)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.prometheus_stack_version

  values = [
    yamlencode({
      # Global configuration
      fullnameOverride = "prometheus"

      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
          retentionSize = var.prometheus_retention_size

          # Storage configuration
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.prometheus_storage_class
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }

          # Resource allocation based on environment
          resources = var.prometheus_resources

          # Replicas for high availability
          replicas = var.environment == "prod" ? 2 : 1

          # Additional scrape configs for ArgoCD
          additionalScrapeConfigs = [
            {
              job_name = "argocd-metrics"
              static_configs = [
                {
                  targets = ["argocd-metrics.argocd.svc.cluster.local:8082"]
                }
              ]
            },
            {
              job_name = "argocd-server-metrics"
              static_configs = [
                {
                  targets = ["argocd-server-metrics.argocd.svc.cluster.local:8083"]
                }
              ]
            },
            {
              job_name = "argocd-repo-server-metrics"
              static_configs = [
                {
                  targets = ["argocd-repo-server.argocd.svc.cluster.local:8084"]
                }
              ]
            }
          ]

          # Service discovery for Istio
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues = false
          ruleSelectorNilUsesHelmValues = false
        }

        # Ingress configuration
        ingress = var.enable_prometheus_ingress ? {
          enabled = true
          ingressClassName = "nginx"
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/auth-type" = "basic"
            "nginx.ingress.kubernetes.io/auth-secret" = "prometheus-basic-auth"
          }
          hosts = [
            {
              host = "prometheus.${var.domain_name}"
              paths = [
                {
                  path = "/"
                  pathType = "Prefix"
                }
              ]
            }
          ]
          tls = [
            {
              secretName = "prometheus-tls"
              hosts = ["prometheus.${var.domain_name}"]
            }
          ]
        } : {}
      }

      # Grafana configuration
      grafana = {
        enabled = true

        # Admin credentials
        adminPassword = var.grafana_admin_password

        # Persistence
        persistence = {
          enabled = true
          storageClassName = var.grafana_storage_class
          size = var.grafana_storage_size
        }

        # Resource allocation
        resources = var.grafana_resources

        # Grafana configuration
        grafana.ini = {
          server = {
            domain = var.enable_grafana_ingress ? "grafana.${var.domain_name}" : ""
            root_url = var.enable_grafana_ingress ? "https://grafana.${var.domain_name}" : ""
          }
          "auth.google" = var.enable_grafana_oauth ? {
            enabled = true
            client_id = var.grafana_oauth_client_id
            client_secret = var.grafana_oauth_client_secret
            scopes = "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email"
            auth_url = "https://accounts.google.com/o/oauth2/auth"
            token_url = "https://accounts.google.com/o/oauth2/token"
            allowed_domains = var.grafana_allowed_domains
          } : {}
        }

        # Default dashboards
        defaultDashboardsEnabled = true

        # Additional dashboards
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name = "custom"
                orgId = 1
                folder = "Custom"
                type = "file"
                disableDeletion = false
                editable = true
                options = {
                  path = "/var/lib/grafana/dashboards/custom"
                }
              }
            ]
          }
        }

        # Custom dashboards
        dashboards = {
          custom = {
            argocd = {
              gnetId = 14584
              revision = 1
              datasource = "Prometheus"
            }
            istio-mesh = {
              gnetId = 7639
              revision = 1
              datasource = "Prometheus"
            }
            istio-service = {
              gnetId = 7636
              revision = 1
              datasource = "Prometheus"
            }
            nginx-ingress = {
              gnetId = 9614
              revision = 1
              datasource = "Prometheus"
            }
          }
        }

        # Ingress configuration
        ingress = var.enable_grafana_ingress ? {
          enabled = true
          ingressClassName = "nginx"
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = ["grafana.${var.domain_name}"]
          tls = [
            {
              secretName = "grafana-tls"
              hosts = ["grafana.${var.domain_name}"]
            }
          ]
        } : {}
      }

      # AlertManager configuration
      alertmanager = {
        enabled = true

        alertmanagerSpec = {
          # Storage configuration
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.alertmanager_storage_class
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alertmanager_storage_size
                  }
                }
              }
            }
          }

          # Resource allocation
          resources = var.alertmanager_resources

          # Replicas for high availability
          replicas = var.environment == "prod" ? 3 : 1
        }

        # AlertManager configuration
        config = {
          global = {
            smtp_smarthost = var.smtp_smarthost
            smtp_from = var.smtp_from
          }
          route = {
            group_by = ["alertname"]
            group_wait = "10s"
            group_interval = "10s"
            repeat_interval = "1h"
            receiver = "web.hook"
          }
          receivers = [
            {
              name = "web.hook"
              email_configs = var.enable_email_alerts ? [
                {
                  to = var.alert_email_to
                  subject = "[${upper(var.environment)}] Alert: {{ .GroupLabels.alertname }}"
                  body = "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.description }}{{ end }}"
                }
              ] : []
              slack_configs = var.enable_slack_alerts ? [
                {
                  api_url = var.slack_webhook_url
                  channel = var.slack_channel
                  title = "[${upper(var.environment)}] Alert: {{ .GroupLabels.alertname }}"
                  text = "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.description }}{{ end }}"
                }
              ] : []
            }
          ]
        }
      }

      # Node Exporter
      nodeExporter = {
        enabled = true
      }

      # kube-state-metrics
      kubeStateMetrics = {
        enabled = true
      }

      # Service monitors for additional services
      kubeApiServer = {
        enabled = true
      }

      kubelet = {
        enabled = true
      }

      kubeControllerManager = {
        enabled = true
      }

      coreDns = {
        enabled = true
      }

      kubeEtcd = {
        enabled = true
      }

      kubeScheduler = {
        enabled = true
      }

      kubeProxy = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# Loki for log aggregation (optional)
resource "helm_release" "loki" {
  count = var.enable_loki ? 1 : 0

  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.loki_version

  values = [
    yamlencode({
      # Loki configuration
      loki = {
        commonConfig = {
          replication_factor = var.environment == "prod" ? 3 : 1
        }

        storage = {
          type = "s3"
          s3 = {
            endpoint = ""
            region = var.aws_region
            s3 = "s3"
          }
          bucketNames = {
            chunks = var.loki_s3_bucket
            ruler = var.loki_s3_bucket
            admin = var.loki_s3_bucket
          }
        }
      }

      # Resource allocation
      ingester = {
        replicas = var.environment == "prod" ? 3 : 1
        resources = var.loki_ingester_resources
      }

      querier = {
        replicas = var.environment == "prod" ? 3 : 1
        resources = var.loki_querier_resources
      }

      distributor = {
        replicas = var.environment == "prod" ? 3 : 1
        resources = var.loki_distributor_resources
      }

      gateway = {
        enabled = true
        replicas = var.environment == "prod" ? 2 : 1
      }
    })
  ]
}

# Promtail for log shipping (if Loki is enabled)
resource "helm_release" "promtail" {
  count = var.enable_loki ? 1 : 0

  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.promtail_version

  values = [
    yamlencode({
      config = {
        clients = [
          {
            url = "http://loki-gateway/loki/api/v1/push"
          }
        ]
      }

      resources = var.promtail_resources
    })
  ]

  depends_on = [helm_release.loki]
}