# AWS IAM OIDC Configuration Guide

## Overview
This guide walks you through configuring AWS IAM for OIDC authentication with GitHub Actions for the fintech-infra repository.

**Target Role:** `arn:aws:iam::205991466249:role/d3mola3d`
**Repository:** `demolized/fintech-infra`
**Branch Restriction:** `beta-test`

---

## Part 1: Verify/Create OIDC Identity Provider

### Step 1.1: Check if OIDC Provider Exists
1. Open AWS Console → **IAM** → **Identity providers**
2. Look for provider with URL: `https://token.actions.githubusercontent.com`

### Step 1.2: Create OIDC Provider (if missing)
If the provider doesn't exist:

1. Click **Add provider**
2. Select **OpenID Connect**
3. **Provider URL:** `https://token.actions.githubusercontent.com`
4. **Audience:** `sts.amazonaws.com`
5. Click **Add provider**

---

## Part 2: Configure IAM Role Trust Policy

### Step 2.1: Navigate to Role
1. AWS Console → **IAM** → **Roles** 
2. Search for and click **d3mola3d**

### Step 2.2: Update Trust Policy
1. Click **Trust relationships** tab
2. Click **Edit trust policy**
3. Replace the entire trust policy with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::205991466249:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:demolized/fintech-infra:ref:refs/heads/beta-test"
        }
      }
    }
  ]
}
```

4. Click **Update policy**

> **Security Note:** This restricts the role to ONLY the `beta-test` branch of your repository.

---

## Part 3: Configure Permissions Policy

The role needs permissions to manage your Terraform infrastructure. You'll need to check your Terraform configurations to determine exact requirements.

### Step 3.1: Check Current Terraform Backend Configuration

First, let's identify what permissions are needed by examining your backend configuration:

```bash
# Check backend configuration in each environment
cat dev/backend.tf
cat prod/backend.tf
cat qa/backend.tf
cat uat/backend.tf
```

### Step 3.2: Basic Terraform Backend Permissions

Create a policy with minimum backend permissions (replace placeholders with actual values):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning"
      ],
      "Resource": "arn:aws:s3:::YOUR_TERRAFORM_STATE_BUCKET"
    },
    {
      "Sid": "TerraformStateObjects",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::YOUR_TERRAFORM_STATE_BUCKET/*"
    },
    {
      "Sid": "TerraformLockTable",
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-2:205991466249:table/YOUR_LOCK_TABLE"
    }
  ]
}
```

### Step 3.3: Additional Infrastructure Permissions

Based on your modules, you'll likely need permissions for:
- **VPC/Networking:** EC2 VPC actions
- **EKS:** EKS cluster management
- **IAM:** Role/policy management  
- **ECR:** Container registry
- **ALB:** Load balancer management
- **ACM:** Certificate management

**Recommendation:** Start with basic backend permissions and add others incrementally based on Terraform plan output.

---

## Part 4: Test Configuration

### Step 4.1: Push Changes and Test
1. Ensure your workflow changes are pushed to `beta-test` branch
2. Go to GitHub → Actions → **Terraform-AWS-Infra-Deployment**
3. Click **Run workflow**
4. Select:
   - **Branch:** `beta-test`
   - **Environment:** `dev` (safest for testing)
   - **Region:** `us-east-2`
   - **Action:** `plan`
5. Monitor logs for:
   - ✅ "Retrieved credentials via OIDC"
   - ✅ Successful AWS authentication
   - ✅ Terraform init success

### Step 4.2: Troubleshooting Common Issues

**Issue:** `AssumeRoleWithWebIdentity` failed
- **Fix:** Check trust policy syntax and branch restriction

**Issue:** Access denied during terraform init
- **Fix:** Add S3/DynamoDB permissions to role

**Issue:** Access denied during terraform plan
- **Fix:** Add infrastructure-specific permissions

---

## Next Steps After Basic Setup

1. **Identify Required Permissions:** Run terraform plan and note any permission errors
2. **Create Custom Policy:** Build specific policy based on your infrastructure needs
3. **Test All Environments:** Verify dev, qa, uat, prod configurations
4. **Document:** Keep track of required permissions for future reference

---

## Security Best Practices

✅ **Branch Restriction:** Trust policy limits to `beta-test` branch
✅ **Least Privilege:** Only add permissions actually needed
✅ **Resource ARNs:** Scope permissions to specific resources when possible
✅ **Regular Review:** Audit role permissions periodically

---

## Emergency Fallback

If OIDC setup faces issues, you can temporarily revert to the access key method:
1. Store keys in GitHub repository secrets
2. Modify workflow to use `aws-actions/configure-aws-credentials@v4` with access-key-id/secret-access-key
3. Switch back to OIDC once issues are resolved

---

## Support Commands

Use these to gather information during setup:

```bash
# Check current AWS identity (if AWS CLI available)
aws sts get-caller-identity

# List OIDC providers
aws iam list-open-id-connect-providers

# Describe role
aws iam get-role --role-name d3mola3d

# Get role trust policy  
aws iam get-role --role-name d3mola3d --query 'Role.AssumeRolePolicyDocument'
```