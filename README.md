# AI Platform Multi-Cloud

A lightweight, multi-cloud deployment platform for **Open WebUI** (ChatGPT-like interface) connecting to **Ollama Cloud API** or other LLM providers.

## 🌟 Features

- **Multi-Cloud Support**: Deploy to AWS EKS, GCP GKE, Azure AKS, or Oracle OKE
- **Open WebUI**: Modern ChatGPT-like web interface
- **Cloud LLMs**: Connect to Ollama Cloud API, OpenAI, or other providers
- **No Local GPU Required**: Use cloud-based LLM APIs
- **GitHub Actions**: Automated CI/CD deployment pipelines
- **Terraform**: Infrastructure as Code for all providers
- **Kubernetes**: Simple container deployment

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Multi-Cloud Deployment                             │
├─────────────┬─────────────┬─────────────┬───────────────────────────────────┤
│    AWS      │    GCP      │   Azure     │   Oracle Cloud                    │
│  ┌───────┐  │  ┌───────┐  │  ┌───────┐  │  ┌───────────────┐               │
│  │  EKS  │  │  │  GKE  │  │  │  AKS  │  │  │     OKE       │               │
│  └───┬───┘  │  └───┬───┘  │  └───┬───┘  │  └───────┬───────┘               │
│      │      │      │      │      │      │          │                       │
│  ┌───┴───┐  │  ┌───┴───┐  │  ┌───┴───┐  │  ┌───────┴───────┐               │
│  │ Open  │  │  │ Open  │  │  │ Open  │  │  │     Open      │               │
│  │WebUI  │  │  │WebUI  │  │  │WebUI  │  │  │     WebUI      │               │
│  └───────┘  │  └───────┘  │  └───────┘  │  └───────────────┘               │
│      │      │      │      │      │      │          │                       │
└──────┼──────┴──────┼──────┴──────┼──────┴──────┼───┴───────────────────────┘
       │             │             │             │
       └─────────────┴─────────────┴─────────────┘
                            │
       ┌────────────────────┴────────────────────┐
       │          External LLM Providers        │
       │  ┌──────────┐      ┌───────────────┐   │
       │  │ Ollama   │      │    OpenAI     │   │
       │  │ Cloud    │      │    (GPT-4)    │   │
       │  └──────────┘      └───────────────┘   │
       └──────────────────────────────────────────┘
