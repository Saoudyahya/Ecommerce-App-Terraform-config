#!/bin/bash
# two-phase-deploy.sh - Deploy infrastructure in two phases to avoid Kubernetes provider issues

set -e

ENV=${1:-dev}
cd "terraform/environments/$ENV"

echo "=== Two-Phase EKS Deployment for $ENV ==="

# Phase 1: Deploy infrastructure without ArgoCD bootstrap
echo ""
echo "🚀 PHASE 1: Deploying EKS Infrastructure"
echo "=================================================="

# Temporarily disable ArgoCD bootstrap
echo "Temporarily disabling ArgoCD bootstrap..."

# Create a temporary tfvars file with bootstrap disabled
cat > terraform-phase1.tfvars << 'EOF'
# Copy all variables from terraform.tfvars but disable bootstrap
EOF

# Copy existing tfvars and modify bootstrap setting
grep -v "bootstrap_argocd" terraform.tfvars > terraform-phase1.tfvars
echo "bootstrap_argocd = false" >> terraform-phase1.tfvars

echo "Deploying EKS cluster and addons..."
terraform apply -var-file='terraform-phase1.tfvars' -auto-approve

echo "✅ Phase 1 complete: EKS cluster and addons deployed"

# Wait for cluster to be fully ready
echo ""
echo "⏳ Waiting for cluster to be fully ready..."
sleep 60

# Configure kubectl and verify connectivity
CLUSTER_NAME=$(terraform output -raw cluster_id)
AWS_REGION=$(terraform output -raw aws_region)

echo "Configuring kubectl for cluster: $CLUSTER_NAME"
aws eks --region "$AWS_REGION" update-kubeconfig --name "$CLUSTER_NAME"

echo "Testing cluster connectivity..."
kubectl get nodes
kubectl get pods -A

# Wait for core services to be ready
echo "Waiting for core services to be ready..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

echo "✅ Cluster is ready for ArgoCD deployment"

# Phase 2: Deploy ArgoCD with bootstrap
echo ""
echo "🚀 PHASE 2: Deploying ArgoCD with Bootstrap"
echo "=================================================="

echo "Re-enabling ArgoCD bootstrap..."
terraform apply -var-file='terraform.tfvars' -auto-approve

echo "✅ Phase 2 complete: ArgoCD with bootstrap deployed"

# Verify ArgoCD deployment
echo ""
echo "🔍 Verifying ArgoCD deployment..."
kubectl get pods -n argocd

echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

echo ""
echo "🎉 Deployment Complete!"
echo "================================"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo ""
echo "ArgoCD Access:"
echo "1. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. URL: https://localhost:8080"
echo "3. Username: admin"
echo "4. Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo ""
echo ""
echo "Useful commands:"
echo "- View applications: kubectl get applications -n argocd"
echo "- View ArgoCD logs: kubectl logs -l app.kubernetes.io/name=argocd-server -n argocd"

# Cleanup temporary file
rm -f terraform-phase1.tfvars

echo ""
echo "✅ Two-phase deployment completed successfully!"