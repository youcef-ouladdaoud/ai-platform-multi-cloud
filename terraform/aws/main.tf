# AWS AI Platform Deployment - Open WebUI only (Ollama Cloud)

locals {
  cluster_name = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Networking Module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = local.cluster_name
  cidr = var.vpc_cidr
  
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
  public_subnets  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment == "dev"
  enable_dns_hostnames   = true
  enable_dns_support     = true
  
  # Tag subnets for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  
  tags = local.tags
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"
  
  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  control_plane_subnet_ids       = module.vpc.private_subnets
  
  # Enable OIDC provider for service accounts
  enable_irsa = true
  
  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
  
  # Managed node groups - simplified for Open WebUI only
  eks_managed_node_groups = {
    general = {
      name           = "general-workers"
      instance_types = ["t3.small"]  # Smaller instance for WebUI only
      
      min_size     = 1
      max_size     = 2
      desired_size = 1
      
      capacity_type = "ON_DEMAND"
      
      labels = {
        workload = "general"
      }
      
      tags = local.tags
    }
  }
  
  # Fargate profile for serverless workloads (optional)
  fargate_profiles = var.enable_fargate ? {
    default = {
      name = "default"
      selectors = [
        { namespace = "kube-system" },
        { namespace = "default" }
      ]
    }
  } : {}
  
  tags = local.tags
}

# Install NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace  = "ingress-nginx"
  
  create_namespace = true
  
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

# Install cert-manager for TLS
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.13.0"
  namespace  = "cert-manager"
  
  create_namespace = true
  
  set {
    name  = "installCRDs"
    value = "true"
  }
}

# Secrets Manager for Open WebUI secrets
resource "aws_secretsmanager_secret" "open_webui" {
  name        = "${local.cluster_name}/open-webui"
  description = "Open WebUI configuration secrets"
  
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "open_webui" {
  secret_id = aws_secretsmanager_secret.open_webui.id
  secret_string = jsonencode({
    secret-key      = random_password.webui_secret.result
    ollama-api-key  = var.ollama_api_key
    openai-api-key  = var.openai_api_key
  })
}

resource "random_password" "webui_secret" {
  length  = 32
  special = false
}

# External Secrets Operator to sync AWS Secrets Manager to K8s
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.9"
  namespace  = "external-secrets"
  
  create_namespace = true
}

# IAM role for External Secrets Operator
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"
  
  role_name = "${local.cluster_name}-external-secrets"
  
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
  
  role_policy_arns = {
    secrets = aws_iam_policy.secrets_access.arn
  }
}

resource "aws_iam_policy" "secrets_access" {
  name        = "${local.cluster_name}-secrets-access"
  description = "Allow External Secrets to access Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.open_webui.arn
      }
    ]
  })
}