```

## 📁 Project Structure

```
ai-platform-multi-cloud/
├── .github/workflows/          # CI/CD pipelines
├── terraform/                   # Infrastructure as Code
│   ├── modules/networking/     # Multi-cloud networking
│   ├── aws/                    # EKS deployment
│   ├── gcp/                    # GKE deployment
│   ├── azure/                  # AKS deployment
│   └── oracle/                 # OKE deployment
├── k8s/
│   ├── base/                   # Open WebUI manifests
│   └── overlays/              # Provider-specific configs
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.5.0
- kubectl
- Cloud CLI (awscli, gcloud, az, oci)
- Ollama Cloud API Key (get from https://ollama.com/settings/api)

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/ai-platform-multi-cloud.git
cd ai-platform-multi-cloud
```

### 2. Get Ollama Cloud API Key

1. Visit https://ollama.com and create an account
2. Go to Settings → API Keys
3. Generate a new API key

### 3. Choose Cloud Provider

#### AWS
```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="us-west-2"
export TF_VAR_ollama_api_key="your-ollama-api-key"

cd terraform/aws
terraform init
terraform apply -var="environment=dev"
```

#### GCP
```bash
gcloud auth application-default login
export GOOGLE_PROJECT="your-project-id"
export TF_VAR_ollama_api_key="your-ollama-api-key"

cd terraform/gcp
terraform init
terraform apply -var="project_id=$GOOGLE_PROJECT" -var="environment=dev"
```

#### Azure
```bash
az login
export ARM_SUBSCRIPTION_ID="your-subscription"
export TF_VAR_ollama_api_key="your-ollama-api-key"

cd terraform/azure
terraform init
terraform apply -var="subscription_id=$ARM_SUBSCRIPTION_ID" -var="environment=dev"
```

#### Oracle Cloud (Recommended for Free Tier)
```bash
export TF_VAR_tenancy_ocid="your-tenancy"
export TF_VAR_user_ocid="your-user"
export TF_VAR_fingerprint="your-fingerprint"
export TF_VAR_private_key_path="~/.oci/oci_api_key.pem"
export TF_VAR_compartment_ocid="your-compartment"
export TF_VAR_namespace="your-namespace"
export TF_VAR_ollama_api_key="your-ollama-api-key"

cd terraform/oracle
terraform init
terraform apply -var="environment=dev"
```

### 4. Deploy Application

```bash
# Configure kubectl for your provider
aws eks update-kubeconfig --name ai-platform-dev        # AWS
gcloud container clusters get-credentials ai-platform-dev # GCP
az aks get-credentials --name ai-platform-dev            # Azure
oci ce cluster create-kubeconfig --cluster-id <id>      # Oracle

# Deploy Open WebUI
kubectl apply -k k8s/overlays/aws    # or gcp, azure, oracle
```

### 5. Access Open WebUI

```bash
# Get the Load Balancer URL
kubectl get ingress open-webui -n ai-platform

# Or port forward for local access
kubectl port-forward svc/open-webui 8080:8080 -n ai-platform
```

Access at: http://localhost:8080

## ☁️ Cloud Provider Comparison

| Provider | Kubernetes | Cost | Free Tier | Best For |
|----------|-----------|------|-----------|----------|
| **Oracle** | OKE | $ | Always Free | Best value, no GPU costs |
| **GCP** | GKE | $$ | $300 credit | Fast setup |
| **AWS** | EKS | $$ | 750 hrs EC2 | Enterprise features |
| **Azure** | AKS | $$ | $200 credit | Microsoft ecosystem |

**Recommendation**: Oracle Cloud for free tier, GCP for ease of use.

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OLLAMA_API_KEY` | Your Ollama Cloud API key | Yes |
| `OPENAI_API_KEY` | OpenAI API key (optional) | No |

### Supported LLM Providers

- **Ollama Cloud** (default): Llama 2, Mistral, Code Llama
- **OpenAI**: GPT-4, GPT-3.5 (optional)

### Adding Models in Open WebUI

1. Open WebUI Settings → Models
2. Enter model name (e.g., `llama2`, `mistral`, `codellama`)
3. These models run on Ollama Cloud infrastructure

## 🔒 Security

- Secrets stored in cloud provider's secret manager (AWS Secrets Manager, etc.)
- External Secrets Operator syncs to Kubernetes
- TLS termination at ingress
- No GPU instances needed (cost savings)

## 💰 Cost Optimization

### Why This Architecture Saves Money

| Component | Traditional (Local Ollama) | This Architecture |
|-----------|---------------------------|-------------------|
| GPU Instances | $500-1000/mo | $0 (cloud API) |
| Compute | Large instances | Small (t3.small) |
| Storage | 100GB+ models | 10GB WebUI data |
| **Total** | **$600-1200/mo** | **$20-50/mo** |

### Free Tier Eligibility

- **Oracle Cloud**: 4 ARM instances always free = $0
- **GCP**: $300 credit covers 3+ months
- **AWS/Azure**: Free tier covers small deployments

## 🔄 CI/CD with GitHub Actions

This project includes automated CI/CD pipelines for all cloud providers.

### Quick Setup

1. **Fork this repository** (it's public so GitHub Actions are free!)
2. **Configure secrets** (see detailed guides below):
   - Get Ollama API Key: https://ollama.com/settings/api
   - Get cloud credentials: Follow [docs/GITHUB_SECRETS_SETUP.md](docs/GITHUB_SECRETS_SETUP.md)
3. **Add secrets** to GitHub: `Settings → Secrets and variables → Actions`
4. **Deploy**: Go to `Actions` tab → Select workflow → Run

### Required Secrets by Provider

| Provider | Secrets Required | Setup Guide |
|----------|------------------|-------------|
| **Oracle Cloud** ⭐ | `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT`, `OCI_PRIVATE_KEY`, `OCI_COMPARTMENT_OCID`, `OCI_NAMESPACE` | [Setup Guide](docs/GITHUB_SECRETS_SETUP.md#oracle-cloud-setup) |
| **AWS** | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | [Setup Guide](docs/GITHUB_SECRETS_SETUP.md#aws-setup) |
| **GCP** | `GCP_PROJECT_ID`, `GCP_SA_KEY` | [Setup Guide](docs/GITHUB_SECRETS_SETUP.md#gcp-setup) |
| **Azure** | `AZURE_CREDENTIALS`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID` | [Setup Guide](docs/GITHUB_SECRETS_SETUP.md#azure-setup) |
| **Common** | `OLLAMA_API_KEY` (required), `OPENAI_API_KEY` (optional) | [Get Ollama Key](https://ollama.com/settings/api) |

### Documentation

- 📋 **[Quick Reference](docs/SECRETS_QUICK_REFERENCE.md)** - Quick table to fill in your values
- 📖 **[Complete Setup Guide](docs/GITHUB_SECRETS_SETUP.md)** - Step-by-step with screenshots
- 🔧 **[Setup Script](scripts/setup-github-secrets.sh)** - Interactive script to add secrets

### Automatic Deployment

Push to `main` branch triggers automatic deployment to your configured environments.

## 🛠️ Troubleshooting

### Open WebUI can't connect to Ollama

Check the API key is set:
```bash
kubectl get secret open-webui-secrets -n ai-platform -o yaml
```

### Pod not starting

```bash
kubectl logs deployment/open-webui -n ai-platform
kubectl describe pod -l app=open-webui -n ai-platform
```

### External Secrets not syncing

```bash
kubectl get externalsecret -n ai-platform
kubectl logs deployment/external-secrets -n external-secrets
```

## 📊 Monitoring

Access Grafana (if deployed):
```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

Default credentials: admin/admin

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open a Pull Request

## 📄 License

MIT License

## 🙏 Acknowledgments

- [Open WebUI](https://github.com/open-webui/open-webui)
- [Ollama Cloud](https://ollama.com)
- [Terraform](https://terraform.io)

---

**Note**: This deployment uses Ollama Cloud API for LLM inference. No local GPU required!
