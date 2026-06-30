# next-devops-completion - Work Plan

## TL;DR (For humans)

**What you'll get:** A complete CI/CD pipeline that builds, tests, and deploys your Flask API automatically; a Kubernetes deployment that works on both your local K3d cluster and OpenShift; external access to your API via an Ingress; your secret key managed securely as a Kubernetes Secret; 13+ new tests closing every coverage gap I found; and all code stubs and git cruft cleaned up.

**Why this approach:** The capstone Flask app and its CRUD endpoints are 100% done — the gaps are all in the DevOps layer. The highest-value next step is completing the Tekton CD pipeline (currently only lints — no build, test, or deploy), then making the service actually reachable from outside the cluster (currently ClusterIP-only), then hardening secrets and tests. I chose Kustomize for multi-environment deployment because you already have two registries (K3d localhost:32000 and OpenShift us.icr.io) and Kustomize handles that swap with one line per overlay.

**What it will NOT do:** Switch from nose to pytest; upgrade SQLAlchemy; add Helm charts; add CI/CD webhook triggers; modify the working GitHub Actions CI; add PostgreSQL persistent storage; add multi-stage Docker build.

**Effort:** Large
**Risk:** Medium — the main risk is the Tekton pipeline requiring a running K3d cluster with ClusterTasks installed to actually execute; all manifests can be validated with dry-run without a cluster.
**Decisions I made for you:**
- I treated this as open-ended and chose defaults from codebase evidence + best practices. If you had a specific outcome in mind, say so and I'll switch to asking.
- **K3d as primary dev environment** — your Makefile already configures it; OpenShift is a secondary overlay. (Reversible: swap overlay.)
- **Kustomize base+overlays** — industry standard for multi-env Kubernetes packaging. (Reversible: `kustomize build` is pure rendering.)
- **Ingress (not OpenShift Route) as base** — K3d has Traefik built-in; OpenShift auto-converts Ingress→Route. (Reversible.)
- **Custom nosetests Tekton Task** — no catalog task exists for nose. (Reversible.)
- **buildah + openshift-client ClusterTasks** — already installed via `make clustertasks`. (Reversible.)
- **SECRET_KEY via Kustomize secretGenerator** — gitignored .env file for K3d; sealed-secrets for OpenShift later. (Reversible.)
- **Fix Location header** — `url_for("read_account", ...)` instead of hardcoded `"/"`. (Reversible.)
- **Migrate Query.get()** → `db.session.get()` — works in SQLAlchemy 1.4.46 and 2.x. (Reversible.)
- **Keep nose** — project convention. (Reversible.)
- **Warn on missing SECRET_KEY** rather than removing the default — keeps tests working. (Reversible.)

Your next move: I ran a high-accuracy review (Metis + dual Momus/Oracle). Review the results below, then say "start work" to begin execution. Full execution detail follows below.

---

> TL;DR (machine): Large effort, Medium risk, 24 todos across 6 waves — complete Tekton CD pipeline, Kustomize deployment with Ingress, SECRET_KEY as K8s Secret, 13+ new tests, and code stub fixes.

## Scope
### Must have
1. **Tekton CD pipeline completed** — test, build-image, and deploy stages added to the existing init→clone→lint pipeline, with a PipelineRun manifest, RBAC, and git-clone vendored
2. **Kustomize deployment structure** — deploy/ restructured into base/ + overlays/k3d/ + overlays/openshift/ with per-env image registries
3. **External service access** — Ingress resource for Traefik (K3d built-in) so the API is reachable from outside the cluster at http://localhost:8080
4. **SECRET_KEY as Kubernetes Secret** — no hardcoded defaults in production; gitignored .env for K3d, sealed-secret placeholder for OpenShift
5. **Test coverage gaps closed** — 405, 500, __repr__, PUT 415, find_by_name edge cases, date_joined branches, malformed JSON, follow-up GET after DELETE, phone_number=None
6. **Code stubs fixed** — Location header returns real URL; Query.get() migrated to db.session.get(); dirty git tree committed; stale branches deleted

### Must NOT have (guardrails, anti-slop, scope boundaries)
- Must NOT switch from nose to pytest — project convention is nose/pinocchio (setup.cfg, Makefile)
- Must NOT upgrade SQLAlchemy from 1.4.46 to 2.x — pinned in requirements.txt; migration is to use the 1.4-compatible `db.session.get()` API only
- Must NOT add OpenShift Route CRD to the K3d base — K3d is vanilla K8s; Ingress is the portable base; Route goes in the openshift overlay only
- Must NOT remove the SECRET_KEY default without setting it in test environments — tests that import `service.config` will crash without a fallback or env var
- Must NOT add CI/CD triggers (TriggerTemplate/EventListener) — out of scope; PipelineRun is manually started
- Must NOT add Helm charts — Kustomize is the chosen packaging tool
- Must NOT add multi-stage Docker build — current Dockerfile is adequate; image size optimization is out of scope
- Must NOT modify the GitHub Actions CI workflow — it already works; this plan extends Tekton CD only
- Must NOT add PostgreSQL PVC for data persistence in the base — the capstone uses ephemeral PostgreSQL; a PVC is an overlay-level concern

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- **Prerequisites**: `kustomize` must be installed (`kustomize version` to verify — install via `curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash`). `kubectl` must be installed for dry-run validation. PostgreSQL must be running (`make db`) before Wave 5/6 test verification.
- Test decision: tests-after + existing nose framework (nosetests --with-spec --spec-color --with-coverage --cover-package=service)
- Kubernetes validation: `kustomize build` output piped to `kubectl apply --dry-run=client -f -` for manifest validation
- Tekton validation: `kubectl apply --dry-run=client -f tekton/` for resource validation
- Evidence: .omo/evidence/task-<N>-next-devops-completion.<ext>

## Execution strategy
### Parallel execution waves
> Target 5-8 todos per wave. Fewer than 3 (except the final) means you under-split.

