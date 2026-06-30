# service/common/ — Shared Utilities

## Overview
Cross-cutting modules reused throughout the application: error handling, logging, CLI commands, and HTTP status constants.

## Where To Look
| Task | File | Notes |
|------|------|-------|
| Add error handler | `error_handlers.py` | 5 handlers: 400, 404, 405, 415, 500 + DataValidationError |
| Add CLI command | `cli_commands.py` | Use `@app.cli.command("name")` decorator |
| Configure logging | `log_handlers.py` | `init_logging(app, "gunicorn.error")` |
| Use status codes | `status.py` | Named constants throughout routes and tests |

## Conventions
- **Error response shape** — `{status, error, message}` triple for all handlers.
- **Status imports** — `from service.common import status` then `status.HTTP_200_OK`.
- **Logging format** — `[%Y-%m-%d %H:%M:%S %z] [LEVEL] [module] msg`.

## Anti-Patterns
- **status.py is hand-rolled** — not a library import. Keep in sync with RFC 2616/6585.
- **cli_commands.py only has `db-create`** — no other CLI commands exist yet.
- **No middleware layer** — all cross-cutting concerns are registered as error handlers or imported at app init.
