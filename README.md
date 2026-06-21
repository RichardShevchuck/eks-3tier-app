# DevOps Learning Platform

Quiz app for DevOps topics (Docker, Kubernetes, Jenkins, AWS, Linux). Three-tier architecture deployed on AWS EKS.

## Stack

| Layer | Tech |
|-------|------|
| Frontend | React 18, Tailwind CSS, nginx |
| Backend | Flask, SQLAlchemy, Flask-Migrate |
| Database | PostgreSQL 13 |
| Infrastructure | Terraform, AWS EKS (eu-central-1) |

## Local Development

```bash
docker compose up --build
```

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000/api
- Health check: http://localhost:8000/api

## Backend (without Docker)

```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Start Postgres
docker run --name pg -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=devops_learning -p 5432:5432 -d postgres

# Create .env
echo "DATABASE_URL=postgresql://postgres:password@localhost:5432/devops_learning
FLASK_APP=run.py
FLASK_DEBUG=1" > .env

flask db init && flask db migrate -m "init" && flask db upgrade
python seed_data.py
python run.py
```

## Seed & Bulk Data

```bash
# Initial seed (Docker, Kubernetes, Jenkins topics + questions)
python seed_data.py

# Bulk load from CSV
python bulk_upload_questions.py questions-answers/kubernetes_questions.csv
python bulk_upload_questions.py questions-answers/docker_questions.csv
python bulk_upload_questions.py questions-answers/jenkins_questions.csv
python bulk_upload_questions.py questions-answers/aws.csv
python bulk_upload_questions.py questions-answers/linux.csv
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/topics` | List all topics |
| POST | `/api/topics` | Create topic |
| PUT | `/api/topics/<id>` | Update topic |
| DELETE | `/api/topics/<id>` | Delete topic |
| GET | `/api/quiz/<topic_slug>` | Get quiz (up to 15 random questions, shuffled) |
| POST | `/api/quiz/submit` | Submit answers, get score |
| POST | `/api/quiz/questions` | Add single question |
| POST | `/api/quiz/questions/bulk` | Bulk add questions |

## Infrastructure

Terraform in `terrafrom/` (note spelling). Targets AWS `eu-central-1`.

```bash
cd terrafrom
terraform init
terraform plan
terraform apply
```

### Modules

- **vpc** — VPC, 2 public + 2 private subnets, IGW, NAT gateway. Subnets tagged for EKS load balancer controller.
- **eks** — EKS 1.31 cluster on private subnets, `t3.medium` node group (1–3 nodes).
- **iam** — Node group IAM role with `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`.

## Environment Variables

**Backend:**

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://postgres:postgres@db:5432/devops_learning` | Postgres connection string |
| `SECRET_KEY` | `dev-secret-key` | Flask secret key |
| `FLASK_DEBUG` | `0` | Enable debug mode |
| `ALLOWED_ORIGINS` | _(all)_ | Comma-separated CORS origins |

**Frontend:**

| Variable | Default | Description |
|----------|---------|-------------|
| `REACT_APP_API_URL` | `http://localhost:8000/api` | Backend API base URL |
