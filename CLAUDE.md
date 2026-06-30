# DevOps Capstone Project

## Project Overview
Flask-based REST API service with PostgreSQL, deployed on OpenShift. DevOps capstone project demonstrating CI/CD, containerization, and cloud-native deployment.

## Tech Stack
- **Backend:** Python 3.x, Flask, Flask-RESTful
- **Database:** PostgreSQL (ephemeral template)
- **Container:** Docker, Dockerfile
- **Deployment:** OpenShift (Kubernetes)
- **CI/CD:** Tekton Pipelines
- **Testing:** pytest, factory_boy
- **Linting:** flake8

## Project Structure

### `/service/` — Flask Application
- `__init__.py` — App factory and initialization
- `config.py` — Configuration (env-based, Flask)
- `models.py` — SQLAlchemy models
- `routes.py` — API endpoint definitions
- `common/` — Shared utilities
  - `cli_commands.py` — Flask CLI commands
  - `error_handlers.py` — Error handling middleware
  - `log_handlers.py` — Logging configuration
  - `status.py` — Status/health check utilities

### `/tests/` — Test Suite
- `factories.py` — Test data factories (factory_boy)
- `test_cli_commands.py` — CLI command tests
- `test_models.py` — Model tests
- `test_routes.py` — API route tests

### `/deploy/` — Kubernetes Manifests
- `deployment.yaml` — App deployment
- `service.yaml` — Service definition
- `postgresql.yaml` — Database deployment

### `/tekton/` — CI/CD Pipelines
- `pipeline.yaml` — Main pipeline definition
- `tasks.yaml` — Pipeline tasks
- `flake8.yaml` — Linting task
- `pvc.yaml` — Persistent volume claim

### Root Files
- `Dockerfile` — Container image definition
- `Makefile` — Build automation
- `requirements.txt` — Python dependencies
- `Procfile` — Process type definitions
- `setup.cfg` — Tool configuration
- `.flaskenv` — Flask environment variables

## Key Patterns
- **App Factory:** `create_app()` in `__init__.py`
- **Config by Environment:** `config.py` reads from env vars
- **RESTful Routes:** Blueprint-based routing in `routes.py`
- **Error Handling:** Centralized in `common/error_handlers.py`
- **Logging:** Structured logging via `common/log_handlers.py`
- **CLI Commands:** Custom Flask commands in `common/cli_commands.py`

## Coding Standards
- Follow PEP 8 (enforced by flake8)
- Use type hints where practical
- Write tests for all new routes and models
- Keep functions small and focused
- Use meaningful variable names
- No hardcoded secrets — use environment variables

## Testing
- Run: `pytest` or `make test`
- Coverage: Aim for 80%+ coverage
- Factories in `tests/factories.py` for test data
- Use pytest fixtures for setup/teardown

## Common Tasks
- **Add a route:** Create endpoint in `service/routes.py`, add test in `tests/test_routes.py`
- **Add a model:** Define in `service/models.py`, add factory in `tests/factories.py`
- **Add config:** Update `service/config.py` with new env var
- **Deploy:** `kubectl apply -f deploy/`
- **Build image:** `docker build -t app .`
