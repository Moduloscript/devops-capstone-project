# DevOps Career Transition Plan

## From Coursera Capstone → Hireable DevOps Engineer

**Author:** Zoo (Technical Advisor)
**Date:** June 2026
**Duration:** 12 Weeks
**Goal:** Entry-level DevOps Engineer / Junior Platform Engineer

---

## Table of Contents

1. [Current Assessment](#1-current-assessment)
2. [The 12-Week Plan](#2-the-12-week-plan)
3. [Weekly Schedule](#3-weekly-schedule)
4. [Skills Matrix](#4-skills-matrix)
5. [Job Search Strategy](#5-job-search-strategy)
6. [Resources & Costs](#6-resources--costs)
7. [Appendix: Interview Prep](#7-appendix-interview-prep)

---

## 1. Current Assessment

### What You Already Know (From Capstone)

| Skill                   | Evidence                                                |
| ----------------------- | ------------------------------------------------------- |
| Python/Flask REST API   | Service layer with routes, models, error handling       |
| Test-Driven Development | 27 test cases covering CRUD + security + CORS           |
| Docker                  | Dockerfile, multi-stage concepts, image build/push      |
| Git/GitHub              | Branching, PRs, merge, Kanban board management          |
| GitHub Actions CI       | Workflow with lint + test on push/PR                    |
| Kubernetes Manifests    | Deployments, Services, Probes, PVCs                     |
| Tekton CD Pipeline      | 6-stage pipeline (clone → lint → test → build → deploy) |
| IBM Cloud               | IKS cluster, VPC, subnets, container registry           |

### Skill Gaps to Fill

| Gap                | Priority     | Why It Matters                        |
| ------------------ | ------------ | ------------------------------------- |
| Terraform (IaC)    | **Critical** | Every DevOps job posting requires IaC |
| Helm               | **Critical** | Standard K8s package manager          |
| Prometheus/Grafana | **High**     | Monitoring is half of DevOps work     |
| ArgoCD/GitOps      | **High**     | Dominant CD paradigm in 2026          |
| CKA Certification  | **Medium**   | Most recognized K8s credential        |
| AWS or GCP         | **Medium**   | More widely used than IBM Cloud       |

---

## 2. The 12-Week Plan

```
MONTH 1: Infrastructure-as-Code  (Weeks 1-4)
  ├── Week 1-2: Terraform
  └── Week 3-4: Helm Charts

MONTH 2: Production Readiness  (Weeks 5-8)
  ├── Week 5-6: Prometheus + Grafana
  └── Week 7-8: ArgoCD + GitOps

MONTH 3: Certification + Job Search  (Weeks 9-12)
  ├── Week 9-10: CKA Exam Prep
  └── Week 11-12: 50 Applications
```

---

## 3. Weekly Schedule

### Week 1-2: Terraform

**Objective:** Convert manual `ibmcloud ks cluster create` commands into reusable Terraform code.

#### Day-by-Day Tasks

| Day   | Task                                                                                       | Duration | Success Check                    |
| ----- | ------------------------------------------------------------------------------------------ | -------- | -------------------------------- |
| **1** | Install Terraform. Create `terraform/main.tf` with IBM Cloud provider and VPC resource.    | 1h       | `terraform init` succeeds        |
| **2** | Add subnet and public gateway to `main.tf`.                                                | 1h       | `terraform plan` shows resources |
| **3** | Add VPC-gen2 Kubernetes cluster resource.                                                  | 2h       | Cluster provisions via Terraform |
| **4** | Add ICR namespace resource to `main.tf`. Push Docker images using Terraform null_resource. | 1h       | Registry namespace created       |
| **5** | `terraform destroy` old cluster. `terraform apply` everything from code. Verify pods run.  | 1h       | Cluster is fully reproducible    |

**Deliverable:** Directory structure:

```
terraform/
├── main.tf          # VPC, subnet, gateway, cluster, registry
├── variables.tf     # Region, zone, cluster name
├── outputs.tf       # Cluster ID, kubeconfig command
└── terraform.tfvars # Your values (API key, etc.)
```

**Key commands to learn:**

```bash
terraform init
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
terraform destroy
```

---

### Week 3-4: Helm

**Objective:** Replace raw `deploy/deployment.yaml` with a reusable Helm chart.

#### Day-by-Day Tasks

| Day    | Task                                                                                                                                         | Duration | Success Check                           |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------------------------------- |
| **6**  | Install Helm CLI. Run `helm create accounts-chart`. Understand the directory structure.                                                      | 30m      | `helm create` succeeds                  |
| **7**  | Move `deploy/deployment.yaml` logic into `accounts-chart/templates/deployment.yaml`. Use `.Values.image.repository` and `.Values.image.tag`. | 1h       | `helm template` shows correct output    |
| **8**  | Add Bitnami PostgreSQL as a chart dependency in `Chart.yaml` and `values.yaml`.                                                              | 1h       | PostgreSQL deploys via subchart         |
| **9**  | Create `values-dev.yaml` (1 replica, sqlite) and `values-prod.yaml` (3 replicas, postgresql).                                                | 1h       | Files show clear environment separation |
| **10** | `helm install accounts ./accounts-chart -f values-prod.yaml`. Then `helm upgrade accounts ./accounts-chart --set image.tag=v2`.              | 1h       | Rolling update works                    |

**Deliverable:** Directory structure:

```
accounts-chart/
├── Chart.yaml          # Name, version, dependencies
├── values.yaml         # Default values
├── values-dev.yaml     # Dev overrides
├── values-prod.yaml    # Prod overrides
└── templates/
    ├── deployment.yaml # Uses {{ .Values.image.tag }}
    ├── service.yaml    # Uses {{ .Values.service.port }}
    └── _helpers.tpl    # Name templates
```

---

### Week 5-6: Prometheus + Grafana

**Objective:** Add metrics, monitoring, and dashboards to your accounts service.

#### Day-by-Day Tasks

| Day    | Task                                                                                                             | Duration | Success Check                              |
| ------ | ---------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------ |
| **11** | Add `prometheus_flask_exporter` to `service/__init__.py`. Expose `/metrics` endpoint.                            | 1h       | `curl localhost:8080/metrics` returns data |
| **12** | Rebuild Docker image as `accounts:3` with metrics support. Push to registry.                                     | 1h       | Image pushed                               |
| **13** | Deploy `kube-prometheus-stack` Helm chart to cluster.                                                            | 2h       | Prometheus + Grafana pods running          |
| **14** | Add Prometheus scrape annotations to your deployment template. Verify targets appear in Prometheus.              | 1h       | Prometheus shows "UP" for your pod         |
| **15** | Build Grafana dashboard with: request count, latency (p50/p95/p99), error rate, active connections. Export JSON. | 2h       | Dashboard shows live data                  |

**Deliverable:**

```
monitoring/
├── dashboard.json     # Exported Grafana dashboard
├── prometheus-rules.yaml  # Alerting rules
└── README.md          # How to access Grafana
```

**Grafana dashboard panels to create:**

- **Panel 1:** HTTP Request Rate (graph, queries per second)
- **Panel 2:** Response Latency (heatmap, p50/p95/p99)
- **Panel 3:** Error Rate (% of 4xx/5xx responses)
- **Panel 4:** Active Users / Connections (gauge)

---

### Week 7-8: ArgoCD + GitOps

**Objective:** Implement GitOps deployment — changes pushed to Git auto-deploy to cluster.

#### Day-by-Day Tasks

| Day    | Task                                                                                                                                | Duration | Success Check                              |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------ |
| **16** | Install ArgoCD on cluster: `kubectl create namespace argocd && kubectl apply -n argocd -f install.yaml`.                            | 1h       | ArgoCD pods running                        |
| **17** | Create a second GitHub repo: `accounts-gitops`. Push your Helm chart + `values.yaml` to it.                                         | 1h       | Repo exists with manifests                 |
| **18** | Connect ArgoCD to the Git repo: `argocd repo add git@github.com:your-org/accounts-gitops.git`.                                      | 30m      | Repo shows "Successful" in ArgoCD UI       |
| **19** | Create ArgoCD Application: `argocd app create accounts --repo URL --path . --dest-server https://...`. Set `syncPolicy: automated`. | 1h       | App shows "Synced" + "Healthy"             |
| **20** | Change a value in the Git repo (e.g., replica count 1→2). Push. Watch ArgoCD auto-sync.                                             | 30m      | Pod count changes without manual `kubectl` |

**Deliverable:**

```
accounts-gitops/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   └── service.yaml
├── README.md
└── argo-app.yaml     # ArgoCD Application manifest
```

**Architecture diagram:**

```
┌──────────────┐     push     ┌──────────────┐    sync    ┌──────────────┐
│  Developer   │ ──────────→  │   GitHub     │ ─────────→  │    ArgoCD    │
│  (git push)  │             │  Manifests   │             │  (operator)  │
└──────────────┘             └──────────────┘             └──────┬───────┘
                                                                 │ apply
                                                                 ▼
                                                            ┌──────────────┐
                                                            │  Kubernetes  │
                                                            │   Cluster    │
                                                            └──────────────┘
```

---

### Week 9-10: CKA Certification Prep

**Objective:** Pass the Certified Kubernetes Administrator exam (the most valuable K8s credential).

#### Daily Study Schedule (Weeks 9-10)

| Time Block  | Activity                                           | Duration |
| ----------- | -------------------------------------------------- | -------- |
| 09:00-10:30 | KodeKloud CKA Course Video + Lab                   | 1.5h     |
| 10:30-10:45 | Break                                              | 15m      |
| 10:45-12:15 | Hands-on practice in KodeKloud playground          | 1.5h     |
| 12:15-13:00 | Lunch                                              | 45m      |
| 13:00-14:30 | Killer.sh simulator or official practice questions | 1.5h     |
| 14:30-14:45 | Break                                              | 15m      |
| 14:45-16:00 | Weak areas review + flashcards                     | 1.25h    |

#### Topics to Master

| Topic                               | Weight on Exam | Your Target |
| ----------------------------------- | -------------- | ----------- |
| Cluster Architecture & Installation | 25%            | 90%         |
| Workloads & Scheduling              | 15%            | 90%         |
| Services & Networking               | 20%            | 85%         |
| Storage                             | 10%            | 80%         |
| Troubleshooting                     | 30%            | 90%         |

#### Key Commands to Memorize

```bash
kubectl run, create, apply, delete, describe, get, logs, exec
kubectl cordon, drain, taint, label, annotate
kubectl top, cluster-info, api-resources
kubectl rollout status, undo, history
kubectl auth can-i, --as, --as-group
```

#### Exam Day Checklist

- [ ] Register at [CNCF Training](https://www.cncf.io/training/) ($395)
- [ ] Schedule remote proctored exam (choose 2+ weeks out)
- [ ] Test your webcam + microphone
- [ ] Have a quiet room with no external monitors
- [ ] Bring: government ID, water, no notes allowed
- [ ] Strategy: Skip hard questions, return later. 2 hours for 17 questions.

---

### Week 11-12: Job Search

**Objective:** Submit 50 targeted applications.

#### Daily Schedule

| Time        | Activity                                                                    |
| ----------- | --------------------------------------------------------------------------- |
| 09:00-10:00 | Apply to 5 jobs (LinkedIn, Indeed, Wellfound, company sites)                |
| 10:00-11:00 | Prepare for upcoming interviews (research company, review their tech stack) |
| 11:00-12:00 | Practice interview question (record yourself)                               |
| Afternoon   | Attend scheduled interviews                                                 |

#### Where to Apply (Ranked by Likelihood)

| #   | Company Type                                           | Platforms                 | Approx. Response Rate |
| --- | ------------------------------------------------------ | ------------------------- | --------------------- |
| 1   | IBM Partner Companies (Infosys, Wipro, TCS, Accenture) | LinkedIn, company careers | 20-30%                |
| 2   | Managed Service Providers (Rackspace, Mission, DoiT)   | LinkedIn, Wellfound       | 15-25%                |
| 3   | Startups (< 50 people, funded)                         | Wellfound (AngelList)     | 10-20%                |
| 4   | Mid-size SaaS (Atlassian, Zendesk, Intercom)           | Company careers           | 5-10%                 |
| 5   | Big Tech (Google, Microsoft, AWS)                      | Company portals           | 1-5%                  |

#### Applications Tracker

Use a spreadsheet to track:

| Date        | Company     | Role         | Platform  | Contact              | Status           | Next Action           |
| ----------- | ----------- | ------------ | --------- | -------------------- | ---------------- | --------------------- |
| Week 11 Mon | Example Inc | Jr DevOps    | LinkedIn  | None                 | Applied          | Follow up in 1 week   |
| Week 11 Tue | Startup Co  | Platform Eng | Wellfound | Referral from friend | Phone screen Wed | Prepare K8s questions |

**Target:** 5 applications per day × 10 weekdays = 50 total.

---

## 4. Skills Matrix

### By Week 12, You'll Know

| Tool           | Level                               | Evidence to Show                      |
| -------------- | ----------------------------------- | ------------------------------------- |
| **Terraform**  | Create, modify, destroy cloud infra | `terraform/` directory in GitHub      |
| **Helm**       | Package, install, upgrade K8s apps  | `accounts-chart/` directory in GitHub |
| **Prometheus** | Scrape metrics, write queries       | Grafana dashboard screenshot          |
| **Grafana**    | Build dashboards, set alerts        | `dashboard.json` in GitHub            |
| **ArgoCD**     | GitOps sync, application management | ArgoCD "Synced" screenshot            |
| **Kubernetes** | CKA-level troubleshooting cert      | CKA badge on LinkedIn                 |
| **CI/CD**      | Multi-stage pipeline design         | Pipeline diagram in README            |
| **Docker**     | Build, tag, push, optimize          | Dockerfile with multi-stage build     |
| **Cloud**      | Provision and manage K8s clusters   | Terraform + cluster screenshots       |

### Resume Keywords (use these EXACT terms)

```
CI/CD, GitHub Actions, Tekton, ArgoCD, GitOps,
Kubernetes, Docker, Containers, Pods, Deployments, Services, Ingress,
Terraform, Infrastructure as Code, Helm Charts,
Prometheus, Grafana, Monitoring, Observability,
Python, Flask, REST APIs, pytest, TDD,
IBM Cloud, AWS/GCP (if you learn one),
Linux, Bash, YAML, Git, GitHub, Pull Requests, Code Review
```

---

## 5. Job Search Strategy

### Resume Structure

```
[NAME]
DevOps Engineer | Kubernetes | CI/CD | Terraform
Email | Phone | LinkedIn | GitHub

SKILLS
- CI/CD: GitHub Actions, Tekton Pipelines, ArgoCD
- Containers: Docker, multi-stage builds, image optimization
- Orchestration: Kubernetes (CKA certified), Helm, Kustomize
- Infrastructure: Terraform, IBM Cloud VPC/IKS
- Monitoring: Prometheus, Grafana, alerting, dashboards
- Languages: Python, YAML, Bash, Go (basics if you learn)
- Testing: pytest, TDD, API testing, coverage

EXPERIENCE
DevOps Capstone Project | IBM/Coursera | 2026
• Built 6-stage Tekton CD pipeline (clone → lint → test → build → deploy)
• Containerized Flask microservice with health probes and resource limits
• Deployed to IBM Kubernetes Service with PostgreSQL backend
• Implemented CORS policies and security headers (Talisman)
• Configured GitHub Actions CI: lint + test on every push

PROJECTS
GitOps-Deployed Microservice | GitHub | 2026
• Provisioned K8s cluster using Terraform (IaC)
• Packaged application as Helm chart with environment overrides
• Deployed Prometheus/Grafana monitoring stack
• Implemented ArgoCD GitOps workflow (auto-sync from Git)

CERTIFICATIONS
• CKA: Certified Kubernetes Administrator (In Progress)
• IBM DevOps Capstone Certificate (Coursera)

EDUCATION
[Your degree, if any] | [School] | [Year]
```

### Interview Questions to Prepare

**Tell me about yourself (30-second version):**

> "I'm a DevOps engineer focused on Kubernetes and CI/CD. I recently built a complete CI/CD pipeline using Tekton and GitHub Actions, deployed on IBM Cloud, with monitoring via Prometheus. I'm pursuing my CKA certification and looking for a role where I can build reliable deployment systems."

**Technical questions (be ready for these):**

1. "How does Kubernetes scheduling work?" (kube-scheduler, predicates, priorities)
2. "Explain a Deployment vs a StatefulSet." (stateless vs stateful, stable network IDs)
3. "How do you debug a pod stuck in CrashLoopBackOff?" (`kubectl logs`, `kubectl describe`, `kubectl get events`)
4. "What's the difference between a Liveness and Readiness probe?" (Liveness = restart, Readiness = traffic)
5. "How would you handle a blue-green deployment?" (two deployments, switch service selector)
6. "Explain GitOps in 30 seconds." (Git is source of truth → operator syncs cluster → automatic rollback)

**Behavioral questions:**

1. "Tell me about a time something broke in production."
   → Your answer: Talisman probe issue (proven example from this project)
2. "How do you handle a disagreement with a teammate?"
   → Data over ego. "Let's test both approaches and compare metrics."
3. "What's the most difficult technical problem you've solved?"
   → The outbound traffic protection issue (debugging network-level block)

---

## 6. Resources & Costs

### Required Costs

| Item                   | Cost      | Notes                             |
| ---------------------- | --------- | --------------------------------- |
| CKA Exam               | $395      | One attempt included, retake $395 |
| AWS Free Tier          | $0        | 12 months free for new accounts   |
| Domain name (optional) | ~$12/year | For ingress/GitOps demo           |

**Total required investment: ~$395-407**

### Free Resources

| Resource                   | Topic         | Link                                                                    |
| -------------------------- | ------------- | ----------------------------------------------------------------------- |
| Terraform Tutorials        | IaC           | [learn.hashicorp.com/terraform](https://learn.hashicorp.com/terraform)  |
| Helm Docs                  | K8s packaging | [helm.sh/docs](https://helm.sh/docs/)                                   |
| Prometheus Getting Started | Monitoring    | [prometheus.io/docs](https://prometheus.io/docs/introduction/overview/) |
| ArgoCD Docs                | GitOps        | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/)               |
| KodeKloud CKA Course       | CKA Prep      | [learn.kodekloud.com](https://learn.kodekloud.com/) (~$30/month)        |
| Killer.sh                  | CKA Simulator | [killer.sh](https://killer.sh/) (2 free with CKA purchase)              |
| Kubernetes Docs            | K8s Reference | [kubernetes.io/docs](https://kubernetes.io/docs/)                       |

### Learning Platforms

| Platform                      | Best For                   | Cost       |
| ----------------------------- | -------------------------- | ---------- |
| KodeKloud                     | Hands-on K8s labs          | ~$30/month |
| Pluralsight                   | Terraform + AWS courses    | ~$30/month |
| Coursera                      | Structured specializations | Free audit |
| YouTube (TechWorld with Nana) | K8s overview               | Free       |

---

## 7. Appendix: Interview Prep

### Common DevOps Scenarios

**Scenario 1: Pod won't start**

```bash
kubectl get pods
# → CrashLoopBackOff
kubectl logs pod-name
# → Error: cannot connect to database
kubectl get svc postgresql
# → Service exists but endpoint missing
kubectl get endpoints postgresql
# → No endpoints
# Root cause: PostgreSQL pod failed, no ready endpoints
```

**Scenario 2: Deployment not rolling out**

```bash
kubectl rollout status deployment/accounts
# → Waiting for rollout to finish: 0 of 1 updated replicas are available...
kubectl describe pod accounts-new-xxxxx
# → Failed to pull image "us.icr.io/accounts-namespace/accounts:3"
# → 401 Unauthorized
# Root cause: Image pull secret missing or expired
```

**Scenario 3: High latency**

```bash
kubectl top pods
# → accounts pod using 90% CPU
kubectl describe pod accounts-xxxxx
# → Resource limits: 500m CPU, but requests: 50m CPU
# → Pod is throttled but not restricted
# Fix: Increase CPU limits or optimize application code
```

### Whiteboarding Exercise

Practice drawing this on a whiteboard (or paper):

```
[GitHub Repo] → push → [GitHub Actions] → test + build → push to [Container Registry]
     ↑                                                     │
     │                                                     ▼
     │                                              [ArgoCD detects change]
     │                                                     │
     │                                                     ▼
     │                                              [Syncs manifests from Git]
     │                                                     │
     └────────────── deploy ───────────────────────────────┘
                                                        │
                                                        ▼
                                                 [Kubernetes Cluster]
                                                 ├── accounts:3 (new)
                                                 ├── accounts:2 (old)
                                                 └── PostgreSQL
                                                        │
                                                        ▼
                                                 [Prometheus scrapes]
                                                 [Grafana dashboards]
```

If you can draw and explain this diagram, you can pass any DevOps interview.

---

## Final Checklist

### End of Month 1

- [ ] Terraform code provisions full cluster
- [ ] Helm chart packages accounts service
- [ ] Both repositories pushed to GitHub

### End of Month 2

- [ ] Prometheus scraping your app metrics
- [ ] Grafana dashboard with 4+ panels
- [ ] ArgoCD auto-syncing from Git repo
- [ ] All repos linked on GitHub profile

### End of Month 3

- [ ] CKA certification earned
- [ ] LinkedIn updated with CKA badge
- [ ] Resume optimized with keywords
- [ ] 50 applications submitted
- [ ] At least 5 interviews attended
- [ ] Iterated on interview performance

---

_"The best time to start was 3 months ago. The second best time is today."_

Good luck.
