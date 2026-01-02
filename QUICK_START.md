# Quick Start Guide - Fintech Infrastructure

## 🚀 Quick Deployment (Dev Environment)

### 1️⃣ Prerequisites Check
```bash
# Verify tools installation
terraform version    # Should be >= 0.12.0
aws --version
kubectl version --client
```

### 2️⃣ Configure AWS
```bash
# Set up AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### 3️⃣ Update Configuration

**Update variables in `dev/variables.tf`:**
```hcl
cluster_name     = "your-cluster-name"
domain_name      = "yourdomain.com"
route53_zone_id  = "YOUR_ZONE_ID"
aws_account_id   = "YOUR_ACCOUNT_ID"
key_name         = "your-key-name"
```

### 4️⃣ Deploy Infrastructure

```bash
# Navigate to dev directory
cd dev/

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (choose one approach)

# Approach A: All at once
terraform apply -auto-approve

# Approach B: Step by step (recommended)
terraform apply -target=module.vpc -auto-approve
terraform apply -target=module.eks -auto-approve
terraform apply -target=module.eks-client-node -auto-approve
terraform apply -auto-approve
```

### 5️⃣ Access Cluster

```bash
# Update kubeconfig
aws eks --region us-east-2 update-kubeconfig --name prod-dominion-cluster

# Verify access
kubectl get nodes
kubectl get pods -A
```

### 6️⃣ Access Senior SRE Tools

```bash
# ArgoCD UI (Get password)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Argo Rollouts Dashboard
kubectl argo rollouts dashboard -n argo-rollouts

# Chaos Mesh Dashboard
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333
```

---

## 📋 Common Commands

### Terraform
```bash
# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Destroy specific resource
terraform destroy -target=module.jenkins-server

# Show outputs
terraform output

# Format code
terraform fmt -recursive

# Validate
terraform validate
```

### Kubernetes (Senior SRE Tools)

#### ArgoCD (GitOps)
```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Sync application
argocd app sync fintech-app-dev

# Check app status
argocd app get fintech-app-dev
```

#### Argo Rollouts (Progressive Delivery)
```bash
# Watch rollout status
kubectl argo rollouts get rollout fintech-app -n fintech

# Promote rollout
kubectl argo rollouts promote fintech-app -n fintech

# Abort rollout
kubectl argo rollouts abort fintech-app -n fintech
```

#### Chaos Mesh (Chaos Engineering)
```bash
# List chaos experiments
kubectl get networkchaos,podchaos,iochaos -A

# Apply a chaos experiment
kubectl apply -f scripts/chaos/pod-kill.yaml
```

#### Kyverno (Policy as Code)
```bash
# Check policy violations
kubectl get policyreport -A

# List cluster policies
kubectl get clusterpolicy
```

### Kubernetes (General)
```bash
# Get cluster info
kubectl cluster-info

# Get all resources
kubectl get all -A

# Get nodes
kubectl get nodes -o wide

# Get pods in namespace
kubectl get pods -n fintech

# Describe resource
kubectl describe pod <pod-name> -n fintech

# Get logs
kubectl logs <pod-name> -n fintech

# Port forward
kubectl port-forward svc/fintech-app 8080:80 -n fintech

# Execute command in pod
kubectl exec -it <pod-name> -n fintech -- /bin/bash
```

### AWS CLI
```bash
# List EKS clusters
aws eks list-clusters --region us-east-2

# Describe cluster
aws eks describe-cluster --name prod-dominion-cluster --region us-east-2

# List ECR repositories
aws ecr describe-repositories --region us-east-2

# Get ECR login
aws ecr get-login-password --region us-east-2

# List running instances
aws ec2 describe-instances --region us-east-2 --filters "Name=instance-state-name,Values=running"
```

### Docker & ECR
```bash
# Login to ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 999568710647.dkr.ecr.us-east-2.amazonaws.com

# Build image
docker build -t fintech-app:latest .

# Tag image
docker tag fintech-app:latest 999568710647.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest

# Push image
docker push 999568710647.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest

# Pull image
docker pull 999568710647.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest
```

---

## 🔍 Quick Troubleshooting

### Issue: Terraform State Lock
```bash
# Get lock ID from error, then:
terraform force-unlock <LOCK_ID>
```

### Issue: Can't Connect to Cluster
```bash
# Update kubeconfig
aws eks --region us-east-2 update-kubeconfig --name prod-dominion-cluster

