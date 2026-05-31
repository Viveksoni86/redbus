Jenkins setup for Redbus pipeline

1) Prerequisites on Jenkins master/agent
- Install `docker`, `awscli`, and `kubectl` on the Jenkins agent that runs the pipeline.
- Install the Jenkins plugins: `Pipeline`, `Credentials`, `Git`, `Job DSL`.

2) Create credentials
- Add AWS credentials as a Jenkins credential (kind: "Username with password" or better use AWS Credential plugin). Give it ID `aws-creds`.
- Add Git credentials and set its ID where `'<GIT_CREDENTIALS_ID>'` exists in `seed_job.groovy`.

3) Seed the pipeline job
- Create a seed job (Freestyle) that runs the Job DSL script `seed_job.groovy` (set the DSL lookup to this script). Replace `<GIT_REPO_URL>` and `<GIT_CREDENTIALS_ID>` before seeding.

4) Configure job environment variables
- In the pipeline job, set environment variables or use Jenkins global environment for:
  - `AWS_ACCOUNT_ID`
  - `AWS_REGION` (default `ap-south-1`)
  - `CLUSTER_NAME`

5) Run the pipeline
- The pipeline will:
  - Apply `kubernetes/secrets.yaml` and services
  - Create an `IMAGE_TAG`, build backend and frontend images, push to ECR
  - Substitute the `ECR_*` and `IMAGE_TAG` placeholders in k8s manifests and apply them
  - Deploy Prometheus & Grafana

6) Notes
- Ensure the Jenkins agent has permission to access EKS and ECR (AWS IAM). Use instance role or IAM user keys stored in Jenkins credentials.
- Replace placeholders in `seed_job.groovy` before running the seed job.
