# EKS 3-Tier App — DevOps Quiz Platform

A three-tier web application deployed on AWS EKS: React frontend, Flask backend, PostgreSQL database. GitHub Actions pipeline uses OIDC (keyless AWS auth) to build Docker images, push to ECR, and deploy to Kubernetes.

## Architecture

```
GitHub Actions (OIDC → IAM Role, no stored keys)
  │
  ├── Build frontend image → ECR
  ├── Build backend image  → ECR
  │
  └── kubectl apply → EKS Cluster
                         │
                   ┌─────┴──────┐
                   │            │
             Frontend         Backend
             (React+nginx)    (Flask+SQLAlchemy)
                   │            │
                   └─────┬──────┘
                         │
                    PostgreSQL 13
                    (PersistentVolumeClaim)
```

## Tech Stack

- **Frontend:** React 18, Tailwind CSS, nginx
- **Backend:** Python, Flask, SQLAlchemy, Flask-Migrate
- **Database:** PostgreSQL 13 (deployed in cluster with PVC)
- **Container Registry:** AWS ECR (lifecycle policies configured)
- **Orchestration:** AWS EKS 1.31 (eu-central-1), t3.small node group (1–3 nodes)
- **CI/CD:** GitHub Actions with OIDC (no stored AWS credentials)
- **IaC:** Terraform

## Kubernetes Structure

```
k8s/
├── namespace.yml
├── frontend/
│   ├── deployment.yaml   # IMAGE_TAG replaced by sed in pipeline
│   └── service.yaml
├── backend/
│   ├── deployment.yaml
│   └── service.yaml
├── postgres/
│   ├── deployment.yaml
│   ├── pvc.yaml          # Persistent storage for DB data
│   └── service.yaml
└── config/               # ConfigMaps
```

## Terraform Modules

```
terraform/modules/
├── vpc/    # VPC, 2 public + 2 private subnets, IGW, NAT GW
├── iam/    # EKS cluster role, node group role
├── eks/    # EKS 1.31 cluster, t3.small node group
└── ecr/    # 2 ECR repositories (frontend + backend)
```

## CI/CD Pipeline

```yaml
jobs:
  test:    # Run backend tests
  build:   # Build + push both images to ECR (tag: $GITHUB_SHA)
  deploy:  # sed IMAGE_TAG in manifests → kubectl apply
```

## Deploy

**Prerequisites:** AWS account, Terraform, kubectl, Docker

```bash
# 1. Deploy infrastructure
cd terraform/
terraform init
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region eu-central-1 --name <cluster-name>

# 3. Deploy manually (or let CI do it)
kubectl apply -f k8s/
```

## Key Concepts

- **OIDC keyless auth** — no `AWS_ACCESS_KEY_ID` stored in GitHub Secrets; IAM role is assumed via OIDC token
- **Image pinned to commit SHA** — every deploy is reproducible and traceable
- **PostgreSQL in-cluster with PVC** — persistent storage survives pod restarts
