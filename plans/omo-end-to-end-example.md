# End-to-End Example: Building a Product with Oh-My-OpenAgent

**Pseudo Project:** Task Manager API (Flask + PostgreSQL)
**Goal:** Show the complete workflow from zero to shipped product

---

## Phase 0: Project Setup (5 minutes)

### Step 0.1 — Create the project directory
```bash
mkdir task-manager-api
cd task-manager-api
```

### Step 0.2 — Create opencode.json
```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["oh-my-openagent@latest"]
}
```

### Step 0.3 — Create minimal AGENTS.md
```markdown
# Task Manager API

## Overview
A REST API for managing tasks with Flask and PostgreSQL.

## Tech Stack
- Python 3.9, Flask, SQLAlchemy
- PostgreSQL
- Docker, gunicorn

## Structure
```
.
├── service/     # Flask app
├── tests/       # Test suite
├── Dockerfile
└── requirements.txt
```
```

### Step 0.4 — Open the project in OpenCode
```bash
opencode .
```

**Result:** OpenCode loads with OmO already active. All 10 agents are available immediately because they're registered globally.

---

## Phase 1: Ideation — Define What to Build

### You type in OpenCode:
```
/ulw @prometheus I want to build a Task Manager API.
Features needed:
- CRUD for tasks (create, read, update, delete)
- Each task has: title, description, status (pending/in-progress/done), priority (low/medium/high), created_at
- Filter tasks by status and priority
- Sort by created_at or priority
- Health check endpoint

Design the complete architecture plan.
```

### Prometheus responds with:

```markdown
## Architecture Plan: Task Manager API

### Data Model
```
Task
├── id: Integer (PK, auto-increment)
├── title: String(255), required
├── description: Text, optional
├── status: Enum(pending, in_progress, done), default=pending
├── priority: Enum(low, medium, high), default=medium
├── created_at: DateTime, auto-set
└── updated_at: DateTime, auto-update
```

### API Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check |
| GET | / | API info |
| POST | /tasks | Create task |
| GET | /tasks | List tasks (with ?status=&priority=&sort=) |
| GET | /tasks/:id | Get single task |
| PUT | /tasks/:id | Update task |
| DELETE | /tasks/:id | Delete task |

### Implementation Order
1. Project scaffold (requirements.txt, config, app factory)
2. Task model (SQLAlchemy)
3. Routes (CRUD + filtering/sorting)
4. Error handlers
5. Tests
6. Dockerfile
7. AGENTS.md update
```

### You review and approve:
```
Looks good. Proceed with implementation.
```

---

## Phase 2: Implementation — Sisyphus Orchestrates

### You type:
```
/ulw @sisyphus Implement the Task Manager API following Prometheus's plan.
Use Hephaestus for the actual coding. Work through each step.
```

### What happens internally:

**Sisyphus** creates a task list and starts delegating:

```
Task List:
[ ] Step 1: Create requirements.txt, config.py, app factory
[ ] Step 2: Create Task model in models.py
[ ] Step 3: Create routes.py with all endpoints
[ ] Step 4: Create error handlers
[ ] Step 5: Create tests
[ ] Step 6: Create Dockerfile
[ ] Step 7: Update AGENTS.md
```

**Sisyphus delegates Step 1 to Hephaestus:**

Hephaestus creates `requirements.txt`:
```
Flask==2.1.0
Flask-SQLAlchemy==2.5.1
psycopg2-binary==2.9.3
gunicorn==20.1.0
```

Hephaestus creates `service/config.py`:
```python
import os

DATABASE_URI = os.getenv("DATABASE_URI", "postgresql://postgres:postgres@localhost:5432/tasks")
SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key")
```

Hephaestus creates `service/__init__.py`:
```python
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://postgres:postgres@localhost:5432/tasks"
    app.config["SECRET_KEY"] = "dev-secret-key"
    db.init_app(app)

    with app.app_context():
        from . import routes
        db.create_all()

    return app
```

**Sisyphus marks Step 1 complete, delegates Step 2:**

Hephaestus creates `service/models.py`:
```python
from . import db
from datetime import datetime

class Task(db.Model):
    __tablename__ = "tasks"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(20), default="pending")
    priority = db.Column(db.String(10), default="medium")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def serialize(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "status": self.status,
            "priority": self.priority,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }

    @classmethod
    def all(cls):
        return cls.query.all()

    @classmethod
    def find(cls, task_id):
        return cls.query.get(task_id)

    def create(self):
        db.session.add(self)
        db.session.commit()

    def update(self):
        db.session.commit()

    def delete(self):
        db.session.delete(self)
        db.session.commit()
```

**Sisyphus continues delegating through all steps...**

After all 7 steps, Sisyphus reports:
```
✅ Implementation complete:
- requirements.txt created
- service/__init__.py (app factory)
- service/config.py
- service/models.py (Task model)
- service/routes.py (7 endpoints)
- service/common/error_handlers.py
- tests/test_routes.py (15 tests)
- Dockerfile
- AGENTS.md updated
```

---

## Phase 3: Review — Metis + Momus Check Quality

### You type:
```
/ulw @metis @momus Review the entire implementation.
Check for: security, edge cases, code quality, test coverage.
```

