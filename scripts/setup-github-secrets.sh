#!/bin/bash
# Setup GitHub Actions Secrets
# Usage: ./setup-github-secrets.sh [REPO_NAME]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="youcef-ouladdaoud"
REPO_NAME="${1:-ai-platform-multi-cloud}"
FULL_REPO="$REPO_OWNER/$REPO_NAME"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  GitHub Secrets Setup Helper${NC}"
echo -e "${BLUE}  Repository: $FULL_REPO${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI (gh) not found.${NC}"
    echo -e "${YELLOW}Please install it first: https://cli.github.com/${NC}"
    echo ""
    echo "Or manually add secrets via GitHub Web:"
    echo "  https://github.com/$FULL_REPO/settings/secrets/actions"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Please login to GitHub first:${NC}"
    echo "  gh auth login"
    exit 1
fi

echo -e "${GREEN}✓ GitHub CLI is ready${NC}"
echo ""

# Function to set secret
set_secret() {
    local name=$1
    local value=$2
    
    if [ -z "$value" ]; then
        echo -e "${YELLOW}Skipping $name (empty value)${NC}"
        return
    fi
    
    echo -e "${BLUE}Setting $name...${NC}"
    if gh secret set "$name" -b"$value" -R "$FULL_REPO" 2>/dev/null; then
        echo -e "${GREEN}✓ $name set successfully${NC}"
    else
        echo -e "${RED}✗ Failed to set $name${NC}"
    fi
}

# Function to set secret with file content
set_secret_file() {
    local name=$1
    local filepath=$2
    
    if [ -f "$filepath" ]; then
        echo -e "${BLUE}Setting $name from file...${NC}"
        if gh secret set "$name" < "$filepath" -R "$FULL_REPO" 2>/dev/null; then
            echo -e "${GREEN}✓ $name set successfully${NC}"
        else
            echo -e "${RED}✗ Failed to set $name${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping $name - file not found: $filepath${NC}"
    fi
}

echo -e "${YELLOW}This script will help you configure GitHub Secrets.${NC}"
echo -e "${YELLOW}Press Ctrl+C at any time to cancel.${NC}"
echo ""

# ==================== COMMON SECRETS ====================
echo -e "${BLUE}=== COMMON SECRETS ===${NC}"
echo ""

read -p "Enter OLLAMA_API_KEY (from https://ollama.com/settings/api): " OLLAMA_API_KEY
set_secret "OLLAMA_API_KEY" "$OLLAMA_API_KEY"

read -p "Enter OPENAI_API_KEY (optional, press Enter to skip): " OPENAI_API_KEY
set_secret "OPENAI_API_KEY" "$OPENAI_API_KEY"

echo ""

# ==================== AWS SECRETS ====================
echo -e "${BLUE}=== AWS SECRETS (Optional) ===${NC}"
echo -e "${YELLOW}Skip if you don't plan to use AWS${NC}"
echo ""

read -p "Configure AWS secrets? (y/n): " CONFIGURE_AWS
if [ "$CONFIGURE_AWS" = "y" ] || [ "$CONFIGURE_AWS" = "Y" ]; then
    read -p "Enter AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
    set_secret "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID"
    
    read -sp "Enter AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
    echo ""
    set_secret "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY"
fi

echo ""

# ==================== GCP SECRETS ====================
echo -e "${BLUE}=== GCP SECRETS (Optional) ===${NC}"
echo -e "${YELLOW}Skip if you don't plan to use GCP${NC}"
echo ""

read -p "Configure GCP secrets? (y/n): " CONFIGURE_GCP
if [ "$CONFIGURE_GCP" = "y" ] || [ "$CONFIGURE_GCP" = "Y" ]; then
    read -p "Enter GCP_PROJECT_ID: " GCP_PROJECT_ID
    set_secret "GCP_PROJECT_ID" "$GCP_PROJECT_ID"
    
    echo -e "${YELLOW}For GCP_SA_KEY, paste the base64-encoded JSON key:${NC}"
    read -p "Enter GCP_SA_KEY (base64 string): " GCP_SA_KEY
    set_secret "GCP_SA_KEY" "$GCP_SA_KEY"
