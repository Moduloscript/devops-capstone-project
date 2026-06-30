# tests/ — Test Suite

## Overview
Unit tests for the Account REST API using nose (not pytest). Test on a real PostgreSQL instance via Docker.

## Where To Look
| Task | File | Notes |
|------|------|-------|
| Add route tests | `test_routes.py` | `TestAccountService` class, test_client |
| Add model tests | `test_models.py` | CRUD + serialization tests |
| Add CLI tests | `test_cli_commands.py` | `db-create` command |
| Add/modify factory | `factories.py` | `AccountFactory` uses Faker + FuzzyDate |

## Conventions
- **nose + pinocchio** — run with `nosetests --with-spec --spec-color`, not `pytest`.
- **TestCase class style** — extend `unittest.TestCase`, not pytest functions.
- **`setUp`** — deletes all rows via `db.session.query(Account).delete()` before each test.
- **Factories** — `AccountFactory()` creates fresh fake data per test. No shared state.
- **DB** — connects to real PostgreSQL at `postgresql://postgres:postgres@localhost:5432/postgres`.
- **Helper** — `_create_accounts(count)` creates N accounts via POST for setup.

## Anti-Patterns
- **No pytest** — project uses nose exclusively. Don't use pytest fixtures or `assert` statements without `self.assertEqual`.
- **No mocking** — tests hit a real database, not mocked. Ensure PostgreSQL is running.
- **`force_https=False`** — set in both `setUpClass` and early app init (for kubelet probes).
