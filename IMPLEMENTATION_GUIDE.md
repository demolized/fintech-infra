# Fintech Infrastructure - Complete Implementation Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Project Structure](#project-structure)
5. [Infrastructure Components](#infrastructure-components)
6. [Implementation Steps](#implementation-steps)
7. [Deployment Workflow](#deployment-workflow)
8. [Post-Deployment Tasks](#post-deployment-tasks)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This is a **Terraform-based Infrastructure as Code (IaC)** project designed to deploy a complete fintech application infrastructure on AWS. The infrastructure is built around **Amazon EKS (Elastic Kubernetes Service)** and includes all necessary supporting services.

### Key Features:
- ✅ Multi-environment support (dev, QA, UAT, prod)
- ✅ EKS cluster with auto-scaling node groups
- ✅ AWS Application Load Balancer (ALB) integration
- ✅ Container registry (ECR) for Docker images
- ✅ SSL/TLS certificate management via ACM
- ✅ CI/CD tooling (Jenkins, Maven, SonarQube)
- ✅ Infrastructure monitoring capabilities
- ✅ Secure VPC networking with private/public subnets
- ✅ Remote state management with S3 and DynamoDB

---

## 🏗️ Architecture

### High-Level Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (us-east-2)                    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      VPC                                  │   │
│  │                                                           │   │
│  │  ┌──────────────┐           ┌──────────────┐            │   │
│  │  │  Public      │           │   Private    │            │   │
│  │  │  Subnets     │           │   Subnets    │            │   │
│  │  │              │           │              │            │   │
│  │  │ - EKS Client │           │ - EKS Nodes  │            │   │
│  │  │ - Jenkins    │           │ - Workloads  │            │   │
│  │  │ - Terraform  │           │              │            │   │
│  │  │   Node       │           │              │            │   │
│  │  └──────┬───────┘           └──────┬───────┘            │   │
│  │         │                          │                     │   │
│  │         └──────────┬───────────────┘                     │   │
│  │                    │                                     │   │
│  │            ┌───────▼────────┐                            │   │
│  │            │  EKS Cluster   │                            │   │
│  │            │  (Kubernetes)  │                            │   │
│  │            └───────┬────────┘                            │   │
│  │                    │                                     │   │
│  └────────────────────┼─────────────────────────────────────┘   │
│                       │                                          │
│  ┌────────────────────▼──────────────────────────────────┐     │
│  │              Supporting Services                       │     │
│  │  - ECR (Container Registry)                           │     │
│  │  - ACM (SSL Certificates)                             │     │
│  │  - IAM (Roles & Policies)                             │     │
│  │  - ALB Controller (Load Balancing)                    │     │
│  │  - S3 (Terraform State)                               │     │
│  │  - DynamoDB (State Locking)                           │     │
│  └────────────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

### Required Tools:
1. **Terraform** >= 0.12.0
2. **AWS CLI** (configured with credentials)
3. **kubectl** (for Kubernetes management)
4. **Helm** (for package management)
5. **Git** (for version control)

### AWS Requirements:
- ✅ AWS Account with administrative access
- ✅ IAM user/role with sufficient permissions
- ✅ S3 bucket for Terraform state (`class38dominion-terraform-backend`)
- ✅ DynamoDB table for state locking (`terraform-state-locking`)
- ✅ Route53 hosted zone (for domain management)
- ✅ Valid domain name configured in Route53

### AWS Permissions Required:
- EC2 (VPC, Subnets, Security Groups, Instances)
- EKS (Cluster, Node Groups)
- IAM (Roles, Policies)
- S3 (Buckets)
- ECR (Repositories)
- ACM (Certificates)
- Route53 (DNS records)
- Elastic Load Balancing

---

## 📁 Project Structure

```
fintech-infra/
│
├── dev/                          # Development environment
│   ├── main.tf                   # Main orchestration file
│   ├── variables.tf              # Variable definitions
│   ├── backend.tf                # S3 backend configuration
│   ├── providers.tf              # Provider configurations
│   ├── local.tf                  # Local variables
│   ├── output.tf                 # Output values
│   └── dev.tfvars               # Environment-specific values
│
├── qa/                           # QA environment
├── uat/                          # UAT environment
├── prod/                         # Production environment
│
├── modules/                      # Reusable Terraform modules
│   ├── vpc/                     # VPC networking module
│   ├── eks-cluster/             # EKS cluster module
│   ├── eks-client-node/         # Bastion/client node
│   ├── aws-alb-controller/      # ALB controller module
│   ├── ecr/                     # ECR repositories
│   ├── acm/                     # SSL certificate management
│   ├── iam/                     # IAM roles and policies
│   ├── jenkins-server/          # Jenkins CI/CD server
│   ├── maven-sonarqube-server/  # Build and code quality
│   ├── grafana/                 # Monitoring dashboards
│   └── prometheus/              # Metrics collection
│
└── scripts/                      # Helper scripts
    ├── install_helm.sh          # Helm installation
    └── update-kubeconfig.sh     # Kubeconfig setup
```

---

## 🔧 Infrastructure Components

### 1. **VPC Module** (`modules/vpc/`)
Creates a multi-AZ VPC with:
- Public subnets (for load balancers, bastion hosts)
- Private subnets (for EKS worker nodes)
- Internet Gateway
- NAT Gateways
- Route tables

### 2. **EKS Cluster Module** (`modules/eks-cluster/`)
Provisions:
- EKS control plane
- Managed node groups with auto-scaling
- OIDC provider for IRSA (IAM Roles for Service Accounts)
- Security groups
- aws-auth ConfigMap

### 3. **EKS Client Node** (`modules/eks-client-node/`)
A bastion/jump server with:
- AWS CLI
- kubectl
- Terraform
- Docker
- SSM Agent (for secure access)
- Pre-configured tools for cluster management

### 4. **AWS ALB Controller** (`modules/aws-alb-controller/`)
Enables:
- Ingress controller for Kubernetes
- Application Load Balancer provisioning
- Path-based routing
- SSL termination

### 5. **ECR Module** (`modules/ecr/`)
Creates Docker container registries for application images

### 6. **ACM Module** (`modules/acm/`)
Manages SSL/TLS certificates with automatic Route53 validation

### 7. **IAM Module** (`modules/iam/`)
Creates:
- Service accounts for EKS
- Kubernetes namespaces
- IAM roles with IRSA

### 8. **CI/CD Tools**
- **Jenkins**: Continuous integration/deployment
- **Maven + SonarQube**: Build automation and code quality

### 9. **Monitoring (Optional)**
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards

---

## 🚀 Implementation Steps

### Step 1: Pre-requisites Setup

#### 1.1 Create S3 Backend (If not exists)
```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket class38dominion-terraform-backend \
  --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket class38dominion-terraform-backend \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-locking \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-2
```

#### 1.2 Configure AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

#### 1.3 Update Configuration Files

**Edit `dev/variables.tf` or `dev/dev.tfvars`:**
```hcl
# Update these values according to your setup
cluster_name     = "your-cluster-name"
domain_name      = "yourdomain.com"
san_domains      = ["*.yourdomain.com"]
route53_zone_id  = "YOUR_ROUTE53_ZONE_ID"
aws_account_id   = "YOUR_AWS_ACCOUNT_ID"
rolearn          = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ADMIN_ROLE"
key_name         = "your-ssh-key-name"
```

**Important: Fix the provider region typo in `dev/providers.tf`:**
```hcl
# Current (line 3):
region = us-eest-2

# Should be:
region = "us-east-2"
```

---

### Step 2: Initialize Terraform

```bash
# Navigate to the environment directory
cd c:\Users\FALADEA\Downloads\fintech-Infra\fintech-infra\dev

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan
```

---

### Step 3: Deploy Infrastructure

#### Option A: Deploy Everything at Once
```bash
# Deploy all resources
terraform apply -auto-approve
```

#### Option B: Deploy Module by Module (Recommended for first deployment)

```bash
# 1. Deploy VPC first
terraform apply -target=module.vpc -auto-approve

# 2. Deploy EKS cluster
terraform apply -target=module.eks -auto-approve

# 3. Deploy EKS client node
terraform apply -target=module.eks-client-node -auto-approve

# 4. Deploy ALB controller
terraform apply -target=module.aws_alb_controller -auto-approve

# 5. Deploy remaining resources
terraform apply -auto-approve
```

---

### Step 4: Configure kubectl Access

#### 4.1 Update Kubeconfig
```bash
# Update kubeconfig to access the cluster
aws eks --region us-east-2 update-kubeconfig --name prod-dominion-cluster

# Or use the provided script
bash scripts/update-kubeconfig.sh

# Verify access
kubectl get nodes
kubectl get pods -A
```

#### 4.2 Verify Cluster
```bash
# Check cluster info
kubectl cluster-info

# Check namespaces
kubectl get namespaces

# Check deployments
kubectl get deployments -A
```

---

### Step 5: Install Helm (On EKS Client Node)

```bash
# SSH/SSM into the EKS client node
aws ssm start-session --target <instance-id>

# Run the Helm installation script
sudo bash /path/to/scripts/install_helm.sh

# Verify Helm
helm version
```

---

### Step 6: Deploy Applications

#### 6.1 Build and Push Docker Images to ECR
```bash
# Login to ECR
aws ecr get-login-password --region us-east-2 | \
  docker login --username AWS --password-stdin \
  999568710647.dkr.ecr.us-east-2.amazonaws.com

# Build your application
docker build -t fintech-app:latest .

# Tag the image
docker tag fintech-app:latest \
  999568710647.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest

# Push to ECR
docker push 999568710647.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest
```

#### 6.2 Deploy to Kubernetes
```bash
# Create deployment
kubectl create deployment fintech-app \
  --image=999568710647.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest \
  -n fintech

# Expose the deployment
kubectl expose deployment fintech-app \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8080 \
  -n fintech
```

---

## 🔄 Deployment Workflow

### Environment Promotion Flow
```
Dev → QA → UAT → Prod
```

### For Each Environment:

1. **Navigate to environment directory:**
   ```bash
   cd dev/    # or qa/, uat/, prod/
   ```

2. **Initialize backend:**
   ```bash
   terraform init
   ```

3. **Plan changes:**
   ```bash
   terraform plan -out=tfplan
   ```

4. **Apply changes:**
   ```bash
   terraform apply tfplan
   ```

5. **Verify deployment:**
   ```bash
   terraform output
   kubectl get all -A
   ```

---

## 📊 Post-Deployment Tasks

### 1. Configure DNS
Point your domain to the ALB created by the ALB controller:
```bash
# Get ALB DNS name
kubectl get ingress -A

# Create Route53 record pointing to ALB
```

### 2. Set up Monitoring
```bash
# Enable CloudWatch Container Insights
aws eks create-addon \
  --cluster-name prod-dominion-cluster \
  --addon-name amazon-cloudwatch-observability

# Attach CloudWatch policy to worker nodes
aws iam attach-role-policy \
  --role-name <worker-node-role> \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

### 3. Configure Jenkins
```bash
# Access Jenkins (get public IP)
terraform output jenkins_public_ip

# Initial admin password
ssh -i your-key.pem ubuntu@<jenkins-ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 4. Configure SonarQube
```bash
# Access SonarQube
terraform output sonarqube_public_ip

# Default credentials: admin/admin
```

---

## 🛠️ Troubleshooting

### Common Issues:

#### Issue 1: Provider Region Typo
**Error:** Invalid region `us-eest-2`
**Fix:** Update `dev/providers.tf` line 3:
```hcl
region = "us-east-2"  # Add quotes and fix typo
```

#### Issue 2: State Lock
**Error:** "Error acquiring the state lock"
**Fix:**
```bash
# Force unlock (use the Lock ID from error message)
terraform force-unlock <LOCK_ID>
```

#### Issue 3: kubectl Connection Issues
**Error:** "The connection to the server was refused"
**Fix:**
```bash
# Re-configure kubeconfig
aws eks --region us-east-2 update-kubeconfig \
  --name prod-dominion-cluster

# Check if cluster is running
aws eks describe-cluster --name prod-dominion-cluster \
  --region us-east-2 --query cluster.status
```

#### Issue 4: ALB Not Created
**Fix:**
```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify IAM roles
kubectl describe sa aws-load-balancer-controller -n kube-system
```

#### Issue 5: ECR Push Failure
**Fix:**
```bash
# Re-authenticate
aws ecr get-login-password --region us-east-2 | \
  docker login --username AWS --password-stdin \
  999568710647.dkr.ecr.us-east-2.amazonaws.com
```

---

## 🔐 Security Best Practices

1. **Use IAM roles instead of access keys** where possible
2. **Enable MFA** for admin accounts
3. **Rotate credentials** regularly
4. **Use private subnets** for workloads
5. **Enable VPC Flow Logs** for network monitoring
6. **Use Secrets Manager** or Parameter Store for sensitive data
7. **Implement network policies** in Kubernetes
8. **Regular security scanning** with tools like Trivy or Anchore
9. **Enable audit logging** for EKS

---

## 📈 Scaling Considerations

### Node Auto-scaling
EKS node groups support auto-scaling based on:
- CPU/Memory utilization
- Pod scheduling requirements

### Application Scaling
Use Horizontal Pod Autoscaler (HPA):
```bash
kubectl autoscale deployment fintech-app \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n fintech
```

---

## 💰 Cost Optimization

1. **Use Reserved Instances** for predictable workloads
2. **Right-size instances** based on actual usage
3. **Use Spot Instances** for non-critical workloads
4. **Enable cluster autoscaler** to scale down during low usage
5. **Delete unused resources** (old AMIs, snapshots, load balancers)
6. **Monitor costs** with AWS Cost Explorer

---

## 🔄 Maintenance

### Regular Tasks:
- **Weekly:** Review CloudWatch logs and metrics
- **Monthly:** Update Kubernetes version, patch AMIs
- **Quarterly:** Review and optimize costs
- **Annually:** Disaster recovery drills

---

## 📚 Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS ALB Ingress Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review Terraform and AWS documentation
3. Check CloudWatch logs
4. Review Kubernetes events: `kubectl get events -A`

---

**Last Updated:** November 19, 2025
**Version:** 1.0.0
