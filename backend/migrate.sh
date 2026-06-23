#!/bin/bash

set -e

export FLASK_APP=${FLASK_APP:-run.py}

echo "Running database migrations..."

if [ ! -d "migrations" ]; then
    echo "Initializing migrations directory..."
    flask db init
fi

echo "Creating migrations..."
flask db migrate -m "Auto-generated migration" 2>/dev/null || true

echo "Applying migrations..."
# Stamp base if revision mismatch (EBS persists old alembic_version across pod restarts)
if ! flask db upgrade 2>/dev/null; then
    echo "Revision mismatch, stamping base and retrying..."
    flask db stamp base
    flask db upgrade
fi

echo "Checking if seed data is needed..."
python -c "
from app import create_app, db
from app.models.topic import Topic
app = create_app()
with app.app_context():
    if Topic.query.count() == 0:
        import subprocess
        subprocess.run(['python', 'seed_data.py'], check=True)
        print('Seed data applied')
    else:
        print('Database already contains data, skipping seed')
" || true

echo "Database setup completed successfully!"