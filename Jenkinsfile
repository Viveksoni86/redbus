pipeline {
    agent any

<<<<<<< HEAD
    environment {
        AWS_ACCOUNT_ID = "740349584703"
        AWS_REGION     = "ap-south-1"

        ECR_BACKEND_REPOSITORY  = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/redbus-backend"
        ECR_FRONTEND_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/redbus-frontend"

        CLUSTER_NAME = "redbus-eks-cluster"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
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

                    sh 'kubectl apply -f kubernetes/secrets.yaml'
                    sh 'kubectl apply -f kubernetes/backend-service.yaml'

                    sh '''
                    BACKEND_URL=""

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
pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = "740349584703"
        AWS_REGION     = "ap-south-1"

        ECR_BACKEND_REPOSITORY  = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/redbus-backend"
        ECR_FRONTEND_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/redbus-frontend"

        CLUSTER_NAME = "redbus-eks-cluster"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
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

                    sh 'kubectl apply -f kubernetes/secrets.yaml'
                    sh 'kubectl apply -f kubernetes/backend-service.yaml'

                    sh '''
                    BACKEND_URL=""

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

                    sh """
                    docker build --no-cache \
                    -t ${ECR_BACKEND_REPOSITORY}:latest \
                    ./back-end-redbus
                    """

                    sh "docker push ${ECR_BACKEND_REPOSITORY}:latest"
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                script {

                    def backendUrl = readFile('backend_url.txt').trim()

                    sh """
                    docker build --no-cache \
                    --build-arg REACT_APP_BACKEND_URL=${backendUrl} \
                    -t ${ECR_FRONTEND_REPOSITORY}:latest \
                    ./front-end-redbus
                    """

                    sh "docker push ${ECR_FRONTEND_REPOSITORY}:latest"
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {

                    sh """
                    sed -i 's|\\${ECR_BACKEND_REPOSITORY}|${ECR_BACKEND_REPOSITORY}|g' kubernetes/backend-deployment.yaml
                    sed -i 's|\\${ECR_FRONTEND_REPOSITORY}|${ECR_FRONTEND_REPOSITORY}|g' kubernetes/frontend-deployment.yaml
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