- **Wave 1 (5 todos): Tekton CD Pipeline Completion** — all Tekton changes; can be done in parallel with Wave 5 (tests) and Wave 6 (code stubs) since they touch different files
- **Wave 2 (4 todos): Kustomize Deployment Restructuring** — depends on nothing; can parallel with Wave 1, 5, 6
- **Wave 3 (2 todos): Service Exposure** — depends on Wave 2 (Ingress goes into the Kustomize base); make deploy target depends on Wave 2
- **Wave 4 (4 todos): Kubernetes Secret & Security** — depends on Wave 2 (secretGenerator goes in overlays); config.py change can parallel with Wave 5
- **Wave 5 (6 todos): Test Coverage Expansion** — most tests depend on nothing; only todo 21 (update test_create_account for Location URL) depends on todo 22 (Location header fix in Wave 6)
- **Wave 6 (3 todos): Code Stubs & Git Cleanup** — Location header fix (todo 22) must complete before Wave 5 todo 21 updates the test_create_account test; Query.get migration (todo 23) is independent; final commit (todo 24) depends on all prior todos

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1.1 nosetests Task | none | 1.4 | 1.2, 1.3, 1.5, 2.x, 5.x, 6.x |
| 1.2 buildah stage | none | 1.4 | 1.1, 1.3, 1.5, 2.x, 5.x, 6.x |
| 1.3 deploy stage | none | 1.4 | 1.1, 1.2, 1.5, 2.x, 5.x, 6.x |
| 1.4 PipelineRun + RBAC | 1.1, 1.2, 1.3 | none | 1.5, 2.x, 5.x, 6.x |
| 1.5 Clean up tasks.yaml | none | none | all others |
| 2.1 Kustomize base | none | 2.2, 2.3, 2.4, 3.1, 3.2, 4.1 | 1.x, 5.x, 6.x |
| 2.2 K3d overlay | 2.1 | 3.2, 4.1 | 2.3, 2.4 |
| 2.3 OpenShift overlay | 2.1 | none | 2.2, 2.4 |
| 2.4 PostgreSQL image fix | 2.1 | none | 2.2, 2.3 |
| 3.1 Ingress resource | 2.1 | 3.2 | 2.2, 2.3, 2.4 |
| 3.2 make deploy target | 2.2, 3.1 | none | none |
| 4.1 SECRET_KEY Secret | 2.2 | none | 4.2, 4.3, 4.4 |
| 4.2 Warn on missing SECRET_KEY | none | 4.1 (ordering) | 4.3, 4.4, 5.x, 6.x |
| 4.3 .dockerignore | none | none | all others |
| 4.4 .gitignore entries | none | none | all others |
| 5.1 Route error handler tests | none | none | all others in Wave 5 |
| 5.2 Model edge case tests | none | none | 5.1, 5.3, 5.4, 5.5, 5.6 |
| 5.3 PUT error path tests | none | none | all others in Wave 5 |
| 5.4 Malformed JSON and empty body tests | none | none | all others in Wave 5 |
| 5.5 DELETE follow-up GET test | none | none | all others in Wave 5 |
| 5.6 Update test_create_account for Location | 6.1 (Location fix) | none | 5.1, 5.2, 5.3, 5.4, 5.5 |
| 6.1 Fix Location header | none | 5.6 | 6.2, 6.3 |
| 6.2 Migrate Query.get() | none | none | 6.1, 6.3 |
| 6.3 Commit dirty tree + delete stale branches | all code todos | none | none (final) |

## Todos
> Implementation + Test = ONE todo. Never separate.
<!-- APPEND TASK BATCHES BELOW THIS LINE WITH edit/apply_patch - never rewrite the headers above. -->

### Wave 1 — Tekton CD Pipeline Completion

- [x] 1. Create `tekton/nosetests.yaml` Task and add `test` stage to pipeline
  What to do: Create a new Tekton Task named `nosetests` that runs the project's nose test suite. The task must: (a) use `python:3.9-slim` as the step image, (b) install dependencies from `requirements.txt` via `pip install --no-cache-dir -r requirements.txt` (no system deps needed — `psycopg2-binary` is a pre-built wheel), (c) set `DATABASE_URI` env from a param, (d) add a wait loop at the start of the test step: `until python -c "import socket; socket.create_connection(('localhost', 5432), timeout=1)" 2>/dev/null; do echo "Waiting for PostgreSQL..."; sleep 1; done` (e) run `nosetests -v --with-spec --spec-color --with-coverage --cover-package=service`. Add a `test` task to `tekton/pipeline.yaml` that runs after `clone` in parallel with `lint`, referencing the `nosetests` Task with workspace `source` bound to `pipeline-workspace`. The test task needs a PostgreSQL sidecar — add a `sidecars` section at the Task spec level (sibling of `steps`, not nested inside a step) that runs `postgres:alpine` with `POSTGRES_PASSWORD=postgres` and `POSTGRES_DB=testdb`, and set the `database-url` param to `postgresql://postgres:postgres@localhost:5432/testdb`. Must NOT use pytest. Must NOT modify the existing lint task. Must NOT install `gcc` or `libpq-dev` — `psycopg2-binary` is a self-contained wheel.
  Parallelization: Wave 1 | Blocked by: none | Blocks: 1.4 (PipelineRun)
  References: `tekton/pipeline.yaml:18-56` (existing pipeline tasks), `tekton/flake8.yaml:1-47` (pattern for custom Task with workspace+params), `Makefile:52-55` (nosetests command), `requirements.txt:1-33` (deps), `setup.cfg:1-12` (nose config), `.github/workflows/ci-build.yaml:15-46` (GitHub Actions pattern for postgres service sidecar)
  Acceptance criteria (agent-executable): `kubectl apply --dry-run=client -f tekton/nosetests.yaml` succeeds with no validation errors. The Task spec has `workspaces: [source]`, `params: [image, database-url, requirements]`, and a `sidecars` section running `postgres:alpine`. The pipeline.yaml has a `test` task with `runAfter: [clone]`.
  QA scenarios: happy — `kubectl apply --dry-run=client -f tekton/nosetests.yaml` exits 0; failure — remove the sidecars section and verify the task spec still validates but would fail at runtime (no DB). Evidence .omo/evidence/task-1-next-devops-completion.txt
  Commit: Y | feat(tekton): add nosetests Task and test stage to pipeline

