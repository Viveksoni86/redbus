#!/usr/bin/env bash
set -euo pipefail

# Simple helper to build and push backend/frontend images to ECR.
# Usage: AWS_ACCOUNT_ID=... AWS_REGION=... ./build_and_push.sh

AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-}
AWS_REGION=${AWS_REGION:-ap-south-1}

if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "Please set AWS_ACCOUNT_ID environment variable"
  exit 1
fi

ECR_BACKEND_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/redbus-backend"
ECR_FRONTEND_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/redbus-frontend"

echo "Logging into ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Building backend image..."
docker build --no-cache -t "${ECR_BACKEND_REPOSITORY}:latest" ./back-end-redbus
echo "Pushing backend image..."
docker push "${ECR_BACKEND_REPOSITORY}:latest"

echo "Building frontend image..."
# If REACT_APP_BACKEND_URL is set, pass it as a build-arg
FRONTEND_BUILD_ARG=""
if [ ! -z "${REACT_APP_BACKEND_URL:-}" ]; then
  FRONTEND_BUILD_ARG="--build-arg REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}"
fi
docker build --no-cache ${FRONTEND_BUILD_ARG} -t "${ECR_FRONTEND_REPOSITORY}:latest" ./front-end-redbus
echo "Pushing frontend image..."
docker push "${ECR_FRONTEND_REPOSITORY}:latest"

echo "Build and push complete."
