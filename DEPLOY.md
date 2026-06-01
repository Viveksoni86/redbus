Deployment guide — Docker Compose (local) + Jenkins + EKS + Monitoring

Architecture note
- The React frontend calls the API with relative URLs (`/v1/api/...`).
- The frontend's nginx proxies `/v1/api/` to the backend, so no backend URL is
  baked into the build. The backend host is set via the `BACKEND_HOST` env var
  (`backend` in docker-compose, `redbus-backend` in Kubernetes).
- The backend listens on `PORT` (set to `5000` in compose and the k8s deployment).

## Option A — Run locally with Docker Compose

```bash
docker compose up --build
```

- Frontend: http://localhost:3001
- Backend API: http://localhost:5000/v1/api/routes (also proxied at http://localhost:3001/v1/api/routes)

The Mongo connection string lives in `back-end-redbus/config.env`.

## Option B — Deploy to EKS (Jenkins)

Prerequisites
- `aws`, `docker`, and `kubectl` installed and configured.
- IAM credentials with ECR and EKS access available to Jenkins.
- An EKS cluster and ECR repositories created (or let Jenkins create them).

The provided `Jenkinsfile` checks out the repo, builds & pushes both images to
ECR with a unique tag, substitutes the `${ECR_*_REPOSITORY}` and `${IMAGE_TAG}`
placeholders in the manifests, and applies them to the cluster.

### Manual steps (equivalent to the pipeline)

1. Point kubeconfig at your cluster:

```bash
aws eks update-kubeconfig --region <AWS_REGION> --name <CLUSTER_NAME>
```

2. Apply secrets and the backend (internal) service:

```bash
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/backend-service.yaml
```

3. Build & push images (locally or via Jenkins):

```bash
AWS_ACCOUNT_ID=... AWS_REGION=ap-south-1 ./scripts/build_and_push.sh
```

4. Render image placeholders and deploy. `${IMAGE_TAG}` is the tag you pushed:

```bash
export ECR_BACKEND_REPOSITORY=...dkr.ecr...amazonaws.com/redbus-backend
export ECR_FRONTEND_REPOSITORY=...dkr.ecr...amazonaws.com/redbus-frontend
export IMAGE_TAG=<the tag you pushed>

sed -i "s|\${ECR_BACKEND_REPOSITORY}|$ECR_BACKEND_REPOSITORY|g; s|\${IMAGE_TAG}|$IMAGE_TAG|g" kubernetes/backend-deployment.yaml
sed -i "s|\${ECR_FRONTEND_REPOSITORY}|$ECR_FRONTEND_REPOSITORY|g; s|\${IMAGE_TAG}|$IMAGE_TAG|g" kubernetes/frontend-deployment.yaml

kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/frontend-service.yaml
```

5. Deploy monitoring (Prometheus + Grafana):

```bash
kubectl apply -f kubernetes/monitoring/namespace.yaml
kubectl apply -f kubernetes/monitoring/
```

The only externally exposed service is `redbus-frontend` (LoadBalancer); the
backend is `ClusterIP` and reached internally through the frontend proxy.

## Validate locally with kind (no AWS needed)

```bash
kind create cluster --name redbus-test
docker compose build
docker tag redbus-backend:latest redbus-backend:local-test
docker tag redbus-frontend:latest redbus-frontend:local-test
kind load docker-image redbus-backend:local-test redbus-frontend:local-test --name redbus-test
# substitute placeholders with redbus-backend / redbus-frontend / local-test and apply
```

## Rollback

```bash
kubectl rollout undo deployment/redbus-backend
kubectl rollout undo deployment/redbus-frontend
```

## Troubleshooting

```bash
kubectl get pods,svc,deploy -A
kubectl describe deploy redbus-backend
kubectl logs deploy/redbus-backend -c backend
```