- [x] 2. Add `build-image` stage to pipeline using buildah ClusterTask
  What to do: Add a `build-image` task to `tekton/pipeline.yaml` that uses the `buildah` ClusterTask (installed via `make clustertasks`). Parameters: `IMAGE` set to `localhost:32000/accounts:$(params.image-tag)` (K3d local registry), `DOCKERFILE` set to `./Dockerfile`, `CONTEXT` set to `.`, `TLSVERIFY` set to `"false"` (K3d local registry has self-signed certs). Bind workspace `source` to `pipeline-workspace`. Add `runAfter: [lint, test]` so build only happens if both lint and test pass. Add a new pipeline param `image-tag` with default `"1.0"`. Must NOT use `us.icr.io` in the pipeline — that's overlay-specific. Must NOT add `SKIP_PUSH` — we want push to happen.
  Parallelization: Wave 1 | Blocked by: none | Blocks: 1.4 (PipelineRun)
  References: `tekton/pipeline.yaml:7-17` (pipeline params section), `Makefile:21-25` (clustertasks installs buildah), `Makefile:27-36` (build+push pattern: `docker build --tag accounts:1.0` then tag+push to `localhost:32000`), `Dockerfile:1-17` (the Dockerfile being built)
  Acceptance criteria (agent-executable): `kubectl apply --dry-run=client -f tekton/pipeline.yaml` succeeds. The pipeline has a `build-image` task with `taskRef: {name: buildah, kind: ClusterTask}`, `runAfter: [lint, test]`, and `IMAGE` param set to `localhost:32000/accounts:$(params.image-tag)`. Pipeline has `image-tag` param with default `"1.0"`.
  QA scenarios: happy — dry-run apply validates; failure — change `kind: ClusterTask` to `kind: Task` and verify it still validates (buildah is installed as ClusterTask per Makefile:25). Evidence .omo/evidence/task-2-next-devops-completion.txt
  Commit: Y | feat(tekton): add buildah build-image stage to CD pipeline

- [x] 3. Add `deploy` stage to pipeline using openshift-client ClusterTask
  What to do: Add a `deploy` task to `tekton/pipeline.yaml` that uses the `openshift-client` ClusterTask. Use the `SCRIPT` param (NOT `ARGS` — v0.2 breaking change) with value: `set -e\nkubectl apply -k deploy/overlays/k3d\nkubectl set image deployment/accounts app=localhost:32000/accounts:$(params.image-tag) --record\nkubectl rollout status deployment/accounts --timeout=300s\nkubectl get pods -l app=accounts`. Bind workspace `manifest-dir` to `pipeline-workspace`. Add `runAfter: [build-image]`. Must NOT hardcode `us.icr.io` in the SCRIPT — use the same `localhost:32000` registry as build-image. Must NOT use `ARGS` param — openshift-client 0.2 uses `SCRIPT`. Must NOT use `kubectl apply -f deploy/` — after Wave 2, deploy/ has Kustomize subdirectories, not flat YAML; use `kubectl apply -k deploy/overlays/k3d` (kubectl has built-in kustomize support since K8s 1.14).
  Parallelization: Wave 1 | Blocked by: none | Blocks: 1.4 (PipelineRun)
  References: `tekton/pipeline.yaml:7-17` (pipeline params), `Makefile:21-24` (clustertasks installs openshift-client), `deploy/deployment.yaml:1-44` (the manifests being applied)
  Acceptance criteria (agent-executable): `kubectl apply --dry-run=client -f tekton/pipeline.yaml` succeeds. The pipeline has a `deploy` task with `taskRef: {name: openshift-client, kind: ClusterTask}`, `runAfter: [build-image]`, and `SCRIPT` param containing `kubectl apply -k deploy/overlays/k3d`.
  QA scenarios: happy — dry-run validates; failure — replace `SCRIPT` with `ARGS` and verify the task spec validates but would fail at runtime (ARGS not supported in v0.2). Evidence .omo/evidence/task-3-next-devops-completion.txt
  Commit: Y | feat(tekton): add deploy stage using openshift-client ClusterTask

- [x] 4. Create `tekton/pipelinerun.yaml` and `tekton/rbac.yaml`
  What to do: Create two new files: (1) `tekton/pipelinerun.yaml` — a PipelineRun that references `cd-pipeline`, sets `serviceAccountName: pipeline`, binds `pipeline-workspace` to the existing `pipelinerun-pvc` PVC (`tekton/pvc.yaml`), and sets params: `repo-url` to `https://github.com/Moduloscript/devops-capstone-project`, `branch` to `main`, `image-tag` to `"1.0"`. Use `generateName: accounts-cd-pr-` so Tekton appends a random suffix. (2) `tekton/rbac.yaml` — a ServiceAccount named `pipeline`, a Role granting `get,create,update,patch,list,delete` on `pods,pods/log,services,deployments,configmaps,secrets`, and a RoleBinding binding the Role to the ServiceAccount. Also add a `ClusterRole` granting `get,list` on `clustertasks` (needed to reference buildah/openshift-client) and a `ClusterRoleBinding`. Must NOT use `volumeClaimTemplate` — use the existing pre-created PVC from `tekton/pvc.yaml`.
  Parallelization: Wave 1 | Blocked by: 1.1, 1.2, 1.3 | Blocks: none
  References: `tekton/pipeline.yaml:1-56` (pipeline being run), `tekton/pvc.yaml:1-11` (PVC to bind), `Makefile:11` (K3d cluster already created with port mapping)
  Acceptance criteria (agent-executable): `kubectl apply --dry-run=client -f tekton/pipelinerun.yaml` succeeds. `kubectl apply --dry-run=client -f tekton/rbac.yaml` succeeds. The PipelineRun has `pipelineRef: {name: cd-pipeline}`, `serviceAccountName: pipeline`, and `workspaces` binding `pipeline-workspace` to `persistentVolumeClaim: {claimName: pipelinerun-pvc}`. The RBAC has ServiceAccount `pipeline`, Role with rules for pods/services/deployments, and RoleBinding.
  QA scenarios: happy — both dry-runs validate; failure — remove the RoleBinding and verify the ServiceAccount exists but has no permissions. Evidence .omo/evidence/task-4-next-devops-completion.txt
  Commit: Y | feat(tekton): add PipelineRun manifest and RBAC for pipeline service account

- [x] 5. Clean up `tekton/tasks.yaml` and fix pipeline header comment
  What to do: (a) Remove the dead `echo` Task from `tekton/tasks.yaml` (lines 1-16) — it is never referenced by the pipeline. Keep only the `cleanup` Task. (b) Update the header comment in `tekton/pipeline.yaml` (lines 1-5) to accurately list required tasks: `git-clone` (from Tekton catalog — install with `kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.8/git-clone.yaml`), `flake8` (vendored in `tekton/flake8.yaml`), `nosetests` (vendored in `tekton/nosetests.yaml`), `buildah` (ClusterTask — install via `make clustertasks`), `openshift-client` (ClusterTask — install via `make clustertasks`). (c) Add a `make git-clone` target to the Makefile that downloads and applies the git-clone Task from the Tekton catalog. Must NOT delete the `cleanup` Task — it is used by the pipeline's `init` stage.
  Parallelization: Wave 1 | Blocked by: none | Blocks: none
  References: `tekton/tasks.yaml:1-16` (echo Task to remove), `tekton/tasks.yaml:17-51` (cleanup Task to keep), `tekton/pipeline.yaml:1-5` (header comment to fix), `Makefile:21-25` (clustertasks pattern for new git-clone target)
  Acceptance criteria (agent-executable): `grep "name: echo" tekton/tasks.yaml` returns nothing (no echo Task). `grep "git-clone" tekton/pipeline.yaml` shows the updated comment. `grep "git-clone" Makefile` shows the new target. `kubectl apply --dry-run=client -f tekton/tasks.yaml` succeeds with only the cleanup Task.
  QA scenarios: happy — tasks.yaml has only cleanup Task; failure — verify that `kubectl apply --dry-run=client -f tekton/tasks.yaml` still works after echo removal. Evidence .omo/evidence/task-5-next-devops-completion.txt
  Commit: Y | chore(tekton): remove dead echo task, fix pipeline header, add git-clone Makefile target

