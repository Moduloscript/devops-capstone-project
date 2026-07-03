# IBM Cloud Deployment Plan — Accounts API

**Project:** Flask Account REST API (PostgreSQL, Docker, Kubernetes)
**Target:** IBM Cloud Kubernetes Service (IKS) — Community K8s
**Author:** Zoo (Technical Advisor)
**Date:** July 2026
**Status:** Planning / Reference

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [IBM Cloud Account Preparation](#3-ibm-cloud-account-preparation)
4. [CLI Tools Installation](#4-cli-tools-installation)
5. [Container Registry Setup](#5-container-registry-setup)
6. [Cluster Creation](#6-cluster-creation)
7. [Cluster Access & Configuration](#7-cluster-access--configuration)
8. [Kustomize Overlay for IBM Cloud](#8-kustomize-overlay-for-ibm-cloud)
9. [Deploy the Application](#9-deploy-the-application)
10. [Expose the Application (Ingress)](#10-expose-the-application-ingress)
11. [PostgreSQL on IBM Cloud](#11-postgresql-on-ibm-cloud)
12. [Tekton CI/CD Pipeline for IBM Cloud](#12-tekton-cicd-pipeline-for-ibm-cloud)
13. [Verification](#13-verification)
14. [Troubleshooting](#14-troubleshooting)
15. [Cost Considerations](#15-cost-considerations)
16. [Cleanup & Teardown](#16-cleanup--teardown)
17. [Reference Links](#17-reference-links)

---

## 1. Overview

This document provides a comprehensive, step-by-step plan for deploying the Accounts API (Flask + PostgreSQL) to **IBM Cloud Kubernetes Service (IKS)**. It covers everything from account preparation and CLI setup through cluster creation, container registry configuration, application deployment, and CI/CD pipeline integration.

### Architecture Diagram (Conceptual)

```
┌─────────────────────────────────────────────────────────────┐
│                     IBM Cloud                               │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────────────────┐   │
│  │  IBM Container   │    │  IBM Kubernetes Service (IKS) │   │
│  │  Registry (ICR)  │    │                              │   │
│  │  us.icr.io/      │    │  ┌────────────────────────┐  │   │
│  │  accounts-       │───▶│  │  accounts Pod          │  │   │
│  │  namespace/      │    │  │  Flask + gunicorn      │  │   │
│  │  accounts:latest │    │  │  port 8080             │  │   │
│  └──────────────────┘    │  └──────────┬─────────────┘  │   │
│                           │             │                │   │
│                           │  ┌──────────▼─────────────┐  │   │
│                           │  │  PostgreSQL Pod         │  │   │
│                           │  │  (ephemeral or          │  │   │
│                           │  │  IBM Cloud Databases)   │  │   │
│                           │  └────────────────────────┘  │   │
│                           │                              │   │
│                           │  ┌────────────────────────┐  │   │
│                           │  │  Ingress (NLB/ALB)     │  │   │
│                           │  │  accounts.<cluster>.   │  │   │
│                           │  │  us-south.containers.  │  │   │
│                           │  │  appdomain.cloud       │  │   │
│                           │  └────────────────────────┘  │   │
│                           └──────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Tekton CI/CD Pipeline                               │   │
│  │  clone → lint → test → build → push → deploy         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Prerequisites

### 2.1 Required Accounts & Subscriptions

| Item                            | Required | Notes                                                                              |
| ------------------------------- | -------- | ---------------------------------------------------------------------------------- |
| IBM Cloud billable account      | **Yes**  | Pay-As-You-Go or Subscription. Free trial accounts **cannot** create IKS clusters. |
| IBM Cloud API Key               | **Yes**  | Used by CLI and Tekton for authentication.                                         |
| Docker Hub or container runtime | **Yes**  | For building and pushing images locally.                                           |
| Git repository access           | **Yes**  | For Tekton pipeline to clone source code.                                          |

### 2.2 Required CLI Tools

| Tool           | Version | Install Method                                           |
| -------------- | ------- | -------------------------------------------------------- |
| `ibmcloud` CLI | Latest  | See [Section 4](#4-cli-tools-installation)               |
| `kubectl`      | 1.28+   | `ibmcloud ks cluster config` or direct download          |
| `kustomize`    | v5+     | `ibmcloud plugin install kustomize` or standalone binary |
| `docker`       | 24+     | Docker Desktop or equivalent                             |
| `git`          | Latest  | Standard git client                                      |

### 2.3 Required IAM Permissions

The user or service ID performing the deployment needs these IAM roles:

| Service                            | Role                              | Scope                                  |
| ---------------------------------- | --------------------------------- | -------------------------------------- |
| IBM Cloud Kubernetes Service       | **Administrator** or **Operator** | At the account or resource group level |
| IBM Cloud Container Registry       | **Administrator**                 | At the account level                   |
| Resource Group access              | **Viewer** (minimum)              | For the target resource group          |
| IAM Identity (if using service ID) | **Operator** or **Editor**        | For service ID creation                |

---

## 3. IBM Cloud Account Preparation

Follow these 6 steps to prepare your IBM Cloud account for IKS.

### Step 1: Create or Upgrade to a Billable Account

- **Pay-As-You-Go**: Pay only for what you use. No upfront commitment.
- **Subscription**: Commit to a spending amount for discounted rates.

> **Note:** Lite (free) accounts cannot provision IKS clusters. You must upgrade.

### Step 2: Set User Permissions (IAM)

1. Go to **IBM Cloud Console → Manage → Access (IAM) → Users**
2. Select your user → **Access policies**
3. Assign these policies:

```bash
# Via CLI (requires Administrator access)
ibmcloud iam user-policy-create <user@example.com> \
  --roles Administrator \
  --service-name containers-kubernetes

ibmcloud iam user-policy-create <user@example.com> \
  --roles Administrator \
  --service-name container-registry
```

### Step 3: (Optional) Create a Trusted Profile

Trusted profiles allow compute resources to authenticate without API keys:

```bash
ibmcloud iam trusted-profile-create accounts-deploy-profile
ibmcloud iam trusted-profile-add-policy accounts-deploy-profile \
  --roles Administrator \
  --service-name containers-kubernetes
```

### Step 4: Plan Resource Groups

Create a dedicated resource group for the project:

```bash
ibmcloud resource group-create accounts-rg
ibmcloud target -g accounts-rg
```

### Step 5: Cluster-Specific Setup

**For VPC clusters (recommended):**

- VRF (Virtual Routing and Forwarding) is automatically enabled in VPC.
- Service endpoints are configured during VPC creation.

**For Classic clusters:**

- Enable VRF: `ibmcloud account vrf-enable`
- Enable VLAN spanning: `ibmcloud ks vlan-spanning-set --enabled true`

### Step 6: Set Up API Key for IKS

```bash
# Create an API key for the cluster
ibmcloud ks api-key-reset --region us-south
```

---

## 4. CLI Tools Installation

### 4.1 Install IBM Cloud CLI

**macOS:**

```bash
curl -fsSL https://clis.cloud.ibm.com/install/osx | sh
```

**Linux (including WSL2):**

```bash
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
```

**Windows (PowerShell as Administrator):**

```powershell
iex (New-Object Net.WebClient).DownloadString('https://clis.cloud.ibm.com/install/powershell')
```

### 4.2 Install Required Plugins

```bash
# Kubernetes Service plugin
ibmcloud plugin install ks

# Container Registry plugin
ibmcloud plugin install cr

# Kustomize plugin (optional, or use standalone)
ibmcloud plugin install kustomize
```

### 4.3 Install kubectl

```bash
# Download kubectl (Linux/WSL2/macOS)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Windows: Download from https://kubernetes.io/docs/tasks/tools/
```

### 4.4 Verify Installation

```bash
ibmcloud version
ibmcloud plugin list
kubectl version --client
docker --version
```

### 4.5 Log In to IBM Cloud

```bash
# Interactive login
ibmcloud login --sso

# Or with API key (non-interactive, good for CI/CD)
ibmcloud login --apikey @<path-to-api-key-file>

# Set target region and resource group
ibmcloud target -r us-south -g accounts-rg
```

---

## 5. Container Registry Setup

### 5.1 Create a Namespace

```bash
# List existing namespaces
ibmcloud cr namespace-list

# Create a namespace for the accounts project
ibmcloud cr namespace-add accounts-namespace
```

### 5.2 Build and Tag the Image

```bash
# Build the Docker image
docker build --rm --pull --tag accounts:latest .

# Tag for IBM Cloud Container Registry
docker tag accounts:latest us.icr.io/accounts-namespace/accounts:latest
docker tag accounts:latest us.icr.io/accounts-namespace/accounts:1.0
```

### 5.3 Push to IBM Cloud Container Registry

```bash
# Log in to ICR
ibmcloud cr login

# Push the image
docker push us.icr.io/accounts-namespace/accounts:latest
docker push us.icr.io/accounts-namespace/accounts:1.0
```

### 5.4 Verify the Image

```bash
# List images in the registry
ibmcloud cr image-list

# Inspect a specific image
ibmcloud cr image-inspect us.icr.io/accounts-namespace/accounts:latest
```

### 5.5 Image Pull Secrets

IBM Cloud automatically creates a default image pull secret `all-icr-io` in the `default` namespace with an IAM Reader role. This allows any pod in `default` to pull from any `icr.io` registry.

**To use a different namespace (e.g., `accounts-prod`):**

```bash
# Copy the default secret to the target namespace
kubectl get secret all-icr-io -n default -o yaml \
  | sed 's/default/accounts-prod/g' \
  | kubectl create -n accounts-prod -f -
```

**To create a custom service ID with restricted access:**

```bash
# Create a service ID
ibmcloud iam service-id-create accounts-puller

# Create a Reader policy for Container Registry
ibmcloud iam service-policy-create accounts-puller \
  --roles Reader \
  --service-name container-registry

# Create an API key for the service ID
ibmcloud iam service-api-key-create accounts-puller-key \
  accounts-puller \
  --output json
```

**To create a custom image pull secret:**

```bash
kubectl create secret docker-registry icr-pull-secret \
  --docker-server=us.icr.io \
  --docker-username=iamapikey \
  --docker-password=<api-key-from-above> \
  --docker-email=accounts@example.com \
  -n accounts-prod
```

**To use the secret in a deployment, add to the pod spec:**

```yaml
spec:
  imagePullSecrets:
    - name: icr-pull-secret
```

---

## 6. Cluster Creation

### 6.1 Choose Cluster Type

| Feature             | VPC Cluster (Recommended) | Classic Cluster                 |
| ------------------- | ------------------------- | ------------------------------- |
| Network isolation   | VPC (Secure by Default)   | VLAN-based                      |
| Service endpoints   | Built-in VPE support      | Requires VRF + NLB              |
| Worker node flavors | Next-gen profiles         | Classic profiles                |
| Pricing             | Slightly higher           | Lower entry cost                |
| Recommended for     | **New deployments**       | Existing classic infrastructure |

### 6.2 Create a VPC Cluster

**Prerequisites:**

- VPC created in IBM Cloud Console or via CLI
- Subnet(s) in the VPC
- Public gateway attached to the subnet (for public endpoint)

**Create the cluster:**

```bash
# Set the resource group
ibmcloud target -g accounts-rg

# Create a VPC-gen2 cluster (single zone, 1 worker node)
ibmcloud ks cluster create vpc-gen2 \
  --name accounts-cluster \
  --zone us-south-1 \
  --flavor bx2.4x16 \
  --workers 1 \
  --vpc-id <vpc-id> \
  --subnet-id <subnet-id> \
  --public-service-endpoint \
  --private-service-endpoint
```

**Parameters explained:**

| Parameter                    | Value              | Notes                                               |
| ---------------------------- | ------------------ | --------------------------------------------------- |
| `--name`                     | `accounts-cluster` | Cluster name, must be unique per region             |
| `--zone`                     | `us-south-1`       | Choose the zone closest to your users               |
| `--flavor`                   | `bx2.4x16`         | 4 vCPU, 16 GB RAM. Adjust based on workload.        |
| `--workers`                  | `1`                | Start with 1, scale as needed                       |
| `--vpc-id`                   | `<vpc-id>`         | VPC ID from `ibmcloud is vpcs`                      |
| `--subnet-id`                | `<subnet-id>`      | Subnet ID from `ibmcloud is subnets`                |
| `--public-service-endpoint`  | —                  | Enables public access to the cluster API            |
| `--private-service-endpoint` | —                  | Enables private access (recommended for production) |

### 6.3 Create a Classic Cluster (Alternative)

```bash
ibmcloud ks cluster create classic \
  --name accounts-cluster-classic \
  --zone dal10 \
  --flavor b3c.4x16 \
  --workers 1 \
  --public-vlan <public-vlan-id> \
  --private-vlan <private-vlan-id> \
  --public-service-endpoint
```

### 6.4 Monitor Cluster Creation

```bash
# Check cluster status
ibmcloud ks cluster ls

# Get detailed cluster info
ibmcloud ks cluster get -c accounts-cluster

# Watch worker node provisioning
ibmcloud ks worker ls -c accounts-cluster

# Wait for cluster to be ready (can take 10-30 minutes)
ibmcloud ks cluster get -c accounts-cluster | grep State
```

Expected output when ready:

```
State:                   normal
Master Status:           Ready (1 master)
Worker Status:           normal
```

---

## 7. Cluster Access & Configuration

### 7.1 Download Cluster Configuration

**Public endpoint (default):**

```bash
ibmcloud ks cluster config -c accounts-cluster
```

**Private endpoint (VPC):**

```bash
ibmcloud ks cluster config -c accounts-cluster --endpoint private
```

**VPE (Virtual Private Endpoint):**

```bash
ibmcloud ks cluster config -c accounts-cluster --endpoint vpe
```

### 7.2 Verify Cluster Access

```bash
# Check current context
kubectl config current-context

# List nodes
kubectl get nodes

# List all namespaces
kubectl get ns
```

### 7.3 Create the Target Namespace

```bash
kubectl create namespace accounts-prod
```

### 7.4 Copy Image Pull Secret to Namespace

```bash
kubectl get secret all-icr-io -n default -o yaml \
  | sed 's/default/accounts-prod/g' \
  | kubectl create -n accounts-prod -f -
```

### 7.5 (Optional) Set Up kubectl Autocomplete

```bash
# Bash
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# Zsh
source <(kubectl completion zsh)
echo "source <(kubectl completion zsh)" >> ~/.zshrc
```

---

## 8. Kustomize Overlay for IBM Cloud

### 8.1 Create the Overlay Directory

```bash
mkdir -p deploy/overlays/ibmcloud
```

### 8.2 Create `kustomization.yaml`

File: [`deploy/overlays/ibmcloud/kustomization.yaml`](deploy/overlays/ibmcloud/kustomization.yaml)

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: accounts-prod

resources:
  - ../../base
  - ingress-ibm.yaml

images:
  - name: accounts
    newName: us.icr.io/accounts-namespace/accounts
    newTag: latest

secretGenerator:
  - name: app-secrets
    envs:
      - secret.env
    type: Opaque

replicas:
  - name: accounts
    count: 2
```

### 8.3 Create `ingress-ibm.yaml`

IBM Cloud IKS uses a managed NGINX Ingress Controller (ALB — Application Load Balancer). The Ingress subdomain is automatically assigned to the cluster.

File: [`deploy/overlays/ibmcloud/ingress-ibm.yaml`](deploy/overlays/ibmcloud/ingress-ibm.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: accounts
  annotations:
    kubernetes.io/ingress.class: "public-iks-k8s-nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
    - host: accounts.<cluster-ingress-subdomain>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: accounts
                port:
                  number: 8080
```

> **Note:** Replace `<cluster-ingress-subdomain>` with your cluster's Ingress subdomain, obtained via:
>
> ```bash
> ibmcloud ks cluster get -c accounts-cluster | grep Ingress
> ```

### 8.4 Create `secret.env.example`

File: [`deploy/overlays/ibmcloud/secret.env.example`](deploy/overlays/ibmcloud/secret.env.example)

```env
SECRET_KEY=your-production-secret-key-here
```

> **Important:** Generate a strong random secret for production:
>
> ```bash
> python3 -c "import secrets; print(secrets.token_hex(32))"
> ```

### 8.5 (Optional) TLS Certificate with Let's Encrypt

For production, add TLS using cert-manager or IBM Cloud's certificate manager:

```yaml
# ingress-ibm-tls.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: accounts-tls
  annotations:
    kubernetes.io/ingress.class: "public-iks-k8s-nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
    - hosts:
        - accounts.<cluster-ingress-subdomain>
      secretName: accounts-tls-secret
  rules:
    - host: accounts.<cluster-ingress-subdomain>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: accounts
                port:
                  number: 8080
```

---

## 9. Deploy the Application

### 9.1 Deploy with Kustomize

```bash
# Preview the resources
kustomize build deploy/overlays/ibmcloud

# Apply to the cluster
kustomize build deploy/overlays/ibmcloud | kubectl apply -f -
```

### 9.2 Verify Deployment

```bash
# Check pods
kubectl get pods -n accounts-prod -w

# Check services
kubectl get svc -n accounts-prod

# Check ingress
kubectl get ingress -n accounts-prod

# Check deployment details
kubectl describe deployment accounts -n accounts-prod
```

### 9.3 Check Pod Logs

```bash
# Get pod name
POD=$(kubectl get pods -n accounts-prod -l app=accounts -o jsonpath='{.items[0].metadata.name}')

# Follow logs
kubectl logs -n accounts-prod -f $POD

# Check for errors
kubectl logs -n accounts-prod $POD | grep -i error
```

### 9.4 Scale the Deployment

```bash
# Scale to 3 replicas
kubectl scale deployment accounts -n accounts-prod --replicas=3

# Verify
kubectl get pods -n accounts-prod
```

### 9.5 Rolling Update

```bash
# Update the image tag
kubectl set image deployment/accounts \
  -n accounts-prod \
  accounts=us.icr.io/accounts-namespace/accounts:2.0

# Monitor rollout
kubectl rollout status deployment/accounts -n accounts-prod
```

---

## 10. Expose the Application (Ingress)

### 10.1 Get the Ingress Subdomain

```bash
ibmcloud ks cluster get -c accounts-cluster | grep -i ingress
```

Example output:

```
Ingress Subdomain:      accounts-cluster-xxxxx.us-south.containers.appdomain.cloud
Ingress Secret:         accounts-cluster-xxxxx
```

### 10.2 Update the Ingress Host

Edit [`deploy/overlays/ibmcloud/ingress-ibm.yaml`](deploy/overlays/ibmcloud/ingress-ibm.yaml) and set the `host` field to the Ingress subdomain.

### 10.3 Re-apply the Ingress

```bash
kustomize build deploy/overlays/ibmcloud | kubectl apply -f -
```

### 10.4 Test the Endpoint

```bash
# Get the Ingress host
INGRESS_HOST=$(kubectl get ingress accounts -n accounts-prod -o jsonpath='{.spec.rules[0].host}')

# Test health endpoint
curl -v http://$INGRESS_HOST/health

# Test API
curl -v http://$INGRESS_HOST/accounts
```

### 10.5 (Alternative) NodePort or LoadBalancer

If Ingress is not needed, modify the service to use `LoadBalancer` type:

```bash
# Patch the service
kubectl patch svc accounts -n accounts-prod -p '{"spec":{"type":"LoadBalancer"}}'

# Get the external IP
kubectl get svc accounts -n accounts-prod -w
```

---

## 11. PostgreSQL on IBM Cloud

### 11.1 Option A: Ephemeral PostgreSQL (Development)

Use the existing PostgreSQL deployment from the base Kustomize manifests. This is suitable for development but data is lost on pod restart.

```bash
# Already included in base kustomization
# deploy/base/postgresql.yaml and deploy/base/postgresql-pvc.yaml
```

### 11.2 Option B: IBM Cloud Databases for PostgreSQL (Production)

Provision a managed PostgreSQL instance:

```bash
# Create the database instance
ibmcloud resource service-instance-create accounts-postgres \
  databases-for-postgresql \
  standard \
  us-south \
  -g accounts-rg

# Create service credentials
ibmcloud resource service-key-create accounts-postgres-key \
  --instance-name accounts-postgres \
  --output json
```

**Get the connection URI:**

```bash
ibmcloud resource service-key-show accounts-postgres-key | grep "postgres://"
```

**Create a secret with the connection string:**

```bash
kubectl create secret generic postgres-credentials \
  -n accounts-prod \
  --from-literal=DATABASE_URI="postgresql://<user>:<password>@<host>:<port>/<database>?sslmode=require"
```

**Update the deployment to use the secret:**

Edit [`deploy/base/deployment.yaml`](deploy/base/deployment.yaml) to reference the secret:

```yaml
env:
  - name: DATABASE_URI
    valueFrom:
      secretKeyRef:
        name: postgres-credentials
        key: DATABASE_URI
```

### 11.3 Option C: IBM Cloud Compose for PostgreSQL (Legacy)

```bash
ibmcloud resource service-instance-create accounts-postgres-compose \
  compose-for-postgresql \
  standard \
  us-south
```

---

## 12. Tekton CI/CD Pipeline for IBM Cloud

### 12.1 Update the Pipeline for ICR

The existing Tekton pipeline at [`tekton/pipeline.yaml`](tekton/pipeline.yaml) already references `us.icr.io/accounts-namespace/accounts` in the build-image task. The deploy task needs to be updated to target the IBM Cloud overlay.

### 12.2 Create a PipelineRun for IBM Cloud

File: [`tekton/pipelinerun-ibmcloud.yaml`](tekton/pipelinerun-ibmcloud.yaml)

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: cd-pipeline-run-ibmcloud
spec:
  pipelineRef:
    name: cd-pipeline
  params:
    - name: repo-url
      value: https://github.com/your-org/accounts-api
    - name: branch
      value: main
    - name: image-tag
      value: "1.0"
  workspaces:
    - name: pipeline-workspace
      persistentVolumeClaim:
        claimName: tekton-pvc
    - name: docker-credentials
      secret:
        secretName: ibmcloud-dockerconfig
```

### 12.3 Create IBM Cloud Docker Config Secret

```bash
# Log in to ICR and get the config
ibmcloud cr login
cat ~/.docker/config.json

# Create the secret in the tekton namespace
kubectl create secret generic ibmcloud-dockerconfig \
  -n tekton-pipelines \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

### 12.4 Update the Deploy Task

The deploy task in [`tekton/tasks.yaml`](tekton/tasks.yaml) currently uses `kubectl apply -k deploy/overlays/k3d`. Update it to use the IBM Cloud overlay:

```yaml
# In the deploy task, change:
args:
  - apply
  - -k
  - deploy/overlays/ibmcloud
```

### 12.5 IBM Cloud API Key for Tekton

Create a Kubernetes secret with the IBM Cloud API key for non-interactive login:

```bash
kubectl create secret generic ibmcloud-credentials \
  -n tekton-pipelines \
  --from-literal=API_KEY=<your-ibm-cloud-api-key>
```

### 12.6 (Optional) Use `openshift-client` ClusterTask for ROKS

If deploying to Red Hat OpenShift on IBM Cloud (ROKS), the existing `openshift-client` ClusterTask works directly. The pipeline already references it.

---

## 13. Verification

### 13.1 Health Check

```bash
# Via Ingress
curl -v http://accounts-cluster-xxxxx.us-south.containers.appdomain.cloud/health

# Expected response: {"status": "OK", "timestamp": "..."}
```

### 13.2 CRUD Operations

```bash
BASE_URL="http://accounts-cluster-xxxxx.us-south.containers.appdomain.cloud"

# Create an account
curl -X POST $BASE_URL/accounts \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

# List all accounts
curl $BASE_URL/accounts

# Read a specific account
curl $BASE_URL/accounts/1

# Update an account
curl -X PUT $BASE_URL/accounts/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe Updated", "email": "john.updated@example.com"}'

# Delete an account
curl -X DELETE $BASE_URL/accounts/1
```

### 13.3 PostgreSQL Connectivity

```bash
# Exec into the pod
kubectl exec -n accounts-prod -it deployment/accounts -- /bin/bash

# Test database connection from within the pod
python3 -c "
from service import app
from service.models import db
with app.app_context():
    db.engine.execute('SELECT 1')
    print('Database connection OK')
"
```

### 13.4 Security Headers

```bash
curl -I $BASE_URL/health

# Expected headers:
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
# Content-Security-Policy: default-src 'self'
# X-XSS-Protection: 1; mode=block
```

### 13.5 CORS Verification

```bash
curl -X OPTIONS $BASE_URL/accounts \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: GET" \
  -v

# Expected: Access-Control-Allow-Origin: *
```

---

## 14. Troubleshooting

### 14.1 ImagePullBackOff / ErrImagePull

**Symptoms:** Pod status shows `ImagePullBackOff` or `ErrImagePull`.

**Causes & Fixes:**

| Cause                                  | Fix                                       |
| -------------------------------------- | ----------------------------------------- |
| Image pull secret missing in namespace | Copy `all-icr-io` secret to the namespace |
| Image tag doesn't exist                | Verify with `ibmcloud cr image-list`      |
| Wrong registry URL                     | Check `newName` in kustomization.yaml     |
| IAM permissions insufficient           | Verify Reader role on Container Registry  |

```bash
# Debug image pull issues
kubectl describe pod <pod-name> -n accounts-prod
kubectl get secrets -n accounts-prod
```

### 14.2 Pod Pending / CrashLoopBackOff

**Symptoms:** Pod stays in `Pending` or `CrashLoopBackOff`.

**Causes & Fixes:**

| Cause                          | Fix                                              |
| ------------------------------ | ------------------------------------------------ |
| Insufficient cluster resources | Scale up worker pool or reduce resource requests |
| Missing ConfigMap or Secret    | Verify `app-secrets` exists in namespace         |
| Database not ready             | Check PostgreSQL pod status                      |
| Wrong environment variables    | Check deployment env configuration               |

```bash
# Check pod events
kubectl describe pod <pod-name> -n accounts-prod

# Check node resources
kubectl top nodes
kubectl describe node <node-name>
```

### 14.3 Ingress Not Working

**Symptoms:** `curl` to Ingress host returns connection refused or 404.

**Causes & Fixes:**

| Cause                         | Fix                                               |
| ----------------------------- | ------------------------------------------------- |
| Ingress subdomain not updated | Replace `<cluster-ingress-subdomain>` placeholder |
| ALB not healthy               | Check `ibmcloud ks alb ls -c accounts-cluster`    |
| Service not running           | Verify `kubectl get svc -n accounts-prod`         |
| Wrong ingress class           | Use `public-iks-k8s-nginx` for IKS managed ALB    |

```bash
# Check ALB status
ibmcloud ks alb ls -c accounts-cluster

# Check Ingress details
kubectl describe ingress accounts -n accounts-prod
```

### 14.4 Database Connection Issues

**Symptoms:** Application logs show database connection errors.

**Causes & Fixes:**

| Cause                    | Fix                                                         |
| ------------------------ | ----------------------------------------------------------- |
| PostgreSQL pod not ready | Check `kubectl get pods -n accounts-prod -l app=postgresql` |
| Wrong connection string  | Verify `DATABASE_URI` environment variable                  |
| Network policy blocking  | Check NetworkPolicy resources                               |
| SSL mode mismatch        | Add `?sslmode=require` for IBM Cloud Databases              |

### 14.5 Cluster Creation Fails

**Symptoms:** `ibmcloud ks cluster create` returns an error.

**Causes & Fixes:**

| Cause                         | Fix                                      |
| ----------------------------- | ---------------------------------------- |
| Account not billable          | Upgrade from Lite to Pay-As-You-Go       |
| Insufficient permissions      | Verify IAM roles (Administrator for IKS) |
| VPC/subnet not configured     | Create VPC and subnet first              |
| Resource quota exceeded       | Check `ibmcloud ks quotas`               |
| Region doesn't support flavor | Try a different zone or flavor           |

### 14.6 Tekton Pipeline Failures

**Symptoms:** PipelineRun shows failed tasks.

**Causes & Fixes:**

| Cause                         | Fix                                            |
| ----------------------------- | ---------------------------------------------- |
| Docker config secret missing  | Create `ibmcloud-dockerconfig` secret          |
| IBM Cloud API key expired     | Rotate the API key                             |
| Git repository not accessible | Verify repo URL and credentials                |
| Buildah cannot push to ICR    | Verify dockerconfig secret has ICR credentials |

---

## 15. Cost Considerations

### 15.1 Estimated Monthly Costs

| Resource                   | Flavor/SKU                   | Estimated Monthly Cost           |
| -------------------------- | ---------------------------- | -------------------------------- |
| IKS Worker Node            | `bx2.4x16` (4 vCPU, 16 GB)   | ~$130–$170                       |
| IKS Cluster Management     | Per cluster fee              | ~$0 (included with worker nodes) |
| Container Registry         | Standard (first 0.5 GB free) | ~$0–$5                           |
| Container Registry Storage | Per GB/month                 | ~$0.10/GB                        |
| Container Registry Pulls   | Per GB                       | ~$0.002/GB                       |
| PostgreSQL (managed)       | Standard (1 GB)              | ~$25–$50                         |
| VPC                        | Public Gateway + Subnet      | ~$0–$10                          |
| Load Balancer (if used)    | Per month                    | ~$20                             |
| **Total (estimated)**      |                              | **~$175–$255/month**             |

### 15.2 Cost Optimization Tips

1. **Use preemptible workers** for non-production workloads (up to 50% savings).
2. **Right-size worker nodes** — start with `bx2.2x8` for development.
3. **Use ephemeral PostgreSQL** for development (no additional cost).
4. **Schedule cluster shutdown** during non-business hours (for dev clusters).
5. **Use IBM Cloud Budgets** to set spending alerts:

```bash
ibmcloud billing budget-create accounts-budget \
  --amount 300 \
  --currency USD \
  --email alerts@example.com
```

### 15.3 Free Tier Resources

IBM Cloud offers a limited free tier that can supplement the deployment:

- **Container Registry:** 0.5 GB of storage free per month
- **Databases:** Lite plans available (but not for production)
- **VPC:** Limited free tier for first 30 days

---

## 16. Cleanup & Teardown

### 16.1 Delete the Application

```bash
kustomize build deploy/overlays/ibmcloud | kubectl delete -f -
```

### 16.2 Delete the Cluster

```bash
ibmcloud ks cluster rm -c accounts-cluster -f
```

### 16.3 Delete Container Registry Images

```bash
ibmcloud cr image-rm us.icr.io/accounts-namespace/accounts:latest
ibmcloud cr image-rm us.icr.io/accounts-namespace/accounts:1.0
```

### 16.4 Delete Container Registry Namespace

```bash
ibmcloud cr namespace-rm accounts-namespace
```

### 16.5 Delete Managed PostgreSQL

```bash
ibmcloud resource service-instance-delete accounts-postgres -f
```

### 16.6 Delete Resource Group

```bash
ibmcloud resource group-delete accounts-rg -f
```

### 16.7 Delete VPC and Subnets

```bash
# List VPCs
ibmcloud is vpcs

# Delete VPC (this also deletes subnets, gateways, and other resources)
ibmcloud is vpc-delete <vpc-id> -f
```

### 16.8 Delete API Keys and Service IDs

```bash
# List API keys
ibmcloud iam api-keys

# Delete an API key
ibmcloud iam api-key-delete <key-name> -f

# List service IDs
ibmcloud iam service-ids

# Delete a service ID
ibmcloud iam service-id-delete <service-id> -f
```

### 16.9 Verify Cleanup

```bash
# Check remaining clusters
ibmcloud ks cluster ls

# Check remaining images
ibmcloud cr image-list

# Check remaining namespaces
ibmcloud cr namespace-list

# Check remaining resource groups
ibmcloud resource groups
```

---

## 17. Reference Links

### 17.1 IBM Cloud Documentation

| Resource                           | URL                                                                                                                                                      |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IKS Getting Started                | [https://cloud.ibm.com/docs/containers?topic=containers-getting-started](https://cloud.ibm.com/docs/containers?topic=containers-getting-started)         |
| CLI Installation                   | [https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli](https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli)                           |
| VPC Cluster Creation Tutorial      | [https://cloud.ibm.com/docs/containers?topic=containers-vpc_ks_tutorial](https://cloud.ibm.com/docs/containers?topic=containers-vpc_ks_tutorial)         |
| Classic Cluster Creation           | [https://cloud.ibm.com/docs/containers?topic=containers-classic_ks_tutorial](https://cloud.ibm.com/docs/containers?topic=containers-classic_ks_tutorial) |
| Accessing Clusters                 | [https://cloud.ibm.com/docs/containers?topic=containers-access_cluster](https://cloud.ibm.com/docs/containers?topic=containers-access_cluster)           |
| Preparing Your Account             | [https://cloud.ibm.com/docs/containers?topic=containers-kubernetes-prep](https://cloud.ibm.com/docs/containers?topic=containers-kubernetes-prep)         |
| Container Registry Getting Started | [https://cloud.ibm.com/docs/Registry?topic=Registry-getting-started](https://cloud.ibm.com/docs/Registry?topic=Registry-getting-started)                 |
| Setting Up Container Registry      | [https://cloud.ibm.com/docs/Registry?topic=Registry-registry_setup](https://cloud.ibm.com/docs/Registry?topic=Registry-registry_setup)                   |
| Image Pull Secrets                 | [https://cloud.ibm.com/docs/containers?topic=containers-registry](https://cloud.ibm.com/docs/containers?topic=containers-registry)                       |
| Deploying Apps on IKS              | [https://cloud.ibm.com/docs/containers?topic=containers-deploy_app](https://cloud.ibm.com/docs/containers?topic=containers-deploy_app)                   |
| Ingress with ALB                   | [https://cloud.ibm.com/docs/containers?topic=containers-ingress-about](https://cloud.ibm.com/docs/containers?topic=containers-ingress-about)             |
| IBM Cloud Databases for PostgreSQL | [https://cloud.ibm.com/docs/databases-for-postgresql](https://cloud.ibm.com/docs/databases-for-postgresql)                                               |
| IAM Access Roles                   | [https://cloud.ibm.com/docs/containers?topic=containers-access_reference](https://cloud.ibm.com/docs/containers?topic=containers-access_reference)       |
| VPC Network                        | [https://cloud.ibm.com/docs/vpc](https://cloud.ibm.com/docs/vpc)                                                                                         |
| Pricing Calculator                 | [https://cloud.ibm.com/estimator](https://cloud.ibm.com/estimator)                                                                                       |

### 17.2 Project Files Reference

| File                                                                                         | Purpose                                    |
| -------------------------------------------------------------------------------------------- | ------------------------------------------ |
| [`deploy/overlays/ibmcloud/kustomization.yaml`](deploy/overlays/ibmcloud/kustomization.yaml) | Kustomize overlay for IBM Cloud deployment |
| [`deploy/overlays/ibmcloud/ingress-ibm.yaml`](deploy/overlays/ibmcloud/ingress-ibm.yaml)     | IKS Ingress configuration                  |
| [`deploy/overlays/ibmcloud/secret.env.example`](deploy/overlays/ibmcloud/secret.env.example) | Secret template for production             |
| [`deploy/base/deployment.yaml`](deploy/base/deployment.yaml)                                 | Base deployment manifest                   |
| [`deploy/base/service.yaml`](deploy/base/service.yaml)                                       | Base service manifest                      |
| [`deploy/base/ingress.yaml`](deploy/base/ingress.yaml)                                       | Base ingress manifest (Traefik for K3d)    |
| [`tekton/pipeline.yaml`](tekton/pipeline.yaml)                                               | Tekton CI/CD pipeline                      |
| [`Dockerfile`](Dockerfile)                                                                   | Container build definition                 |
| [`Makefile`](Makefile)                                                                       | Build automation targets                   |

### 17.3 Quick Command Reference

```bash
# ── Authentication ──────────────────────────────────────────
ibmcloud login --sso                          # Interactive login
ibmcloud login --apikey @key-file             # Non-interactive login
ibmcloud target -r us-south -g accounts-rg    # Set region + resource group

# ── Container Registry ──────────────────────────────────────
ibmcloud cr login                             # Log in to ICR
ibmcloud cr namespace-add accounts-namespace  # Create namespace
docker push us.icr.io/accounts-namespace/accounts:latest  # Push image
ibmcloud cr image-list                        # List images

# ── Cluster Management ──────────────────────────────────────
ibmcloud ks cluster ls                        # List clusters
ibmcloud ks cluster get -c accounts-cluster   # Get cluster details
ibmcloud ks cluster config -c accounts-cluster # Download kubeconfig
ibmcloud ks worker ls -c accounts-cluster     # List worker nodes

# ── Application Deployment ──────────────────────────────────
kustomize build deploy/overlays/ibmcloud | kubectl apply -f -
kubectl get pods -n accounts-prod -w
kubectl logs -n accounts-prod -l app=accounts
kubectl rollout status deployment/accounts -n accounts-prod

# ── Cleanup ─────────────────────────────────────────────────
ibmcloud ks cluster rm -c accounts-cluster -f
ibmcloud cr image-rm us.icr.io/accounts-namespace/accounts:latest
ibmcloud cr namespace-rm accounts-namespace
```

---

## Appendix A: Makefile Targets for IBM Cloud

Add these targets to the project's [`Makefile`](Makefile) for convenience:

```makefile
.PHONY: login-ibm
login-ibm: ## Log in to IBM Cloud
	ibmcloud login --sso
	ibmcloud target -r us-south -g accounts-rg

.PHONY: login-ibm-ci
login-ibm-ci: ## Log in to IBM Cloud (non-interactive for CI/CD)
	ibmcloud login --apikey @$(IBMCLOUD_API_KEY_FILE)
	ibmcloud target -r us-south -g accounts-rg

.PHONY: build-ibm
build-ibm: ## Build and tag image for IBM Cloud
	docker build --rm --pull --tag accounts:latest .
	docker tag accounts:latest us.icr.io/accounts-namespace/accounts:latest

.PHONY: push-ibm
push-ibm: ## Push image to IBM Cloud Container Registry
	ibmcloud cr login
	docker push us.icr.io/accounts-namespace/accounts:latest

.PHONY: deploy-ibm
deploy-ibm: ## Deploy to IBM Cloud IKS cluster
	kustomize build deploy/overlays/ibmcloud | kubectl apply -f -
	kubectl get pods -n accounts-prod -l app=accounts

.PHONY: cluster-create
cluster-create: ## Create IKS VPC cluster
	ibmcloud ks cluster create vpc-gen2 \
		--name accounts-cluster \
		--zone us-south-1 \
		--flavor bx2.4x16 \
		--workers 1 \
		--vpc-id $(VPC_ID) \
		--subnet-id $(SUBNET_ID) \
		--public-service-endpoint

.PHONY: cluster-config
cluster-config: ## Download cluster kubeconfig
	ibmcloud ks cluster config -c accounts-cluster

.PHONY: cleanup-ibm
cleanup-ibm: ## Delete all IBM Cloud resources
	ibmcloud ks cluster rm -c accounts-cluster -f
	ibmcloud cr image-rm us.icr.io/accounts-namespace/accounts:latest
	ibmcloud cr namespace-rm accounts-namespace
```

---

## Appendix B: Deployment Checklist

Use this checklist when deploying to IBM Cloud:

### Pre-Deployment

- [ ] IBM Cloud billable account is active
- [ ] IAM permissions are configured (Administrator for IKS + Container Registry)
- [ ] CLI tools installed: `ibmcloud`, `kubectl`, `kustomize`, `docker`
- [ ] IBM Cloud CLI plugins installed: `ks`, `cr`
- [ ] Logged in to IBM Cloud: `ibmcloud login --sso`
- [ ] Target region and resource group set
- [ ] VPC and subnet created (for VPC cluster)
- [ ] VRF enabled (for classic cluster)

### Container Registry

- [ ] Namespace created: `ibmcloud cr namespace-add accounts-namespace`
- [ ] Image built and tagged: `docker build -t accounts:latest .`
- [ ] Image tagged for ICR: `docker tag accounts:latest us.icr.io/accounts-namespace/accounts:latest`
- [ ] Image pushed to ICR: `docker push us.icr.io/accounts-namespace/accounts:latest`
- [ ] Image verified: `ibmcloud cr image-list`

### Cluster

- [ ] Cluster created and in `normal` state
- [ ] Cluster kubeconfig downloaded
- [ ] `kubectl get nodes` returns ready nodes
- [ ] Target namespace created: `kubectl create namespace accounts-prod`
- [ ] Image pull secret copied: `all-icr-io` in `accounts-prod` namespace
- [ ] Ingress subdomain noted

### Application

- [ ] Kustomize overlay created at `deploy/overlays/ibmcloud/`
- [ ] `secret.env` created with production `SECRET_KEY`
- [ ] Ingress host set to cluster's Ingress subdomain
- [ ] Application deployed: `kustomize build deploy/overlays/ibmcloud | kubectl apply -f -`
- [ ] All pods in `Running` state
- [ ] Health endpoint responds: `curl <ingress-host>/health`
- [ ] CRUD operations work on `/accounts` endpoint
- [ ] Security headers present
- [ ] CORS headers present

### CI/CD (Optional)

- [ ] Tekton pipeline updated for IBM Cloud overlay
- [ ] IBM Cloud API key secret created in Tekton namespace
- [ ] Docker config secret created for ICR push
- [ ] PipelineRun executes successfully

### Production Readiness

- [ ] TLS certificate configured (Let's Encrypt or IBM Cloud Certificate Manager)
- [ ] Managed PostgreSQL provisioned (not ephemeral)
- [ ] Resource limits and requests set appropriately
- [ ] Horizontal Pod Autoscaler configured
- [ ] Monitoring and alerting set up
- [ ] Budget alerts configured
- [ ] Backup strategy documented

---

## Appendix C: Architecture Decision Record

### ADR-001: VPC vs Classic Cluster

**Decision:** Use VPC-gen2 cluster.

**Rationale:**

- VPC is IBM Cloud's modern networking model ("Secure by Default")
- Built-in private service endpoints without VRF configuration
- Better isolation and security group support
- Recommended by IBM for new deployments

**Trade-offs:**

- Slightly higher cost than classic
- Requires VPC and subnet creation upfront

### ADR-002: Community K8s vs OpenShift (ROKS)

**Decision:** Use Community Kubernetes (IKS) unless OpenShift-specific features are needed.

**Rationale:**

- Lower cost (no OpenShift licensing overhead)
- Simpler learning curve
- Existing manifests are standard Kubernetes (not OpenShift-specific)
- The existing `route.yaml` (OpenShift Route) would need to be replaced with standard Ingress

**Trade-offs:**

- No OpenShift Routes (use standard Ingress with NGINX ALB)
- No OpenShift Builds (use Tekton Buildah instead)
- No OpenShift Web Console (use Kubernetes Dashboard)

### ADR-003: Managed PostgreSQL vs Ephemeral

**Decision:** Use ephemeral PostgreSQL for development, managed PostgreSQL for production.

**Rationale:**

- Ephemeral: Zero additional cost, simple setup, data loss on pod restart
- Managed: Persistent storage, automated backups, high availability, SSL enforcement

**Trade-offs:**

- Managed PostgreSQL adds ~$25–$50/month
- Ephemeral requires PVC for some persistence but still risky

### ADR-004: Ingress via IKS ALB vs Custom Ingress Controller

**Decision:** Use IKS managed NGINX ALB.

**Rationale:**

- Zero maintenance (IBM manages the ALB)
- Automatically provisioned with the cluster
- Supports TLS termination
- Standard Kubernetes Ingress API

**Trade-offs:**

- Less control over NGINX configuration
- Limited to features supported by IKS ALB

---

_End of Document_
