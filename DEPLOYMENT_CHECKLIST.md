# Deployment Checklist - Fintech Infrastructure

Use this checklist to ensure a successful deployment of the fintech infrastructure. Check off each item as you complete it.

---

## 📋 Pre-Deployment Phase

### 1. AWS Prerequisites
- [ ] AWS Account created and accessible
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS credentials configured (`aws configure`)
- [ ] Account ID verified (`aws sts get-caller-identity`)
- [ ] Sufficient permissions (EC2, EKS, VPC, IAM, S3, ECR, ACM, Route53)

### 2. Tool Installation
- [ ] Terraform >= 0.12.0 installed (`terraform version`)
- [ ] kubectl installed (`kubectl version --client`)
- [ ] Helm installed (optional, for later use)
- [ ] Docker installed (for building images)
- [ ] Git installed (for version control)

### 3. S3 Backend Setup
- [ ] S3 bucket created: `class38dominion-terraform-backend`
  ```bash
  aws s3api create-bucket \
    --bucket class38dominion-terraform-backend \
    --region us-east-2 \
    --create-bucket-configuration LocationConstraint=us-east-2
  ```
- [ ] Versioning enabled on S3 bucket
  ```bash
  aws s3api put-bucket-versioning \
    --bucket class38dominion-terraform-backend \
    --versioning-configuration Status=Enabled
  ```

### 4. DynamoDB State Lock Table
- [ ] DynamoDB table created: `terraform-state-locking`
  ```bash
  aws dynamodb create-table \
    --table-name terraform-state-locking \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-2
  ```
- [ ] Table verified
  ```bash
  aws dynamodb describe-table --table-name terraform-state-locking --region us-east-2
  ```

### 5. SSH Key Pair
- [ ] SSH key pair created in AWS
  ```bash
  aws ec2 create-key-pair --key-name class38_demo_key --region us-east-2 --query 'KeyMaterial' --output text > class38_demo_key.pem
  chmod 400 class38_demo_key.pem
  ```
- [ ] Key pair name noted: ___________________

### 6. Route53 & Domain
- [ ] Domain registered or available
- [ ] Route53 hosted zone created
- [ ] Hosted Zone ID noted: ___________________
- [ ] NS records configured with domain registrar

---

## 🔧 Configuration Phase

### 7. Clone/Download Repository
- [ ] Repository downloaded to local machine
- [ ] Navigate to project directory
  ```bash
  cd c:\Users\FALADEA\Downloads\fintech-Infra\fintech-infra
  ```

### 8. Fix Provider Configuration (CRITICAL)
- [ ] Fix typo in `dev/providers.tf` line 3
  ```hcl
  # BEFORE:
  region = us-eest-2
  
  # AFTER:
  region = "us-east-2"
  ```

### 9. Update Variables
- [ ] Open `dev/variables.tf` or create `dev/terraform.tfvars`
- [ ] Update `cluster_name` (line 18): ___________________
- [ ] Update `domain_name` (line 70): ___________________
- [ ] Update `san_domains` (line 76): ___________________
- [ ] Update `route53_zone_id` (line 82): ___________________
- [ ] Update `aws_account_id` (line 90): ___________________
- [ ] Update `rolearn` (line 23): ___________________
- [ ] Update `key_name` (line 63): ___________________
- [ ] Update `repositories` if needed (line 96)

### 10. Review Backend Configuration
- [ ] Verify S3 bucket name in `dev/backend.tf` (line 5)
- [ ] Verify DynamoDB table name in `dev/backend.tf` (line 7)
- [ ] Verify region in `dev/backend.tf` (line 6)

---

## 🚀 Deployment Phase

### 11. Initialize Terraform
```bash
cd dev/
```
- [ ] Run `terraform init`
- [ ] Verify successful initialization
- [ ] Backend initialized successfully
- [ ] Provider plugins downloaded

