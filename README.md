# 🏗️ NexusCommerce Terraform Infrastructure

<div align="center">

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-%234ea94b.svg?style=for-the-badge&logo=mongodb&logoColor=white)
![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white)
![Apache Kafka](https://img.shields.io/badge/Apache%20Kafka-000?style=for-the-badge&logo=apachekafka)
![Elastic](https://img.shields.io/badge/-ElasticSearch-005571?style=for-the-badge&logo=elasticsearch)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)
![Istio](https://img.shields.io/badge/Istio-466BB0?style=for-the-badge&logo=istio&logoColor=white)
![Kiali](https://img.shields.io/badge/Kiali-0F1419?style=for-the-badge&logo=kiali&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)
![Docker Hub](https://img.shields.io/badge/Docker%20Hub-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Zipkin](https://img.shields.io/badge/Zipkin-FF6B35?style=for-the-badge&logo=zipkin&logoColor=white)

**Infrastructure as Code for Cloud-Native E-Commerce Microservices Platform**

[🚀 Quick Start](#-quick-start) • [🏗️ Architecture](#️-architecture) • [📖 Modules](#-modules) • [🌍 Environments](#-environments)

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://terraform.io)
[![AWS Provider](https://img.shields.io/badge/AWS_Provider-5.0+-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#️-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Modules](#-modules)
- [Environments](#-environments)
- [Deployment Workflow](#-deployment-workflow)
- [Service Mesh Observability](#-service-mesh-observability)
- [Monitoring](#-monitoring)
- [Contributing](#-contributing)

---

## 🌟 Overview

This repository contains Terraform Infrastructure as Code (IaC) for provisioning and managing the complete cloud infrastructure required to run the **NexusCommerce** microservices platform. It follows best practices for multi-environment deployments and cost optimization with comprehensive service mesh observability.

### 🎯 Key Features

- **🏗️ Modular Architecture**: Reusable, composable Terraform modules
- **🌍 Multi-Environment**: Separate configurations for dev, staging, and production
- **📊 Service Mesh Observability**: Complete Istio + Kiali monitoring
- **🔍 Advanced Monitoring**: Prometheus, Grafana, and ELK stack integration
- **🔄 GitOps Integration**: Seamlessly integrates with ArgoCD workflows
- **🐳 Container Registry**: Docker Hub integration for image management

---

## 🏗️ Architecture

### Infrastructure Overview

```mermaid
graph TB
    subgraph "AWS Cloud"
        subgraph "VPC - 10.0.0.0/16"
            subgraph "Public Subnets"
                ALB[Application Load Balancer]
                NAT[NAT Gateway]
                BASTION[Bastion Host]
            end
            
            subgraph "Private Subnets"
                subgraph "EKS Cluster"
                    CONTROL[Control Plane]
                    NG1[Node Group - General]
                    NG2[Node Group - Data]
                    NG3[Node Group - Monitoring]
                end
                
                subgraph "Managed Services"
                    RDS[(RDS PostgreSQL)]
                    ELASTICACHE[(ElastiCache Redis)]
                    MSK[MSK Kafka]
                    ES[(Elasticsearch)]
                end
            end
            
            subgraph "Database Subnets"
                DB1[(Product DB)]
                DB2[(Order DB)]
                DB3[(Payment DB)]
                DB4[(Shipping DB)]
                DB5[(Loyalty DB)]
            end
        end
        
        subgraph "External Services"
            ATLAS[(MongoDB Atlas)]
            SECRETS[Secrets Manager]
        end
    end
    
    subgraph "Third Party"
        MONGO_CLOUD[MongoDB Cloud]
        ROUTE53[Route 53 DNS]
        ACM[SSL Certificates]
        DOCKER_HUB[Docker Hub Registry]
    end
    
    ALB --> CONTROL
    CONTROL --> NG1
    CONTROL --> NG2
    CONTROL --> NG3
    
    NG1 --> RDS
    NG1 --> ELASTICACHE
    NG1 --> MSK
    NG1 --> ES
    
    RDS --> DB1
    RDS --> DB2
    RDS --> DB3
    RDS --> DB4
    RDS --> DB5
    
    NG1 --> ATLAS
    NG1 --> SECRETS
    NG1 --> DOCKER_HUB
    
    ATLAS --> MONGO_CLOUD
    ALB --> ROUTE53
    ALB --> ACM
    
    style CONTROL fill:#326ce5,stroke:#fff,stroke-width:2px,color:#fff
    style ALB fill:#FF9900,stroke:#fff,stroke-width:2px,color:#fff
    style RDS fill:#336791,stroke:#fff,stroke-width:2px,color:#fff
    style ELASTICACHE fill:#DC382D,stroke:#fff,stroke-width:2px,color:#fff
    style MSK fill:#000,stroke:#fff,stroke-width:2px,color:#fff
    style ES fill:#005571,stroke:#fff,stroke-width:2px,color:#fff
    style ATLAS fill:#4EA94B,stroke:#fff,stroke-width:2px,color:#fff
    style DOCKER_HUB fill:#2496ED,stroke:#fff,stroke-width:2px,color:#fff
```

### Service Mesh Architecture with Kiali

```mermaid
graph TB
    subgraph "Istio Service Mesh"
        subgraph "Control Plane"
            PILOT[Pilot - Traffic Management]
            CITADEL[Citadel - Security]
            GALLEY[Galley - Configuration]
        end
        
        subgraph "Data Plane"
            ENVOY1[Envoy Proxy - Service A]
            ENVOY2[Envoy Proxy - Service B]
            ENVOY3[Envoy Proxy - Service C]
        end
        
        subgraph "Observability"
            KIALI[Kiali - Service Graph]
            ZIPKIN[Zipkin - Tracing]
            PROM[Prometheus - Metrics]
            GRAFANA[Grafana - Dashboards]
        end
    end
    
    subgraph "Microservices"
        PRODUCT[Product Service]
        ORDER[Order Service]
        PAYMENT[Payment Service]
        SHIPPING[Shipping Service]
    end
    
    PILOT --> ENVOY1
    PILOT --> ENVOY2
    PILOT --> ENVOY3
    
    ENVOY1 --> PRODUCT
    ENVOY2 --> ORDER
    ENVOY3 --> PAYMENT
    
    ENVOY1 --> KIALI
    ENVOY2 --> KIALI
    ENVOY3 --> KIALI
    
    ENVOY1 --> ZIPKIN
    ENVOY2 --> ZIPKIN
    ENVOY3 --> ZIPKIN
    
    KIALI --> PROM
    PROM --> GRAFANA
    
    style KIALI fill:#0F1419,stroke:#fff,stroke-width:2px,color:#fff
    style PILOT fill:#466BB0,stroke:#fff,stroke-width:2px,color:#fff
    style PROM fill:#E6522C,stroke:#fff,stroke-width:2px,color:#fff
    style GRAFANA fill:#F46800,stroke:#fff,stroke-width:2px,color:#fff
```

### Terraform Module Dependencies

```mermaid
graph TD
    subgraph "Foundation Layer"
        NET[networking]
        IAM[iam-roles]
    end
    
    subgraph "Platform Layer"
        K8S[kubernetes]
        LB[load-balancer]
    end
    
    subgraph "Data Layer"
        PG[postgresql]
        MONGO[mongodb]
        REDIS[redis]
        KAFKA[kafka]
    end
    
    subgraph "Service Mesh"
        ISTIO[istio]
        KIALI[kiali]
    end
    
    subgraph "GitOps"
        ARGO[argocd]
    end
    
    subgraph "Observability"
        ELK[elasticsearch]
        PROM[prometheus]
        GRAF[grafana]
        ZIPKIN[zipkin]
    end
    
    subgraph "Environment Orchestration"
        DEV[dev/main.tf]
        STAGING[staging/main.tf]
        PROD[production/main.tf]
    end
    
    NET --> K8S
    NET --> PG
    NET --> MONGO
    NET --> REDIS
    NET --> KAFKA
    NET --> LB
    
    IAM --> K8S
    IAM --> ARGO
    
    K8S --> ISTIO
    K8S --> ARGO
    K8S --> ELK
    K8S --> PROM
    K8S --> GRAF
    K8S --> ZIPKIN
    
    ISTIO --> KIALI
    PROM --> GRAF
    PROM --> KIALI
    
    DEV --> NET
    DEV --> K8S
    DEV --> PG
    DEV --> MONGO
    DEV --> REDIS
    DEV --> KAFKA
    DEV --> ISTIO
    DEV --> KIALI
    DEV --> ARGO
    DEV --> ELK
    DEV --> PROM
    DEV --> GRAF
    DEV --> ZIPKIN
    
    STAGING --> NET
    STAGING --> K8S
    STAGING --> PG
    STAGING --> MONGO
    STAGING --> REDIS
    STAGING --> KAFKA
    STAGING --> ISTIO
    STAGING --> KIALI
    STAGING --> ARGO
    STAGING --> ELK
    STAGING --> PROM
    STAGING --> GRAF
    STAGING --> ZIPKIN
    
    PROD --> NET
    PROD --> K8S
    PROD --> PG
    PROD --> MONGO
    PROD --> REDIS
    PROD --> KAFKA
    PROD --> ISTIO
    PROD --> KIALI
    PROD --> ARGO
    PROD --> ELK
    PROD --> PROM
    PROD --> GRAF
    PROD --> ZIPKIN
    
    style NET fill:#FF6B6B,stroke:#fff,stroke-width:2px,color:#fff
    style K8S fill:#326ce5,stroke:#fff,stroke-width:2px,color:#fff
    style PG fill:#336791,stroke:#fff,stroke-width:2px,color:#fff
    style MONGO fill:#4EA94B,stroke:#fff,stroke-width:2px,color:#fff
    style REDIS fill:#DC382D,stroke:#fff,stroke-width:2px,color:#fff
    style KAFKA fill:#000,stroke:#fff,stroke-width:2px,color:#fff
    style ISTIO fill:#466BB0,stroke:#fff,stroke-width:2px,color:#fff
    style KIALI fill:#0F1419,stroke:#fff,stroke-width:2px,color:#fff
    style ARGO fill:#EF7B4D,stroke:#fff,stroke-width:2px,color:#fff
    style ELK fill:#005571,stroke:#fff,stroke-width:2px,color:#fff
    style PROM fill:#E6522C,stroke:#fff,stroke-width:2px,color:#fff
    style GRAF fill:#F46800,stroke:#fff,stroke-width:2px,color:#fff
```

### Multi-Environment Strategy

```mermaid
graph LR
    subgraph "Source Control"
        GIT[Git Repository]
        BRANCH1[feature/branch]
        BRANCH2[develop]
        BRANCH3[main]
    end
    
    subgraph "Terraform Workspaces"
        WS1[terraform workspace dev]
        WS2[terraform workspace staging]
        WS3[terraform workspace production]
    end
    
    subgraph "AWS Environments"
        subgraph "Development Account"
            DEV_VPC[VPC: 10.0.0.0/16]
            DEV_EKS[EKS: dev-cluster]
            DEV_RDS[RDS: dev instances]
        end
        
        subgraph "Staging Account"
            STAGE_VPC[VPC: 10.1.0.0/16]
            STAGE_EKS[EKS: staging-cluster]
            STAGE_RDS[RDS: staging instances]
        end
        
        subgraph "Production Account"
            PROD_VPC[VPC: 10.2.0.0/16]
            PROD_EKS[EKS: prod-cluster]
            PROD_RDS[RDS: prod instances]
        end
    end
    
    subgraph "State Management"
        LOCAL_STATE[Local State Files]
        REMOTE_BACKEND[Remote Backend]
    end
    
    BRANCH1 --> WS1
    BRANCH2 --> WS2
    BRANCH3 --> WS3
    
    WS1 --> DEV_VPC
    WS1 --> DEV_EKS
    WS1 --> DEV_RDS
    
    WS2 --> STAGE_VPC
    WS2 --> STAGE_EKS
    WS2 --> STAGE_RDS
    
    WS3 --> PROD_VPC
    WS3 --> PROD_EKS
    WS3 --> PROD_RDS
    
    WS1 --> LOCAL_STATE
    WS2 --> REMOTE_BACKEND
    WS3 --> REMOTE_BACKEND
    
    style DEV_VPC fill:#87CEEB,stroke:#fff,stroke-width:2px,color:#000
    style STAGE_VPC fill:#FFB347,stroke:#fff,stroke-width:2px,color:#000
    style PROD_VPC fill:#FF6B6B,stroke:#fff,stroke-width:2px,color:#fff
```

### Resource Sizing by Environment

```mermaid
graph TB
    subgraph "Development Environment"
        DEV_SPECS["
        💻 EKS: 3 nodes (t3.medium)
        🗄️ RDS: db.t3.micro
        🔄 Redis: cache.t3.micro
        📊 Kafka: kafka.t3.small
        🕸️ Istio + Kiali: Basic setup
        "]
    end
    
    subgraph "Staging Environment"
        STAGE_SPECS["
        🖥️ EKS: 5 nodes (t3.large)
        🗄️ RDS: db.t3.small
        🔄 Redis: cache.t3.small
        📊 Kafka: kafka.m5.large
        🕸️ Istio + Kiali: Full observability
        "]
    end
    
    subgraph "Production Environment"
        PROD_SPECS["
        🏭 EKS: 10+ nodes (r5.xlarge)
        🗄️ RDS: db.r5.xlarge (Multi-AZ)
        🔄 Redis: cache.r5.large (Cluster)
        📊 Kafka: kafka.m5.xlarge (HA)
        🕸️ Istio + Kiali: HA + Performance
        "]
    end
    
    DEV_SPECS --> STAGE_SPECS
    STAGE_SPECS --> PROD_SPECS
    
    style DEV_SPECS fill:#87CEEB,stroke:#333,stroke-width:2px,color:#000
    style STAGE_SPECS fill:#FFB347,stroke:#333,stroke-width:2px,color:#000
    style PROD_SPECS fill:#FF6B6B,stroke:#333,stroke-width:2px,color:#fff
```

---

## 📋 Prerequisites

### Required Tools

```bash
# Core Tools
terraform >= 1.5.0
aws-cli >= 2.0
kubectl >= 1.24

# Optional Tools
helm >= 3.8         # For Kubernetes package management
k9s                 # Kubernetes CLI tool
terragrunt          # Terraform wrapper (optional)
```

### AWS Requirements

| Resource | Requirement |
|----------|-------------|
| **AWS Account** | Admin access or sufficient IAM permissions |
| **VPC Limits** | Default VPC limits sufficient |
| **EC2 Limits** | Sufficient for chosen instance types |
| **Route53** | For DNS management |
| **Docker Hub** | For container image registry |

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/your-org/nexus-commerce-terraform.git
cd nexus-commerce-terraform

# Configure AWS credentials
aws configure

# Set up environment variables
export AWS_REGION=us-west-2
export TF_VAR_environment=dev
export DOCKER_HUB_USERNAME=your-username
```

### 2. Deploy Development Environment

```bash
# Navigate to dev environment
cd environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="terraform.tfvars"

# Apply the infrastructure
terraform apply -var-file="terraform.tfvars"
```

### 3. Configure kubectl and Service Mesh

```bash
# Update kubeconfig
aws eks update-kubeconfig \
    --region us-west-2 \
    --name dev-nexus-commerce

# Verify cluster access
kubectl get nodes
kubectl get namespaces

# Access Kiali dashboard
kubectl port-forward -n istio-system svc/kiali 20001:20001
```

### 4. Verify Deployment

```bash
# Check all resources
terraform output

# Test connectivity
kubectl get pods -A
kubectl get svc -A

# Verify Istio and Kiali
kubectl get pods -n istio-system
```

---

## 🧩 Modules

### Core Infrastructure Modules

| Module | Purpose | Dependencies | Outputs |
|--------|---------|--------------|---------|
| **🌐 networking** | VPC, subnets, security groups | None | vpc_id, subnet_ids, security_groups |
| **☸️ kubernetes** | EKS cluster and node groups | networking | cluster_endpoint, node_groups |
| **⚖️ load-balancer** | ALB, target groups, listeners | networking | alb_arn, target_groups |

### Data Layer Modules

| Module | Purpose | Technology | Configuration |
|--------|---------|------------|---------------|
| **🐘 postgresql** | Relational databases | Amazon RDS | Multi-AZ, automated backups |
| **🍃 mongodb** | Document databases | MongoDB Atlas | Replica sets, sharding |
| **🔴 redis** | Caching layer | ElastiCache | Clustering, failover |
| **📊 kafka** | Message streaming | Amazon MSK | Multi-broker, encryption |

### Service Mesh & Observability Modules

| Module | Purpose | Technology | Features |
|--------|---------|------------|----------|
| **🕸️ istio** | Service mesh | Istio | mTLS, traffic management |
| **🔍 kiali** | Service mesh observability | Kiali | Service graph, traffic analysis |
| **📈 prometheus** | Metrics collection | Prometheus | Time-series metrics |
| **📊 grafana** | Monitoring dashboards | Grafana | Custom dashboards, alerting |
| **🔍 zipkin** | Distributed tracing | Zipkin | Request tracing |

### Platform Modules

| Module | Purpose | Technology | Features |
|--------|---------|------------|----------|
| **🔄 argocd** | GitOps deployment | ArgoCD | App of apps, RBAC |
| **📈 observability** | Monitoring stack | ELK, Prometheus, Grafana | Dashboards, alerting |

---

## 🌍 Environments

### Deployment Flow

```mermaid
flowchart TD
    START([Developer Push]) --> FEATURE{Feature Branch?}
    
    FEATURE -->|Yes| DEV_PLAN[Terraform Plan - Dev]
    FEATURE -->|No| MAIN{Main Branch?}
    
    DEV_PLAN --> DEV_APPLY[Auto Apply - Dev]
    DEV_APPLY --> DEV_TEST[Integration Tests]
    DEV_TEST --> KIALI_CHECK[Kiali Service Graph Check]
    KIALI_CHECK --> DEV_SUCCESS{Tests Pass?}
    
    DEV_SUCCESS -->|Yes| PR[Create Pull Request]
    DEV_SUCCESS -->|No| FIX[Fix Issues]
    FIX --> DEV_PLAN
    
    MAIN -->|Yes| STAGE_PLAN[Terraform Plan - Staging]
    
    PR --> REVIEW[Code Review]
    REVIEW --> MERGE{Approved & Merged?}
    MERGE -->|Yes| STAGE_PLAN
    MERGE -->|No| FEATURE
    
    STAGE_PLAN --> STAGE_APPLY[Manual Apply - Staging]
    STAGE_APPLY --> STAGE_TEST[E2E Tests]
    STAGE_TEST --> STAGE_SUCCESS{Tests Pass?}
    
    STAGE_SUCCESS -->|Yes| PROD_PLAN[Terraform Plan - Production]
    STAGE_SUCCESS -->|No| HOTFIX[Create Hotfix]
    
    PROD_PLAN --> APPROVAL[Manual Approval Required]
    APPROVAL --> PROD_APPLY[Apply - Production]
    PROD_APPLY --> PROD_VERIFY[Verify Deployment]
    PROD_VERIFY --> END([Complete])
    
    HOTFIX --> STAGE_PLAN
    
    style DEV_APPLY fill:#87CEEB,stroke:#333,stroke-width:2px
    style STAGE_APPLY fill:#FFB347,stroke:#333,stroke-width:2px
    style PROD_APPLY fill:#FF6B6B,stroke:#333,stroke-width:2px
    style APPROVAL fill:#9370DB,stroke:#333,stroke-width:2px,color:#fff
    style KIALI_CHECK fill:#0F1419,stroke:#333,stroke-width:2px,color:#fff
```

### Environment Configurations

#### Development
```hcl
# Optimized for development and testing
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    min_size      = 2
    max_size      = 10
    desired_size  = 3
  }
}

postgresql_config = {
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  backup_retention_period = 7
}

istio_config = {
  enable_kiali = true
  kiali_config = {
    auth_strategy = "anonymous"
  }
}
```

#### Staging
```hcl
# Production-like environment for testing
node_groups = {
  general = {
    instance_types = ["t3.large"]
    min_size      = 3
    max_size      = 15
    desired_size  = 5
  }
}

postgresql_config = {
  instance_class    = "db.t3.small"
  allocated_storage = 100
  multi_az         = true
  backup_retention_period = 14
}

istio_config = {
  enable_kiali = true
  kiali_config = {
    auth_strategy = "token"
    external_services = {
      prometheus = true
      grafana = true
      zipkin = true
    }
  }
}
```

#### Production
```hcl
# High availability and performance
node_groups = {
  general = {
    instance_types = ["r5.xlarge"]
    min_size      = 10
    max_size      = 50
    desired_size  = 15
  }
  
  data = {
    instance_types = ["r5.2xlarge"]
    min_size      = 3
    max_size      = 10
    desired_size  = 5
  }
}

postgresql_config = {
  instance_class    = "db.r5.xlarge"
  allocated_storage = 500
  multi_az         = true
  backup_retention_period = 30
  performance_insights_enabled = true
}

istio_config = {
  enable_kiali = true
  kiali_config = {
    auth_strategy = "openid"
    external_services = {
      prometheus = true
      grafana = true
      zipkin = true
    }
    deployment = {
      replicas = 2
      resources = {
        requests = {
          cpu = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu = "1"
          memory = "1Gi"
        }
      }
    }
  }
}
```

---

## 🔄 Deployment Workflow

### CI/CD Pipeline Integration

```mermaid
graph TB
    subgraph "GitHub Actions Workflow"
        TRIGGER[Git Push/PR]
        LINT[Terraform Lint]
        VALIDATE[Terraform Validate]
        PLAN[Terraform Plan]
        APPLY[Terraform Apply]
        TEST[Infrastructure Tests]

    end
    
    subgraph "Docker Hub Integration"
        BUILD[Build Images]
        PUSH[Push to Docker Hub]
        SCAN[Image Scanning]
    end
    
    subgraph "Approval Process"
        AUTO[Auto Approve - Dev]
        MANUAL[Manual Approve - Staging/Prod]
        SLACK[Slack Notification]
    end
    
    TRIGGER --> LINT
    LINT --> VALIDATE
    VALIDATE --> BUILD
    BUILD --> PUSH
    PUSH --> SCAN
    SCAN --> PLAN
    
    PLAN --> AUTO
    PLAN --> MANUAL
    
    AUTO --> APPLY
    MANUAL --> SLACK
    SLACK --> APPLY
    
    
    style TRIGGER fill:#4CAF50,stroke:#fff,stroke-width:2px,color:#fff
    style MANUAL fill:#9C27B0,stroke:#fff,stroke-width:2px,color:#fff
    style APPLY fill:#2196F3,stroke:#fff,stroke-width:2px,color:#fff
    style PUSH fill:#2496ED,stroke:#fff,stroke-width:2px,color:#fff
```

---

## 🔍 Service Mesh Observability



### Accessing Kiali

```bash
# Port forward to access Kiali dashboard
kubectl port-forward -n istio-system svc/kiali 20001:20001

# Access via browser
open http://localhost:20001

# Or use kubectl proxy
kubectl proxy &
open http://localhost:8001/api/v1/namespaces/istio-system/services/kiali:20001/proxy/
```

### Kiali Configuration Options

```yaml
# kiali-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kiali
  namespace: istio-system
data:
  config.yaml: |
    auth:
      strategy: "anonymous"  # For dev, use "token" or "openid" for prod
    deployment:
      image_name: "quay.io/kiali/kiali"
      image_version: "latest"
    external_services:
      prometheus:
        url: "http://prometheus:9090"
      grafana:
        enabled: true
        in_cluster_url: "http://grafana:3000"
      zipkin:
        enabled: true
        in_cluster_url: "http://zipkin:9411"
    server:
      web_root: "/kiali"
```

---

## 📊 Monitoring


### Key Metrics Monitored

| Category | Metrics | Tools |
|----------|---------|--------|
| **Service Mesh** | Request rate, Success rate, Duration, Traffic flow | Kiali + Istio |
| **Infrastructure** | CPU, Memory, Disk, Network | Prometheus + Grafana |
| **Kubernetes** | Pod health, Resource usage | Kubernetes Dashboard |
| **Applications** | Response time, Error rate, Throughput | Custom metrics + Kiali |
| **Databases** | Connections, Query performance | RDS/Atlas monitoring |
| **Service Communication** | mTLS status, Circuit breakers | Kiali + Istio |

### Kiali-Specific Monitoring

```bash
# View service graph
echo "Access Kiali service graph for real-time topology"

# Monitor traffic policies
kubectl get virtualservices -A
kubectl get destinationrules -A

# Check mTLS status
kubectl get peerauthentications -A
kubectl get authorizationpolicies -A

# Validate configuration
kubectl get gateway -A
kubectl get serviceentries -A
```

---

## 🛠️ Advanced Usage

### Custom Module Development

```bash
# Create a new module
mkdir -p modules/my-service
cd modules/my-service

# Standard module structure
touch main.tf variables.tf outputs.tf versions.tf README.md

# Follow module best practices
terraform-docs markdown table --output-file README.md .
```

### Testing Infrastructure

```bash
# Validate Terraform syntax
terraform validate

# Format code
terraform fmt -recursive

# Plan without applying
terraform plan -detailed-exitcode

# Integration tests
go test ./tests/...
```

### Kiali Configuration Testing

```bash
# Test Kiali API
kubectl exec -n istio-system deployment/kiali -- \
    curl -s http://localhost:20001/api/status

# Validate service mesh configuration
kubectl exec -n istio-system deployment/kiali -- \
    curl -s "http://localhost:20001/api/namespaces/default/services"

# Test graph API
kubectl exec -n istio-system deployment/kiali -- \
    curl -s "http://localhost:20001/api/namespaces/graph?namespaces=default"

# Test Zipkin integration
kubectl get pods -n istio-system | grep zipkin
kubectl logs -n istio-system deployment/zipkin
```

---

## 🤝 Contributing

### Development Workflow

1. **Fork & Clone**
   ```bash
   git clone https://github.com/your-username/nexus-commerce-terraform.git
   cd nexus-commerce-terraform
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-module
   ```

3. **Make Changes**
   - Follow Terraform best practices
   - Update documentation
   - Add tests
   - Configure Kiali integration

4. **Test Changes**
   ```bash
   make validate
   make test
   ```

5. **Submit Pull Request**
   - Clear description
   - Reference issues
   - Include test results

### Module Standards

- **📝 Documentation**: Every module must have a README
- **🧪 Testing**: Include unit and integration tests
- **🏷️ Tagging**: Consistent resource tagging
- **🔍 Observability**: Kiali and monitoring integration

---

## 📚 Resources

### Official Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [Kiali Documentation](https://kiali.io/docs/)

### Service Mesh Resources
- [Istio Best Practices](https://istio.io/latest/docs/ops/best-practices/)
- [Kiali Configuration](https://kiali.io/docs/configuration/)
- [Service Mesh Patterns](https://www.oreilly.com/library/view/service-mesh-patterns/9781492086444/)

### Container Registry
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support

### Getting Help
- **📖 Documentation**: Check the docs/ directory
- **🐛 Issues**: [GitHub Issues](https://github.com/your-org/nexus-commerce-terraform/issues)
- **💬 Discussions**: [GitHub Discussions](https://github.com/your-org/nexus-commerce-terraform/discussions)

### Contact
- **Email**: devops@nexuscommerce.com
- **Slack**: [#infrastructure](https://nexuscommerce.slack.com/channels/infrastructure)

---

<div align="center">

**⭐ If this helps your infrastructure journey, please give it a star! ⭐**

Made with ❤️ by the NexusCommerce Platform Team

![Infrastructure as Code](https://img.shields.io/badge/Infrastructure-as%20Code-blue?style=for-the-badge)
![Cloud Native](https://img.shields.io/badge/Cloud-Native-green?style=for-the-badge)
![DevOps](https://img.shields.io/badge/DevOps-Ready-orange?style=for-the-badge)
![Service Mesh](https://img.shields.io/badge/Service%20Mesh-Enabled-purple?style=for-the-badge)

</div>

