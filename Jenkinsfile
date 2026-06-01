pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = "740349584703"
        AWS_REGION     = "ap-south-1"

        ECR_BACKEND_REPOSITORY  = "740349584703.dkr.ecr.ap-south-1.amazonaws.com/redbus-backend"
        ECR_FRONTEND_REPOSITORY = "740349584703.dkr.ecr.ap-south-1.amazonaws.com/redbus-frontend"

        CLUSTER_NAME = "redbus-eks-cluster"
    }

    stages {

        stage('Checkout') {
            steps {
                // Pull the repo for this build. (Do NOT deleteDir() here - that
                // would wipe the checkout that every later stage depends on.)
                checkout scm
                script {
                    // One unique tag reused by every stage: git sha + build number + timestamp.
                    env.IMAGE_TAG = sh(
                        returnStdout: true,
                        script: 'echo "$(git rev-parse --short HEAD 2>/dev/null || echo no-git)-${BUILD_NUMBER}-$(date +%s)"'
                    ).trim()
                    echo "Image tag for this build: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Initialize & Authenticate') {
            steps {
                script {
                    sh 'aws --version'
                    sh 'docker --version'
                    sh 'kubectl version --client'

                    sh """
                    aws eks update-kubeconfig \
                    --region ${AWS_REGION} \
                    --name ${CLUSTER_NAME}
                    """

                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS \
                    --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Build & Push Images') {
            steps {
                script {
                    // Backend
                    sh """
                    docker build --no-cache -t ${ECR_BACKEND_REPOSITORY}:${env.IMAGE_TAG} ./back-end-redbus
                    docker push ${ECR_BACKEND_REPOSITORY}:${env.IMAGE_TAG}
                    """

                    // Frontend talks to the backend through nginx using relative
                    // /v1/api URLs, so no backend URL needs to be baked in at build time.
                    sh """
                    docker build --no-cache -t ${ECR_FRONTEND_REPOSITORY}:${env.IMAGE_TAG} ./front-end-redbus
                    docker push ${ECR_FRONTEND_REPOSITORY}:${env.IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh 'kubectl apply -f kubernetes/secrets.yaml'
                    sh 'kubectl apply -f kubernetes/backend-service.yaml'

                    // Substitute the ECR repo + image tag placeholders in the manifests.
                    // Groovy interpolates the real values; \\\$ keeps the literal
                    // ${...} text that sed matches in the YAML.
                    sh """
                    sed -i 's|\\\${ECR_BACKEND_REPOSITORY}|${ECR_BACKEND_REPOSITORY}|g; s|\\\${IMAGE_TAG}|${env.IMAGE_TAG}|g' kubernetes/backend-deployment.yaml
                    sed -i 's|\\\${ECR_FRONTEND_REPOSITORY}|${ECR_FRONTEND_REPOSITORY}|g; s|\\\${IMAGE_TAG}|${env.IMAGE_TAG}|g' kubernetes/frontend-deployment.yaml
                    """

                    sh 'kubectl apply -f kubernetes/backend-deployment.yaml'
                    sh 'kubectl apply -f kubernetes/frontend-deployment.yaml'
                    sh 'kubectl apply -f kubernetes/frontend-service.yaml'

                    sh 'kubectl rollout status deployment/redbus-backend --timeout=180s'
                    sh 'kubectl rollout status deployment/redbus-frontend --timeout=180s'

                    sh 'kubectl get svc'
                }
            }
        }

        stage('Deploy Monitoring') {
            steps {
                script {
                    sh 'kubectl apply -f kubernetes/monitoring/namespace.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/prometheus-configmap.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/prometheus-rbac.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/prometheus-deployment.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/prometheus-service.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/grafana-datasource-configmap.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/grafana-deployment.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/grafana-service.yaml'
                    sh 'kubectl rollout status deployment/prometheus-deployment -n monitoring --timeout=180s || true'
                    sh 'kubectl rollout status deployment/grafana-deployment -n monitoring --timeout=180s || true'
                }
            }
        }
    }

    post {
        success {
            echo "Deployment Successful"

            sh '''
            FRONTEND_DNS=$(kubectl get svc redbus-frontend \
            -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

            echo "====================================="
            echo "APP LIVE:"
            echo "http://$FRONTEND_DNS"
            echo "====================================="
            '''
        }

        failure {
            echo "Pipeline Failed"
        }
    }
}