# Check cluster status
aws eks describe-cluster --name prod-dominion-cluster --region us-east-2 --query cluster.status
```

### Issue: Pods Not Starting
```bash
# Check pod status
kubectl get pods -n fintech

# Describe pod for details
kubectl describe pod <pod-name> -n fintech

# Check events
kubectl get events -n fintech --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n fintech
```

### Issue: ALB Not Created
```bash
# Check ALB controller
kubectl get deployment -n kube-system aws-load-balancer-controller

# Check logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```
---

## 🗂️ Module Overview

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `vpc` | Networking | VPC, Subnets, IGW, NAT |
| `eks-cluster` | Kubernetes | EKS Control Plane, Node Groups |
| `eks-client-node` | Management | Bastion with kubectl, terraform |
| `aws-alb-controller` | Load Balancing | ALB Ingress Controller |
| `ecr` | Container Registry | ECR Repositories |
| `acm` | SSL Certificates | ACM Certificate + Validation |
| `iam` | Access Control | IAM Roles, Service Accounts |
| `argocd` | GitOps | ArgoCD Server, Repo Server |
| `argo-rollouts` | Progressive Delivery | Rollout Controller |
| `chaos-mesh` | Chaos Engineering | Chaos Daemon, Dashboard |
| `kyverno` | Policy as Code | Kyverno Admission Controller |
| `opentelemetry` | Observability | OTEL Collector |
| `jenkins-server` | CI/CD | Jenkins Server |
| `maven-sonarqube-server` | Code Quality | Maven + SonarQube |

---

## 🌍 Environment Structure

```
dev/     → Development environment
qa/      → Quality Assurance
uat/     → User Acceptance Testing
prod/    → Production
```

Each environment has:
- `main.tf` - Module orchestration
- `variables.tf` - Variable definitions
- `backend.tf` - State backend config
- `providers.tf` - Provider setup
- `*.tfvars` - Environment-specific values

---

## 📊 Important Outputs

After deployment, get important values:
```bash
# Show all outputs
terraform output

# Get specific output
terraform output vpc_id
terraform output eks_cluster_name
terraform output jenkins_public_ip
```

---

## 🔐 Security Checklist

- [ ] AWS credentials configured
- [ ] IAM roles properly set up
- [ ] S3 bucket for state exists
- [ ] DynamoDB table for locks exists
- [ ] SSH key pair created
- [ ] Route53 zone configured
- [ ] VPC endpoints configured (optional)
- [ ] Security groups reviewed
- [ ] Network ACLs configured

---

## 💡 Tips

1. **Always run `terraform plan`** before apply
2. **Use workspace** for managing multiple environments
3. **Enable state locking** to prevent conflicts
4. **Tag all resources** for cost tracking
5. **Use modules** for reusability
6. **Version pin providers** for consistency
7. **Regular backups** of tfstate files
8. **Document changes** in version control

---

## 📞 Getting Help

1. Check `IMPLEMENTATION_GUIDE.md` for detailed docs
2. Review CloudWatch logs
3. Check Kubernetes events: `kubectl get events -A`
4. Review Terraform plan output
5. Check AWS console for resource status

---

## 🚦 Deployment Checklist

### Pre-Deployment
- [ ] AWS credentials configured
- [ ] S3 backend bucket exists
- [ ] DynamoDB table exists
- [ ] Variables updated in `variables.tf`
- [ ] SSH key exists in AWS

### Deployment
- [ ] `terraform init` successful
- [ ] `terraform validate` passes
- [ ] `terraform plan` reviewed
- [ ] `terraform apply` completed
- [ ] No errors in output

### Post-Deployment
- [ ] Cluster accessible via kubectl
- [ ] Nodes are healthy
- [ ] Namespaces created
- [ ] ALB controller running
- [ ] ArgoCD installed and accessible
- [ ] Argo Rollouts controller running
- [ ] Chaos Mesh dashboard accessible
- [ ] Kyverno policies enforced
- [ ] DNS configured
- [ ] SSL certificate validated
- [ ] Applications deployed via ArgoCD
- [ ] Monitoring enabled with SLO alerts

---

**Last Updated:** January 1, 2026
