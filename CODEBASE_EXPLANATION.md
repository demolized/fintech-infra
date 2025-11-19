# Fintech Infrastructure - Codebase Explanation

## 📖 Executive Summary

This repository contains a **production-ready Terraform Infrastructure as Code (IaC)** solution for deploying a complete fintech application platform on AWS. The infrastructure is centered around **Amazon EKS (Elastic Kubernetes Service)** and includes comprehensive networking, security, CI/CD tooling, and monitoring capabilities.

---

## 🎯 What This Codebase Does

This infrastructure automates the deployment of:

1. **Highly Available Kubernetes Cluster** - Multi-AZ EKS cluster for running containerized applications
2. **Complete Networking Stack** - VPC with public/private subnets, NAT gateways, security groups
3. **Load Balancing** - AWS Application Load Balancer with SSL/TLS termination
4. **Container Management** - ECR repositories for Docker images
5. **CI/CD Pipeline** - Jenkins for automated builds and deployments
6. **Code Quality** - SonarQube for static code analysis
7. **Security** - SSL certificates, IAM roles, security groups, bastion hosts
8. **Monitoring** - CloudWatch integration for logs and metrics
9. **Multi-Environment** - Separate configurations for Dev, QA, UAT, and Production

---

## 🏗️ Architecture Overview

### High-Level Components

```
┌─────────────────────────────────────────────────────────────────┐
│                      Internet Users                              │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   Route53    │ (DNS)
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │     ALB      │ (Load Balancer + SSL)
                    └──────┬───────┘
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
       ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  EKS Pod     │   │  EKS Pod     │   │  EKS Pod     │
│  (AZ-1)      │   │  (AZ-2)      │   │  (AZ-3)      │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────▼───────┐
                    │  EKS Cluster │
                    └──────────────┘
```

### Supporting Infrastructure

- **ECR**: Stores Docker container images
- **ACM**: Manages SSL/TLS certificates
- **IAM**: Controls access and permissions
- **S3**: Stores Terraform state files
- **DynamoDB**: Locks Terraform state during operations
- **CloudWatch**: Collects logs and metrics

---

## 📂 Directory Structure Explained

### Root Level
```
fintech-infra/
├── dev/           # Development environment files
├── qa/            # QA environment files
├── uat/           # UAT environment files
├── prod/          # Production environment files
├── modules/       # Reusable Terraform modules
├── scripts/       # Helper bash scripts
└── .git/          # Version control
```

### Environment Directories (dev/, qa/, uat/, prod/)
Each environment contains identical structure but different configurations:

```
dev/
├── main.tf        # Orchestrates all modules
├── variables.tf   # Declares input variables
├── backend.tf     # Configures remote state storage
├── providers.tf   # Configures AWS/Kubernetes providers
├── local.tf       # Local computed values
├── output.tf      # Output values after deployment
└── *.tfvars      # Environment-specific variable values
```

### Modules Directory
Contains reusable infrastructure components:

```
modules/
├── vpc/                      # Network foundation
├── eks-cluster/              # Kubernetes cluster
├── eks-client-node/          # Management bastion host
├── aws-alb-controller/       # Load balancer controller
├── ecr/                      # Container registry
├── acm/                      # SSL certificates
├── iam/                      # Identity & access
├── jenkins-server/           # CI/CD server
├── maven-sonarqube-server/   # Build & quality tools
├── grafana/                  # Monitoring dashboards (optional)
└── prometheus/               # Metrics collection (optional)
```

---

## 🔍 Key Files Deep Dive

### 1. `dev/main.tf` (Main Orchestration)

This is the **heart of the deployment**. It calls all the modules in the correct order:

```hcl
# Example structure:
module "vpc" {
  source = "./../modules/vpc"
  # VPC configuration
}

module "eks" {
  source = "./../modules/eks-cluster"
  vpc_id = module.vpc.vpc_id  # Uses output from VPC module
  # EKS configuration
}

# ... more modules
```

**What it does:**
- Creates VPC networking
- Deploys EKS cluster
- Sets up security
- Provisions management nodes
- Configures load balancing
- Sets up CI/CD tools

### 2. `dev/variables.tf` (Configuration Variables)

Defines all configurable parameters:

```hcl
variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "prod-dominion-cluster"
}

variable "domain_name" {
  description = "Your domain name"
  default     = "dominionsystem.org"
}

# ... many more variables
```

