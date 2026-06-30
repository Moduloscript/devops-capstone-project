# Project Knowledge Base

**Generated:** 2026-06-29
**Commit:** cbda803
**Branch:** main

## Overview
Flask-based Account REST API service with PostgreSQL, containerized via Docker, deployed on OpenShift/K3d, with Tekton CI/CD pipelines.

## Tech Stack
- **Backend:** Python 3.9, Flask 2.1, Flask-SQLAlchemy, Flask-Talisman, Flask-CORS
- **Database:** PostgreSQL (ephemeral template + SQLAlchemy ORM)
- **Container:** Docker, gunicorn (WSGI)
- **Deployment:** OpenShift / K3d (Kubernetes manifests)
- **CI/CD:** Tekton Pipelines
- **Testing:** nose + pinocchio (spec output), factory_boy, coverage
- **Linting:** flake8, pylint

## Structure
```
.
├── service/          # Flask application (app factory, models, routes, common/)
├── tests/            # Test suite (nose, factories, route/model/CLI tests)
├── deploy/           # Kubernetes manifests (deployment + services)
├── tekton/           # Tekton pipeline definitions (pipeline, tasks, lint)
├── bin/              # Development setup scripts
├── plans/            # Planning documents
├── Dockerfile        # Container build (python:3.9-slim, gunicorn)
├── Makefile          # Build automation (k3d, tekton, docker, lint, test)
├── requirements.txt  # Pinned Python dependencies
├── Procfile          # Honcho process (gunicorn)
├── setup.cfg         # flake8 + nose + coverage config
└── .flaskenv         # FLASK_APP=service:app, FLASK_RUN_PORT=8000
```

## Where To Look
| Task | Location | Notes |
|------|----------|-------|
| Add/modify API endpoint | `service/routes.py` | CRUD for `/accounts`, content-type check |
| Add/modify DB model | `service/models.py` | `Account` model, `PersistentBase` mixin |
| Add config | `service/config.py` | Env-based `DATABASE_URI`, `SECRET_KEY` |
| Add error handler | `service/common/error_handlers.py` | 400/404/405/415/500 + validation errors |
| Add CLI command | `service/common/cli_commands.py` | `flask db-create` |
| Add test | `tests/test_routes.py` | `TestAccountService` class |
| Add test factory | `tests/factories.py` | `AccountFactory` (Faker-based) |
| Modify deployment | `deploy/` | Deployment, Service, PostgreSQL manifests |
| Modify CI/CD | `tekton/` | Pipeline + tasks (clone → lint → ...) |

## Code Map
| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `app` | Flask instance | `service/__init__.py` | App factory, routes, error handlers registered here |
| `Account` | Model | `service/models.py` | Main entity: id, name, email, address, phone, date_joined |
| `PersistentBase` | Mixin | `service/models.py` | CRUD: create/update/delete/all/find |
| `DataValidationError` | Exception | `service/models.py` | Validation error during deserialize |
| `db` | SQLAlchemy | `service/models.py` | DB session, initted via `init_db(app)` |
| `config.*` | Config | `service/config.py` | Env-driven `DATABASE_URI`, `SECRET_KEY` |
| `create_accounts()` | Route | `service/routes.py` | POST /accounts |
| `list_accounts()` | Route | `service/routes.py` | GET /accounts |
| `read_account()` | Route | `service/routes.py` | GET /accounts/\<id\> |
| `update_account()` | Route | `service/routes.py` | PUT /accounts/\<id\> |
| `delete_account()` | Route | `service/routes.py` | DELETE /accounts/\<id\> |
| `health()` | Route | `service/routes.py` | GET /health |
| `index()` | Route | `service/routes.py` | GET / |
| `status.*` | Constants | `service/common/status.py` | HTTP status code constants |
| `error handlers` | Handlers | `service/common/error_handlers.py` | 400/404/405/415/500 + DataValidationError |
| `init_logging()` | Utility | `service/common/log_handlers.py` | Gunicorn log integration |
| `db_create` | CLI cmd | `service/common/cli_commands.py` | `flask db-create` |

## Conventions
- **App factory:** Global `app` in `service/__init__.py` (not lazy factory). Routes import `app` directly.
- **Config:** Module-level globals in `config.py`, read from env vars. Not a class-based config.
- **Error handling:** Centralized decorators; all return `(jsonify(...), status_code)` tuple.
- **Logging:** Structured format `[%Y-%m-%d %H:%M:%S %z] [LEVEL] [module] msg`. Gunicorn propagates.
- **Testing:** nose + TestCase class (not pytest functions). Factories create fresh objects per test.
- **Linting:** flake8 with max-complexity=10, max-line-length=127. Pylint disables E1101 (no-member).
- **DB init:** Init happens at import time in `__init__.py` (not lazy). Tests bypass via `app.extensions` guard.
- **Security headers:** Talisman (force_https=False for kubelet HTTP probes) + CORS (all origins).

## Anti-Patterns (This Project)
- **`pylint: disable` comments** — present on several lines (broad-except, wrong-import-position, no-member, too-few-public-methods). Accept only where necessary.
- **`# noqa: E402`** — used for imports after app creation. This pattern is required by the global app architecture.
- **Hardcoded secrets** — `SECRET_KEY` defaults to `"s3cr3t-key-shhhh"` in `config.py`. Override via env in production.
- **`nose` over pytest** — project uses nose/pinocchio, not pytest. Keep tests compatible.
- **Module-level `app`** — not lazy. Tests must properly import the module (not create a test app instance).
- **Commented-out code** — `url_for("get_accounts", ...)` is commented out in `routes.py:54` (placeholder for unimplemented route).
- **No `__init__.py` in `deploy/`, `tekton/`, `bin/`** — expected (non-Python dirs).

## Commands
```bash
make help              # List all targets
make cluster           # Create K3d cluster with registry
make tekton            # Install Tekton into cluster
make build             # docker build --tag accounts:1.0 .
make push              # Push to K3d registry (localhost:32000)
make lint              # flake8 (F/E severity) + flake8 (complexity=10, line=127)
make tests             # nosetests --with-spec --with-coverage --cover-package=service
make run               # honcho start (gunicorn)
make db                # PostgreSQL in Docker (alpine)
make venv              # python3 -m venv ~/venv
make install           # pip install -r requirements.txt
```

## Notes
- Tests run against a real PostgreSQL (default: `postgresql://postgres:postgres@localhost:5432/postgres`).
- The `__pycache__/` and `instance/test.db` are generated artifacts — don't track.
- OpenShift route config is not yet defined (Service is ClusterIP only).
- Tekton pipeline stub has `init` (cleanup) → `clone` (git-clone) → `lint` (flake8) — build/deploy stages are placeholders.
- Flask-Talisman has `force_https=False` — intentional for kubelet HTTP health probes.
- Use `nosetests` not `pytest` — Makefile and setup.cfg are nose-specific.
