pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    environment {
        AWS_ACCOUNT_ID = "740349584703"
        AWS_REGION     = "ap-south-1"
        CLUSTER_NAME   = "redbus-eks-cluster"

        ECR_BACKEND_REPOSITORY  = "740349584703.dkr.ecr.ap-south-1.amazonaws.com/redbus-backend"
        ECR_FRONTEND_REPOSITORY = "740349584703.dkr.ecr.ap-south-1.amazonaws.com/redbus-frontend"
    }

    stages {

        stage('Checkout') {
            steps {
                deleteDir()
                git branch: 'main', url: 'https://github.com/Viveksoni86/redbus.git'
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

        stage('Deploy Secrets & Backend Service') {
            steps {
                script {
                    sh 'kubectl apply -f kubernetes/secrets.yaml || true'
                    sh 'kubectl apply -f kubernetes/backend-service.yaml'

                    sh '''
                    for i in {1..30}; do
                        BACKEND_URL=$(kubectl get svc redbus-backend \
                        -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2>/dev/null || true)

                        if [ ! -z "$BACKEND_URL" ]; then
                            echo "http://$BACKEND_URL:5000" > backend_url.txt
                            echo "Backend Ready: $BACKEND_URL"
                            break
                        fi

                        echo "Waiting for LoadBalancer..."
                        sleep 10
                    done

                    if [ ! -f backend_url.txt ]; then
                        echo "Backend URL not generated"
                        exit 1
                    fi
                    '''
                }
            }
        }

        stage('Build & Push Backend') {
            steps {
                script {

                    sh '''
                    GIT_SHA=$(git rev-parse --short HEAD)
                    IMAGE_TAG="${GIT_SHA}-${BUILD_NUMBER}-$(date +%s)"
                    echo $IMAGE_TAG > image_tag.txt

                    docker build --no-cache --progress=plain \
                    -t ${ECR_BACKEND_REPOSITORY}:$IMAGE_TAG \
                    ./back-end-redbus

                    docker push ${ECR_BACKEND_REPOSITORY}:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                script {

                    def backendUrl = sh(script: "cat backend_url.txt", returnStdout: true).trim()
                    def imageTag = sh(script: "cat image_tag.txt", returnStdout: true).trim()

                    sh """
                    docker build --no-cache --progress=plain \
                    --build-arg REACT_APP_BACKEND_URL=${backendUrl} \
                    -t ${ECR_FRONTEND_REPOSITORY}:${imageTag} \
                    ./front-end-redbus

                    docker push ${ECR_FRONTEND_REPOSITORY}:${imageTag}
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {

                    def imageTag = sh(script: "cat image_tag.txt", returnStdout: true).trim()

                    sh """
                    sed -i 's|\\${ECR_BACKEND_REPOSITORY}|${ECR_BACKEND_REPOSITORY}|g' kubernetes/backend-deployment.yaml
                    sed -i 's|\\${ECR_FRONTEND_REPOSITORY}|${ECR_FRONTEND_REPOSITORY}|g' kubernetes/frontend-deployment.yaml

                    sed -i 's|\\${IMAGE_TAG}|${imageTag}|g' kubernetes/backend-deployment.yaml
                    sed -i 's|\\${IMAGE_TAG}|${imageTag}|g' kubernetes/frontend-deployment.yaml
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
                    sh 'kubectl apply -f kubernetes/monitoring/prometheus-deployment.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/prometheus-rbac.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/prometheus-service.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/grafana-datasource-configmap.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/grafana-deployment.yaml'
                    sh 'kubectl apply -f kubernetes/monitoring/grafana-service.yaml'

                    sh 'kubectl rollout status deployment/prometheus -n monitoring --timeout=180s || true'
                    sh 'kubectl rollout status deployment/grafana -n monitoring --timeout=180s || true'
                }
            }
        }
    }

    post {
        success {
            echo "Deployment Successful 🚀"

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
            echo "Pipeline Failed ❌"
        }
    }
}
