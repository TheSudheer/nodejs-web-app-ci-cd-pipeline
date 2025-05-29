#!/usr/bin/env groovy

pipeline {
    agent any
    
    options {
        timeout(time: 50, unit: 'MINUTES')
    }
    environment {
        AWS_ECR_SERVER = "710271936636.dkr.ecr.ap-south-1.amazonaws.com" //replace this with your AWS ECR REPO
        AWS_ECR_REPO = "710271936636.dkr.ecr.ap-south-1.amazonaws.com/react_js_app" //replace this with your AWS ECR REPO
        imageName = "latest"
    }
    stages {

        stage("build image") {
            steps {
                script {
                    echo "Starting build image stage"
                    timeout(time: 5, unit: 'MINUTES') {
                        echo 'Building the docker image and pushing it to AWS ECR...'
                        withCredentials([usernamePassword(credentialsId: 'ecr-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                            sh "docker build -t ${AWS_ECR_REPO}:${imageName} ."
                            sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin ${AWS_ECR_SERVER}"
                            sh "docker push ${AWS_ECR_REPO}:${imageName}"
                        }
                    }
                    echo "Finished build image stage"
                }
            }
        }
        stage("Provision Server") {
            environment {
                AWS_ACCESS_KEY_ID     = credentials("jenkins_aws_access_key_id")
                AWS_SECRET_ACCESS_KEY = credentials("jenkins_aws_secret_access_key")
            }
            steps {
                script {
                    dir("terraform-eks-cluster") {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                    }
                }
            }
        }

        stage("Configure Kubeconfig and Test Connectivity") {
            steps {
                echo "Starting Configure Kubeconfig and Test Connectivity stage"
                withCredentials([
                    string(credentialsId: 'jenkins_aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'jenkins_aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    timeout(time: 3, unit: 'MINUTES') {
                        sh '''
                            set -x
                            echo "Verifying AWS CLI version..."
                            aws --version

                            echo "Setting AWS_DEFAULT_REGION to ap-southeast-1..."
                            export AWS_DEFAULT_REGION=ap-south-1

                            echo "Updating kubeconfig for cluster demo-cluster-3..."
                            aws eks update-kubeconfig --region=ap-southeast-1 --name=myapp-eks-cluster

                            echo "Listing Kubernetes nodes..."
                            kubectl get nodes
                            set +x
                        '''
                    }
                }
                echo "Finished Configure Kubeconfig and Test Connectivity stage"
            }
        }
        stage("deploy") {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                APP_NAME = 'react-js-app'
                IMAGE_NAME = "${env.imageName}"
            }
            steps {
                script {
                    echo "Starting deploy stage"
                    timeout(time: 3, unit: 'MINUTES') {
                        sh '''
                            set -x
                            echo "Deploying using kubernetes/deployment.yaml..."
                            envsubst < kubernetes/app-deployment.yml | kubectl apply -f -

                            echo "Deploying using kubernetes/service.yaml..."
                            envsubst < kubernetes/db.yaml | kubectl apply -f -
                            set +x
                        '''
                    }
                    echo "Finished deploy stage"
                }
            }
        }
    }
}