### Wave 2 — Kustomize Deployment Restructuring

- [x] 6. Create `deploy/base/` with kustomization.yaml and moved manifests
  What to do: Create `deploy/base/` directory. Move `deploy/deployment.yaml`, `deploy/service.yaml`, `deploy/postgresql.yaml` into `deploy/base/` (copy then delete originals). Create `deploy/base/kustomization.yaml` with `apiVersion: kustomize.config.k8s.io/v1beta1`, `kind: Kustomization`, `resources:` listing all three YAML files. In `deploy/base/deployment.yaml`, change the image from `us.icr.io/accounts-namespace/accounts:2` to a placeholder `accounts:PLACEHOLDER` — Kustomize `images:` field in overlays will replace this. Also change `deploy/base/postgresql.yaml` image from `us.icr.io/accounts-namespace/postgres:alpine` to `postgres:alpine` (Docker Hub default — works everywhere). Must NOT add environment-specific values to the base. Must NOT add namespace or namePrefix to the base.
  Parallelization: Wave 2 | Blocked by: none | Blocks: 7, 8, 9, 10, 11
  References: `deploy/deployment.yaml:1-44` (to move), `deploy/service.yaml:1-15` (to move), `deploy/postgresql.yaml:1-61` (to move), `Makefile:11` (K3d cluster with registry at localhost:32000)
  Acceptance criteria (agent-executable): `kustomize build deploy/base/` succeeds and outputs valid YAML. The output deployment has image `accounts:PLACEHOLDER`. The output postgresql has image `postgres:alpine`. `test -f deploy/base/kustomization.yaml` succeeds. `test ! -f deploy/deployment.yaml` succeeds (original deleted).
  QA scenarios: happy — `kustomize build deploy/base/ | kubectl apply --dry-run=client -f -` succeeds; failure — remove kustomization.yaml and verify `kustomize build` fails. Evidence .omo/evidence/task-6-next-devops-completion.txt
  Commit: Y | refactor(deploy): restructure into Kustomize base with placeholder image

