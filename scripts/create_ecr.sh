#!/usr/bin/env bash
set -euo pipefail

# Create ECR repositories for backend and frontend if they don't exist
# Usage: AWS_ACCOUNT_ID=... AWS_REGION=... ./create_ecr.sh

AWS_REGION=${AWS_REGION:-ap-south-1}
BACKEND_REPO_NAME=redbus-backend
FRONTEND_REPO_NAME=redbus-frontend

echo "Using AWS region: ${AWS_REGION}"

for repo in ${BACKEND_REPO_NAME} ${FRONTEND_REPO_NAME}; do
  echo "Checking repository: $repo"
  if aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "Repository $repo already exists"
  else
    echo "Creating repository $repo"
    aws ecr create-repository --repository-name "$repo" --region "$AWS_REGION" >/dev/null
    echo "Repository $repo created"
  fi
done

echo "ECR repositories ensured."
