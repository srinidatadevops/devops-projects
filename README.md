# Production Infrastructure Challenge

This repo is my take-home submission for moving a small FastAPI service toward production on AWS.

No real AWS credentials, kubeconfigs, database passwords, or production secrets are committed here.

## What is included

- `app/`: FastAPI service with `/health` and `/items`
- `app/Dockerfile`: multi-stage image build running as a non-root user
- `app/docker-compose.yml`: local app and Postgres setup
- `terraform/`: AWS infrastructure split into small modules
- `k8s/`: Kubernetes manifests for EKS
- `.github/workflows/deploy.yml`: CI, image scan, ECR push, and EKS rollout
- `RUNBOOK.md`: observability and incident response notes

## Architecture

The AWS layer creates a VPC across two Availability Zones with public and private subnets. The EKS node group runs in private subnets, and RDS Postgres is private as well. The database security group only allows Postgres traffic from the EKS cluster security group.

The app image is pushed to ECR and deployed to EKS with two replicas. Kubernetes handles rolling updates, probes, service discovery, ingress, resource limits, and CPU-based autoscaling. The pod uses an IRSA role scoped to the application S3 bucket.

I used one NAT gateway to keep the baseline cost low. The tradeoff is that it is less resilient than one NAT gateway per AZ. If this service had strict availability needs, I would either add one NAT gateway per AZ or add VPC endpoints for AWS services to reduce NAT dependency.

## Local app

```bash
cd app
docker compose up --build
```

```bash
curl http://localhost:8000/health
curl http://localhost:8000/items
```

To run tests locally:

```bash
cd app
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
ruff check .
pytest
```

## Terraform

Create or choose an S3 bucket and DynamoDB table for Terraform state, then copy the example files.

```bash
cd terraform
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
```

Update `backend.hcl` and `terraform.tfvars` with real values. Use a new database password and keep it out of Git.

```bash
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
```

The useful outputs after apply are:

```bash
terraform output ecr_repository_url
terraform output app_pod_role_arn
terraform output kubeconfig_command
```

## Kubernetes

Before applying to a real cluster, replace these placeholder values:

- `k8s/service-account.yaml`: IRSA role ARN from `terraform output app_pod_role_arn`
- `k8s/secret.yaml`: database connection string
- `k8s/deployment.yaml`: ECR image URL
- `k8s/ingress.yaml`: real hostname

For production, I would not keep database credentials in a plain Kubernetes Secret file. I would use AWS Secrets Manager with External Secrets Operator, or Sealed Secrets if the team wants GitOps-style encrypted manifests.

## CI/CD

The GitHub Actions workflow runs on pushes to `main`.

It does the following:

- installs dependencies
- runs Ruff and Pytest
- builds the Docker image
- scans the image with Trivy and fails on critical vulnerabilities
- pushes the image to ECR with the git SHA as the tag
- deploys to EKS with `kubectl`
- waits for rollout success

Repository or environment secrets needed:

- `AWS_GITHUB_ACTIONS_ROLE_ARN`
- `KUBECONFIG`
- `APP_POD_ROLE_ARN`

The deploy job uses the `production` GitHub Environment. If reviewers are configured on that environment, the workflow becomes a manual approval gate before production rollout.

## Tradeoffs

I kept the setup focused on the core production path: infrastructure, image build, Kubernetes deployment, CI/CD, and a runbook. The next pieces I would add are Helm or Kustomize overlays, External Secrets for database credentials, cert-manager for TLS, metrics-server during cluster bootstrap, and application metrics.
