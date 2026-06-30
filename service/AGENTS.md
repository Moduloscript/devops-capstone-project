# service/ — Flask Application Core

## Overview
Flask app factory, Account model, and REST API routes. The entire application lives here.

## Where To Look
| Task | File | Notes |
|------|------|-------|
| App bootstrap | `__init__.py` | Global `app` object, Talisman/CORS, DB init, imports |
| Config | `config.py` | Env-driven globals, constructs `DATABASE_URI` from parts |
| Model | `models.py` | `Account` (id, name, email, address, phone, date_joined), CRUD via `PersistentBase` |
| Routes | `routes.py` | CRUD endpoints, health/index, content-type validation |
| Common utilities | `common/` | Error handlers, CLI, logging, status codes |

## Conventions (service-specific)
- **No Blueprints** — routes registered via `@app.route()` on the global `app`.
- **Content-Type required** — POST/PUT must be `application/json` (enforced by `check_content_type()`).
- **Model deserialize** — raises `DataValidationError` on missing fields; callers return 400.
- **DB init** — guarded by `"sqlalchemy" not in app.extensions` to skip when tests already initialized.

## Anti-Patterns
- **Import order** — routes/models/error_handlers imported after `app` creation (requires `# noqa: E402`).
- **Broad except** — `__init__.py:41` catches all exceptions during DB init (intentional: gunicorn needs exit code 4).
