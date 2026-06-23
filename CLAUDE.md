# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

DevOps quiz platform (Docker, Kubernetes, Jenkins, AWS, Linux topics). Three-tier: React frontend → Flask API → PostgreSQL. Deployed on AWS EKS via Terraform. CI/CD via GitHub Actions.

Terraform directory: `terraform/`.

## Collaboration Style

User writes all Terraform, K8s, and GitHub Actions code. Claude reviews only — points out bugs, missing resources, syntax errors. Do not rewrite user's code unprompted.

## Project Source

Based on: https://github.com/NotHarshhaa/DevOps-Projects/tree/master/DevOps-Project-36

## CI/CD

**GitHub Actions** (`.github/workflows/deploy.yaml`). Three jobs (all complete):
1. `test` — Python pytest
2. `build` — Docker build + push to ECR (tagged with `github.sha` and `latest`). `needs: test`.
3. `deploy` — `aws eks update-kubeconfig`, replaces `IMAGE_TAG` placeholder in manifests with `github.sha`, `kubectl apply -f k8s/ --recursive`. `needs: build`.

Required GitHub repository secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `ECR_FRONTEND` — full ECR URL e.g. `123.dkr.ecr.eu-central-1.amazonaws.com/k8s-ecr-repository-frontend`
- `ECR_BACKEND` — full ECR URL e.g. `123.dkr.ecr.eu-central-1.amazonaws.com/k8s-ecr-repository-backend`

## Local Development

**Backend only (no Docker):**
```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

docker run --name flask_postgres \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=devops_learning -p 5432:5432 -d postgres

# .env file needed:
# DATABASE_URL=postgresql://postgres:password@localhost:5432/devops_learning
# FLASK_APP=run.py
# FLASK_DEBUG=1

flask db init
flask db migrate -m "Initial migration"
flask db upgrade
python seed_data.py
python run.py          # serves on :8000
```

**Frontend only:**
```bash
cd frontend
npm install
REACT_APP_API_URL=http://localhost:8000/api npm start
```

## Database Operations

```bash
flask db migrate -m "Description"
flask db upgrade

python seed_data.py
python bulk_upload_questions.py questions-answers/kubernetes_questions.csv
python bulk_upload_questions.py questions-answers/docker_questions.csv
python bulk_upload_questions.py questions-answers/jenkins_questions.csv
```

CSV format: `topic_slug, question_text, option_1, option_2, option_3, option_4, correct_answer` (0-indexed).

## Frontend Tests

```bash
cd frontend
npm test -- --watchAll=false
```

## Terraform (Infrastructure)

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Region: `eu-central-1`.

### Modules (all complete)

- **vpc** — VPC, 2 public + 2 private subnets, IGW, NAT gateway. Tagged for EKS LB controller.
- **iam** — EKS cluster role (`AmazonEKSClusterPolicy`) + node group role (Worker, CNI, ECR policies). Three separate `aws_iam_role_policy_attachment` resources each.
- **eks** — EKS 1.31 cluster, node group `t3.small` (1–3 nodes), security group. `depends_on = [module.iam, module.vpc]`.
- **ecr** — Two repos: `k8s-ecr-repository-frontend`, `k8s-ecr-repository-backend`. Lifecycle policy: keep last 10 images.

### Root outputs

`cluster_endpoint`, `cluster_name`, `oidc_issuer_url`, `ecr_repository_url`

## Architecture

### Backend (`backend/`)

Flask app factory pattern in `app/__init__.py`. Three blueprints:

| Blueprint | Prefix | File |
|-----------|--------|------|
| `topic_bp` | `/api/topics` | `routes/topic_routes.py` |
| `quiz_bp` | `/api/quiz` | `routes/quiz_routes.py` |
| `api_bp` | `/api` | `routes/__init__.py` (health check only) |

**Data model quirks:**
- `Topic.to_dict()` returns `slug` as `id` (not integer PK). Frontend always uses slug.
- `Question.correct_answer` is 0-based index into `options` JSON array.
- `Question.to_dict(shuffle=True)` (default) randomizes options and remaps `correct_answer`.
- Quiz GET samples up to `MAX_QUIZ_QUESTIONS = 15` randomly per topic.

**CORS:** `ALLOWED_ORIGINS` env var controls allowed origins. Unset = all origins allowed.

### Frontend (`frontend/`)

React + React Router v6 + Tailwind CSS. Three routes:
- `/` → `Home`
- `/quiz/:topic` → `Quiz`
- `/manage-questions` → `QuestionManager`

API base URL from `REACT_APP_API_URL` env var. All calls go through `src/services/api.js`.
Production build served by nginx (`frontend/nginx.conf`).

Docker build context must be `./frontend` (not repo root) — `nginx.conf` is relative to service dir.

### K8s (`k8s/`) — complete

```
k8s/
  namespace.yml
  config/configmap.yaml        # POSTGRES_DB, REACT_APP_API_URL, ALLOWED_ORIGINS
  config/secret.yaml           # POSTGRES_USER, POSTGRES_PASSWORD, DATABASE_URL
  postgres/pvc.yaml            # EBS gp2 1Gi
  postgres/service.yaml        # ClusterIP :5432
  postgres/deployment.yaml     # postgres:13, envFrom both secret+configmap, volumeMount
  backend/service.yaml         # ClusterIP :8000
  backend/deployment.yaml      # Flask 2 replicas, initContainer runs migrate.sh, IMAGE_TAG placeholder
  frontend/service.yaml        # LoadBalancer :80 (creates AWS CLB)
  frontend/deployment.yaml     # React+nginx 2 replicas, IMAGE_TAG placeholder
```

`IMAGE_TAG` in backend and frontend deployments is replaced at deploy time by GitHub Actions with `github.sha`.

## What's Left

1. **`terraform apply`** — spin up EKS cluster before deploying
2. **Security hardening**:
   - ECR `IMMUTABLE` + scan-on-push
   - GitHub OIDC instead of long-lived AWS keys
   - VPC Flow Logs
   - S3 + DynamoDB Terraform remote state backend
