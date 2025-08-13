set -e

ENVIRONMENT=${1}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

if [[ -z "$ENVIRONMENT" ]]; then
    echo "Available environments:"
    ls -1 "$PROJECT_ROOT/environments" 2>/dev/null
    echo ""
    echo "Usage: $0 <environment>"
    exit 1
fi

ENV_DIR="$PROJECT_ROOT/environments/$ENVIRONMENT"

if [[ ! -d "$ENV_DIR" ]]; then
    echo "Environment '$ENVIRONMENT' not found"
    exit 1
fi

# Switch to environment directory
cd "$ENV_DIR"

log_info "Switched to $ENVIRONMENT environment"
log_info "Current directory: $(pwd)"

# Show current state if available
if terraform state list &> /dev/null; then
    log_info "Current infrastructure:"
    terraform state list | head -5
    if [[ $(terraform state list | wc -l) -gt 5 ]]; then
        echo "... and $(($(terraform state list | wc -l) - 5)) more resources"
    fi
else
    log_warning "No infrastructure deployed in this environment"
fi

# Configure kubectl if cluster exists
CLUSTER_NAME=$(terraform output -raw cluster_id 2>/dev/null || echo "")
if [[ -n "$CLUSTER_NAME" ]]; then
    AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")
    log_info "Configuring kubectl for cluster: $CLUSTER_NAME"
    aws eks --region "$AWS_REGION" update-kubeconfig --name "$CLUSTER_NAME"
    log_success "kubectl configured"
else
    log_warning "No EKS cluster found in this environment"
fi

echo ""
echo "Environment: $ENVIRONMENT"
echo "Ready for terraform commands!"