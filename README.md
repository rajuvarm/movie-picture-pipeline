# Movie Picture Pipeline

This repository contains the CI/CD pipelines and infrastructure code for the Movie Picture web application. The application consists of a React frontend and a Flask backend, both running as containerized services deployed to an Amazon EKS cluster.

## Architecture

* **Frontend**: React application (JavaScript/TypeScript) served via Nginx.
* **Backend**: Python Flask REST API serving the movie catalog.
* **CI/CD**: GitHub Actions automating linting, testing, Docker container builds, ECR image publishing, and EKS deployments using Kustomize.
* **Infrastructure**: AWS VPC, Amazon EKS, Amazon ECR, and IAM resources provisioned via Terraform.

## Repository Layout

```text
.
├── .github/
│   └── workflows/
│       ├── frontend-ci.yaml     # Frontend pull request pipeline (lint, test, build)
│       ├── frontend-cd.yaml     # Frontend continuous deployment pipeline (ECR & EKS)
│       ├── backend-ci.yaml      # Backend pull request pipeline (lint, test, build)
│       └── backend-cd.yaml      # Backend continuous deployment pipeline (ECR & EKS)
├── starter/
│   ├── frontend/                # React application source code, Dockerfile & K8s manifests
│   │   ├── src/
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   ├── package.json
│   │   └── k8s/
│   └── backend/                 # Flask application source code, Dockerfile & K8s manifests
│       ├── movies/
│       ├── test_app.py
│       ├── Pipfile
│       ├── setup.cfg
│       ├── Dockerfile
│       └── k8s/
├── setup/
│   ├── init.sh                  # Script to add GitHub Actions IAM user to EKS aws-auth
│   └── terraform/               # Terraform manifests for AWS resources
├── .gitignore
└── README.md
```

## Workflows

### Frontend Workflows
1. **Continuous Integration (`frontend-ci.yaml`)**
   * Triggered on pull requests to `main` modifying `starter/frontend/**`, and can be triggered manually via `workflow_dispatch`.
   * Runs `lint` and `test` jobs concurrently in parallel.
   * Runs the `build` job only after both `lint` and `test` pass (`needs: [lint, test]`).
   * Builds the Docker image passing `REACT_APP_MOVIE_API_URL` as a build argument using an environment variable.

2. **Continuous Deployment (`frontend-cd.yaml`)**
   * Triggered on push to `main` modifying `starter/frontend/**`, and can be triggered manually via `workflow_dispatch`.
   * Runs tests and lint checks before building.
   * Tags the Docker image with the commit SHA (`${{ github.sha }}`) and pushes to Amazon ECR.
   * Uses Kustomize (`kustomize edit set image`) to update the Kubernetes manifest and applies it to the EKS cluster.

### Backend Workflows
1. **Continuous Integration (`backend-ci.yaml`)**
   * Triggered on pull requests to `main` modifying `starter/backend/**`, and can be triggered manually via `workflow_dispatch`.
   * Runs `lint` (`pipenv run lint`) and `test` (`pipenv run test`) in parallel.
   * Runs the Docker build job only when both `lint` and `test` pass (`needs: [lint, test]`).

2. **Continuous Deployment (`backend-cd.yaml`)**
   * Triggered on push to `main` modifying `starter/backend/**`, and can be triggered manually via `workflow_dispatch`.
   * Tags the Docker image with the Git commit SHA (`${{ github.sha }}`) and pushes to Amazon ECR.
   * Updates the backend deployment image via Kustomize and applies the manifest to the cluster.

## Local Development and Verification

### Frontend
```bash
cd starter/frontend

# Install dependencies
npm ci

# Run unit tests
CI=true npm test

# Run linter
npm run lint

# Simulate test failure
FAIL_TEST=true CI=true npm test

# Build and run Docker container locally
docker build --build-arg REACT_APP_MOVIE_API_URL=http://localhost:5000 --tag mp-frontend:latest .
docker run --name mp-frontend -p 3000:3000 -d mp-frontend
```

### Backend
```bash
cd starter/backend

# Install dependencies
pipenv install --dev

# Run tests
pipenv run test

# Run linter
pipenv run lint

# Simulate test failure
FAIL_TEST=true pipenv run test

# Build and run Docker container locally
docker build --tag mp-backend:latest .
docker run -p 5000:5000 --name mp-backend -d mp-backend
curl http://localhost:5000/movies/
```

## Deployment Setup

### 1. Provision AWS Infrastructure
```bash
cd setup/terraform
terraform init
terraform apply
```

### 2. Configure GitHub Secrets
In your GitHub repository, navigate to **Settings > Secrets and variables > Actions** and configure:
* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

### 3. Grant IAM User Access to Kubernetes
Run the setup helper script to add the IAM user ARN to the Kubernetes aws-auth mapping:
```bash
cd setup
./init.sh
```

### 4. Teardown
Once testing is finished, destroy the AWS resources to avoid unnecessary costs:
```bash
cd setup/terraform
terraform destroy
```
