# Fintech Infrastructure - AWS EKS Terraform Deployment

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D0.12.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326CE5?logo=kubernetes)](https://kubernetes.io/)

## 🎯 Overview

Complete **Infrastructure as Code (IaC)** solution for deploying a production-grade fintech application on AWS using Terraform. This project provisions an Amazon EKS cluster with all supporting infrastructure including networking, security, CI/CD tools, and monitoring capabilities.

## 🏗️ Architecture

```
AWS Cloud (Multi-AZ)
├── VPC with Public/Private Subnets
├── EKS Cluster (Kubernetes)
│   ├── Managed Node Groups (Auto-scaling)
│   ├── ALB Ingress Controller
│   └── IRSA (IAM Roles for Service Accounts)
├── Supporting Services
│   ├── ECR (Container Registry)
│   ├── ACM (SSL Certificates)
│   ├── Route53 (DNS)
│   └── CloudWatch (Monitoring)
└── DevOps Tools
    ├── Jenkins (CI/CD)
    ├── SonarQube (Code Quality)
    ├── EKS Client Node (Bastion)
    └── Terraform Node
```

## 🚀 Quick Start

```bash
# 1. Navigate to environment
cd dev/

# 2. Initialize Terraform
terraform init

# 3. Plan deployment
terraform plan

# 4. Deploy infrastructure
terraform apply -auto-approve

# 5. Configure kubectl
aws eks --region us-east-2 update-kubeconfig --name prod-dominion-cluster
```

## 📚 Documentation

- **[Implementation Guide](IMPLEMENTATION_GUIDE.md)** - Comprehensive deployment and architecture guide
- **[Quick Start](QUICK_START.md)** - Commands and cheat sheet reference

## ✨ Features

- ✅ **Multi-Environment Support** - dev, QA, UAT, production
- ✅ **EKS Cluster** - Fully managed Kubernetes with auto-scaling
- ✅ **High Availability** - Multi-AZ deployment
- ✅ **SSL/TLS** - Automatic certificate management
- ✅ **Load Balancing** - AWS Application Load Balancer
- ✅ **Container Registry** - Private ECR repositories
- ✅ **CI/CD Pipeline** - Jenkins integration
- ✅ **Code Quality** - SonarQube analysis
- ✅ **Secure Access** - Bastion hosts with SSM
- ✅ **Monitoring Ready** - CloudWatch integration
- ✅ **Remote State** - S3 backend with DynamoDB locking

## 🗂️ Project Structure

```
fintech-infra/
├── dev/                    # Development environment
├── qa/                     # QA environment
├── uat/                    # UAT environment
├── prod/                   # Production environment
├── modules/                # Reusable Terraform modules
│   ├── vpc/               # VPC networking
│   ├── eks-cluster/       # EKS cluster
│   ├── eks-client-node/   # Bastion/client node
│   ├── aws-alb-controller/# ALB controller
│   ├── ecr/               # Container registry
│   ├── acm/               # SSL certificates
│   ├── iam/               # IAM roles
│   ├── jenkins-server/    # Jenkins CI/CD
│   └── maven-sonarqube-server/  # Code quality
├── scripts/               # Helper scripts
└── docs/                  # Documentation
```

## 📋 Prerequisites

### Required Tools
- Terraform >= 0.12.0
- AWS CLI (configured)
- kubectl
- Helm
- Docker

### AWS Requirements
- AWS Account with admin access
- S3 bucket for Terraform state
- DynamoDB table for state locking
- Route53 hosted zone
- Valid domain name

## 🔧 Configuration

Before deployment, update the following in `dev/variables.tf`:

```hcl
cluster_name    = "your-cluster-name"
domain_name     = "yourdomain.com"
aws_account_id  = "YOUR_ACCOUNT_ID"
route53_zone_id = "YOUR_ZONE_ID"
```

⚠️ **Important:** Fix the typo in `dev/providers.tf` line 3:
```hcl
region = "us-east-2"  # Add quotes and fix the typo
```

## 🌍 Environments

| Environment | Directory | Purpose |
|-------------|-----------|---------|
| Development | `dev/` | Development and testing |
| QA | `qa/` | Quality assurance |
| UAT | `uat/` | User acceptance testing |
| Production | `prod/` | Live production environment |

## 🛠️ Key Modules

| Module | Description |
|--------|-------------|
| **vpc** | Multi-AZ VPC with public/private subnets |
| **eks-cluster** | EKS control plane and node groups |
| **eks-client-node** | Bastion host with management tools |
| **aws-alb-controller** | Kubernetes ingress controller |
| **ecr** | Docker container registries |
| **acm** | SSL/TLS certificate management |
| **iam** | IAM roles and Kubernetes service accounts |
| **jenkins-server** | CI/CD automation server |
| **maven-sonarqube-server** | Build and code quality tools |

## 🔐 Security Features

- VPC with isolated subnets
- Security groups with least privilege
- IAM roles for service accounts (IRSA)
- Private EKS endpoints option
- SSL/TLS encryption
- SSM Session Manager for secure access
- Container image scanning

## 💰 Cost Optimization

- Auto-scaling node groups
- Spot instance support
- Resource tagging for cost allocation
- Scheduled scaling policies
- Right-sized instance types

## 📊 Monitoring

- CloudWatch Container Insights
- EKS control plane logging
- Application Load Balancer metrics
- Custom CloudWatch dashboards
- Optional: Prometheus & Grafana

## 🚦 Deployment Process

1. **Plan** - Review changes with `terraform plan`
2. **Apply** - Deploy with `terraform apply`
3. **Verify** - Check resources in AWS console
4. **Configure** - Update kubeconfig for cluster access
5. **Deploy Apps** - Deploy containerized applications
6. **Monitor** - Set up monitoring and alerts

## 🔄 CI/CD Integration

The infrastructure includes Jenkins for continuous integration and deployment:
- Automated builds
- Container image creation
- Push to ECR
- Deploy to EKS
- Quality gates with SonarQube

## 🧪 Testing

```bash
# Validate Terraform
terraform validate

# Check cluster connectivity
kubectl cluster-info

# Verify node health
kubectl get nodes

# Check all resources
kubectl get all -A
```

## 🆘 Troubleshooting

Common issues and solutions:

1. **State lock error** - Use `terraform force-unlock <LOCK_ID>`
2. **kubectl connection** - Update kubeconfig with AWS CLI
3. **Provider error** - Fix region typo in providers.tf
4. **Docker push fails** - Re-authenticate with ECR

See [Implementation Guide](IMPLEMENTATION_GUIDE.md) for detailed troubleshooting.

## 📈 Scaling

- **Horizontal Pod Autoscaler** - Scale pods based on metrics
- **Cluster Autoscaler** - Scale nodes based on demand
- **Load Balancer** - Distribute traffic efficiently
- **Multi-AZ** - High availability across zones

## 🔄 Maintenance

- Regular Terraform state backups
- Kubernetes version updates
- Security patches for worker nodes
- Certificate renewal (automated)
- Cost optimization reviews

## 📝 Best Practices

- Use remote state in S3
- Enable state locking with DynamoDB
- Tag all resources consistently
- Use modules for reusability
- Version control all configurations
- Review security groups regularly
- Implement least privilege access
- Enable audit logging

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- HashiCorp Terraform
- AWS EKS Team
- Kubernetes Community
- Open Source Contributors

## 📞 Support

For detailed implementation instructions, see:
- [Implementation Guide](IMPLEMENTATION_GUIDE.md)
- [Quick Start Guide](QUICK_START.md)

---

**Built with ❤️ for Fintech Applications**