### 12. Validate Configuration
- [ ] Run `terraform validate`
- [ ] All validation checks pass
- [ ] No syntax errors

### 13. Review Deployment Plan
- [ ] Run `terraform plan`
- [ ] Review all resources to be created
- [ ] Verify resource counts:
  - VPC resources (subnets, route tables, gateways)
  - EKS cluster
  - EKS node groups
  - Security groups
  - IAM roles
  - EC2 instances (client node, Jenkins, etc.)
  - ECR repositories
  - ACM certificates
- [ ] No unexpected resource deletions
- [ ] Save plan: `terraform plan -out=tfplan`

### 14. Deploy Infrastructure

#### Option A: Deploy All at Once
- [ ] Run `terraform apply tfplan` or `terraform apply -auto-approve`
- [ ] Monitor deployment progress
- [ ] Wait for completion (typically 15-20 minutes for EKS)

#### Option B: Incremental Deployment (Recommended)
- [ ] Deploy VPC: `terraform apply -target=module.vpc -auto-approve`
- [ ] Deploy EKS Cluster: `terraform apply -target=module.eks -auto-approve`
- [ ] Deploy EKS Client Node: `terraform apply -target=module.eks-client-node -auto-approve`
- [ ] Deploy ALB Controller: `terraform apply -target=module.aws_alb_controller -auto-approve`
- [ ] Deploy ACM: `terraform apply -target=module.acm -auto-approve`
- [ ] Deploy ECR: `terraform apply -target=module.ecr -auto-approve`
- [ ] Deploy IAM: `terraform apply -target=module.iam -auto-approve`
- [ ] Deploy Jenkins: `terraform apply -target=module.jenkins-server -auto-approve`
- [ ] Deploy Maven/SonarQube: `terraform apply -target=module.maven-sonarqube-server -auto-approve`
- [ ] Deploy remaining: `terraform apply -auto-approve`

### 15. Verify Deployment
- [ ] No errors in Terraform output
- [ ] All resources created successfully
- [ ] Review outputs: `terraform output`
- [ ] Note important values:
  - VPC ID: ___________________
  - EKS Cluster Name: ___________________
  - EKS Cluster Endpoint: ___________________
  - Jenkins Public IP: ___________________
  - SonarQube Public IP: ___________________

---

## 🔌 Post-Deployment Phase

### 16. Configure kubectl Access
- [ ] Update kubeconfig
  ```bash
  aws eks --region us-east-2 update-kubeconfig --name prod-dominion-cluster
  ```
- [ ] Verify cluster connectivity
  ```bash
  kubectl cluster-info
  ```
- [ ] Check nodes
  ```bash
  kubectl get nodes
  ```
- [ ] Nodes showing as "Ready"

### 17. Verify Kubernetes Resources
- [ ] Check namespaces
  ```bash
  kubectl get namespaces
  ```
- [ ] Verify namespace creation:
  - [ ] `fintech` namespace exists
  - [ ] `monitoring` namespace exists
- [ ] Check system pods
  ```bash
  kubectl get pods -n kube-system
  ```
- [ ] Verify critical pods running:
  - [ ] CoreDNS pods
  - [ ] AWS Load Balancer Controller
  - [ ] kube-proxy

### 18. Verify SSL Certificate
- [ ] Check ACM certificate status
  ```bash
  aws acm list-certificates --region us-east-2
  ```
- [ ] Certificate status is "ISSUED"
- [ ] Certificate domain matches your domain

### 19. Configure DNS
- [ ] Get ALB DNS name (will be created when you deploy apps with ingress)
  ```bash
  kubectl get ingress -A
  ```
- [ ] Create/Update Route53 record pointing to ALB
- [ ] Verify DNS propagation
  ```bash
  nslookup yourdomain.com
  ```

### 20. Access EKS Client Node
- [ ] Get instance ID
  ```bash
  terraform output eks_client_instance_id
  ```
- [ ] Connect via SSM
  ```bash
  aws ssm start-session --target <instance-id>
  ```
