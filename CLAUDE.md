# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

DevOps quiz platform (Docker, Kubernetes, Jenkins, AWS, Linux topics). Three-tier: React frontend → Flask API → PostgreSQL. Intended for deployment on EKS via Terraform.

Note: the Terraform directory is named `terrafrom` (typo), not `terraform`.

## Local Development

**Full stack (recommended):**
```bash
docker compose up --build
# frontend → http://localhost:3000
# backend  → http://localhost:8000
# postgres → localhost:5432
```

**Backend only (no Docker):**
```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Start a local Postgres
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
# After changing models:
flask db migrate -m "Description"
flask db upgrade

# Seed initial topics + questions (Docker, Kubernetes, Jenkins):
python seed_data.py

# Bulk-load questions from CSV:
python bulk_upload_questions.py questions-answers/kubernetes_questions.csv
python bulk_upload_questions.py questions-answers/docker_questions.csv
python bulk_upload_questions.py questions-answers/jenkins_questions.csv
```

CSV format: `topic_slug, question_text, option_1, option_2, option_3, option_4, correct_answer` (0-indexed).

## Frontend Tests

```bash
cd frontend
npm test                    # watch mode
npm test -- --watchAll=false  # single run
```

## Terraform (Infrastructure)

```bash
cd terrafrom   # note spelling
terraform init
terraform plan
terraform apply
```

Region hardcoded to `eu-central-1`. Only a VPC module exists; EKS resources not yet written.

## Architecture

### Backend (`backend/`)

Flask app factory pattern in `app/__init__.py`. Three blueprints registered:

| Blueprint | Prefix | File |
|-----------|--------|------|
| `topic_bp` | `/api/topics` | `routes/topic_routes.py` |
| `quiz_bp` | `/api/quiz` | `routes/quiz_routes.py` |
| `api_bp` | `/api` | `routes/__init__.py` (health check only) |

**Data model quirks to know:**
- `Topic.to_dict()` returns `slug` as the `id` field (not the integer PK). Frontend always uses slug, never numeric ID.
- `Question.correct_answer` is a 0-based index into the `options` JSON array.
- `Question.to_dict(shuffle=True)` (the default) randomizes option order and remaps `correct_answer` to the new index. Quiz GET endpoint uses shuffle; management endpoints use `shuffle=False`.
- Quiz GET randomly samples up to `MAX_QUIZ_QUESTIONS = 15` from the full question pool per topic.

**CORS:** If `ALLOWED_ORIGINS` env var is set, only those origins are allowed. Otherwise all origins pass. Set `ALLOWED_ORIGINS=http://your-frontend` in production.

### Frontend (`frontend/`)

React + React Router v6 + Tailwind CSS. Three routes:
- `/` → `Home` (topic list)
- `/quiz/:topic` → `Quiz` (takes topic slug)
- `/manage-questions` → `QuestionManager` (CRUD UI for questions)

API base URL comes from `REACT_APP_API_URL` env var (defaults to `http://localhost:8000/api`). All API calls go through `src/services/api.js` which imports from `src/config/api.js`.

Production build is served by nginx (`frontend/nginx.conf`).

### Terraform (`terrafrom/`)

VPC module (`modules/vpc/`) creates: VPC, 2 public subnets, 2 private subnets, IGW, NAT gateway (single, on public subnet 0), public and private route tables. Subnets are tagged for EKS load balancer controller (`kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`, `kubernetes.io/cluster/<name>`).

### Docker

`docker-compose.yml` wires all three services. Backend mounts `./backend:/app` for live reload in dev. `migrate.sh` is the migration entrypoint script used inside the container — it checks if the `topics` table is empty before running `seed_data.py`.
