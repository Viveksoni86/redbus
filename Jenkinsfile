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
                sh '''
                aws --version
                docker --version
                kubectl version --client

                aws eks update-kubeconfig \
                    --region $AWS_REGION \
                    --name $CLUSTER_NAME
                '''
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

        stage('Deploy K8s Backend (Infra First)') {
            steps {
                sh '''
                kubectl apply -f kubernetes/secrets.yaml
                kubectl apply -f kubernetes/backend-service.yaml
                '''
            }
        }

        stage('Build & Push Backend') {
            steps {
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

                docker build \
                    --build-arg REACT_APP_BACKEND_URL=$BACKEND_URL \
                    -t redbus-frontend ./redbus-master/front-end-redbus

                docker tag redbus-frontend:latest $ECR_FRONTEND_REPOSITORY:latest
                docker push $ECR_FRONTEND_REPOSITORY:latest
                '''
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

                kubectl get svc
                '''
            }
        }
    }

    post {
        success {
            echo "Deployment Successful 🚀"
        }

        failure {
            echo "Pipeline Failed ❌"
        }
    }
}