- [ ] Verify tools installed:
  - [ ] AWS CLI: `aws --version`
  - [ ] kubectl: `kubectl version`
  - [ ] Docker: `docker --version`
  - [ ] Terraform: `terraform version`

### 21. Install Helm (on Client Node)
- [ ] SSH/SSM into client node
- [ ] Run Helm installation script
  ```bash
  sudo bash /path/to/scripts/install_helm.sh
  ```
- [ ] Verify Helm installation
  ```bash
  helm version
  ```
- [ ] Add Helm repositories
  ```bash
  helm repo add stable https://charts.helm.sh/stable
  helm repo update
  ```

### 22. Configure Jenkins
- [ ] Get Jenkins public IP
  ```bash
  terraform output jenkins_public_ip
  ```
- [ ] Access Jenkins: `http://<jenkins-ip>:8080`
- [ ] Get initial admin password
  ```bash
  ssh -i your-key.pem ubuntu@<jenkins-ip>
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```
- [ ] Complete Jenkins setup wizard
- [ ] Install suggested plugins
- [ ] Create admin user

### 23. Configure SonarQube
- [ ] Get SonarQube public IP
  ```bash
  terraform output sonarqube_public_ip
  ```
- [ ] Access SonarQube: `http://<sonarqube-ip>:9000`
- [ ] Login with default credentials (admin/admin)
- [ ] Change admin password
- [ ] Create project for your application

---

## 📦 Application Deployment Phase

### 24. Build Docker Image
- [ ] Navigate to your application directory
- [ ] Create Dockerfile (if not exists)
- [ ] Build image
  ```bash
  docker build -t fintech-app:latest .
  ```
- [ ] Test image locally
  ```bash
  docker run -p 8080:8080 fintech-app:latest
  ```

### 25. Push to ECR
- [ ] Get ECR repository URL
  ```bash
  terraform output ecr_repository_url
  ```
- [ ] Login to ECR
  ```bash
  aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 999568710647.dkr.ecr.us-east-2.amazonaws.com
  ```
- [ ] Tag image
  ```bash
  docker tag fintech-app:latest 999568710647.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest
  ```
- [ ] Push image
  ```bash
  docker push 999568710647.dkr.ecr.us-east-2.amazonaws.com/fintech-app:latest
  ```

### 26. Deploy to Kubernetes
- [ ] Create Kubernetes deployment manifest
- [ ] Create service manifest
- [ ] Create ingress manifest (for ALB)
- [ ] Apply manifests
  ```bash
  kubectl apply -f deployment.yaml -n fintech
  kubectl apply -f service.yaml -n fintech
  kubectl apply -f ingress.yaml -n fintech
  ```
- [ ] Verify deployment
  ```bash
  kubectl get deployments -n fintech
  kubectl get pods -n fintech
  kubectl get services -n fintech
  kubectl get ingress -n fintech
  ```
- [ ] All pods running successfully

---

## 📊 Monitoring & Validation Phase

### 27. Enable CloudWatch Container Insights
- [ ] Attach policy to worker node role
  ```bash
  aws iam attach-role-policy \
    --role-name <worker-node-role> \
    --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
  ```
- [ ] Create CloudWatch addon
  ```bash
  aws eks create-addon \
    --cluster-name prod-dominion-cluster \
    --addon-name amazon-cloudwatch-observability
  ```
- [ ] Verify addon status
  ```bash
  aws eks describe-addon \
    --cluster-name prod-dominion-cluster \
    --addon-name amazon-cloudwatch-observability
  ```

### 28. Verify Application Access
- [ ] Get application URL (from ingress)
  ```bash
  kubectl get ingress -n fintech
  ```
- [ ] Access application via browser
- [ ] Application loads successfully
- [ ] SSL certificate valid (green padlock)
- [ ] All features working

