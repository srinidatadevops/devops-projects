# Engineering Decisions

This exercise is built around a small FastAPI service moving from a local setup to a production-style AWS deployment. I kept the design practical for an early-stage team: enough structure to be maintainable, but not so much that the first version becomes heavy to operate.

## Infrastructure

I used Terraform and split the AWS resources into small modules for VPC, EKS, RDS, S3, ECR, and IAM. The goal was to make the layout easy to review and change without putting every resource in one large file.

The VPC uses public and private subnets across two Availability Zones. EKS worker nodes and RDS run in private subnets. The database security group only allows Postgres traffic from the EKS cluster security group, which keeps the database away from public access.

I used a single NAT gateway to keep the baseline cost lower. The tradeoff is reduced availability compared with one NAT gateway per AZ. For a stricter production setup, I would add one NAT gateway per AZ or add VPC endpoints for AWS services such as S3, ECR, CloudWatch Logs, and STS.

## Kubernetes

The Kubernetes manifests use two replicas, rolling updates, readiness and liveness probes, resource requests and limits, a ClusterIP service, NGINX ingress, and an HPA targeting 70% CPU. This gives the service a basic production shape without adding Helm or a GitOps layer too early.

I included IRSA for the application pod instead of giving broad permissions to nodes. The pod role is scoped to the application S3 bucket. For database credentials, the repo contains only a placeholder Kubernetes Secret. In production, I would use AWS Secrets Manager with External Secrets Operator or Sealed Secrets.

## Container

The Dockerfile uses a multi-stage build, runs as a non-root user, and does not bake in secrets. The final image is small enough for the assignment target and keeps runtime dependencies separate from local test tooling.

The compose file is only for local development. It runs the app with a Postgres container so the service can be tested without touching AWS.

## CI/CD

The GitHub Actions workflow runs lint, tests, image build, Trivy scanning, ECR push, and EKS rollout. Images are tagged with the git SHA so each deployment points to a specific build.

I used GitHub Environment support for the production deploy job. That allows a manual approval gate without adding a separate deployment tool.

## Observability

The runbook focuses on user-facing symptoms first: 5xx rate and latency. It also covers pod restarts, CPU, memory, and RDS pressure because those are the most likely places this small service would fail early.

For tooling, I chose CloudWatch, EKS control-plane logs, Container Insights, and structured application logs as the starting point. Prometheus and Grafana would make sense once the service has custom metrics and clearer SLOs. Datadog is useful, but I would only choose it early if the team wants the faster setup and accepts the extra cost.

## What I would change next

The next changes I would make are environment overlays with Helm or Kustomize, External Secrets for database credentials, cert-manager for TLS, metrics-server as part of cluster bootstrap, and application-level metrics.