**Key Variables to Update:**
- `cluster_name` - Your EKS cluster name
- `domain_name` - Your domain
- `aws_account_id` - Your AWS account ID
- `route53_zone_id` - Your Route53 zone
- `key_name` - SSH key for instances

### 3. `dev/backend.tf` (State Management)

Configures where Terraform stores its state:

```hcl
terraform {
  backend "s3" {
    bucket         = "class38dominion-terraform-backend"
    key            = "dev/terraform.state"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-locking"
  }
}
```

**Why this matters:**
- Enables team collaboration
- Prevents concurrent modifications
- Provides state versioning
- Disaster recovery capability

### 4. `dev/providers.tf` (Cloud Provider Setup)

Configures how Terraform talks to AWS and Kubernetes:

```hcl
provider "aws" {
  region = "us-east-2"  # ⚠️ FIX THE TYPO HERE
}

provider "kubernetes" {
  # Configured to talk to EKS cluster
}

provider "helm" {
  # For installing Kubernetes packages
}
```

**⚠️ CRITICAL FIX NEEDED:**
Line 3 has a typo: `region = us-eest-2`  
Should be: `region = "us-east-2"`

---

## 🧩 Module Breakdown

### VPC Module (`modules/vpc/`)

**Purpose:** Creates the network foundation

**What it creates:**
- VPC (Virtual Private Cloud)
- Public subnets (3, one per AZ)
- Private subnets (3, one per AZ)
- Internet Gateway (for public internet access)
- NAT Gateways (for private subnet internet access)
- Route tables
- Network ACLs

**Why it's important:**
- Isolates your infrastructure
- Provides network segmentation
- Enables high availability across zones
- Secures private resources

### EKS Cluster Module (`modules/eks-cluster/`)

**Purpose:** Deploys the Kubernetes cluster

**What it creates:**
- EKS control plane (managed by AWS)
- Managed node groups
- Auto-scaling configuration
- OIDC provider (for IAM integration)
- Security groups
- aws-auth ConfigMap

**Key Features:**
- Kubernetes 1.31
- Auto-scaling worker nodes
- Multi-AZ deployment
- IAM Roles for Service Accounts (IRSA)

### EKS Client Node (`modules/eks-client-node/`)

**Purpose:** Bastion/jump host for cluster management

**What it creates:**
- EC2 instance in public subnet
- Security group (SSH access)
- SSH key pair
- IAM instance profile

**Pre-installed Tools:**
- AWS CLI
- kubectl
- Terraform
- Docker
- SSM Agent

**Use Cases:**
- Cluster administration
- Running kubectl commands
- Debugging
- Running Terraform operations

### AWS ALB Controller (`modules/aws-alb-controller/`)

**Purpose:** Enables Kubernetes Ingress to create AWS Load Balancers

**What it creates:**
- IAM role for ALB controller
- Helm deployment of AWS Load Balancer Controller
- Service account with IRSA

**How it works:**
1. You create a Kubernetes Ingress resource
2. ALB Controller detects the Ingress
3. Automatically creates an AWS Application Load Balancer
4. Configures routing rules
5. Manages SSL/TLS certificates

### ECR Module (`modules/ecr/`)

**Purpose:** Container image storage

**What it creates:**
- ECR repositories (one per application)
- Repository policies
- Lifecycle policies (auto-delete old images)

**Usage:**
```bash
# Build image
docker build -t my-app .

# Tag for ECR
docker tag my-app:latest 123456.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest

# Push to ECR
docker push 123456.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest
```

### ACM Module (`modules/acm/`)

**Purpose:** SSL/TLS certificate management

**What it creates:**
- ACM certificate for your domain
- Route53 validation records
- Automatic renewal setup

**Domains Covered:**
- Primary: `dominionsystem.org`
- Wildcard: `*.dominionsystem.org`

### IAM Module (`modules/iam/`)

**Purpose:** Access control and permissions

**What it creates:**
- Kubernetes namespaces (fintech, monitoring)
- Service accounts
- IAM roles with IRSA
- Policies for EKS access

**Namespaces Created:**
- `fintech` - For application workloads
- `monitoring` - For monitoring tools

### Jenkins Server (`modules/jenkins-server/`)

**Purpose:** CI/CD automation

**What it creates:**
- EC2 instance with Jenkins installed
- Security group (port 8080, 50000)
- IAM role for AWS access

