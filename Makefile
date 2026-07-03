.PHONY: all help install venv run git-clone deploy deploy-oc login-ibm login-ibm-ci build-ibm push-ibm deploy-ibm cluster-create-ibm cluster-config-ibm cleanup-ibm

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-\\.]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

all: help

.PHONY: cluster
cluster: ## Create a Kubernetes cluster
	$(info Creating Kubernetes cluster with a registry...)
	k3d cluster create --registry-create cluster-registry:0.0.0.0:32000 --port '8080:80@loadbalancer'

.PHONY: tekton
tekton: ## Install Tekton into cluster
	$(info Installing Tekton in the Cluster...)
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
	kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

.PHONY: clustertasks
clustertasks: ## Create Tekton Cluster Tasks
	$(info Creating Tekton Cluster Tasks...)
	wget -qO - https://raw.githubusercontent.com/tektoncd/catalog/main/task/openshift-client/0.2/openshift-client.yaml | sed 's/kind: Task/kind: ClusterTask/g' | kubectl create -f -
	wget -qO - https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildah/0.4/buildah.yaml | sed 's/kind: Task/kind: ClusterTask/g' | kubectl create -f -

.PHONY: git-clone
git-clone: ## Install git-clone Tekton Task
	$(info Installing git-clone task...)
	kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.8/git-clone.yaml

.PHONY: build
build: ## Build a Docker image
	$(info Building Docker image...)
	docker build --rm --pull --tag accounts:1.0 . 

.PHONY: push
push: ## Push image to K3d registry
	$(info Pushing Docker image to K3D registry...)
	docker tag accounts:1.0 localhost:32000/accounts:1.0
	docker push localhost:32000/accounts:1.0

venv: ## Create a Python virtual environment
	$(info Creating Python 3 virtual environment...)
	python3 -m venv ~/venv

install: ## Install Python dependencies
	$(info Installing dependencies...)
	python3 -m pip install --upgrade pip wheel
	pip install -r requirements.txt

lint: ## Run the linter
	$(info Running linting...)
	flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 . --count --max-complexity=10 --max-line-length=127 --statistics

.PHONY: tests
tests: ## Run the unit tests
	$(info Running tests...)
	nosetests -vv --with-spec --spec-color --with-coverage --cover-package=service

run: ## Run the service
	$(info Starting service...)
	honcho start

dbrm: ## Stop and remove PostgreSQL in Docker
	$(info Stopping and removing PostgreSQL...)
	docker stop postgres
	docker rm postgres

db: ## Run PostgreSQL in Docker
	$(info Running PostgreSQL...)
	docker run -d --name postgresql \
		-p 5432:5432 \
		-e POSTGRES_PASSWORD=postgres \
		-v postgresql:/var/lib/postgresql/data \
		postgres:alpine

.PHONY: deploy
deploy: ## Deploy to K3d cluster
	$(info Deploying to K3d cluster...)
	kustomize build deploy/overlays/k3d | kubectl apply -f -
	kubectl get pods -l app=accounts

.PHONY: deploy-oc
deploy-oc: ## Deploy to OpenShift cluster
	$(info Deploying to OpenShift cluster...)
	kustomize build deploy/overlays/openshift | oc apply -f -

##@ IBM Cloud

.PHONY: login-ibm
login-ibm: ## Log in to IBM Cloud (interactive)
	$(info Logging in to IBM Cloud...)
	ibmcloud login --sso
	ibmcloud target -r us-south -g accounts-rg

.PHONY: login-ibm-ci
login-ibm-ci: ## Log in to IBM Cloud (non-interactive for CI/CD)
	$(info Logging in to IBM Cloud with API key...)
	ibmcloud login --apikey @$(IBMCLOUD_API_KEY_FILE)
	ibmcloud target -r us-south -g accounts-rg

.PHONY: build-ibm
build-ibm: ## Build and tag image for IBM Cloud Container Registry
	$(info Building and tagging image for IBM Cloud...)
	docker build --rm --pull --tag accounts:latest .
	docker tag accounts:latest us.icr.io/accounts-namespace/accounts:latest

.PHONY: push-ibm
push-ibm: ## Push image to IBM Cloud Container Registry
	$(info Pushing image to IBM Cloud Container Registry...)
	ibmcloud cr login
	docker push us.icr.io/accounts-namespace/accounts:latest

.PHONY: deploy-ibm
deploy-ibm: ## Deploy to IBM Cloud IKS cluster
	$(info Deploying to IBM Cloud IKS cluster...)
	kustomize build deploy/overlays/ibmcloud | kubectl apply -f -
	kubectl get pods -n accounts-prod -l app=accounts

.PHONY: cluster-create-ibm
cluster-create-ibm: ## Create IKS VPC cluster (requires VPC_ID and SUBNET_ID env vars)
	$(info Creating IKS VPC cluster...)
	ibmcloud ks cluster create vpc-gen2 \
		--name accounts-cluster \
		--zone us-south-1 \
		--flavor bx2.4x16 \
		--workers 1 \
		--vpc-id $(VPC_ID) \
		--subnet-id $(SUBNET_ID) \
		--public-service-endpoint

.PHONY: cluster-config-ibm
cluster-config-ibm: ## Download IBM Cloud cluster kubeconfig
	$(info Downloading cluster kubeconfig...)
	ibmcloud ks cluster config -c accounts-cluster

.PHONY: cleanup-ibm
cleanup-ibm: ## Delete all IBM Cloud resources (cluster, images, namespace)
	$(info Cleaning up IBM Cloud resources...)
	ibmcloud ks cluster rm -c accounts-cluster -f
	ibmcloud cr image-rm us.icr.io/accounts-namespace/accounts:latest
	ibmcloud cr namespace-rm accounts-namespace