- [x] 7. Create `deploy/overlays/k3d/` overlay
  What to do: Create `deploy/overlays/k3d/` directory with: (a) `kustomization.yaml` — `resources: [../../base]`, `images:` swapping `accounts` to `newName: localhost:32000/accounts, newTag: "1.0"`, `namespace: default`. (b) `secret.env` — a gitignored file with `SECRET_KEY=k3d-dev-secret-key-change-me` (will be used by Wave 4 secretGenerator). (c) `secret.env.example` — a committed template file with `SECRET_KEY=change-me` that users copy to `secret.env` (so `kustomize build` doesn't fail on fresh clones). (d) Add `secretGenerator` to kustomization.yaml: `name: app-secrets, envs: [secret.env]` with `generatorOptions: {disableNameSuffixHash: true}` so the Secret name is stable. Must NOT use `us.icr.io` in the K3d overlay. Must NOT add `namePrefix` — keep resource names clean for the existing deployment selectors. Must NOT commit `secret.env` — only `secret.env.example`.
  Parallelization: Wave 2 | Blocked by: 6 | Blocks: 11, 12
  References: `deploy/base/kustomization.yaml` (created in todo 6), `Makefile:27-36` (build+push uses `localhost:32000/accounts:1.0`), `deploy/base/deployment.yaml` (image placeholder set in todo 6)
  Acceptance criteria (agent-executable): `kustomize build deploy/overlays/k3d/` succeeds. The output deployment has image `localhost:32000/accounts:1.0`. The output includes a `Secret` named `app-secrets` with `SECRET_KEY` key. `grep "us.icr.io" deploy/overlays/k3d/kustomization.yaml` returns nothing.
  QA scenarios: happy — kustomize build produces correct image and Secret; failure — remove secret.env and verify secretGenerator fails. Evidence .omo/evidence/task-7-next-devops-completion.txt
  Commit: Y | feat(deploy): add K3d overlay with localhost registry and app-secrets

- [x] 8. Create `deploy/overlays/openshift/` overlay
  What to do: Create `deploy/overlays/openshift/` directory with: (a) `kustomization.yaml` — `resources: [../../base]`, `images:` swapping `accounts` to `newName: us.icr.io/accounts-namespace/accounts, newTag: "2"`, `namespace: accounts-prod`, `replicas: [{name: accounts, count: 3}]`. (b) `route.yaml` — an OpenShift Route resource (`apiVersion: route.openshift.io/v1, kind: Route`) that routes to the `accounts` service on port 8080. (c) Add `route.yaml` to the `resources:` list in kustomization.yaml. Must NOT add this overlay to any K3d workflow. Must NOT add imagePullSecrets — that's a future concern documented as a comment.
  Parallelization: Wave 2 | Blocked by: 6 | Blocks: none
  References: `deploy/base/kustomization.yaml` (created in todo 6), `deploy/base/deployment.yaml` (image placeholder set in todo 6, originally `us.icr.io/accounts-namespace/accounts:2`)
  Acceptance criteria (agent-executable): `kustomize build deploy/overlays/openshift/` succeeds. The output deployment has image `us.icr.io/accounts-namespace/accounts:2` and 3 replicas. The output includes a `Route` resource. `grep "route.openshift.io" deploy/overlays/openshift/route.yaml` succeeds.
  QA scenarios: happy — kustomize build produces OpenShift manifests with Route; failure — apply on K3d and verify Route CRD is not found (expected — Route is OpenShift-only). Evidence .omo/evidence/task-8-next-devops-completion.txt
  Commit: Y | feat(deploy): add OpenShift overlay with us.icr.io registry and Route

- [x] 9. Fix PostgreSQL image in base to use Docker Hub
  What to do: This is already done as part of todo 6, but verify: `deploy/base/postgresql.yaml` must use `postgres:alpine` (Docker Hub) not `us.icr.io/accounts-namespace/postgres:alpine`. The K3d overlay does NOT override the postgres image (it stays as `postgres:alpine`). The OpenShift overlay in todo 8 may optionally override it to `us.icr.io/accounts-namespace/postgres:alpine` if needed — add this to the openshift kustomization.yaml `images:` section. Must NOT add a PVC for PostgreSQL data — the capstone uses ephemeral PostgreSQL.
  Parallelization: Wave 2 | Blocked by: 6 | Blocks: none
  References: `deploy/base/postgresql.yaml` (image line, set in todo 6), original file at `deploy/postgresql.yaml:19` had `us.icr.io/accounts-namespace/postgres:alpine`
  Acceptance criteria (agent-executable): `grep "postgres:alpine" deploy/base/postgresql.yaml` succeeds. `grep "us.icr.io" deploy/base/postgresql.yaml` returns nothing. `kustomize build deploy/overlays/k3d/ | grep "postgres:alpine"` succeeds.
  QA scenarios: happy — base uses Docker Hub postgres; failure — revert to us.icr.io and verify K3d can't pull it. Evidence .omo/evidence/task-9-next-devops-completion.txt
  Commit: N | (included in todo 6 commit)

### Wave 3 — Service Exposure

- [x] 10. Create `deploy/base/ingress.yaml` for Traefik
  What to do: Create `deploy/base/ingress.yaml` with an Ingress resource: `apiVersion: networking.k8s.io/v1`, `kind: Ingress`, `metadata: {name: accounts}`, `spec: {ingressClassName: traefik, rules: [{http: {paths: [{path: /, pathType: Prefix, backend: {service: {name: accounts, port: {number: 8080}}}}]}}]}`. Use `spec.ingressClassName: traefik` (the modern field, not the deprecated `kubernetes.io/ingress.class` annotation). Do NOT specify a host — use path-based routing so it works with any host on K3d. Add `ingress.yaml` to the `resources:` list in `deploy/base/kustomization.yaml`. Must NOT use `route.openshift.io` — that's OpenShift-only and goes in the openshift overlay (todo 8). Must NOT use `extensions/v1beta1` — use `networking.k8s.io/v1` (current API). Must NOT use the deprecated `kubernetes.io/ingress.class` annotation — use `spec.ingressClassName` instead.
  Parallelization: Wave 3 | Blocked by: 6 | Blocks: 11
  References: `deploy/base/service.yaml:1-15` (Service to route to — port 8080), `Makefile:11` (K3d maps host 8080 → Traefik :80 via `--port '8080:80@loadbalancer'`)
  Acceptance criteria (agent-executable): `kustomize build deploy/base/ | kubectl apply --dry-run=client -f -` succeeds and includes an Ingress resource. `grep "networking.k8s.io/v1" deploy/base/ingress.yaml` succeeds. `grep "ingressClassName" deploy/base/ingress.yaml` succeeds. `grep "traefik" deploy/base/ingress.yaml` succeeds.
  QA scenarios: happy — Ingress validates and routes to accounts:8080; failure — change API version to `extensions/v1beta1` and verify kubectl rejects it. Evidence .omo/evidence/task-10-next-devops-completion.txt
  Commit: Y | feat(deploy): add Traefik Ingress for external service access

- [x] 11. Add `make deploy` target to Makefile
  What to do: Add two new targets to the Makefile: (1) `deploy` — runs `kustomize build deploy/overlays/k3d | kubectl apply -f -` and then prints `kubectl get pods -l app=accounts` and the Ingress URL. (2) `deploy-oc` — runs `kustomize build deploy/overlays/openshift | oc apply -f -` (for OpenShift). Add both to the `.PHONY` list. Add `## Deploy to K3d cluster` and `## Deploy to OpenShift cluster` comments for the help target. Must NOT use `kubectl apply -f deploy/` (flat files are gone — Kustomize is the only path now). Must NOT delete the existing `make cluster` or `make tekton` targets.
  Parallelization: Wave 3 | Blocked by: 7, 10 | Blocks: none
  References: `Makefile:1-72` (existing targets), `deploy/overlays/k3d/kustomization.yaml` (created in todo 7), `deploy/base/ingress.yaml` (created in todo 10)
  Acceptance criteria (agent-executable): `grep "deploy:" Makefile` finds the new target. `grep "kustomize build" Makefile` finds the kustomize command. `make help` output includes "Deploy to K3d cluster".
  QA scenarios: happy — `make help` shows deploy target; failure — run `make deploy` without a running cluster and verify it fails with a connection error (expected — no cluster running). Evidence .omo/evidence/task-11-next-devops-completion.txt
  Commit: Y | feat(makefile): add deploy and deploy-oc targets using Kustomize

### Wave 4 — Kubernetes Secret & Security

- [x] 12. Add `SECRET_KEY` env var to deployment via Secret reference
  What to do: In `deploy/base/deployment.yaml`, add a new env var to the `accounts` container (after the existing `DATABASE_URI` env var): `name: SECRET_KEY`, `valueFrom: {secretKeyRef: {name: app-secrets, key: SECRET_KEY}}`. The `app-secrets` Secret is created by the Kustomize `secretGenerator` in each overlay (todo 7 for K3d). Must NOT hardcode the SECRET_KEY value in the deployment YAML. Must NOT add `imagePullSecrets` — that's a future concern for the OpenShift overlay.
  Parallelization: Wave 4 | Blocked by: 7 | Blocks: none
  References: `deploy/base/deployment.yaml:23-25` (existing DATABASE_URI env to add after), `deploy/overlays/k3d/kustomization.yaml` (secretGenerator creates app-secrets), `service/config.py:23` (SECRET_KEY is read from env)
  Acceptance criteria (agent-executable): `kustomize build deploy/overlays/k3d/ | grep "SECRET_KEY"` finds the env var. `kustomize build deploy/overlays/k3d/ | grep "secretKeyRef"` finds the reference. `kustomize build deploy/overlays/k3d/ | grep "app-secrets"` finds the secret name.
  QA scenarios: happy — deployment has SECRET_KEY from Secret; failure — remove the secretGenerator from overlay and verify the deployment references a non-existent Secret. Evidence .omo/evidence/task-12-next-devops-completion.txt
  Commit: Y | feat(deploy): inject SECRET_KEY from Kubernetes Secret

- [x] 13. Update `service/config.py` to warn on missing SECRET_KEY
  What to do: Change `service/config.py:23` from `SECRET_KEY = os.getenv("SECRET_KEY", "s3cr3t-key-shhhh")` to the following multi-line code (do NOT use inline semicolons — flake8 E702 would fail):
```python
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    import warnings
    warnings.warn("SECRET_KEY not set — using insecure default for development only")
    SECRET_KEY = "s3cr3t-key-shhhh"
```
This keeps backward compatibility for tests (which don't set SECRET_KEY env) but logs a warning. Must NOT remove the default entirely — tests import `service.config` and would crash. Must NOT use `logging.warn` — use `warnings.warn` so it doesn't require a logger to be configured yet. Must NOT write the if-block on one line with semicolons — flake8 E702 would fail.
  Parallelization: Wave 4 | Blocked by: none | Blocks: none
  References: `service/config.py:23` (line to change), `tests/test_routes.py:17-19` (tests don't set SECRET_KEY env), `tests/test_models.py:12-14` (same)
  Acceptance criteria (agent-executable): `python -c "from service.config import SECRET_KEY; print(SECRET_KEY)"` succeeds and prints the default with a warning. `SECRET_KEY=test-key python -c "from service.config import SECRET_KEY; print(SECRET_KEY)"` prints `test-key` with no warning. `flake8 service/config.py --max-complexity=10 --max-line-length=127` passes.
  QA scenarios: happy — env var set → no warning; failure — env var not set → warning printed but app still works. Evidence .omo/evidence/task-13-next-devops-completion.txt
  Commit: Y | feat(config): warn on missing SECRET_KEY instead of silent insecure default

- [x] 14. Create `.dockerignore`
  What to do: Create a `.dockerignore` file in the project root with entries: `.git/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`, `tests/`, `venv/`, `.venv/`, `ENV/`, `env/`, `.omo/`, `.opencode/`, `plans/`, `deploy/`, `tekton/`, `bin/`, `.github/`, `*.md` (except none — Dockerfile only copies `service/` so these are excluded anyway, but .dockerignore prevents context bloat). Must NOT exclude `requirements.txt` — the Dockerfile copies it. Must NOT exclude `service/` — that's what gets built.
  Parallelization: Wave 4 | Blocked by: none | Blocks: none
  References: `Dockerfile:5-9` (COPY requirements.txt then COPY service/), `.gitignore:1-112` (existing gitignore patterns to mirror)
  Acceptance criteria (agent-executable): `test -f .dockerignore` succeeds. `grep "tests/" .dockerignore` succeeds. `grep "requirements.txt" .dockerignore` returns nothing (not excluded). `docker build --no-cache .` still succeeds (Dockerfile can still copy requirements.txt and service/).
  QA scenarios: happy — docker build succeeds with smaller context; failure — add `requirements.txt` to .dockerignore and verify build fails. Evidence .omo/evidence/task-14-next-devops-completion.txt
  Commit: Y | chore: add .dockerignore to reduce build context

- [x] 15. Add `.gitignore` entries for secret files
  What to do: Add the following lines to the end of `.gitignore`: `# Kustomize secret env files`, `deploy/overlays/*/secret.env`, `# Sealed secrets (decrypted)`, `deploy/overlays/openshift/*.decrypted.yaml`. Must NOT ignore the entire `deploy/` directory. Must NOT ignore `deploy/overlays/` — only the secret.env files inside them.
  Parallelization: Wave 4 | Blocked by: none | Blocks: none
  References: `.gitignore:100-101` (existing `.env` pattern), `deploy/overlays/k3d/secret.env` (file to ignore, created in todo 7)
  Acceptance criteria (agent-executable): `git check-ignore deploy/overlays/k3d/secret.env` returns the file path (is ignored). `git check-ignore deploy/overlays/k3d/kustomization.yaml` returns nothing (not ignored). `grep "secret.env" .gitignore` succeeds.
  QA scenarios: happy — secret.env is ignored, kustomization.yaml is not; failure — remove the gitignore entry and verify secret.env would be tracked. Evidence .omo/evidence/task-15-next-devops-completion.txt
  Commit: Y | chore: gitignore Kustomize secret env files

### Wave 5 — Test Coverage Expansion

- [x] 16. Add 405 and 500 error handler tests to `tests/test_routes.py`
  What to do: Add two test methods to the `TestAccountService` class in `tests/test_routes.py`: (1) `test_method_not_allowed` — send a PATCH request to `/accounts/0` and assert response status_code == 405 and response JSON contains `error: "Method not Allowed"`. (2) `test_internal_server_error` — use `unittest.mock.patch` to make `Account.all()` raise an exception, then call `GET /accounts` and assert status_code == 500 and JSON contains `error: "Internal Server Error"`. Use `from unittest.mock import patch` for the mock. Must NOT use pytest assertions — use `self.assertEqual`. Must NOT modify existing tests.
  Parallelization: Wave 5 | Blocked by: none | Blocks: none
  References: `tests/test_routes.py:28-217` (TestAccountService class to add to), `service/common/error_handlers.py:43-55` (405 handler), `service/common/error_handlers.py:73-85` (500 handler), `service/routes.py:65-74` (list_accounts to mock)
  Acceptance criteria (agent-executable): `nosetests tests/test_routes.py:TestAccountService.test_method_not_allowed -v` passes. `nosetests tests/test_routes.py:TestAccountService.test_internal_server_error -v` passes. `nosetests --with-coverage --cover-package=service` total count increases by 2.
  QA scenarios: happy — both new tests pass; failure — remove the 405 error handler and verify test_method_not_allowed fails. Evidence .omo/evidence/task-16-next-devops-completion.txt
  Commit: Y | test(routes): add 405 Method Not Allowed and 500 Internal Server Error tests

- [x] 17. Add model edge case tests to `tests/test_models.py`
  What to do: Add the following test methods to `TestAccount` class in `tests/test_models.py`: (1) `test_account_repr` — create an Account, set id and name, assert `repr(account) == f"<Account {account.name} id=[{account.id}]>"`. (2) `test_find_by_name_no_match` — call `Account.find_by_name("nonexistent").all()` and assert `len(result) == 0` (must call `.all()` first — `find_by_name` returns a SQLAlchemy Query object which does NOT support `len()` directly). (3) `test_find_by_name_multiple_matches` — create 2 accounts with the same name, call `find_by_name(name).all()`, assert `len(result) == 2`. (4) `test_deserialize_with_date_joined` — deserialize a dict with an explicit ISO date string `"2025-01-15"` and assert `account.date_joined == date(2025, 1, 15)`. (5) `test_deserialize_without_date_joined` — deserialize a dict without `date_joined` key and assert `account.date_joined == date.today()`. (6) `test_deserialize_with_phone_none` — deserialize a dict with `phone_number: None` and assert `account.phone_number is None`. Must NOT use pytest. Must NOT create a separate test class. Must NOT call `len()` directly on a Query object — always call `.all()` first to convert to a list.
  Parallelization: Wave 5 | Blocked by: none | Blocks: none
  References: `tests/test_models.py:20-177` (TestAccount class), `service/models.py:97-98` (__repr__), `service/models.py:111-135` (deserialize), `service/models.py:137-145` (find_by_name), `tests/factories.py:1-23` (AccountFactory)
  Acceptance criteria (agent-executable): `nosetests tests/test_models.py -v` passes with 17 tests (11 existing + 6 new). `nosetests --with-coverage --cover-package=service` coverage for `models.py` increases.
  QA scenarios: happy — all 6 new tests pass; failure — break `find_by_name` to always return `[]` and verify `test_find_by_name_multiple_matches` fails. Evidence .omo/evidence/task-17-next-devops-completion.txt
  Commit: Y | test(models): add repr, find_by_name edge cases, deserialize date/phone branch tests

- [x] 18. Add PUT error path tests to `tests/test_routes.py`
  What to do: Add two test methods to `TestAccountService`: (1) `test_update_account_bad_content_type` — create an account, then PUT with `content_type="text/html"` and assert status_code == 415. (2) `test_update_account_bad_data` — create an account, then PUT with `json={"name": "missing fields"}` (missing email and address) and assert status_code == 400. Must NOT test 404 on PUT — that's already covered by `test_update_account_not_found`.
  Parallelization: Wave 5 | Blocked by: none | Blocks: none
  References: `tests/test_routes.py:163-184` (existing PUT tests), `service/routes.py:99-112` (update_account), `service/routes.py:139-148` (check_content_type), `service/models.py:111-134` (deserialize raises DataValidationError on missing keys)
  Acceptance criteria (agent-executable): `nosetests tests/test_routes.py:TestAccountService.test_update_account_bad_content_type -v` passes. `nosetests tests/test_routes.py:TestAccountService.test_update_account_bad_data -v` passes.
  QA scenarios: happy — both tests pass; failure — remove check_content_type call from PUT route and verify 415 test fails. Evidence .omo/evidence/task-18-next-devops-completion.txt
  Commit: Y | test(routes): add PUT 415 and 400 error path tests

- [x] 19. Add malformed JSON and empty body tests to `tests/test_routes.py`
  What to do: Add two test methods to `TestAccountService`: (1) `test_create_account_malformed_json` — POST to `/accounts` with `data="{not valid json"` and `content_type="application/json"` and assert status_code == 400 (Flask's request.get_json() will raise, which triggers the 400 handler). (2) `test_create_account_empty_body` — POST to `/accounts` with `data=""` and `content_type="application/json"` and assert status_code == 400. Must NOT test with `json=None` — that sends `{}` which is valid JSON.
  Parallelization: Wave 5 | Blocked by: none | Blocks: none
  References: `tests/test_routes.py:95-131` (existing POST tests), `service/routes.py:41-58` (create_accounts), `service/models.py:111-134` (deserialize handles TypeError)
  Acceptance criteria (agent-executable): `nosetests tests/test_routes.py:TestAccountService.test_create_account_malformed_json -v` passes. `nosetests tests/test_routes.py:TestAccountService.test_create_account_empty_body -v` passes.
  QA scenarios: happy — both return 400; failure — send valid JSON with all fields and verify it returns 201 (not 400). Evidence .omo/evidence/task-19-next-devops-completion.txt
  Commit: Y | test(routes): add malformed JSON and empty body POST tests

- [x] 20. Add follow-up GET after DELETE test to `tests/test_routes.py`
  What to do: Add one test method `test_delete_then_read_returns_404` to `TestAccountService`: create an account via `_create_accounts(1)`, DELETE it (assert 204), then GET the same ID and assert 404. This verifies the delete actually persisted. Must NOT use `Account.query` directly — use the HTTP client.
  Parallelization: Wave 5 | Blocked by: none | Blocks: none
  References: `tests/test_routes.py:186-195` (existing delete tests), `service/routes.py:119-131` (delete_account), `service/routes.py:81-92` (read_account)
  Acceptance criteria (agent-executable): `nosetests tests/test_routes.py:TestAccountService.test_delete_then_read_returns_404 -v` passes.
  QA scenarios: happy — 204 then 404; failure — mock delete to not actually delete and verify the follow-up GET returns 200 (test fails as expected). Evidence .omo/evidence/task-20-next-devops-completion.txt
  Commit: Y | test(routes): add follow-up GET after DELETE to verify persistence

- [x] 21. Update `test_create_account` to assert real Location URL after stub fix
  What to do: AFTER todo 22 (Wave 6, fix Location header) is complete, update `test_create_account` in `tests/test_routes.py:95-116` to assert that the Location header is a valid URL containing `/accounts/` followed by the account ID, instead of just `assertIsNotNone(location)`. Use `self.assertIn(f"/accounts/", location)` and `self.assertIn(str(new_account["id"]), location)`. Must NOT hardcode the full URL — use the returned account ID. Must NOT remove the existing `assertIsNotNone(location)` check.
  Parallelization: Wave 5 | Blocked by: 22 (Location header fix) | Blocks: none
  References: `tests/test_routes.py:95-116` (test to update), `service/routes.py:53-57` (Location header — will be fixed in todo 22)
  Acceptance criteria (agent-executable): `nosetests tests/test_routes.py:TestAccountService.test_create_account -v` passes with the new assertions. The Location header in the test response contains `/accounts/` and the account ID.
  QA scenarios: happy — Location URL is `/accounts/<id>`; failure — revert routes.py to `location_url = "/"` and verify the new assertion fails. Evidence .omo/evidence/task-21-next-devops-completion.txt
  Commit: Y | test(routes): assert real Location URL in create account test

### Wave 6 — Code Stubs & Git Cleanup

- [x] 22. Fix Location header stub in `service/routes.py`
  What to do: In `service/routes.py:53-55`, replace the commented-out `url_for` and hardcoded `"/"` with: `location_url = url_for("read_account", account_id=account.id, _external=True)`. Delete lines 53-54 (the comments). The `url_for` import on line 7 is already present (though marked `# noqa; F401` — remove the F401 suppression since it's now used). Must NOT change the endpoint name — `read_account` is the actual function name at line 82. Must NOT use `get_accounts` — that route name doesn't exist.
  Parallelization: Wave 6 | Blocked by: none | Blocks: 21 (test update)
  References: `service/routes.py:7` (url_for import), `service/routes.py:53-55` (stub to fix), `service/routes.py:81-92` (read_account endpoint — the correct url_for target)
  Acceptance criteria (agent-executable): `flake8 service/routes.py --max-line-length=127` passes. `grep "read_account" service/routes.py` finds both the route definition and the url_for call. `grep "get_accounts" service/routes.py` returns nothing. `nosetests tests/test_routes.py:TestAccountService.test_create_account -v` passes.
  QA scenarios: happy — Location header is a full URL like `http://localhost/accounts/1`; failure — use wrong endpoint name `get_accounts` and verify Flask raises BuildError. Evidence .omo/evidence/task-22-next-devops-completion.txt
  Commit: Y | fix(routes): use url_for for Location header instead of hardcoded stub

- [x] 23. Migrate `Query.get()` to `db.session.get()` in `service/models.py`
  What to do: In `service/models.py:76`, change `return cls.query.get(by_id)` to `return db.session.get(cls, by_id)`. This is the SQLAlchemy 1.4+ compatible API (works in both 1.4.46 and 2.x). The `db` object is already imported at line 13. Must NOT upgrade SQLAlchemy version — 1.4.46 supports `db.session.get()`. Must NOT change `cls.query.all()` on line 70 — that's still valid in 1.4 and 2.x.
  Parallelization: Wave 6 | Blocked by: none | Blocks: none
  References: `service/models.py:72-76` (find method), `service/models.py:13` (db = SQLAlchemy()), `requirements.txt:3` (SQLAlchemy==1.4.46)
  Acceptance criteria (agent-executable): `flake8 service/models.py --max-complexity=10 --max-line-length=127` passes. `nosetests tests/test_models.py -v` all pass. `grep "query.get" service/models.py` returns nothing. `grep "db.session.get" service/models.py` succeeds.
  QA scenarios: happy — all model tests pass with new API; failure — use `db.session.get(cls, "not-an-id")` and verify it returns None gracefully. Evidence .omo/evidence/task-23-next-devops-completion.txt
  Commit: Y | refactor(models): migrate Query.get() to db.session.get() for SQLAlchemy 2.0 compat

- [x] 24. Commit dirty git tree and delete stale branches
  What to do: (a) Stage all changes from this plan's execution: `git add -A`. (b) Commit with message: `feat: complete DevOps capstone — Tekton CD pipeline, Kustomize deployment, Ingress, secrets, test coverage`. (c) Delete stale local branches that were already merged to main: first run `git branch` to list them, then delete with `git branch -d add-cors-headers add-security-headers dev-setup delete-account deploy-kubernetes add-ci-build add-docker` (verify each with `git branch` first — if any branch doesn't exist, skip it; if `git branch -d` refuses because it's not merged, use `git branch -D` only after verifying the commits are in main via `git log --cherry-pick main..<branch>`). Must NOT push to remote without explicit user instruction. Must NOT delete the `main` branch.
  Parallelization: Wave 6 | Blocked by: all code todos (1-23) | Blocks: none
  References: `git status` output (10 deleted lab markers + 8 untracked tooling items + all new files from this plan)
  Acceptance criteria (agent-executable): `git status` shows "working tree clean". `git branch` shows only `main`. `git log --oneline -1` shows the capstone completion commit.
  QA scenarios: happy — clean tree, only main branch; failure — try `git branch -d main` and verify it's refused. Evidence .omo/evidence/task-24-next-devops-completion.txt
  Commit: Y | feat: complete DevOps capstone — Tekton CD, Kustomize, Ingress, secrets, tests

## Final verification wave
> Runs in parallel after ALL todos. ALL must APPROVE. Surface results and wait for the user's explicit okay before declaring complete.
- [x] F1. Plan compliance audit — verify every todo's acceptance criteria was met; `grep` each file for the expected changes
- [x] F2. Code quality review — run `flake8 service --count --max-complexity=10 --max-line-length=127 --statistics` and verify zero errors; run `nosetests -v --with-spec --with-coverage --cover-package=service` and verify all tests pass
- [x] F3. Real manual QA — run `kustomize build deploy/overlays/k3d | kubectl apply --dry-run=client -f -` and verify all manifests validate; run `kubectl apply --dry-run=client -f tekton/` and verify all Tekton resources validate
- [x] F4. Scope fidelity — verify no out-of-scope changes were made (no pytest, no SQLAlchemy upgrade, no Helm, no GitHub Actions changes, no Route in K3d base)

## Commit strategy
- **Wave 1 commits** (5): `feat(tekton): ...` — one per todo, all in the `tekton/` directory
- **Wave 2 commits** (3): `refactor(deploy): ...` and `feat(deploy): ...` — restructure + overlays
- **Wave 3 commits** (2): `feat(deploy): ...` and `feat(makefile): ...` — Ingress + deploy target
- **Wave 4 commits** (4): `feat(deploy): ...`, `feat(config): ...`, `chore: ...` — secret, config, dockerignore, gitignore
- **Wave 5 commits** (6): `test(routes): ...` and `test(models): ...` — one per test todo
- **Wave 6 commits** (3): `fix(routes): ...`, `refactor(models): ...`, `feat: ...` — stub fixes + final commit
- **Total: ~23 commits** across 6 waves
- **Branching**: all work on `main` (no feature branches — the stale branch cleanup in todo 24 is the last step)
- **Squash option**: if the user prefers, all Wave commits can be squashed into one `feat: complete DevOps capstone` commit per wave

## Success criteria
1. `nosetests -v --with-spec --spec-color --with-coverage --cover-package=service` passes with 40+ tests (27 existing + 13+ new) and zero failures
2. `flake8 service --count --max-complexity=10 --max-line-length=127 --statistics` passes with zero errors
3. `kustomize build deploy/overlays/k3d | kubectl apply --dry-run=client -f -` validates all K3d manifests
4. `kustomize build deploy/overlays/openshift | oc apply --dry-run=client -f -` validates all OpenShift manifests (if `oc` is available; otherwise `kubectl apply --dry-run=client` will fail on Route CRD — that's expected)
5. `kubectl apply --dry-run=client -f tekton/pipeline.yaml -f tekton/tasks.yaml -f tekton/flake8.yaml -f tekton/nosetests.yaml -f tekton/pipelinerun.yaml -f tekton/rbac.yaml -f tekton/pvc.yaml` validates all Tekton resources
6. `grep "s3cr3t-key-shhhh" service/config.py` still exists (as a warned fallback) but `grep "SECRET_KEY" deploy/base/deployment.yaml` shows `valueFrom: secretKeyRef`
7. `grep "location_url = \"/\"" service/routes.py` returns nothing (stub is fixed)
8. `grep "query.get" service/models.py` returns nothing (deprecated API migrated)
9. `git status` shows "working tree clean" and `git branch` shows only `main`
10. The Tekton pipeline has 6 stages: init → clone → (lint ∥ test) → build-image → deploy
