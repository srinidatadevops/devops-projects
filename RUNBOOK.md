# Observability Runbook

For this service I would alert on user impact first, then infrastructure pressure. I would page on HTTP 5xx rate above 2% for 5 minutes, and treat anything above 5% for 10 minutes as a serious outage. I would also watch p95 latency above 750 ms, pod restarts, CPU above 80%, memory above 85%, and RDS pressure such as high CPU, low storage, or connection usage close to the limit.

If `/items` starts returning 503s at 2 AM, I first check whether the issue is only on that endpoint or across the whole service. I would look at ingress logs and metrics for upstream errors, response time, and healthy endpoints. Then I would check the deployment with `kubectl get pods`, `kubectl describe deployment items-api`, and `kubectl rollout status`. If there was a recent deploy, I would compare the failure time with the rollout and be ready to roll back.

If pods are restarting, I would check `kubectl logs --previous` for startup errors, database connection failures, memory issues, or dependency timeouts. If the pods look healthy but readiness is failing, I would call `/health` through port-forwarding and compare that with the ingress path. If the database is unreachable, I would check the Secret value, RDS endpoint, security groups, RDS events, connection count, CPU, and storage.

For tooling, I would start with CloudWatch, EKS control-plane logs, Container Insights, and structured app logs. It is native to AWS and simple enough for an early-stage team. Prometheus and Grafana would be the next step once the service has custom metrics and clearer SLOs. I would hold off on Datadog unless the team wants faster setup and is comfortable with the cost.
