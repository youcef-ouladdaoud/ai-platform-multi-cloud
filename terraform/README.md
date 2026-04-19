# Terraform Multi-Cloud AI Platform

## Overview

This directory contains Terraform configurations for deploying the AI Platform across AWS, GCP, Azure, and Oracle Cloud.

## Directory Structure

```
terraform/
├── modules/                    # Reusable modules
│   ├── networking/            # VPC/VNet/VCN configurations
│   ├── compute/               # GPU instance configurations
│   ├── storage/               # Persistent storage
│   └── kubernetes/            # K8s cluster configurations
├── aws/                       # AWS-specific deployment
├── gcp/                       # GCP-specific deployment
├── azure/                     # Azure-specific deployment
└── oracle/                    # Oracle Cloud deployment
```

## Usage

### AWS Deployment

```bash
cd aws
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply
```

### GCP Deployment

```bash
cd gcp
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply
```

### Azure Deployment

```bash
cd azure
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply
```

### Oracle Cloud Deployment

```bash
cd oracle
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply
```

## Remote State

Configure Terraform backend for remote state storage:

```hcl
terraform {
  backend "s3" {
    bucket = "ai-platform-terraform-state"
    key    = "aws/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## Variables

See individual provider directories for complete variable documentation.

Common variables:
- `project_name`: Name of the project
- `environment`: Environment (dev/staging/prod)
- `region`: Cloud region
- `gpu_enabled`: Enable GPU nodes
- `node_count`: Number of worker nodes
