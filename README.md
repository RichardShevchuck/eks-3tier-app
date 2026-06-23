# DevOps Learning Platform

Quiz app for DevOps topics (Docker, Kubernetes, Jenkins, AWS, Linux). Three-tier architecture deployed on AWS EKS.

## Stack

| Layer | Tech |
|-------|------|
| Frontend | React 18, Tailwind CSS, nginx |
| Backend | Flask, SQLAlchemy, Flask-Migrate |
| Database | PostgreSQL 13 |
| Infrastructure | Terraform, AWS EKS (`eu-central-1`) |
| CI/CD | GitHub Actions → ECR → EKS |

## Architecture

```
Internet
    │
    ▼
LoadBalancer Service (AWS ALB)
    │
    ▼
Frontend pods (React + nginx)     ← EKS private subnets
    │
    ▼
Backend Service (ClusterIP)
    │
    ▼
Backend pods (Flask)
    │
    ▼
Postgres Service (ClusterIP)
    │
    ▼
Postgres pod + PVC
```

## CI/CD Pipeline

```
git push → GitHub Actions
              ├── test:  pytest
              ├── build: docker build → push ECR (tagged with git SHA)
              └── deploy: kubectl apply → EKS
```

## Infrastructure (Terraform)

Directory: `terraform/`. Region: `eu-central-1`.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Modules

| Module | Resources |
|--------|-----------|
| `vpc` | VPC, 2 public + 2 private subnets, IGW, NAT gateway |
| `iam` | EKS cluster role, node group role + policy attachments |
| `eks` | EKS 1.31 cluster, `t3.small` node group (1–3 nodes) |
| `ecr` | Two ECR repos: frontend + backend, lifecycle policy |

## Local Development

```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

docker run --name pg \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=devops_learning -p 5432:5432 -d postgres

# .env
DATABASE_URL=postgresql://postgres:password@localhost:5432/devops_learning
FLASK_APP=run.py
FLASK_DEBUG=1

flask db upgrade
python seed_data.py
python run.py
```

```bash
cd frontend
npm install
REACT_APP_API_URL=http://localhost:8000/api npm start
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/topics` | List all topics |
| POST | `/api/topics` | Create topic |
| PUT | `/api/topics/<id>` | Update topic |
| DELETE | `/api/topics/<id>` | Delete topic |
| GET | `/api/quiz/<topic_slug>` | Get quiz (up to 15 random questions) |
| POST | `/api/quiz/submit` | Submit answers, get score |
| POST | `/api/quiz/questions` | Add single question |
| POST | `/api/quiz/questions/bulk` | Bulk add questions |

## Environment Variables

**Backend:**

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | — | Postgres connection string |
| `SECRET_KEY` | `dev-secret-key` | Flask secret key |
| `FLASK_DEBUG` | `0` | Enable debug mode |
| `ALLOWED_ORIGINS` | _(all)_ | Comma-separated CORS origins |

**Frontend:**

| Variable | Default | Description |
|----------|---------|-------------|
| `REACT_APP_API_URL` | `http://localhost:8000/api` | Backend API base URL |

## GitHub Actions Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `ECR_FRONTEND` | Full ECR URL for frontend repo |
| `ECR_BACKEND` | Full ECR URL for backend repo |
