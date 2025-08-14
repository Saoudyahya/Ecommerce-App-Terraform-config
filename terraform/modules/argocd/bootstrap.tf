# modules/argocd/bootstrap.tf
# Fixed version using kubectl instead of kubernetes_manifest to avoid provider issues

# Wait for ArgoCD to be ready before creating any manifests
resource "time_sleep" "wait_for_argocd_ready" {
  count = var.bootstrap_argocd ? 1 : 0
  depends_on = [helm_release.argocd]
  create_duration = "120s"
}

# Create ArgoCD project for better organization using kubectl
resource "null_resource" "nexus_project" {
  count = var.bootstrap_argocd && var.use_custom_project ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      cat <<EOT | kubectl apply -f -
      apiVersion: argoproj.io/v1alpha1
      kind: AppProject
      metadata:
        name: nexus-commerce
        namespace: argocd
      spec:
        description: "Nexus Commerce microservices project for ${var.environment}"
        sourceRepos:
        - "${var.gitops_repo_url}"
        - "https://charts.helm.sh/stable"
        - "https://prometheus-community.github.io/helm-charts"
        - "https://grafana.github.io/helm-charts"
        - "https://istio-release.storage.googleapis.com/charts"
        - "https://kubernetes-sigs.github.io/metrics-server/"
        - "https://aws.github.io/eks-charts"
        destinations:
        - namespace: "*"
          server: "https://kubernetes.default.svc"
        clusterResourceWhitelist:
        - group: "*"
          kind: "*"
        namespaceResourceWhitelist:
        - group: "*"
          kind: "*"
        roles:
        - name: admin
          description: "Admin role for ${var.environment}"
          policies:
          - "p, proj:nexus-commerce:admin, applications, *, nexus-commerce/*, allow"
          - "p, proj:nexus-commerce:admin, repositories, *, *, allow"
          groups:
          - "nexus-commerce:admin"
      EOT
    EOF
  }

  # Note: ArgoCD will handle cleanup of projects when the namespace is deleted

  depends_on = [time_sleep.wait_for_argocd_ready]
}

# Bootstrap the app-of-apps application with default project using kubectl
resource "null_resource" "app_of_apps_default" {
  count = var.bootstrap_argocd && !var.use_custom_project ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      cat <<EOT | kubectl apply -f -
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: ${var.cluster_name}-app-of-apps
        namespace: argocd
        finalizers:
        - resources-finalizer.argocd.argoproj.io
        labels:
          environment: ${var.environment}
          tier: platform
      spec:
        project: default
        source:
          repoURL: ${var.gitops_repo_url}
          targetRevision: ${var.gitops_repo_branch}
          path: ${var.gitops_repo_path}
        destination:
          server: https://kubernetes.default.svc
          namespace: argocd
        syncPolicy:
          ${var.auto_sync_prune || var.auto_sync_self_heal ? "automated:" : ""}
          ${var.auto_sync_prune || var.auto_sync_self_heal ? "  prune: ${var.auto_sync_prune}" : ""}
          ${var.auto_sync_prune || var.auto_sync_self_heal ? "  selfHeal: ${var.auto_sync_self_heal}" : ""}
          syncOptions:
          - CreateNamespace=true
          - PrunePropagationPolicy=foreground
          - PruneLast=true
          retry:
            limit: ${var.environment == "prod" ? 10 : 5}
            backoff:
              duration: 30s
              factor: 2
              maxDuration: ${var.environment == "prod" ? "10m" : "5m"}
        info:
        - name: Environment
          value: ${var.environment}
        - name: Deployment Order
          value: |
            Wave 0: Istio Service Mesh (Base, Istiod, Gateway)
            Wave 1: Infrastructure (Config Server, Eureka, etc.)
            Wave 2: Data Layer (Databases, Kafka, Redis)
            Wave 3: Microservices
            Wave 4: Observability
            Wave 5: Ingress
      EOT
    EOF
  }

  # Note: ArgoCD will handle cleanup of applications when the namespace is deleted

  depends_on = [time_sleep.wait_for_argocd_ready]
}

