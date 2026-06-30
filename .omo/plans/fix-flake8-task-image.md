# fix-flake8-task-image - Work Plan

## TL;DR (For humans)

**What you'll get:** Your CI linter task will use the correct base image by default, so it works even when run standalone (outside the pipeline). Today the default points to the application's own built container image — which doesn't exist yet at lint time, creating a circular dependency.

**Why this approach:** The pipeline already overrides this image to `python:3.9-slim` at runtime, so this is a zero-risk fix that only affects standalone usage. We keep the pipeline override for defense-in-depth and consistency with the test task (which does the same thing). We use `python:3.9-slim` because it's already the project's standard base image — used by the Dockerfile, the test task, and the cleanup task.

**What it will NOT do:** It will not remove the pipeline's explicit image override. It will not change the OpenShift deployment config (which legitimately uses a different registry). It will not optimize the requirements install or migrate Tekton API versions.

**Effort:** Quick
**Risk:** Low — the pipeline already overrides this param at runtime, so the change has zero impact on existing pipeline behavior
**Decisions to sanity-check:** We're keeping the pipeline.yaml override (redundant but intentional — consistency + defense-in-depth). We're quoting the value with double quotes to match the sibling nosetests task's style.

Your next move: say "start work" to execute, or ask for a high-accuracy review first. Full execution detail follows below.

---

> TL;DR (machine): Quick effort, Low risk, 1 todo — fix flake8 Tekton Task default image from built-app image to python:3.9-slim, keep pipeline override, verify with dry-run + grep + Docker empirical test.

## Scope
### Must have
1. Change `tekton/flake8.yaml` line 23 default image from `us.icr.io/accounts-namespace/accounts:2` to `"python:3.9-slim"` (quoted, matching `nosetests.yaml:13` style)
2. Verify the change with `kubectl apply --dry-run=client`, positive and negative grep assertions, a consistency check against `nosetests.yaml`, a pipeline.yaml-unchanged check, and an empirical Docker test proving flake8 runs on `python:3.9-slim`
3. Commit the change with a clear message explaining the circular-dependency root cause

### Must NOT have (guardrails, anti-slop, scope boundaries)
- Must NOT modify `tekton/pipeline.yaml` — the override at lines 52-53 stays as-is (consistency with nosetests override at lines 70-71; defense-in-depth)
- Must NOT modify the flake8 task script (lines 39-47) — only the default param value changes
- Must NOT touch `deploy/overlays/openshift/kustomization.yaml:12-13` — the `us.icr.io/accounts-namespace/accounts:2` reference there is the legitimate OpenShift deployment target, not a stale lint image
- Must NOT create a flake8-only requirements file or optimize the pip install scope
- Must NOT change `tekton/nosetests.yaml`, `tekton/tasks.yaml`, `tekton/pipelinerun.yaml`, `tekton/rbac.yaml`, `tekton/pvc.yaml`, or `Dockerfile`
- Must NOT migrate Tekton API from v1beta1 to v1 — that is a separate task

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- Test decision: tests-after — this is a YAML manifest change, not application code; verification is dry-run validation + grep assertions + empirical Docker test. No nose/pytest tests apply.
- Evidence: .omo/evidence/task-1-fix-flake8-task-image.txt

## Execution strategy
### Parallel execution waves
> This is a Trivial task: one todo, one wave, one file changed. No parallelism needed.

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1. Fix flake8 default image + verify | none | F1-F4 | none |

## Todos
> Implementation + Test = ONE todo. Never separate.
<!-- APPEND TASK BATCHES BELOW THIS LINE WITH edit/apply_patch - never rewrite the headers above. -->

