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

        stage('Initialize & Authenticate') {
            steps {

                 withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-cred'
        ]]) {

                script {

                    sh 'aws --version'
                    sh 'docker --version'
                    sh 'kubectl version --client'

                    echo "Connecting to EKS Cluster..."

                    sh """
                    aws eks update-kubeconfig \
                    --region ${AWS_REGION} \
                    --name ${CLUSTER_NAME}
                    """

                    echo "Logging into ECR..."

                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS \
                    --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }
        }

        stage('Deploy Secrets & Backend Service') {
            steps {
                script {

                    sh 'kubectl apply -f kubernetes/secrets.yaml'

                    sh 'kubectl apply -f kubernetes/backend-service.yaml'

                    echo "Waiting for Backend LoadBalancer..."

                    sh '''
                    BACKEND_URL=""

                    for i in {1..20}; do

                        BACKEND_URL=$(kubectl get svc redbus-backend -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" || true)

                        if [ ! -z "$BACKEND_URL" ]; then
                            echo "Backend URL Found: http://${BACKEND_URL}:5000"
                            break
                        fi

                        echo "Waiting for LoadBalancer..."
                        sleep 10
                    done

                    if [ -z "$BACKEND_URL" ]; then
                        echo "LoadBalancer creation failed"
                        exit 1
                    fi

                    echo "REACT_APP_BACKEND_URL=http://${BACKEND_URL}:5000" > frontend.env
                    '''
                }
            }
        }

        stage('Build & Push Backend') {
            steps {
                script {

                    sh """
                    docker build \
                    -t ${ECR_BACKEND_REPOSITORY}:latest \
                    ./redbus-master/back-end-redbus
                    """

                    sh "docker push ${ECR_BACKEND_REPOSITORY}:latest"
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                script {

                    def envFileContent = readFile('frontend.env').trim()

                    def backendUrl = envFileContent.split('=')[1]

                    echo "Backend URL: ${backendUrl}"

                    sh """
                    docker build \
                    --build-arg REACT_APP_BACKEND_URL=${backendUrl} \
                    -t ${ECR_FRONTEND_REPOSITORY}:latest \
                    ./redbus-master/front-end-redbus
                    """

                    sh "docker push ${ECR_FRONTEND_REPOSITORY}:latest"
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {

                    sh """
                    sed -i 's|\\\${ECR_BACKEND_REPOSITORY}|${ECR_BACKEND_REPOSITORY}|g' kubernetes/backend-deployment.yaml
                    """

                    sh """
                    sed -i 's|\\\${ECR_FRONTEND_REPOSITORY}|${ECR_FRONTEND_REPOSITORY}|g' kubernetes/frontend-deployment.yaml
                    """

                    sh 'kubectl apply -f kubernetes/backend-deployment.yaml'

                    sh 'kubectl apply -f kubernetes/frontend-deployment.yaml'

                    sh 'kubectl apply -f kubernetes/frontend-service.yaml'

                    sh 'kubectl rollout status deployment/redbus-backend --timeout=120s'

                    sh 'kubectl rollout status deployment/redbus-frontend --timeout=120s'

                    sh 'kubectl get svc'
                }
            }
        }
    }

    post {

        success {

            echo "Deployment Successful"

            sh '''
            FRONTEND_DNS=$(kubectl get svc redbus-frontend -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

            echo "====================================================="
            echo "Application Live At:"
            echo "http://${FRONTEND_DNS}"
            echo "====================================================="
            '''
        }

        failure {
            echo "Pipeline Failed"
        }
    }
}