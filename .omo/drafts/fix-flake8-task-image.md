---
slug: fix-flake8-task-image
status: approved
intent: clear
review_required: false
pending-action: write .omo/plans/fix-flake8-task-image.md
approach: Change tekton/flake8.yaml default image from us.icr.io/accounts-namespace/accounts:2 to python:3.9-slim (one-line fix). Keep the pipeline.yaml override. Add empirical Docker validation.
---

# Draft: fix-flake8-task-image

## Components (topology ledger)
| id | outcome | status | evidence path |
|----|---------|--------|---------------|
| flake8-default-image | flake8 Tekton Task default image changed from built-app image to python:3.9-slim | active | tekton/flake8.yaml:23 |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
|------------|-----------------|-----------|-------------|
| Should the pipeline.yaml override be kept? | KEEP | Consistency with nosetests override (pipeline.yaml:70-71), defense-in-depth, explicit intent documentation | Yes |
| Should the value be quoted? | Quote it: `"python:3.9-slim"` | Consistency with nosetests.yaml:13 which quotes the same value | Yes |

## Findings (cited - path:lines)
- `tekton/flake8.yaml:23` — `default: us.icr.io/accounts-namespace/accounts:2` (the bug: built app image, circular dep)
- `tekton/pipeline.yaml:52-53` — pipeline overrides image to `python:3.9-slim` (pipeline works today despite the bad default)
- `tekton/pipeline.yaml:60-61` — lint runs `runAfter: clone` (BEFORE build-image at lines 95-97, confirming circular dependency)
- `tekton/nosetests.yaml:13` — `default: "python:3.9-slim"` (sibling task already uses correct default, quoted)
- `tekton/tasks.yaml:12` — cleanup task uses `python:3.9-slim` directly (third data point)
- `Dockerfile:1` — `FROM python:3.9-slim` (project standard base image)
- `requirements.txt:17` — `flake8==4.0.1` (installed via pip in the task script)
- `deploy/overlays/openshift/kustomization.yaml:12-13` — legitimate `us.icr.io` ref (deployment target, NOT a lint image)
- Root cause: flake8.yaml default was copy-pasted from the OpenShift deployment config
- The pipeline builds to `localhost:32000/accounts:1.0` (pipeline.yaml:88), NOT `us.icr.io/accounts-namespace/accounts:2` — the default references a completely different registry

## Decisions (with rationale)
1. KEEP pipeline.yaml override — consistency with nosetests override pattern (pipeline.yaml:70-71 overrides the same param to the same value even though nosetests.yaml already defaults to it)
2. QUOTE the value — nosetests.yaml:13 quotes `"python:3.9-slim"`; matching that style
3. This change has ZERO runtime impact on the existing pipeline — pipeline.yaml:52-53 already overrides this param, so the fix only affects standalone TaskRun executions and future pipelines that don't override
4. Empirical Docker validation included — proves flake8 installs and runs on python:3.9-slim without needing a Tekton cluster

## Scope IN
- Change `tekton/flake8.yaml:23` default image to `"python:3.9-slim"` (quoted)
- Verify via kubectl dry-run, grep assertions, and Docker empirical test

## Scope OUT (Must NOT have)
- Must NOT modify `tekton/pipeline.yaml` — the override stays as-is
- Must NOT modify the task script in flake8.yaml (lines 39-47)
- Must NOT touch `deploy/overlays/openshift/kustomization.yaml` — the `us.icr.io` ref there is legitimate
- Must NOT create a flake8-only requirements file
- Must NOT change any other Tekton file

## Open questions
None — all resolved by exploration and Metis analysis.

## Approval gate
status: approved
User approved on 2026-06-30 with "yes please".