- [x] 1. Fix flake8 Tekton Task default image from built-app image to python:3.9-slim
  What to do: In `tekton/flake8.yaml` line 23, change `default: us.icr.io/accounts-namespace/accounts:2` to `default: "python:3.9-slim"`. Use double quotes to match the style of `tekton/nosetests.yaml:13` which has `default: "python:3.9-slim"`. Do NOT change any other line in the file — the task script (lines 39-47), the workspaces, the other params, and the annotations all stay as-is. Do NOT remove or modify the pipeline.yaml override at `tekton/pipeline.yaml:52-53` — it stays for consistency with the nosetests override at `pipeline.yaml:70-71` and as defense-in-depth. This change has ZERO runtime impact on the existing pipeline because `pipeline.yaml:52-53` already overrides this param to `python:3.9-slim`; the fix only affects standalone TaskRun executions and future pipelines that don't override the param.
  Must NOT do: Must NOT touch `tekton/pipeline.yaml`. Must NOT modify the task script. Must NOT touch `deploy/overlays/openshift/kustomization.yaml`. Must NOT create a flake8-only requirements file. Must NOT quote with single quotes — use double quotes to match `nosetests.yaml:13`.
  Parallelization: Wave 1 | Blocked by: none | Blocks: F1-F4
  References (executor has NO interview context - be exhaustive):
    - `tekton/flake8.yaml:23` — the line to change: `default: us.icr.io/accounts-namespace/accounts:2`
    - `tekton/nosetests.yaml:13` — the style precedent: `default: "python:3.9-slim"` (double-quoted)
    - `tekton/pipeline.yaml:52-53` — the override that makes this zero-runtime-impact: `name: image` / `value: python:3.9-slim`
    - `tekton/pipeline.yaml:60-61` — lint runs `runAfter: clone` (before build-image at lines 95-97, proving the circular dependency)
    - `tekton/pipeline.yaml:70-71` — nosetests also overrides image to `python:3.9-slim` (precedent for keeping overrides even when defaults match)
    - `tekton/tasks.yaml:12` — cleanup task uses `python:3.9-slim` directly (third data point for the standard base image)
    - `Dockerfile:1` — `FROM python:3.9-slim` (project standard base image)
    - `requirements.txt:17` — `flake8==4.0.1` (installed via `pip install --user -r requirements.txt` in the task script at line 43)
    - `deploy/overlays/openshift/kustomization.yaml:12-13` — the legitimate `us.icr.io` ref (OpenShift deployment target — NOT to be touched)
  Acceptance criteria (agent-executable) — ALL must pass:
    1. `kubectl apply --dry-run=client -f tekton/flake8.yaml` exits 0 with no error output (YAML still validates)
    2. `grep "us.icr.io" tekton/flake8.yaml` returns nothing (exit code 1 — old image removed)
    3. `grep "python:3.9-slim" tekton/flake8.yaml` returns exactly 1 match (positive assertion of new value)
    4. `grep -c "python:3.9-slim" tekton/flake8.yaml tekton/nosetests.yaml` shows both files report 1 (consistency check)
    5. `grep "python:3.9-slim" tekton/pipeline.yaml` returns exactly 2 matches (lines 53 and 71 — override intact, unchanged)
    6. `docker run --rm -v "$(pwd):/app" -w /app python:3.9-slim bash -c "pip install --user -r requirements.txt && flake8 --version"` prints a version string containing "4.0.1" (empirical proof that flake8 installs and runs on python:3.9-slim)
  QA scenarios (name the exact tool + invocation):
    - happy: Run all 6 acceptance criteria above. All pass. Evidence: .omo/evidence/task-1-fix-flake8-task-image.txt
    - failure: Before the fix, run `grep "us.icr.io" tekton/flake8.yaml` and confirm it returns a match (proving the bug exists). After the fix, confirm it returns nothing. Evidence: .omo/evidence/task-1-fix-flake8-task-image.txt
  Commit: Y | fix(tekton): change flake8 task default image from built-app image to python:3.9-slim

## Final verification wave
> Runs in parallel after ALL todos. ALL must APPROVE. Surface results and wait for the user's explicit okay before declaring complete.
- [x] F1. Plan compliance audit — verify `tekton/flake8.yaml:23` has `"python:3.9-slim"` and no other file was modified
- [x] F2. Code quality review — `kubectl apply --dry-run=client -f tekton/flake8.yaml` succeeds; no YAML syntax issues
- [x] F3. Real manual QA — run all 6 acceptance criteria commands and verify outputs match expectations
- [x] F4. Scope fidelity — verify `tekton/pipeline.yaml`, `tekton/nosetests.yaml`, `deploy/overlays/openshift/kustomization.yaml`, and `Dockerfile` are all unchanged (`git diff --name-only` shows only `tekton/flake8.yaml`)

## Commit strategy
- Single commit: `fix(tekton): change flake8 task default image from built-app image to python:3.9-slim`
- One file changed: `tekton/flake8.yaml` (one line)
- No squash needed — trivial scope

## Success criteria
1. `grep "us.icr.io" tekton/flake8.yaml` returns nothing
2. `grep "python:3.9-slim" tekton/flake8.yaml` returns exactly 1 match
3. `kubectl apply --dry-run=client -f tekton/flake8.yaml` exits 0
4. `grep "python:3.9-slim" tekton/pipeline.yaml` returns exactly 2 matches (override intact)
5. `docker run --rm -v "$(pwd):/app" -w /app python:3.9-slim bash -c "pip install --user -r requirements.txt && flake8 --version"` prints "4.0.1"
6. `git diff --name-only` shows only `tekton/flake8.yaml`
