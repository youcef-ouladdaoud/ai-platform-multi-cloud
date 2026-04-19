# Kubernetes Manifests for AI Platform

This directory contains the Kubernetes manifests for deploying Open WebUI and Ollama.

## Structure

```
k8s/
├── base/                    # Base manifests
│   ├── namespace.yaml
│   ├── ollama/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   └── open-webui/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       └── ingress.yaml
└── overlays/               # Provider-specific overlays
    ├── aws/
    ├── gcp/
    ├── azure/
    └── oracle/
```

## Deployment

Deploy to a specific provider:

```bash
kubectl apply -k overlays/aws
kubectl apply -k overlays/gcp
kubectl apply -k overlays/azure
kubectl apply -k overlays/oracle
```

## Configuration

### Open WebUI
- Default URL: http://localhost:8080
- Connects to Ollama at `http://ollama:11434`
- Supports multiple LLM models

### Ollama
- Default URL: http://localhost:11434
- API endpoint for LLM inference
- GPU support with NVIDIA runtime

## Models

Default models loaded:
- `llama2` - General purpose LLM
- `codellama` - Code generation
- `mistral` - Efficient performance

To add more models:
```bash
kubectl exec -it deployment/ollama -n ai-platform -- ollama pull llama2
```
