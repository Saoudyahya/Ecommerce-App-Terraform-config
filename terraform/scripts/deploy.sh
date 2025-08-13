#!/bin/bash
# scripts/deploy.sh
# Usage: ./scripts/deploy.sh <environment> [action]
# Actions: plan, apply, destroy

set -e

ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$PROJECT_ROOT/environments/$ENVIRONMENT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
validate_environment() {
    if [[ ! -d "$ENV_DIR" ]]; then
        log_error "Environment '$ENVIRONMENT' not found in $ENV_DIR"
        log_info "Available environments:"
        ls -1 "$PROJECT_ROOT/environments" 2>/dev/null || log_error "No environments directory found"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    local missing_tools=()

    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi

    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws")
    fi

    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid"
        log_info "Please run: aws configure"
        exit 1
    fi
}

# Initialize Terraform
terraform_init() {
    log_info "Initializing Terraform for $ENVIRONMENT environment..."
    cd "$ENV_DIR"

    # Check if backend config exists
    if [[ ! -f "backend.tf" ]]; then
        log_error "Backend configuration not found in $ENV_DIR/backend.tf"
        log_info "Please create the backend configuration first"
        exit 1
    fi

    terraform init -reconfigure
    log_success "Terraform initialized"
}

# Terraform plan
terraform_plan() {
    log_info "Planning Terraform changes for $ENVIRONMENT environment..."
    cd "$ENV_DIR"

    terraform plan -var-file="terraform.tfvars" -out="terraform.plan"
    log_success "Plan completed. Review the changes above."
}

# Terraform apply
terraform_apply() {
    log_info "Applying Terraform changes for $ENVIRONMENT environment..."
    cd "$ENV_DIR"

    if [[ ! -f "terraform.plan" ]]; then
        log_warning "No plan file found. Running plan first..."
        terraform_plan
    fi

    if [[ "$ENVIRONMENT" == "prod" ]]; then
        log_warning "You are about to apply changes to PRODUCTION environment!"
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi

    terraform apply "terraform.plan"
    log_success "Terraform apply completed"

    # Configure kubectl if EKS cluster was created
    configure_kubectl
}

# Terraform destroy
terraform_destroy() {
    log_warning "You are about to DESTROY the $ENVIRONMENT environment!"

    if [[ "$ENVIRONMENT" == "prod" ]]; then
        log_error "Destroying production environment requires manual confirmation"
        read -p "Type 'destroy-production' to confirm: " confirm
        if [[ "$confirm" != "destroy-production" ]]; then
            log_info "Destroy cancelled"
            exit 0
        fi
    else
        read -p "Are you sure you want to destroy the $ENVIRONMENT environment? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log_info "Destroy cancelled"
            exit 0
        fi
    fi

    cd "$ENV_DIR"
    terraform destroy -var-file="terraform.tfvars" -auto-approve
    log_success "Environment destroyed"
}

# Configure kubectl
configure_kubectl() {
    log_info "Configuring kubectl for the cluster..."
    cd "$ENV_DIR"

    # Get cluster name from Terraform output
    CLUSTER_NAME=$(terraform output -raw cluster_id 2>/dev/null || echo "")
    AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")

    if [[ -n "$CLUSTER_NAME" ]]; then
        aws eks --region "$AWS_REGION" update-kubeconfig --name "$CLUSTER_NAME"
        log_success "kubectl configured for cluster: $CLUSTER_NAME"

        # Test connection
        if kubectl get nodes &> /dev/null; then
            log_success "Successfully connected to cluster"
            kubectl get nodes
        else
            log_warning "Could not connect to cluster. It may still be initializing."
        fi
    else
        log_warning "Could not determine cluster name. Configure kubectl manually."
    fi
}

# Show environment info
show_info() {
    log_info "Environment Information for: $ENVIRONMENT"
    cd "$ENV_DIR"

    if [[ -f "terraform.tfstate" ]] || terraform state list &> /dev/null; then
        echo "Current state:"
        terraform state list | head -10
        echo ""
        echo "Outputs:"
        terraform output
    else
        log_info "No infrastructure deployed yet"
    fi
}

# Main execution
main() {
    echo "======================================"
    echo "   Nexus Commerce EKS Deployment"
    echo "======================================"
    echo "Environment: $ENVIRONMENT"
    echo "Action: $ACTION"
    echo "======================================"

    validate_environment
    check_prerequisites

    case "$ACTION" in
        "plan")
            terraform_init
            terraform_plan
            ;;
        "apply")
            terraform_init
            terraform_apply
            ;;
        "destroy")
            terraform_init
            terraform_destroy
            ;;
        "init")
            terraform_init
            ;;
        "info")
            show_info
            ;;
        "kubectl")
            configure_kubectl
            ;;
        *)
            log_error "Unknown action: $ACTION"
            echo "Available actions: plan, apply, destroy, init, info, kubectl"
            exit 1
            ;;
    esac
}

# Help function
show_help() {
    cat << EOF
Nexus Commerce EKS Deployment Script

Usage: $0 <environment> [action]

Environments:
  dev     - Development environment
  stage   - Staging environment
  prod    - Production environment

Actions:
  plan    - Run terraform plan (default)
  apply   - Run terraform apply
  destroy - Run terraform destroy
  init    - Initialize terraform only
  info    - Show environment information
  kubectl - Configure kubectl for the cluster

Examples:
  $0 dev plan          # Plan changes for dev
  $0 stage apply       # Apply changes to staging
  $0 prod destroy      # Destroy production (with confirmations)
  $0 dev kubectl       # Configure kubectl for dev cluster

Prerequisites:
  - terraform CLI
  - aws CLI (configured with credentials)
  - kubectl CLI
EOF
}

# Check if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"