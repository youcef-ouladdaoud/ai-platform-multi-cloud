# AI Platform Architecture

## Overview

This multi-cloud AI platform deploys **Open WebUI** (ChatGPT-like interface) and **OpenClaw** (contract analysis) across AWS, GCP, Azure, and Oracle Cloud.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              User Layer                                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│  │   Users     │    │   Users     │    │   Users     │    │   Users     │   │
│  │  (Browser)  │    │  (Browser)  │    │  (Browser)  │    │  (Browser)  │   │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘   │
│         │                  │                  │                  │          │
└─────────┼──────────────────┼──────────────────┼──────────────────┼──────────┘
          │                  │                  │                  │
          └──────────────────┴──────────────────┴──────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │      Load Balancer         │
                    │    (NGINX Ingress)         │
                    └──────────────┬──────────────┘
                                   │
       ┌──────────────────────────┼──────────────────────────┐
       │                          │                          │
┌──────┴──────┐          ┌────────┴────────┐        ┌───────┴───────┐
│  Open WebUI │          │    OpenClaw     │        │  OpenClaw     │
│  (Port 8080)│          │   (Port 3000)   │        │   PostgreSQL  │
│             │          │                 │        │   (Port 5432) │
│ Chat Interface│        │Contract Analysis│        │   Database    │
└──────┬──────┘          └────────┬────────┘        └───────────────┘
       │                           │
       │                  ┌─────────┴──────────┐
       │                  │                    │
       │         ┌────────┴────────┐  ┌──────┴──────┐
       │         │   Storage       │  │   External  │
       │         │   (Documents)   │  │   AI APIs   │
       │         └───────────────────┘  └──────┬──────┘
       │                                     │
       │                           ┌────────┴────────┐
       │                           │  Ollama Cloud   │
       │                           │  OpenAI API     │
       │                           └─────────────────┘
       │
       └─────────────────────────────────────┐
                                            │
                                   ┌────────┴────────┐
                                   │  LLM Response   │
                                   └─────────────────┘
```

## Component Details

### 1. Open WebUI
- **Purpose**: ChatGPT-like web interface for conversational AI
- **Port**: 8080
- **Features**:
  - Multiple LLM support (Ollama Cloud, OpenAI)
  - Chat history
  - User authentication
  - Document upload for RAG
- **Resources**: 512Mi - 2Gi RAM, 250m - 1000m CPU

### 2. OpenClaw
- **Purpose**: AI-powered contract analysis and clawback detection
- **Port**: 3000
- **Features**:
  - Contract risk analysis
  - Clawback detection
  - Compliance scoring
  - Document parsing
- **Resources**: 1Gi - 4Gi RAM, 500m - 2000m CPU
- **Database**: PostgreSQL for document metadata and analysis results

### 3. PostgreSQL (OpenClaw)
- **Purpose**: Store contract metadata, analysis results, user data
- **Port**: 5432
- **Storage**: 20Gi
- **Resources**: 512Mi - 2Gi RAM

### 4. NGINX Ingress Controller
- **Purpose**: Route traffic, TLS termination, load balancing
- **Features**:
  - SSL/TLS with cert-manager
  - Path-based routing
  - Rate limiting
  - Request size limits

## Data Flow

### Open WebUI Flow
```
User Request → Ingress → Open WebUI → Ollama Cloud API → LLM Response
                     ↓
              WebSocket (real-time updates)
```

### OpenClaw Flow
```
User Upload → Ingress → OpenClaw → Document Processing
                              ↓
                         PostgreSQL (metadata)
                              ↓
                         AI Analysis → Results
```

## Cloud Provider Specifics

### AWS
- **EKS**: Managed Kubernetes
- **ALB**: Application Load Balancer (via Ingress)
- **S3**: Document storage (optional)
- **Secrets Manager**: API keys
- **RDS**: Optional managed PostgreSQL

### GCP
- **GKE**: Autopilot or Standard mode
- **Cloud Load Balancing**: Global LB
- **Cloud Storage**: Document bucket
- **Secret Manager**: API keys
- **Cloud SQL**: Optional managed PostgreSQL

### Azure
- **AKS**: Managed Kubernetes
- **Application Gateway**: Ingress controller
- **Blob Storage**: Document storage
- **Key Vault**: API keys
- **Azure Database**: Optional managed PostgreSQL

### Oracle Cloud (Recommended for Free Tier)
- **OKE**: Kubernetes (control plane free)
- **Load Balancer**: One free instance
- **Object Storage**: 10GB free
- **Vault**: Secrets management
- **Autonomous DB**: Optional managed database

## Security Architecture

### Network Security
- Private subnets for workloads
- NAT Gateway for outbound traffic
- Security Groups/NSGs for traffic control
- Network policies in Kubernetes

### Application Security
- TLS 1.3 for all communications
- JWT authentication for Open WebUI
- API key authentication for OpenClaw
- Secrets management via cloud providers

### Data Security
- Encrypted volumes at rest
- Encrypted traffic in transit
- Database encryption
- Backup encryption

## Scaling Strategy

### Horizontal Scaling
- Open WebUI: 1-3 replicas
- OpenClaw: 1-2 replicas (depends on workload)
- PostgreSQL: Single instance (use managed DB for HA)

### Vertical Scaling
- Open WebUI: 512Mi → 2Gi RAM
- OpenClaw: 1Gi → 4Gi RAM
- PostgreSQL: 512Mi → 2Gi RAM

### Auto-scaling
- HPA based on CPU/memory metrics
- Cluster auto-scaler for node scaling
- Vertical Pod Autoscaler (optional)

## Monitoring & Observability

### Metrics
- Prometheus for metrics collection
- Grafana for visualization
- CloudWatch/Azure Monitor/Stackdriver

### Logging
- Centralized logging with Fluentd/Fluent Bit
- Cloud provider logging services
- Application structured logging

### Alerting
- Prometheus Alertmanager
- Cloud provider alerting
- PagerDuty integration (optional)

## Backup & Disaster Recovery

### Backup Strategy
- PostgreSQL: Daily automated backups
- Application data: Volume snapshots
- Configuration: Git repository

### Recovery
- RTO: < 1 hour
- RPO: < 24 hours
- Documented runbooks

## Cost Optimization

### Resource Right-sizing
- Start with minimal resources
- Monitor and adjust
- Use spot instances for dev (optional)

### Cloud Provider Selection
| Provider | Best For | Estimated Cost |
|----------|----------|----------------|
| Oracle | Free tier, long-term | $0-20/month |
| GCP | Ease of use, credits | $30-50/month |
| AWS | Enterprise features | $50-80/month |
| Azure | Microsoft ecosystem | $50-80/month |

## Future Enhancements

### Phase 2
- Multi-region deployment
- Advanced caching (Redis)
- CDN for static assets
- Advanced analytics

### Phase 3
- Machine learning model serving
- Custom LLM fine-tuning
- Advanced security features
- Compliance automation
