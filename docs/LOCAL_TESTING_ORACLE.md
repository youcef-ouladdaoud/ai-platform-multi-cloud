# Oracle Cloud Local Testing Setup

This guide helps you test the Oracle Cloud Terraform configuration locally without GitHub Actions.

## Prerequisites

- [x] Terraform installed (v1.5.0+)
- [ ] Oracle Cloud Account (Free Tier available)
- [ ] OCI CLI (optional but helpful)

## Step 1: Get Oracle Cloud Credentials

Follow these steps to get your Oracle Cloud credentials:

### 1.1 Sign Up for Oracle Cloud Free Tier

1. Go to https://www.oracle.com/cloud/free/
2. Click **Start for free**
3. Create an account with your email
4. Verify your identity (requires credit card for verification, but won't be charged)

### 1.2 Get Your Tenancy OCID

1. Login to [Oracle Cloud Console](https://cloud.oracle.com)
2. Click your **Profile** (top right corner)
3. Select **Tenancy: your-tenancy-name**
4. Copy the **OCID** (starts with `ocid1.tenancy.oc1..`)

### 1.3 Get Your User OCID

1. Click your **Profile** again
2. Select **User Settings**
3. Copy the **OCID** (starts with `ocid1.user.oc1..`)

### 1.4 Generate API Key

Run these commands in your terminal:

```bash
# Create .oci directory
mkdir -p ~/.oci

# Generate private key
openssl genrsa -out ~/.oci/oci_api_key.pem 2048

# Generate public key
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Set proper permissions
chmod 600 ~/.oci/oci_api_key.pem
chmod 644 ~/.oci/oci_api_key_public.pem

# Get the fingerprint
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c
```

### 1.5 Upload Public Key to Oracle Cloud

1. In Oracle Cloud Console, go to **Profile** → **User Settings**
2. Click **API Keys** on the left
3. Click **Add API Key**
4. Select **Paste Public Keys**
5. Paste the content of `~/.oci/oci_api_key_public.pem`
6. Click **Add**
7. **Copy the Fingerprint** shown (format: `aa:bb:cc:dd:ee:ff:...`)

### 1.6 Get Compartment OCID

1. Go to **Identity & Security** → **Compartments** (or search "Compartments")
2. Click on your root compartment (usually named after your tenancy)
3. Copy the **OCID** (starts with `ocid1.compartment.oc1..`)

### 1.7 Get Object Storage Namespace

1. Go to **Storage** → **Buckets** (or search "Buckets")
2. The **Namespace** is shown at the top of the page
3. It looks like: `axyv8q7vqwqg`

## Step 2: Configure Environment Variables

Create a file with your credentials:

```bash
# Create environment file
cat > ~/.oci/local-env.sh << 'EOF'
export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..xxxxxxxxxxxxxxxx"
export TF_VAR_user_ocid="ocid1.user.oc1..xxxxxxxxxxxxxxxx"
export TF_VAR_fingerprint="aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"
export TF_VAR_private_key_path="$HOME/.oci/oci_api_key.pem"
export TF_VAR_compartment_ocid="ocid1.compartment.oc1..xxxxxxxxxxxxxxxx"
export TF_VAR_namespace="your-namespace-here"
export TF_VAR_region="us-ashburn-1"
EOF

# Load the environment
source ~/.oci/local-env.sh
```

**Fill in your actual values!** Replace the placeholders with your real OCIDs.

## Step 3: Modify Backend for Local State

The Terraform configuration uses a remote backend. For local testing, we need to disable it:

```bash
cd terraform/oracle

# Backup the original
mv providers.tf providers.tf.backup

# Create local version without backend
cat > providers.tf << 'EOF'
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
EOF
```

## Step 4: Initialize and Test

```bash
# Navigate to Oracle terraform directory
cd terraform/oracle

# Initialize Terraform
terraform init

# Validate the configuration
terraform validate

# Create a plan (dry run)
terraform plan -var="environment=dev" -var="node_count=1"
```

If everything looks good, you'll see a plan for creating:
- VCN (Virtual Cloud Network)
- Internet Gateway
- NAT Gateway
- Subnets
- OKE Cluster (Kubernetes)
- Node Pool

## Step 5: Apply (Create Infrastructure)

**⚠️ WARNING: This will create real resources and may incur costs.**

Oracle Cloud Free Tier includes:
- 2 AMD-based Compute VMs
- 4 ARM-based Compute VMs (Always Free)
- 10 TB storage (monthly)

```bash
# Apply the configuration
terraform apply -var="environment=dev" -var="node_count=1"

# Type 'yes' when prompted
```

## Step 6: Configure kubectl

After the cluster is created, configure kubectl:

```bash
# Install OCI CLI if not already installed
# https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm

# Get kubeconfig
oci ce cluster create-kubeconfig \
  --cluster-id $(terraform output -raw cluster_id) \
  --file $HOME/.kube/config \
  --region $TF_VAR_region \
  --token-version 2.0.0

# Verify connection
kubectl get nodes
```

## Step 7: Deploy Open WebUI

```bash
# Go back to project root
cd ../..

# Apply Kubernetes manifests
kubectl apply -k k8s/overlays/oracle

# Wait for deployment
kubectl rollout status deployment/open-webui -n ai-platform --timeout=300s
```

## Step 8: Access Open WebUI

```bash
# Get the load balancer IP
kubectl get svc -n ai-platform

# Or port-forward for local access
kubectl port-forward svc/open-webui 8080:8080 -n ai-platform

# Open browser to: http://localhost:8080
```

## Step 9: Destroy Infrastructure (When Done)

```bash
# Destroy everything
cd terraform/oracle
terraform destroy -var="environment=dev"

# Type 'yes' when prompted
```

## Troubleshooting

### "Authentication failed"
- Check your OCIDs are correct
- Verify the private key path exists: `ls ~/.oci/oci_api_key.pem`
- Ensure fingerprint matches: `openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c`

### "Service limit exceeded"
- Oracle Free Tier has limits (4 ARM instances)
- Reduce `node_count` to 1 or 2
- Check existing resources: `oci compute instance list`

### "Out of host capacity"
- Try a different region: `TF_VAR_region="us-phoenix-1"` or `TF_VAR_region="eu-frankfurt-1"`
- Change `node_shape` to `VM.Standard.E2.1.Micro` (smaller)

### "Provider plugin not found"
```bash
terraform init -upgrade
```

## Cleanup

When done testing:

```bash
# Restore original providers.tf (if you backed it up)
cd terraform/oracle
mv providers.tf.backup providers.tf 2>/dev/null || true

# Remove local state
rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup
```

## Useful Commands

```bash
# Check Terraform version
terraform version

# Format code
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# Refresh state
terraform refresh -var="environment=dev"
```

## Next Steps

Once local testing works:
1. Configure GitHub Actions secrets
2. Push to GitHub
3. Trigger automated deployments
4. See: [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)
