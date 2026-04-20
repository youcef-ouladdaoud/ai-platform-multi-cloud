# GitHub Secrets Quick Reference

Copy this table and fill in your values before adding to GitHub.

## Common Secrets (Required for all providers)

| Secret | Your Value | Source |
|--------|------------|--------|
| `OLLAMA_API_KEY` | | https://ollama.com/settings/api |
| `OPENAI_API_KEY` | | https://platform.openai.com/api-keys (optional) |

## AWS Secrets

| Secret | Your Value | Source |
|--------|------------|--------|
| `AWS_ACCESS_KEY_ID` | | IAM Console → Users → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | | IAM Console (shown once when creating key) |

**Setup Steps:**
1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
2. Create user: `github-actions-ai-platform`
3. Attach policies: AmazonEKSClusterPolicy, AmazonEKSWorkerNodePolicy, AmazonEC2FullAccess, AmazonVPCFullAccess
4. Create Access Key → Copy credentials

## GCP Secrets

| Secret | Your Value | Source |
|--------|------------|--------|
| `GCP_PROJECT_ID` | | GCP Console → Dashboard |
| `GCP_SA_KEY` | (base64) | Service Account JSON key |

**Setup Steps:**
```bash
# 1. Create service account
gcloud iam service-accounts create github-actions --display-name="GitHub Actions"

# 2. Get project ID
export PROJECT_ID=$(gcloud config get-value project)

# 3. Add roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# 4. Create and encode key
gcloud iam service-accounts keys create key.json \
    --iam-account="github-actions@$PROJECT_ID.iam.gserviceaccount.com"
export GCP_SA_KEY=$(base64 -w 0 key.json)
echo "GCP_PROJECT_ID: $PROJECT_ID"
echo "GCP_SA_KEY: $GCP_SA_KEY"
```

## Azure Secrets

| Secret | Your Value | Source |
|--------|------------|--------|
| `AZURE_CREDENTIALS` | (full JSON) | Service Principal creation output |
| `ARM_CLIENT_ID` | | Same as clientId in JSON |
| `ARM_CLIENT_SECRET` | | Same as clientSecret in JSON |
| `ARM_SUBSCRIPTION_ID` | | Same as subscriptionId in JSON |
| `ARM_TENANT_ID` | | Same as tenantId in JSON |

**Setup Steps:**
```bash
# Login and get IDs
az login
az account show --query id -o tsv      # Subscription ID
az account show --query tenantId -o tsv # Tenant ID

# Create service principal (outputs JSON for AZURE_CREDENTIALS)
az ad sp create-for-rbac \
    --name "github-actions-ai-platform" \
    --role contributor \
    --scopes /subscriptions/YOUR-SUBSCRIPTION-ID \
    --sdk-auth
```

## Oracle Cloud Secrets

| Secret | Your Value | Source |
|--------|------------|--------|
| `OCI_TENANCY_OCID` | | Profile → Tenancy: your-tenancy |
| `OCI_USER_OCID` | | Profile → User Settings |
| `OCI_FINGERPRINT` | | User Settings → API Keys |
| `OCI_PRIVATE_KEY` | (full key) | ~/.oci/oci_api_key.pem |
| `OCI_COMPARTMENT_OCID` | | Identity → Compartments → Root |
| `OCI_NAMESPACE` | | Storage → Buckets (top of page) |

**Setup Steps:**
```bash
# 1. Get OCIDs from OCI Console
#    - Tenancy OCID: Profile → Tenancy
#    - User OCID: Profile → User Settings
#    - Compartment OCID: Identity → Compartments
#    - Namespace: Storage → Buckets

# 2. Generate API key
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# 3. Get fingerprint
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c

# 4. Upload public key in OCI Console
#    Profile → User Settings → API Keys → Add API Key

# 5. Get private key content
cat ~/.oci/oci_api_key.pem
```

---

## How to Add to GitHub

### Option 1: Web Interface (Recommended)
1. Go to: `https://github.com/youcef-ouladdaoud/ai-platform-multi-cloud/settings/secrets/actions`
2. Click **New repository secret**
3. Add each secret one by one

### Option 2: Using Script
```bash
# Download and run the helper script
./scripts/setup-github-secrets.sh
```

### Option 3: Using gh CLI
```bash
# Install gh: https://cli.github.com/

# Example for Ollama
gh secret set OLLAMA_API_KEY -b"your-key" -R youcef-ouladdaoud/ai-platform-multi-cloud

# Example for AWS
gh secret set AWS_ACCESS_KEY_ID -b"your-key" -R youcef-ouladdaoud/ai-platform-multi-cloud
gh secret set AWS_SECRET_ACCESS_KEY -b"your-secret" -R youcef-ouladdaoud/ai-platform-multi-cloud
```

---

## Provider Selection Guide

| Provider | Free Tier | Setup Complexity | Recommended For |
|----------|-----------|------------------|-----------------|
| **Oracle Cloud** | ✅ Always Free | Medium | Best value, no costs ever |
| **GCP** | $300 credit | Easy | Fast setup, great docs |
| **AWS** | 750 hrs/month | Medium | Enterprise features |
| **Azure** | $200 credit | Medium | Microsoft integration |

**Recommendation:** Start with Oracle Cloud for truly free Kubernetes, then add others as needed.

---

## Test Your Secrets

After adding secrets, test them:

1. Go to GitHub Actions: `https://github.com/youcef-ouladdaoud/ai-platform-multi-cloud/actions`
2. Select a workflow (e.g., "Deploy to Oracle Cloud OKE")
3. Click **Run workflow**
4. Choose environment: `dev`
5. Click **Run workflow**

If it fails, check:
- Secrets are spelled correctly (case-sensitive)
- Values are complete (especially JSON keys and private keys)
- Service accounts have correct permissions
- APIs are enabled in cloud console

---

## Troubleshooting Quick Fixes

| Error | Solution |
|-------|----------|
| "Repository not found" | Check repository name spelling |
| "Authentication failed" | Regenerate credentials |
| "Permission denied" | Add missing IAM roles |
| "API not enabled" | Enable APIs in cloud console |
| "Invalid key format" | Ensure newlines are preserved in private keys |

---

## Full Documentation

For detailed step-by-step instructions with screenshots, see:
**[GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)**
