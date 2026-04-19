# Deployment Guide

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | ≥ 1.5.0 | Infrastructure provisioning |
| kubectl | ≥ 1.25 | Kubernetes CLI |
| Docker | ≥ 20.10 | Container management |
| Helm | ≥ 3.10 | Kubernetes package manager |

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/ai-platform-multi-cloud.git
cd ai-platform-multi-cloud
```

### 2. Configure Environment

```bash
# Set your API keys
export OLLAMA_API_KEY="your-ollama-api-key"
export OPENCLAW_API_KEY="your-openclaw-api-key"

# Choose provider (aws, gcp, azure, oracle)
export CLOUD_PROVIDER=oracle
```

### 3. Deploy Infrastructure

```bash
cd terraform/$CLOUD_PROVIDER
terraform init
terraform apply
```

### 4. Configure kubectl

```bash
# AWS
aws eks update-kubeconfig --region us-west-2 --name ai-platform-dev

# GCP
gcloud container clusters get-credentials ai-platform-dev --region us-central1

# Azure
az aks get-credentials --name ai-platform-dev --resource-group ai-platform-rg

# Oracle
oci ce cluster create-kubeconfig --cluster-id <cluster-id> --file ~/.kube/config
```

### 5. Deploy Applications

```bash
kubectl apply -k k8s/overlays/$CLOUD_PROVIDER
```

### 6. Access Applications

```bash
# Port forward
kubectl port-forward svc/open-webui 8080:8080 -n ai-platform &
kubectl port-forward svc/openclaw 3000:3000 -n ai-platform &
```

- Open WebUI: http://localhost:8080
- OpenClaw: http://localhost:3000

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n ai-platform
kubectl logs -f deployment/open-webui -n ai-platform
```

### Common Issues
- **Pending pods**: Check node resources
- **Image pull errors**: Verify image names
- **Database connection**: Check PostgreSQL pod status

## Cleanup

```bash
kubectl delete -k k8s/overlays/$CLOUD_PROVIDER
cd terraform/$CLOUD_PROVIDER
terraform destroy
```