### Metis reports:
```
## Code Review

### Security
✅ SQLAlchemy parameterized queries — no injection risk
✅ Input validation on status/priority fields
⚠️ SECRET_KEY is hardcoded — add env var override (minor, config.py already supports it)

### Code Quality
✅ Follows Flask patterns consistently
✅ Good separation of concerns (models/routes/config)
✅ Error handlers centralized
✅ serialize() method on model — clean JSON output

### Test Coverage
✅ 15 tests covering all CRUD operations
✅ Tests for filtering and sorting
✅ Tests for 404 errors
⚠️ Missing test for invalid status/priority values
```

### Momus reports:
```
## Critical Analysis

### Edge Cases Found
1. What happens when title is empty? → Should return 400
2. What happens with invalid status "urgent"? → Should return 400
3. What happens with very long title (>255 chars)? → DB will truncate or error
4. What about pagination? → Not implemented, large datasets will be slow
5. What about CORS? → Not configured, frontend calls will be blocked

### Recommendations
1. Add input validation middleware
2. Add pagination (limit/offset) to GET /tasks
3. Add CORS support for frontend consumption
4. Add database migration support (Alembic) for production
```

### You decide:
```
Fix the input validation and CORS issues. Skip pagination for now.
```

---

## Phase 4: Fix — Sisyphus Implements Fixes

### You type:
```
/ulw @sisyphus Fix the issues Metis and Momus found:
1. Add input validation for title, status, priority
2. Add Flask-CORS
3. Add test for invalid inputs
```

Sisyphus delegates to Hephaestus who updates the routes with validation and adds CORS.

---

## Phase 5: Documentation — Atlas Updates Docs

### You type:
```
/ulw @atlas Update AGENTS.md with the complete API documentation.
Include all endpoints, request/response examples, and error codes.
```

Atlas updates AGENTS.md with full API docs.

---

## Phase 6: Test — Run the Suite

### You type:
```
/ulw @sisyphus Run the test suite and report results.
```

Sisyphus runs the tests:
```
$ nosetests --with-spec --with-coverage --cover-package=service

Test Task Routes
- test_create_task ... OK
- test_create_task_empty_title ... OK
- test_create_task_invalid_status ... OK
- test_list_tasks ... OK
- test_list_tasks_filter_by_status ... OK
- test_list_tasks_sort_by_priority ... OK
- test_get_task ... OK
- test_get_task_not_found ... OK
- test_update_task ... OK
- test_update_task_not_found ... OK
- test_delete_task ... OK
- test_delete_task_not_found ... OK
- test_health_check ... OK
- test_index ... OK
- test_cors_headers ... OK

Name                   Stmts   Miss  Cover
------------------------------------------
service/__init__.py       12      0   100%
service/config.py          2      0   100%
service/models.py         24      0   100%
service/routes.py         45      0   100%
------------------------------------------
TOTAL                     83      0   100%

Ran 15 tests in 1.234s
OK
```

```
✅ All 15 tests pass. 100% coverage.
```

---

## Phase 7: Deploy — Ship It

### You type:
```
/ulw @sisyphus Create a deployment plan.
We need: Docker build, Kubernetes manifests, and a Tekton pipeline.
```

Sisyphus delegates:

**Hephaestus** creates `deploy/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: task-manager
spec:
  replicas: 2
  selector:
    matchLabels:
      app: task-manager
  template:
    metadata:
      labels:
        app: task-manager
    spec:
      containers:
      - name: task-manager
        image: task-manager:1.0
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          value: postgresql://postgres:postgres@postgres:5432/tasks
```

**Hephaestus** creates `deploy/service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: task-manager
spec:
  selector:
    app: task-manager
  ports:
  - port: 8000
    targetPort: 8000
  type: ClusterIP
```

**Sisyphus reports:**
```
✅ Deployment ready:
- Dockerfile already exists
- deploy/deployment.yaml created
- deploy/service.yaml created
- Run: docker build -t task-manager:1.0 .
- Run: kubectl apply -f deploy/
```

---

## The Complete Timeline

```
Phase 0: Setup          → 5 minutes  (you)
Phase 1: Ideation       → 2 minutes  (you + Prometheus)
Phase 2: Implementation → 3 minutes  (Sisyphus + Hephaestus)
Phase 3: Review         → 2 minutes  (Metis + Momus)
Phase 4: Fixes          → 1 minute   (Sisyphus + Hephaestus)
Phase 5: Documentation  → 30 seconds (Atlas)
Phase 6: Test           → 30 seconds (Sisyphus)
Phase 7: Deploy         → 2 minutes  (Sisyphus + Hephaestus)
─────────────────────────────────────────────
Total: ~16 minutes from idea to deployed API
```

---

## Key Takeaways

1. **You are the product manager** — you describe what to build, review plans, and approve/reject
2. **Prometheus is your architect** — designs everything before a line of code is written
3. **Sisyphus is your project manager** — breaks work down, delegates, tracks progress
4. **Hephaestus is your engineer** — writes all the code
5. **Metis + Momus are your QA team** — catch issues before they reach production
6. **Atlas is your technical writer** — keeps documentation up to date

**You never write boilerplate. You never forget tests. You never ship without review.**
