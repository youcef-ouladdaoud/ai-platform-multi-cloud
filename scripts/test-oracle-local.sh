#!/bin/bash
# Local Oracle Cloud Terraform Testing Script
# Usage: ./scripts/test-oracle-local.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform/oracle"

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Oracle Cloud Local Testing Setup${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform not found!${NC}"
    echo -e "${YELLOW}Terraform has been installed at ~/bin/terraform${NC}"
    echo -e "${YELLOW}Add to your PATH:${NC}"
    echo "  export PATH=\"\$HOME/bin:\$PATH\""
    echo ""
    echo -e "${YELLOW}Add this to your ~/.bashrc or ~/.zshrc to make it permanent${NC}"
    export PATH="$HOME/bin:$PATH"
fi

echo -e "${GREEN}✓ Terraform found: $(terraform version | head -1)${NC}"
echo ""

# Check for credentials
echo -e "${BLUE}Checking Oracle Cloud credentials...${NC}"

if [ -z "$TF_VAR_tenancy_ocid" ]; then
    echo -e "${YELLOW}Oracle Cloud credentials not set.${NC}"
    echo ""
    echo "Please set the following environment variables:"
    echo "  export TF_VAR_tenancy_ocid='ocid1.tenancy.oc1..xxxxx'"
    echo "  export TF_VAR_user_ocid='ocid1.user.oc1..xxxxx'"
    echo "  export TF_VAR_fingerprint='aa:bb:cc:...'"
    echo "  export TF_VAR_private_key_path='\$HOME/.oci/oci_api_key.pem'"
    echo "  export TF_VAR_compartment_ocid='ocid1.compartment.oc1..xxxxx'"
    echo "  export TF_VAR_namespace='your-namespace'"
    echo ""
    echo -e "${BLUE}Create credential file:${NC}"
    echo "  mkdir -p ~/.oci"
    echo ""
    echo -e "${BLUE}Then run:${NC}"
    echo "  source ~/.oci/local-env.sh"
    echo ""
    echo "See: docs/LOCAL_TESTING_ORACLE.md for full instructions"
    exit 1
fi

# Check private key exists
if [ ! -f "$TF_VAR_private_key_path" ]; then
    echo -e "${RED}Private key not found at: $TF_VAR_private_key_path${NC}"
    echo -e "${YELLOW}Generate a key pair:${NC}"
    echo "  mkdir -p ~/.oci"
    echo "  openssl genrsa -out ~/.oci/oci_api_key.pem 2048"
    echo "  openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem"
    exit 1
fi

echo -e "${GREEN}✓ Credentials configured${NC}"
echo ""

# Navigate to terraform directory
cd "$TERRAFORM_DIR"

# Backup original providers.tf if it has remote backend
if grep -q "backend \"s3\"" providers.tf 2>/dev/null; then
    echo -e "${BLUE}Creating local-only providers.tf...${NC}"
    cp providers.tf providers.tf.backup
    cat > providers-local.tf <> 'EOF'
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
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
    echo -e "${YELLOW}Original providers.tf backed up to providers.tf.backup${NC}"
    echo -e "${YELLOW}Local version created at providers-local.tf${NC}"
fi

# Use local providers file if it exists
if [ -f "providers-local.tf" ]; then
    echo -e "${BLUE}Using local configuration (no remote backend)${NC}"
fi

echo ""
echo -e "${BLUE}Choose an action:${NC}"
echo ""
echo "1) Initialize Terraform (first time only)"
echo "2) Plan (preview changes)"
echo "3) Apply (create infrastructure)"
echo "4) Destroy (remove everything)"
echo "5) Show current state"
echo "6) Exit"
echo ""
read -p "Enter choice (1-6): " choice

case $choice in
    1)
        echo -e "${BLUE}Initializing Terraform...${NC}"
        terraform init
        echo -e "${GREEN}✓ Initialization complete${NC}"
        ;;
    2)
        echo -e "${BLUE}Creating execution plan...${NC}"
        terraform plan -var="environment=dev" -var="node_count=1"
        ;;
    3)
        echo -e "${YELLOW}⚠️  This will create Oracle Cloud resources${NC}"
        echo -e "${YELLOW}Oracle Free Tier includes: 4 ARM VMs, OKE cluster${NC}"
        read -p "Continue? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            echo -e "${BLUE}Creating infrastructure...${NC}"
            terraform apply -var="environment=dev" -var="node_count=1"
            echo ""
            echo -e "${GREEN}✓ Infrastructure created!${NC}"
            echo ""
            echo -e "${BLUE}To configure kubectl:${NC}"
            echo "  oci ce cluster create-kubeconfig --cluster-id \$(terraform output -raw cluster_id) --file \$HOME/.kube/config --region $TF_VAR_region"
            echo ""
            echo -e "${BLUE}To deploy Open WebUI:${NC}"
            echo "  kubectl apply -k k8s/overlays/oracle"
        else
            echo "Cancelled."
        fi
        ;;
    4)
        echo -e "${RED}⚠️  This will DESTROY all Oracle Cloud resources!${NC}"
        read -p "Type 'destroy' to confirm: " confirm
        if [ "$confirm" = "destroy" ]; then
            echo -e "${BLUE}Destroying infrastructure...${NC}"
            terraform destroy -var="environment=dev"
            echo -e "${GREEN}✓ Infrastructure destroyed${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    5)
        echo -e "${BLUE}Current state:${NC}"
        terraform show
        ;;
    6)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac
