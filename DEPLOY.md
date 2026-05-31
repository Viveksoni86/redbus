Deployment guide — Jenkins + EKS + Monitoring

Prerequisites
- `aws`, `docker`, and `kubectl` installed and configured.
- IAM credentials with ECR and EKS access available to Jenkins.
- An EKS cluster and ECR repositories created (or let Jenkins create them).

Quick steps (manual)

1. Ensure kubeconfig is pointed at your cluster:

```bash
aws eks update-kubeconfig --region <AWS_REGION> --name <CLUSTER_NAME>
```

2. Apply secrets and services:

```bash
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/backend-service.yaml
kubectl apply -f kubernetes/frontend-service.yaml
```

3. Build & push images (locally or via Jenkins):

```bash
cd redbus-master
AWS_ACCOUNT_ID=... AWS_REGION=ap-south-1 ./scripts/build_and_push.sh
```

4. Let Jenkins run the provided `Jenkinsfile` (it will replace image placeholders and deploy to EKS).

5. Deploy monitoring (Prometheus + Grafana):

```bash
kubectl apply -f kubernetes/monitoring/namespace.yaml
kubectl apply -f kubernetes/monitoring/
```

Rollback basics
- To roll back a deployment to the previous revision:

```bash
kubectl rollout undo deployment/redbus-backend
kubectl rollout undo deployment/redbus-frontend
```

Troubleshooting
- Check kube resources:

```bash
kubectl get pods,svc,deploy -A
kubectl describe deploy redbus-backend
kubectl logs deploy/redbus-backend -c backend
```

Next actions for me (if you want): create ECR repos, configure Jenkins credentials, or run a dry-run of the pipeline.
