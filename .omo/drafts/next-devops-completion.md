---
slug: next-devops-completion
status: approved
intent: unclear
review_required: true
pending-action: none (plan written and reviewed)
approach: 6-wave plan completing Tekton CD pipeline, Kustomize deployment, Ingress, secrets, tests, and code stubs
---

# Draft: next-devops-completion

## Components (topology ledger)
1. Tekton CD Pipeline Completion | test+build+deploy stages added | active | .omo/plans/next-devops-completion.md Wave 1
2. Kustomize Deployment Restructuring | base+overlays for k3d/openshift | active | .omo/plans/next-devops-completion.md Wave 2
3. Service Exposure | Ingress for Traefik | active | .omo/plans/next-devops-completion.md Wave 3
4. Kubernetes Secret & Security | SECRET_KEY as K8s Secret | active | .omo/plans/next-devops-completion.md Wave 4
5. Test Coverage Expansion | 13+ new tests | active | .omo/plans/next-devops-completion.md Wave 5
6. Code Stubs & Git Cleanup | Location header, Query.get, git cleanup | active | .omo/plans/next-devops-completion.md Wave 6

## Open assumptions (announced defaults)
1. K3d as primary dev env | localhost:32000 registry | Makefile already configures it | Reversible
2. Kustomize base+overlays | industry standard | multi-env packaging | Reversible
3. Ingress (not Route) as base | Traefik built-in K3d | OpenShift auto-converts | Reversible
4. Custom nosetests Tekton Task | no catalog task for nose | needed for test stage | Reversible
5. buildah + openshift-client | already installed as ClusterTasks | make clustertasks | Reversible
6. SECRET_KEY via secretGenerator | gitignored .env for K3d | Kustomize native | Reversible
7. Warn on missing SECRET_KEY (not remove) | keeps tests working | backward compat | Reversible
8. Keep nose (not pytest) | project convention | setup.cfg + Makefile | Reversible

## Approval gate
status: approved
User approved with "yes" on 2026-06-30.

## High-accuracy review receipts
- Metis gap analysis: ses_0eae38f22ffe1QnnOkkZV5Ho3K — 7 contradictions, 18 missing constraints, 4 scope-creep, 10 unvalidated assumptions, 6 missing acceptance criteria, 10 operational concerns identified and folded into plan.
- Momus round 1: ses_0ead3df05ffeCrTRUMWR9qRBK9 — APPROVE (OKAY) with 4 advisory notes.
- Oracle round 1: ses_0ead3d431ffeh6098l62CbiAwA — REJECT with 5 critical, 4 medium, 3 minor issues.
- Round 2 fixes applied: all 12 issues fixed.
- Momus round 2: ses_0e958828effeNXem0W35x4BFON — REJECT with 1 blocking issue (todo 3 acceptance criteria stale).
- Oracle round 2: ses_0e9587b8bffece1KxDNjKuRQsM — REJECT with 1 critical issue (same todo 3 acceptance criteria) + 2 minor label mismatches.
- Round 3 fixes applied: todo 3 acceptance criteria updated; matrix labels 4.2, 5.4, 5.5 corrected.
- Momus round 3: ses_0e94ea440ffeAbtHl1u5f9WpV0 — APPROVE (OKAY).
- Oracle round 3: ses_0e94ea0f4ffe3RgG0JldJ2hc6U — APPROVE.
- Final verdict: BOTH APPROVE. Plan is ready for execution.
