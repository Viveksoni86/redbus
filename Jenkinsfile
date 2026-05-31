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

        stage('Init Tools & Connect EKS') {
            steps {
<<<<<<< HEAD
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-secret-key'
                ]]) {
                    script {

                        sh 'aws --version'
                        sh 'docker --version'
                        sh 'kubectl version --client'

                        echo "Updating kubeconfig for EKS..."

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
=======
                sh '''
                aws --version
                docker --version
                kubectl version --client

                aws eks update-kubeconfig \
                    --region $AWS_REGION \
                    --name $CLUSTER_NAME
                '''
>>>>>>> 8ee782c706d956fba3942a61cdebb4526940a162
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS \
                --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                '''
            }
        }

<<<<<<< HEAD
                    sh 'kubectl apply -f kubernetes/secrets.yaml'
                    sh 'kubectl apply -f kubernetes/backend-service.yaml'

                    echo "Waiting for Backend LoadBalancer..."

                    sh '''
                    BACKEND_URL=""

                    for i in {1..25}; do
                        BACKEND_URL=$(kubectl get svc redbus-backend \
                        -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2>/dev/null || true)

                        if [ ! -z "$BACKEND_URL" ]; then
                            echo "Backend URL Found: http://${BACKEND_URL}:5000"
                            break
                        fi

                        echo "Waiting for LoadBalancer..."
                        sleep 10
                    done

                    if [ -z "$BACKEND_URL" ]; then
                        echo "ERROR: LoadBalancer creation failed"
                        exit 1
                    fi

                    echo "REACT_APP_BACKEND_URL=http://${BACKEND_URL}:5000" > frontend.env
                    '''
                }
=======
        stage('Deploy K8s Backend (Infra First)') {
            steps {
                sh '''
                kubectl apply -f kubernetes/secrets.yaml
                kubectl apply -f kubernetes/backend-service.yaml
                '''
>>>>>>> 8ee782c706d956fba3942a61cdebb4526940a162
            }
        }

        stage('Build & Push Backend') {
            steps {
<<<<<<< HEAD
                script {
                    sh """
                    docker build \
                    -t ${ECR_BACKEND_REPOSITORY}:latest \
                    ./redbus-master/back-end-redbus
                    """
=======
                sh '''
                docker build -t redbus-backend ./redbus-master/back-end-redbus
                docker tag redbus-backend:latest $ECR_BACKEND_REPOSITORY:latest
                docker push $ECR_BACKEND_REPOSITORY:latest
                '''
            }
        }

        stage('Wait for Backend URL') {
            steps {
                sh '''
                for i in {1..30}; do
                    BACKEND_URL=$(kubectl get svc redbus-backend -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2>/dev/null || true)
>>>>>>> 8ee782c706d956fba3942a61cdebb4526940a162

                    if [ ! -z "$BACKEND_URL" ]; then
                        echo "BACKEND_URL=http://$BACKEND_URL:5000" > backend.env
                        exit 0
                    fi

                    echo "Waiting for LoadBalancer..."
                    sleep 10
                done

                echo "Backend LoadBalancer failed"
                exit 1
                '''
            }
        }

        stage('Build & Push Frontend') {
            steps {
                sh '''
                source backend.env
                echo "Backend URL: $BACKEND_URL"

<<<<<<< HEAD
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
=======
                docker build \
                    --build-arg REACT_APP_BACKEND_URL=$BACKEND_URL \
                    -t redbus-frontend ./redbus-master/front-end-redbus

                docker tag redbus-frontend:latest $ECR_FRONTEND_REPOSITORY:latest
                docker push $ECR_FRONTEND_REPOSITORY:latest
                '''
>>>>>>> 8ee782c706d956fba3942a61cdebb4526940a162
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                sed "s|ECR_BACKEND|$ECR_BACKEND_REPOSITORY|g" kubernetes/backend-deployment.yaml > temp-backend.yaml
                sed "s|ECR_FRONTEND|$ECR_FRONTEND_REPOSITORY|g" kubernetes/frontend-deployment.yaml > temp-frontend.yaml

                kubectl apply -f temp-backend.yaml
                kubectl apply -f temp-frontend.yaml
                kubectl apply -f kubernetes/frontend-service.yaml

                kubectl rollout status deployment/redbus-backend --timeout=180s
                kubectl rollout status deployment/redbus-frontend --timeout=180s

<<<<<<< HEAD
                    sh 'kubectl apply -f kubernetes/backend-deployment.yaml'
                    sh 'kubectl apply -f kubernetes/frontend-deployment.yaml'
                    sh 'kubectl apply -f kubernetes/frontend-service.yaml'

                    sh 'kubectl rollout status deployment/redbus-backend --timeout=120s'
                    sh 'kubectl rollout status deployment/redbus-frontend --timeout=120s'

                    sh 'kubectl get svc'
                }
=======
                kubectl get svc
                '''
>>>>>>> 8ee782c706d956fba3942a61cdebb4526940a162
            }
        }
    }

    post {
        success {
<<<<<<< HEAD
            echo "Deployment Successful"

            sh '''
            FRONTEND_DNS=$(kubectl get svc redbus-frontend \
            -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

            echo "====================================================="
            echo "Application Live At:"
            echo "http://${FRONTEND_DNS}"
            echo "====================================================="
            '''
=======
            echo "Deployment Successful 🚀"
>>>>>>> 8ee782c706d956fba3942a61cdebb4526940a162
        }

        failure {
            echo "Pipeline Failed ❌"
        }
    }
}