**Access:**
```bash
# Get initial password
ssh ubuntu@<jenkins-ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Maven + SonarQube Server (`modules/maven-sonarqube-server/`)

**Purpose:** Code quality and build tools

**What it creates:**
- EC2 instance with Maven and SonarQube
- PostgreSQL database for SonarQube (optional)
- Security group (port 9000)

**Access:**
- SonarQube: `http://<sonarqube-ip>:9000`
- Default credentials: `admin / admin`

---

## 🔄 How the Infrastructure Works Together

### Deployment Flow

1. **User Request**
   ```
   User → Route53 (DNS) → ALB → EKS Service → EKS Pods
   ```

2. **Application Deployment**
   ```
   Developer → Git Push → Jenkins → Build → ECR → Deploy to EKS
   ```

3. **Image Flow**
   ```
   Dockerfile → Docker Build → Tag → ECR Push → EKS Pull → Container Running
   ```

4. **Monitoring Flow**
   ```
   EKS Pods → CloudWatch Agent → CloudWatch → Alerts/Dashboards
   ```

### Resource Dependencies

```
S3 + DynamoDB (State)
    ↓
VPC (Network)
    ↓
EKS Cluster (Compute)
    ↓
ALB Controller (Load Balancing)
    ↓
Applications (Workloads)
```

---

## 🚀 How to Implement

### Phase 1: Preparation (30-60 minutes)

1. **Install Tools**
   - Terraform
   - AWS CLI
   - kubectl

2. **Configure AWS**
   ```bash
   aws configure
   ```

3. **Create S3 Backend**
   ```bash
   aws s3api create-bucket --bucket class38dominion-terraform-backend --region us-east-2
   ```

4. **Create DynamoDB Table**
   ```bash
   aws dynamodb create-table --table-name terraform-state-locking ...
   ```

### Phase 2: Configuration (15-30 minutes)

1. **Fix Provider Typo**
   - Edit `dev/providers.tf` line 3

2. **Update Variables**
   - Edit `dev/variables.tf`
   - Set cluster name, domain, AWS account ID, etc.

3. **Review Configuration**
   - Check all files for environment-specific values

### Phase 3: Deployment (20-40 minutes)

1. **Initialize Terraform**
   ```bash
   cd dev/
   terraform init
   ```

2. **Plan Deployment**
   ```bash
   terraform plan
   ```

3. **Deploy Infrastructure**
   ```bash
   terraform apply -auto-approve
   ```

4. **Wait for Completion**
   - EKS cluster takes ~15-20 minutes
   - Other resources ~5-10 minutes

### Phase 4: Verification (10-15 minutes)

1. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --name prod-dominion-cluster --region us-east-2
   ```

2. **Verify Cluster**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

3. **Check Outputs**
   ```bash
   terraform output
   ```

### Phase 5: Application Deployment (30-60 minutes)

1. **Build Docker Image**
   ```bash
   docker build -t fintech-app .
   ```

2. **Push to ECR**
   ```bash
   docker push <ecr-url>/fintech-app:latest
   ```

3. **Deploy to Kubernetes**
   ```bash
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   kubectl apply -f ingress.yaml
   ```

4. **Configure DNS**
   - Point domain to ALB

---

## 🔧 Common Operations

### Update Infrastructure

```bash
# Modify Terraform files
vim dev/main.tf

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Scale Applications

```bash
# Scale deployment
kubectl scale deployment fintech-app --replicas=5 -n fintech

# Enable auto-scaling
kubectl autoscale deployment fintech-app --cpu-percent=70 --min=2 --max=10 -n fintech
```

### Add New Application

1. Create ECR repository
2. Build and push Docker image
3. Create Kubernetes manifests
4. Deploy to cluster

### Destroy Infrastructure

```bash
# Destroy everything
terraform destroy

# Destroy specific module
terraform destroy -target=module.jenkins-server
```

---

## 🛡️ Security Considerations

### Network Security
- Private subnets for application workloads
- Public subnets only for load balancers and bastion
- Security groups with least privilege
- Network ACLs for additional protection

### Access Control
- IAM roles instead of access keys
- IRSA for pod-level permissions
- MFA for administrative access
- SSM Session Manager for SSH

### Data Protection
- Encryption at rest (EBS, S3)
- Encryption in transit (TLS/SSL)
- Secrets stored in AWS Secrets Manager
- Container image scanning

### Compliance
- All resources tagged for tracking
- Audit logging enabled
- VPC flow logs (optional)
- CloudTrail for API auditing

---

## 💰 Cost Breakdown

