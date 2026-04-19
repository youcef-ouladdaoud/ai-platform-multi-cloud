# GitHub Secrets Configuration Guide

This document lists all the secrets required for the CI/CD pipelines and how to obtain them.

## Table of Contents
1. [Application Secrets (Required)](#application-secrets)
2. [Cloud Provider Secrets](#cloud-provider-secrets)
3. [How to Add Secrets to GitHub](#how-to-add-secrets)

---

## Application Secrets (Required)

These are needed regardless of which cloud provider you use.

### 1. OLLAMA_API_KEY
**Purpose**: Connect Open WebUI to Ollama Cloud API

**How to obtain:**
1. Go to https://ollama.com
2. Sign up or log in to your account
3. Navigate to **Settings** → **API Keys**
4. Click **"Create new API key"**
5. Copy the key (starts with `ollama_`)

**Example:**
```
ollama_sk_abc123xyz789
```

---

### 2. OPENCLAW_API_KEY (Optional)
**Purpose**: Enable contract analysis features

**How to obtain:**
1. Go to https://openclaw.ai
2. Create an account
3. Navigate to **Settings** → **API Keys**
4. Generate a new key
5. Copy the key

**Example:**
```
openclaw_live_abc123xyz789
```

**Note:** You can skip this if you're not using OpenClaw.

---

### 3. OPENAI_API_KEY (Optional)
**Purpose**: Enable GPT-4/GPT-3.5 models as alternatives

**How to obtain:**
1. Go to https://platform.openai.com
2. Sign up or log in
3. Navigate to **API keys** → **Create new secret key**
4. Copy the key (starts with `sk-`)

**Example:**
```
sk-proj-abc123xyz789
```

**Note:** This is optional. Open WebUI works with just Ollama Cloud.

---

## Cloud Provider Secrets

Choose ONE cloud provider and configure its secrets:

### Option 1: AWS

Required secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**How to obtain:**

1. Log in to AWS Console: https://console.aws.amazon.com
2. Go to **IAM** → **Users** → **Your User**
3. Click **Security credentials** tab
4. Under **Access keys**, click **Create access key**
5. Choose **Command Line Interface (CLI)**
6. Copy:
   - Access key ID (looks like: `AKIAIOSFODNN7EXAMPLE`)
   - Secret access key (looks like: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

**Important:** Download the CSV file or copy both immediately - you can't see the secret key again!

---

### Option 2: Google Cloud Platform (GCP)

Required secret:
- `GCP_SA_KEY`
- `GCP_PROJECT_ID`

**How to obtain:**

1. Go to GCP Console: https://console.cloud.google.com
2. Select your project
3. Go to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
   - Name: `github-actions`
   - Role: `Editor` (or more restrictive: `Kubernetes Engine Admin`, `Compute Admin`)
5. Click on the created service account
6. Go to **Keys** tab → **Add Key** → **Create new key**
7. Choose **JSON** format
8. Download the JSON file

**For GitHub Secret:**
```bash
# Convert JSON to base64
cat service-account-key.json | base64 -w 0
```
Copy the output as `GCP_SA_KEY`

**For Project ID:**
- Find in GCP Console top bar (e.g., `my-project-123456`)

---

### Option 3: Microsoft Azure

Required secret:
- `AZURE_CREDENTIALS`

**How to obtain:**

1. Go to Azure Portal: https://portal.azure.com
2. Open **Cloud Shell** (bash) from the top bar
3. Run this command:
```bash
az ad sp create-for-rbac --name "github-actions" --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth
```

4. Copy the entire JSON output

**Example output (your `AZURE_CREDENTIALS`):**
```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "abc123~xyz789",
  "subscriptionId": "87654321-4321-4321-4321-210987654321",
  "tenantId": "abcdef12-1234-1234-1234-123456abcdef",
  "resourceManagerEndpointUrl": "https://management.azure.com/"
}
```

**Also note:**
- `ARM_SUBSCRIPTION_ID`: Your subscription ID
- `ARM_TENANT_ID`: Your tenant ID

---

### Option 4: Oracle Cloud (Recommended for Free Tier)

Required secrets:
- `OCI_TENANCY_OCID`
- `OCI_USER_OCID`
- `OCI_FINGERPRINT`
- `OCI_PRIVATE_KEY`
- `OCI_COMPARTMENT_OCID`
- `OCI_NAMESPACE`

**How to obtain:**

#### Step 1: Get Tenancy OCID
1. Log in to OCI Console: https://cloud.oracle.com
2. Click your **Profile** (top right)
3. Click **Tenancy: your-tenancy-name**
4. Copy **OCID** (looks like: `ocid1.tenancy.oc1..aaaaaaaaxxx`)

#### Step 2: Get User OCID
1. Click **Profile** → **My Profile**
2. Copy **OCID** (looks like: `ocid1.user.oc1..aaaaaaaaxxx`)

#### Step 3: Generate API Key
```bash
# Create .oci directory
mkdir -p ~/.oci

# Generate private key
openssl genrsa -out ~/.oci/oci_api_key.pem 2048

# Generate public key
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Get fingerprint
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c
```

#### Step 4: Upload Public Key to OCI
1. Go to **Profile** → **API Keys**
2. Click **Add API Key**
3. Paste contents of `~/.oci/oci_api_key_public.pem`
4. Copy the **Fingerprint** shown (looks like: `aa:bb:cc:dd:ee:ff:00:11`)

#### Step 5: Get Compartment OCID
1. Go to **Identity & Security** → **Compartments**
2. Find your compartment (usually the root compartment)
3. Copy the **OCID**

#### Step 6: Get Namespace
```bash
oci os ns get
```
Or find in **Object Storage** → **Buckets**

#### Step 7: Prepare Private Key for GitHub
```bash
# View private key (copy this for OCI_PRIVATE_KEY secret)
cat ~/.oci/oci_api_key.pem
```

**Should look like:**
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn/ygWyF8PbnGy0AHB7MhgwKVPSmwaFkYLv
...
-----END RSA PRIVATE KEY-----
```

---

## How to Add Secrets to GitHub

### Method 1: GitHub Web Interface

1. Go to your repository on GitHub
2. Click **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Enter:
   - **Name**: The secret name (e.g., `OLLAMA_API_KEY`)
   - **Value**: The actual secret value
6. Click **Add secret**
7. Repeat for all required secrets

### Method 2: GitHub CLI (gh)

If you have the GitHub CLI installed:

```bash
# Authenticate
gitHub auth login

# Set secrets
gitHub secret set OLLAMA_API_KEY --body "your-actual-key-here"
gitHub secret set OPENCLAW_API_KEY --body "your-actual-key-here"
gitHub secret set AWS_ACCESS_KEY_ID --body "your-access-key"
gitHub secret set AWS_SECRET_ACCESS_KEY --body "your-secret-key"
```

---

## Complete Secrets Checklist

### For AWS Deployment:
```
☐ OLLAMA_API_KEY
☐ OPENCLAW_API_KEY (optional)
☐ OPENAI_API_KEY (optional)
☐ AWS_ACCESS_KEY_ID
☐ AWS_SECRET_ACCESS_KEY
```

### For GCP Deployment:
```
☐ OLLAMA_API_KEY
☐ OPENCLAW_API_KEY (optional)
☐ OPENAI_API_KEY (optional)
☐ GCP_SA_KEY (base64 encoded JSON)
☐ GCP_PROJECT_ID
```

### For Azure Deployment:
```
☐ OLLAMA_API_KEY
☐ OPENCLAW_API_KEY (optional)
☐ OPENAI_API_KEY (optional)
☐ AZURE_CREDENTIALS (JSON)
```

### For Oracle Cloud Deployment:
```
☐ OLLAMA_API_KEY
☐ OPENCLAW_API_KEY (optional)
☐ OPENAI_API_KEY (optional)
☐ OCI_TENANCY_OCID
☐ OCI_USER_OCID
☐ OCI_FINGERPRINT
☐ OCI_PRIVATE_KEY
☐ OCI_COMPARTMENT_OCID
☐ OCI_NAMESPACE
```

---

## Testing Your Secrets

After adding secrets, trigger a deployment:

1. Go to **Actions** tab in your GitHub repository
2. Select a workflow (e.g., "Deploy to Oracle Cloud")
3. Click **Run workflow**
4. Select environment (dev/staging/prod)
5. Click **Run workflow**

Check the Actions logs to verify secrets are working.

---

## Troubleshooting

### Secret not found
- Verify the secret name matches exactly (case-sensitive)
- Check for typos
- Ensure secret is in **Actions** secrets, not **Codespaces** or **Dependabot**

### Invalid credentials
- Regenerate the API key
- Check for extra whitespace when copying
- Verify the secret hasn't expired

### Permission denied
- Check IAM roles/permissions for your cloud account
- Ensure service account has correct access

---

## Security Best Practices

1. **Never commit secrets to code** - Always use GitHub Secrets
2. **Rotate keys regularly** - Every 90 days recommended
3. **Use least privilege** - Grant minimum required permissions
4. **Monitor usage** - Check access logs regularly
5. **Use environment-specific keys** - Separate dev/prod credentials

---

## Need Help?

- Ollama: https://ollama.com/docs/api
- OpenClaw: https://docs.openclaw.ai
- AWS: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
- GCP: https://cloud.google.com/docs/authentication/getting-started
- Azure: https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli
- Oracle: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm
