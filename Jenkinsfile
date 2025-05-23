pipeline {
    agent any
    parameters {
        string(name: 'DEPLOY_ENV', defaultValue: 'dev', description: 'Environment to deploy')
    }
    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        imageName = "kalki2878/react-js-app:${env.BUILD_NUMBER}"
    }
    stages {
        stage("test") {
            steps {
                script {
                    echo "Testing the application..."
                    sh "CI=true npm test || true"
                }
            }
        }
        stage('Docker Build') {
            steps {
                sh "docker build -t ${imageName} ."
            }
        }
        stage('Push to DockerHub Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh "echo $DOCKER_PASSWORD | docker login -u ${DOCKER_USERNAME} --password-stdin"
                    sh "docker push ${imageName}"
                }
            }
        }
        stage('Deploy to EC2-Server') {
            steps {
                sshagent(['ec2-server-key']) {
                    // Pull the latest image and run a new container
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@18.142.239.7 'docker pull ${imageName} && docker run -d --name myapp -p 3080:3080 ${imageName}'"
                    echo "Deploying the application..."
                }
            }
        }
    }
    post {
        always {
            // Archive artifacts such as test results and logs if present
            archiveArtifacts artifacts: '**/test-results/**, **/logs/**', allowEmptyArchive: true
        }
    }
}