### Estimated Monthly Costs (us-east-2)

| Resource | Estimated Cost |
|----------|----------------|
| EKS Control Plane | $72/month |
| EC2 Worker Nodes (3x t3.medium) | ~$100/month |
| NAT Gateways (2) | ~$65/month |
| Application Load Balancer | ~$20/month |
| EKS Client Node (t3.medium) | ~$30/month |
| Jenkins Server (t3.medium) | ~$30/month |
| SonarQube Server (t3.medium) | ~$30/month |
| ECR Storage | ~$10/month |
| Data Transfer | Variable |
| CloudWatch | ~$10/month |
| **Total** | **~$367/month** |

**Cost Optimization Tips:**
- Use Spot instances for non-production
- Rightsize instances based on usage
- Enable cluster autoscaler
- Delete unused resources
- Use Reserved Instances for production

---

## 📊 Monitoring & Observability

### CloudWatch Container Insights

Enable with:
```bash
aws eks create-addon --cluster-name prod-dominion-cluster --addon-name amazon-cloudwatch-observability
```

**Metrics Collected:**
- CPU utilization
- Memory utilization
- Network traffic
- Disk I/O
- Pod count
- Container count

### Kubernetes Metrics

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods -A

# Events
kubectl get events -A --sort-by='.lastTimestamp'
```

### Application Logs

```bash
# View logs
kubectl logs <pod-name> -n fintech

# Follow logs
kubectl logs -f <pod-name> -n fintech

# Previous container logs
kubectl logs <pod-name> -n fintech --previous
```

---

## 🔄 Maintenance & Updates

### Regular Tasks

**Weekly:**
- Review CloudWatch dashboards
- Check cluster health
- Monitor costs
- Review security group rules

**Monthly:**
- Update Kubernetes version
- Patch worker node AMIs
- Review and optimize costs
- Backup Terraform state
- Security audit

**Quarterly:**
- Disaster recovery drill
- Performance optimization
- Capacity planning review
- Update documentation

### Upgrade Procedures

**EKS Cluster Upgrade:**
1. Review release notes
2. Update control plane
3. Update node groups
4. Update add-ons
5. Test applications

**Application Updates:**
1. Build new Docker image
2. Tag with version
3. Push to ECR
4. Update Kubernetes manifests
5. Rolling update deployment

---

## 🆘 Troubleshooting Guide

### Issue: Terraform State Lock

**Error:** "Error acquiring the state lock"

**Solution:**
```bash
terraform force-unlock <LOCK_ID>
```

### Issue: Cannot Connect to EKS

**Error:** "Unable to connect to the server"

**Solution:**
```bash
aws eks --region us-east-2 update-kubeconfig --name prod-dominion-cluster
```

### Issue: Pods Not Starting

**Diagnosis:**
```bash
kubectl describe pod <pod-name> -n fintech
kubectl logs <pod-name> -n fintech
kubectl get events -n fintech
```

**Common Causes:**
- Image pull errors (check ECR permissions)
- Resource limits (CPU/memory)
- Config errors
- Network issues

### Issue: ALB Not Created

**Diagnosis:**
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

**Common Causes:**
- IAM role issues
- Subnet tagging missing
- Ingress annotation errors

---

## 📚 Additional Resources

### Documentation
- [Implementation Guide](IMPLEMENTATION_GUIDE.md) - Detailed deployment guide
- [Quick Start](QUICK_START.md) - Command reference
- [Deployment Checklist](DEPLOYMENT_CHECKLIST.md) - Step-by-step checklist

### External Links
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS ALB Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

---

## 🎓 Learning Path

### For Beginners
1. Understand Terraform basics
2. Learn AWS fundamentals (VPC, EC2, IAM)
3. Study Kubernetes concepts
4. Practice with dev environment

### For Intermediate Users
1. Customize modules for your needs
2. Implement monitoring and alerting
3. Set up CI/CD pipelines
4. Optimize costs and performance

### For Advanced Users
1. Implement GitOps with ArgoCD/Flux
2. Add service mesh (Istio/Linkerd)
3. Implement advanced monitoring (Prometheus/Grafana)
4. Multi-region deployment
5. Disaster recovery automation

---

**This infrastructure provides a solid foundation for running production fintech applications on AWS with security, scalability, and maintainability in mind.**

---

**Last Updated:** November 19, 2025  
**Version:** 1.0.0  
**Maintainer:** Infrastructure Team