# Bootstrap the app-of-apps application with custom project using kubectl
resource "null_resource" "app_of_apps_custom" {
  count = var.bootstrap_argocd && var.use_custom_project ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      cat <<EOT | kubectl apply -f -
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: ${var.cluster_name}-app-of-apps
        namespace: argocd
        finalizers:
        - resources-finalizer.argocd.argoproj.io
        labels:
          environment: ${var.environment}
          tier: platform
      spec:
        project: nexus-commerce
        source:
          repoURL: ${var.gitops_repo_url}
          targetRevision: ${var.gitops_repo_branch}
          path: ${var.gitops_repo_path}
        destination:
          server: https://kubernetes.default.svc
          namespace: argocd
        syncPolicy:
          ${var.auto_sync_prune || var.auto_sync_self_heal ? "automated:" : ""}
          ${var.auto_sync_prune || var.auto_sync_self_heal ? "  prune: ${var.auto_sync_prune}" : ""}
          ${var.auto_sync_prune || var.auto_sync_self_heal ? "  selfHeal: ${var.auto_sync_self_heal}" : ""}
          syncOptions:
          - CreateNamespace=true
          - PrunePropagationPolicy=foreground
          - PruneLast=true
          retry:
            limit: ${var.environment == "prod" ? 10 : 5}
            backoff:
              duration: 30s
              factor: 2
              maxDuration: ${var.environment == "prod" ? "10m" : "5m"}
        info:
        - name: Environment
          value: ${var.environment}
        - name: Project
          value: nexus-commerce
        - name: Deployment Order
          value: |
            Wave 0: Istio Service Mesh (Base, Istiod, Gateway)
            Wave 1: Infrastructure (Config Server, Eureka, etc.)
            Wave 2: Data Layer (Databases, Kafka, Redis)
            Wave 3: Microservices
            Wave 4: Observability
            Wave 5: Ingress
      EOT
    EOF
  }

  # Note: ArgoCD will handle cleanup of applications when the namespace is deleted

  depends_on = [time_sleep.wait_for_argocd_ready, null_resource.nexus_project]
}

# Create initial application set for environment-specific deployments using kubectl
resource "null_resource" "environment_app_set" {
  count = var.bootstrap_argocd && var.enable_application_set ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      cat <<EOT | kubectl apply -f -
      apiVersion: argoproj.io/v1alpha1
      kind: ApplicationSet
      metadata:
        name: ${var.cluster_name}-environment-apps
        namespace: argocd
      spec:
        generators:
        - list:
            elements:
            - cluster: ${var.cluster_name}
              environment: ${var.environment}
              url: https://kubernetes.default.svc
        template:
          metadata:
            name: "{{cluster}}-{{environment}}-apps"
          spec:
            project: ${var.use_custom_project ? "nexus-commerce" : "default"}
            source:
              repoURL: ${var.gitops_repo_url}
              targetRevision: ${var.gitops_repo_branch}
              path: "environments/{{environment}}"
            destination:
              server: "{{url}}"
              namespace: default
            syncPolicy:
              automated:
                prune: ${var.auto_sync_prune}
                selfHeal: ${var.auto_sync_self_heal}
              syncOptions:
              - CreateNamespace=true
      EOT
    EOF
  }

  # Note: ArgoCD will handle cleanup of applicationsets when the namespace is deleted

  depends_on = [time_sleep.wait_for_argocd_ready]
}

# Output the kubectl commands for manual verification
resource "null_resource" "bootstrap_verification" {
  count = var.bootstrap_argocd ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      echo "=== ArgoCD Bootstrap Verification ==="
      echo "Cluster: ${var.cluster_name}"
      echo "Environment: ${var.environment}"
      echo ""
      echo "Checking ArgoCD pods..."
      kubectl get pods -n argocd
      echo ""
      echo "Checking ArgoCD applications..."
      kubectl get applications -n argocd
      echo ""
      if [ "${var.use_custom_project}" = "true" ]; then
        echo "Checking ArgoCD projects..."
        kubectl get appprojects -n argocd
        echo ""
      fi
      echo "ArgoCD admin password:"
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
      echo ""
      echo ""
      echo "To access ArgoCD:"
      echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
      echo "Then visit: https://localhost:8080"
    EOF
  }

  depends_on = [
    null_resource.app_of_apps_default,
    null_resource.app_of_apps_custom,
    null_resource.environment_app_set
  ]
}