### 29. Test Auto-Scaling
- [ ] Set up Horizontal Pod Autoscaler
  ```bash
  kubectl autoscale deployment fintech-app --cpu-percent=70 --min=2 --max=10 -n fintech
  ```
- [ ] Verify HPA
  ```bash
  kubectl get hpa -n fintech
  ```
- [ ] Generate load (optional)
- [ ] Observe scaling behavior

### 30. Verify Monitoring
- [ ] Access CloudWatch console
- [ ] Check Container Insights dashboard
- [ ] Verify metrics collection:
  - [ ] CPU utilization
  - [ ] Memory utilization
  - [ ] Network traffic
  - [ ] Pod count
- [ ] Set up CloudWatch alarms (optional)

---

## 🔐 Security & Compliance Phase

### 31. Security Review
- [ ] Review security groups
  ```bash
  aws ec2 describe-security-groups --region us-east-2 | grep -i fintech
  ```
- [ ] Verify least privilege access
- [ ] No unnecessary ports open
- [ ] Review IAM roles and policies
- [ ] IRSA configured correctly

### 32. Enable Logging
- [ ] Enable EKS control plane logging
  ```bash
  aws eks update-cluster-config \
    --region us-east-2 \
    --name prod-dominion-cluster \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
  ```
- [ ] Verify logs in CloudWatch

### 33. Backup State Files
- [ ] Verify S3 bucket versioning enabled
- [ ] Download local state backup
  ```bash
  aws s3 cp s3://class38dominion-terraform-backend/dev/terraform.state ./backups/terraform.state.backup
  ```
- [ ] Store backup securely

---

## 📝 Documentation Phase

### 34. Document Deployment
- [ ] Record all custom configurations
- [ ] Document IP addresses and endpoints
- [ ] Note any deviations from standard setup
- [ ] Create runbook for common operations
- [ ] Document disaster recovery procedures

### 35. Knowledge Transfer
- [ ] Share access credentials (securely)
- [ ] Demonstrate cluster access
- [ ] Show how to deploy applications
- [ ] Explain monitoring setup
- [ ] Review troubleshooting procedures

---

## ✅ Final Validation

### 36. Smoke Tests
- [ ] Application accessible via domain
- [ ] SSL working correctly
- [ ] Load balancing functioning
- [ ] Auto-scaling configured
- [ ] Monitoring active
- [ ] Logs being collected
- [ ] Jenkins accessible
- [ ] SonarQube accessible

### 37. Performance Baseline
- [ ] Record initial performance metrics
- [ ] Document resource utilization
- [ ] Note response times
- [ ] Establish alerting thresholds

### 38. Handoff
- [ ] Deployment documentation complete
- [ ] Access credentials provided
- [ ] Monitoring configured
- [ ] Alerts set up
- [ ] Support contacts identified
- [ ] Sign-off obtained

---

## 🎯 Success Criteria

**Deployment is considered successful when:**
- ✅ All infrastructure deployed without errors
- ✅ EKS cluster operational with healthy nodes
- ✅ Application running and accessible
- ✅ SSL certificate valid
- ✅ Monitoring active and collecting data
- ✅ Auto-scaling configured and tested
- ✅ CI/CD tools (Jenkins) operational
- ✅ Code quality tools (SonarQube) operational
- ✅ Documentation complete
- ✅ Team trained on operations

---

## 📞 Troubleshooting Reference

If issues occur, refer to:
- [Implementation Guide](IMPLEMENTATION_GUIDE.md) - Detailed troubleshooting
- [Quick Start](QUICK_START.md) - Common commands
- AWS CloudWatch Logs
- Kubernetes events: `kubectl get events -A`
- Terraform state: `terraform show`

---

**Deployment Date:** ___________________  
**Deployed By:** ___________________  
**Environment:** ☐ Dev ☐ QA ☐ UAT ☐ Prod  
**Status:** ☐ In Progress ☐ Complete ☐ Failed  

---

**Last Updated:** November 19, 2025
