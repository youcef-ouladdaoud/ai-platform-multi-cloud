# GitHub Actions Secrets Setup Guide

Complete guide for obtaining and configuring cloud provider credentials for GitHub Actions deployment.

## Table of Contents
- [Overview](#overview)
- [Common Secrets (All Providers)](#common-secrets-all-providers)
- [AWS Setup](#aws-setup)
- [GCP Setup](#gcp-setup)
- [Azure Setup](#azure-setup)
- [Oracle Cloud Setup](#oracle-cloud-setup)
- [Configure Secrets in GitHub](#configure-secrets-in-github)
- [Environment Protection](#environment-protection)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project supports deployment to 4 cloud providers via GitHub Actions:
- **AWS** (EKS)
- **GCP** (GKE)
- **Azure** (AKS)
- **Oracle Cloud** (OKE) ⭐ *Recommended for free tier*

Each provider requires different authentication credentials. This guide will help you obtain and configure all necessary secrets.

---

## Common Secrets (All Providers)

These secrets are required regardless of which cloud provider(s) you use:

| Secret | Description | How to Get |
|--------|-------------|------------|
| `OLLAMA_API_KEY` | Your Ollama Cloud API key | [Get from Ollama](#getting-ollama-api-key) |
| `OPENAI_API_KEY` | OpenAI API key (optional) | [Get from OpenAI](#getting-openai-api-key) |

### Getting Ollama API Key

1. Visit [ollama.com](https://ollama.com) and create an account
2. Navigate to **Settings** → **API Keys**
3. Click **Generate New Key**
4. Copy the key (starts with `ollama_`)

### Getting OpenAI API Key (Optional)

1. Visit [platform.openai.com](https://platform.openai.com)
2. Go to **API Keys** section
3. Click **Create new secret key**
4. Copy the key (starts with `sk-`)

---

## AWS Setup

### Required Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key |

### Step-by-Step Instructions

#### 1. Create an IAM User

```bash
# Login to AWS Console
# Go to: IAM → Users → Add users
```

1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Click **Users** → **Add users**
3. Enter username: `github-actions-ai-platform`
4. Select **Access key - Programmatic access**
5. Click **Next: Permissions**

#### 2. Attach Required Policies

Attach these managed policies:
- `AmazonEKSClusterPolicy`
- `AmazonEKSWorkerNodePolicy`
- `AmazonEC2FullAccess`
- `AmazonVPCFullAccess`
- `IAMFullAccess`
- `AmazonRoute53FullAccess` (if using custom domain)

Or use this custom policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:*",
                "cloudformation:*",
                "logs:*",
                "route53:*"
            ],
            "Resource": "*"
        }
    ]
}
```

#### 3. Get Credentials

1. After creating the user, you'll see the **Access key ID** and **Secret access key**
2. **IMPORTANT**: Copy the Secret access key immediately - you can't see it again!
3. Save both values for GitHub secrets

---

## GCP Setup

### Required Secrets

| Secret | Description |
|--------|-------------|
| `GCP_PROJECT_ID` | Your Google Cloud project ID |
| `GCP_SA_KEY` | Service account JSON key |

### Step-by-Step Instructions

#### 1. Create a GCP Project

```bash
# Go to: https://console.cloud.google.com/projectcreate
```

1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project selector → **New Project**
3. Enter project name: `ai-platform`
4. Note the **Project ID** (e.g., `ai-platform-123456`)

#### 2. Enable Required APIs

```bash
# Enable these APIs:
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
```

Or via Console:
- Go to **APIs & Services** → **Library**
- Enable: Kubernetes Engine API, Compute Engine API, IAM API

#### 3. Create Service Account

```bash
# Create service account
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions"

# Get the service account email
SA_EMAIL="github-actions@YOUR-PROJECT-ID.iam.gserviceaccount.com"
```

#### 4. Grant Required Roles

```bash
# Add roles to service account
gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/iam.serviceAccountUser"
```

#### 5. Create and Download JSON Key

```bash
# Create JSON key
gcloud iam service-accounts keys create key.json \
    --iam-account=$SA_EMAIL

# View the key (copy this for GitHub secret)
cat key.json | base64 -w 0
```

Or via Console:
1. Go to **IAM & Admin** → **Service Accounts**
2. Click your service account → **Keys** tab
3. **Add Key** → **Create new key** → **JSON**
4. The JSON file downloads automatically
5. Encode to base64: `base64 -w 0 key.json`
6. Copy the output for `GCP_SA_KEY`

---

## Azure Setup

### Required Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Full Azure service principal JSON |
| `ARM_CLIENT_ID` | Service Principal App ID |
| `ARM_CLIENT_SECRET` | Service Principal Password |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID |
| `ARM_TENANT_ID` | Azure Tenant ID |

### Step-by-Step Instructions

#### 1. Get Subscription and Tenant ID

```bash
# Login to Azure
az login

# Get subscription ID
az account show --query id -o tsv

# Get tenant ID
az account show --query tenantId -o tsv
```

#### 2. Create Service Principal

```bash
# Create service principal with contributor role
az ad sp create-for-rbac \
    --name "github-actions-ai-platform" \
    --role contributor \
    --scopes /subscriptions/YOUR-SUBSCRIPTION-ID \
    --sdk-auth
```

#### 3. Output Format

The command outputs JSON like this:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

#### 4. Save Values

| Secret | Value from JSON |
|--------|-----------------|
| `AZURE_CREDENTIALS` | Entire JSON (for azure/login action) |
| `ARM_CLIENT_ID` | `clientId` |
| `ARM_CLIENT_SECRET` | `clientSecret` |
| `ARM_SUBSCRIPTION_ID` | `subscriptionId` |
| `ARM_TENANT_ID` | `tenantId` |

---

## Oracle Cloud Setup

### Required Secrets

| Secret | Description |
|--------|-------------|
| `OCI_TENANCY_OCID` | Tenancy OCID |
| `OCI_USER_OCID` | User OCID |
| `OCI_FINGERPRINT` | API Key Fingerprint |
| `OCI_PRIVATE_KEY` | API Private Key (entire content) |
| `OCI_COMPARTMENT_OCID` | Compartment OCID |
| `OCI_NAMESPACE` | Object Storage Namespace |

### Step-by-Step Instructions

#### 1. Get Required OCIDs

**Tenancy OCID:**
1. Login to [Oracle Cloud Console](https://cloud.oracle.com)
2. Click your **Profile** (top right) → **Tenancy: your-tenancy**
3. Copy the **OCID** (starts with `ocid1.tenancy.`)

**User OCID:**
1. Go to **Profile** → **User Settings**
2. Copy the **OCID** (starts with `ocid1.user.`)

**Compartment OCID:**
1. Go to **Identity & Security** → **Compartments**
2. Click your compartment (usually the root compartment)
3. Copy the **OCID** (starts with `ocid1.compartment.`)

**Namespace:**
1. Go to **Storage** → **Buckets**
2. The namespace is shown at the top (format: `namespace-name`)

#### 2. Generate API Key

```bash
# Generate private key
openssl genrsa -out ~/.oci/oci_api_key.pem 2048

# Generate public key
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Get fingerprint
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c
```

#### 3. Upload Public Key to OCI

1. Go to **Profile** → **User Settings** → **API Keys**
2. Click **Add API Key**
3. Select **Paste Public Keys**
4. Paste the content of `~/.oci/oci_api_key_public.pem`
5. Click **Add**
6. Copy the **Fingerprint** shown

#### 4. Get Private Key Content

```bash
# Display private key (copy this for GitHub secret)
cat ~/.oci/oci_api_key.pem
```

Copy the entire content including:
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

---

## Configure Secrets in GitHub

### Method 1: GitHub Web Interface

1. Go to your repository: `https://github.com/youcef-ouladdaoud/ai-platform-multi-cloud`
2. Click **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret:
   - Name: (e.g., `AWS_ACCESS_KEY_ID`)
   - Value: (the secret value)

### Method 2: Using GitHub CLI (if installed locally)

```bash
# Set your repo
REPO="youcef-ouladdaoud/ai-platform-multi-cloud"

# Common secrets
gh secret set OLLAMA_API_KEY -b"your-ollama-api-key" -R $REPO
gh secret set OPENAI_API_KEY -b"your-openai-api-key" -R $REPO

# AWS secrets
gh secret set AWS_ACCESS_KEY_ID -b"your-access-key" -R $REPO
gh secret set AWS_SECRET_ACCESS_KEY -b"your-secret-key" -R $REPO

# GCP secrets
gh secret set GCP_PROJECT_ID -b"your-project-id" -R $REPO
gh secret set GCP_SA_KEY -b"your-base64-encoded-key" -R $REPO

# Azure secrets
gh secret set AZURE_CREDENTIALS -b'{"clientId":"..."}' -R $REPO
gh secret set ARM_CLIENT_ID -b"your-client-id" -R $REPO
gh secret set ARM_CLIENT_SECRET -b"your-client-secret" -R $REPO
gh secret set ARM_SUBSCRIPTION_ID -b"your-subscription-id" -R $REPO
gh secret set ARM_TENANT_ID -b"your-tenant-id" -R $REPO

# Oracle secrets
gh secret set OCI_TENANCY_OCID -b"ocid1.tenancy...." -R $REPO
gh secret set OCI_USER_OCID -b"ocid1.user...." -R $REPO
gh secret set OCI_FINGERPRINT -b"aa:bb:cc:dd:ee:ff..." -R $REPO
gh secret set OCI_PRIVATE_KEY -b"-----BEGIN RSA PRIVATE KEY-----..." -R $REPO
gh secret set OCI_COMPARTMENT_OCID -b"ocid1.compartment...." -R $REPO
gh secret set OCI_NAMESPACE -b"your-namespace" -R $REPO
```

### Complete Secrets List

Add these secrets based on which providers you want to use:

```bash
# ============ COMMON ============
OLLAMA_API_KEY
OPENAI_API_KEY          # Optional

# ============ AWS ============
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

# ============ GCP ============
GCP_PROJECT_ID
GCP_SA_KEY

# ============ AZURE ============
AZURE_CREDENTIALS       # Full JSON
ARM_CLIENT_ID
ARM_CLIENT_SECRET
ARM_SUBSCRIPTION_ID
ARM_TENANT_ID

# ============ ORACLE ============
OCI_TENANCY_OCID
OCI_USER_OCID
OCI_FINGERPRINT
OCI_PRIVATE_KEY         # Full key content
OCI_COMPARTMENT_OCID
OCI_NAMESPACE
```

---

## Environment Protection

GitHub Actions workflows use GitHub Environments for deployment approvals.

### Setup Environments

1. Go to **Settings** → **Environments**
2. Create these environments:
   - `dev` (no protection rules)
   - `staging` (optional: require reviewers)
   - `prod` (required reviewers + wait timer)

### Environment Protection Rules

For `prod` environment:
1. Enable **Required reviewers** (add yourself)
2. Set **Wait timer** (e.g., 5 minutes)
3. Enable **Deployment branches** → restrict to `main`

---

## Troubleshooting

### Common Issues

#### AWS: "InvalidClientTokenId"
- **Cause**: Wrong AWS credentials
- **Fix**: Regenerate access keys in IAM

#### GCP: "Could not find default credentials"
- **Cause**: Invalid or expired service account key
- **Fix**: Create new JSON key and re-encode to base64

#### Azure: "InvalidAuthenticationToken"
- **Cause**: Service principal expired or wrong tenant
- **Fix**: Run `az ad sp create-for-rbac` again

#### Oracle: "NotAuthenticated"
- **Cause**: Wrong fingerprint or private key format
- **Fix**: Ensure private key includes BEGIN/END markers and newlines

### Verify Secrets

Create this workflow to test secrets:

```yaml
# .github/workflows/test-secrets.yml
name: Test Secrets

on:
  workflow_dispatch:

jobs:
  test-aws:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2
      - run: aws sts get-caller-identity

  test-gcp:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - run: gcloud auth list

  test-azure:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - run: az account show
```

---

## Quick Reference

| Provider | Setup Time | Free Tier | Recommended For |
|----------|-----------|-----------|-----------------|
| **Oracle** | 15 min | ✅ Always Free | Best value, no costs |
| **GCP** | 10 min | $300 credit | Easiest setup |
| **AWS** | 15 min | 750 hrs EC2 | Enterprise features |
| **Azure** | 15 min | $200 credit | Microsoft ecosystem |

### Cost-Free Deployment

**Oracle Cloud** is the only provider with truly free Kubernetes:
- 4 ARM-based instances (Always Free)
- OKE (Oracle Kubernetes Engine) - Free
- No charges for API calls

---

## Security Best Practices

1. ✅ Use separate service accounts for CI/CD
2. ✅ Restrict IAM permissions to minimum required
3. ✅ Rotate secrets every 90 days
4. ✅ Enable branch protection on `main`
5. ✅ Require reviews for production deployments
6. ✅ Never commit secrets to code
7. ✅ Use GitHub Environments for approval gates

---

## Next Steps

After configuring secrets:

1. **Test locally first:**
   ```bash
   cd terraform/oracle  # or aws/gcp/azure
   terraform init
   terraform plan
   ```

2. **Trigger GitHub Actions:**
   - Push to `develop` branch for dev environment
   - Push to `main` branch for production
   - Or use **Actions** → **Deploy** → **Run workflow**

3. **Monitor deployments:**
   - Go to **Actions** tab in your repository
   - Watch the workflow execution
   - Check logs if anything fails

---

**Need Help?** Check the provider documentation:
- [AWS IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/)
- [GCP IAM](https://cloud.google.com/iam/docs)
- [Azure AD](https://docs.microsoft.com/en-us/azure/active-directory/)
- [Oracle IAM](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/overview.htm)