fi

echo ""

# ==================== AZURE SECRETS ====================
echo -e "${BLUE}=== AZURE SECRETS (Optional) ===${NC}"
echo -e "${YELLOW}Skip if you don't plan to use Azure${NC}"
echo ""

read -p "Configure Azure secrets? (y/n): " CONFIGURE_AZURE
if [ "$CONFIGURE_AZURE" = "y" ] || [ "$CONFIGURE_AZURE" = "Y" ]; then
    echo -e "${YELLOW}Paste the full JSON output from 'az ad sp create-for-rbac':${NC}"
    echo "(Press Enter, then paste multi-line JSON, then press Ctrl+D)"
    AZURE_CREDENTIALS=$(cat)
    set_secret "AZURE_CREDENTIALS" "$AZURE_CREDENTIALS"
    
    # Parse and set individual values
    if command -v jq &> /dev/null && [ ! -z "$AZURE_CREDENTIALS" ]; then
        echo -e "${BLUE}Parsing Azure credentials...${NC}"
        ARM_CLIENT_ID=$(echo "$AZURE_CREDENTIALS" | jq -r .clientId)
        ARM_CLIENT_SECRET=$(echo "$AZURE_CREDENTIALS" | jq -r .clientSecret)
        ARM_SUBSCRIPTION_ID=$(echo "$AZURE_CREDENTIALS" | jq -r .subscriptionId)
        ARM_TENANT_ID=$(echo "$AZURE_CREDENTIALS" | jq -r .tenantId)
        
        set_secret "ARM_CLIENT_ID" "$ARM_CLIENT_ID"
        set_secret "ARM_CLIENT_SECRET" "$ARM_CLIENT_SECRET"
        set_secret "ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID"
        set_secret "ARM_TENANT_ID" "$ARM_TENANT_ID"
    else
        echo -e "${YELLOW}jq not found. Please set individual ARM_* secrets manually.${NC}"
    fi
fi

echo ""

# ==================== ORACLE SECRETS ====================
echo -e "${BLUE}=== ORACLE CLOUD SECRETS (Optional) ===${NC}"
echo -e "${YELLOW}Skip if you don't plan to use Oracle Cloud${NC}"
echo ""

read -p "Configure Oracle Cloud secrets? (y/n): " CONFIGURE_ORACLE
if [ "$CONFIGURE_ORACLE" = "y" ] || [ "$CONFIGURE_ORACLE" = "Y" ]; then
    read -p "Enter OCI_TENANCY_OCID: " OCI_TENANCY_OCID
    set_secret "OCI_TENANCY_OCID" "$OCI_TENANCY_OCID"
    
    read -p "Enter OCI_USER_OCID: " OCI_USER_OCID
    set_secret "OCI_USER_OCID" "$OCI_USER_OCID"
    
    read -p "Enter OCI_FINGERPRINT: " OCI_FINGERPRINT
    set_secret "OCI_FINGERPRINT" "$OCI_FINGERPRINT"
    
    read -p "Enter OCI_COMPARTMENT_OCID: " OCI_COMPARTMENT_OCID
    set_secret "OCI_COMPARTMENT_OCID" "$OCI_COMPARTMENT_OCID"
    
    read -p "Enter OCI_NAMESPACE: " OCI_NAMESPACE
    set_secret "OCI_NAMESPACE" "$OCI_NAMESPACE"
    
    echo -e "${YELLOW}For OCI_PRIVATE_KEY, paste the entire private key content:${NC}"
    echo "(Press Enter, then paste the key including BEGIN/END markers, then press Ctrl+D)"
    OCI_PRIVATE_KEY=$(cat)
    set_secret "OCI_PRIVATE_KEY" "$OCI_PRIVATE_KEY"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GitHub Secrets Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}View your secrets at:${NC}"
echo "  https://github.com/$FULL_REPO/settings/secrets/actions"
echo ""
echo -e "${BLUE}To trigger a deployment, go to:${NC}"
echo "  https://github.com/$FULL_REPO/actions"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review configured secrets in GitHub"
echo "  2. Set up GitHub Environments (dev, staging, prod)"
echo "  3. Trigger your first deployment!"
