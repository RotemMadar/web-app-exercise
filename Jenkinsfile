pipeline {
    agent any

    parameters {
        string(name: 'IMAGE_TAG', defaultValue: "${BUILD_NUMBER}")
        string(name: 'REPO_NAME')
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials') //Taken from credentials configured in Jenkins
        IMAGE_PATH = ""
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Security Scan') {
            steps {
                echo 'Scanning code for vulnerabilities...'
            }
        }

        stage('Build Docker Image') {
            steps {
                script{
                    withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')])
                    sh "echo Successfully logged to dockerhub repository"
                    env.IMAGE_PATH = "${DOCKER_USER}/${params.REPO_NAME}:${params.IMAGE_TAG}"
                    sh "echo Building the image..."
                    dockerImage = docker.build("${env.IMAGE_PATH}")
                }
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                sh """
                    trivy image \
                      --exit-code 1 \
                      --severity HIGH,CRITICAL \
                      ${env.IMAGE_PATH}
                """
            }
        }

        stage('Upload Image to Artifactory') {
            steps {
                script{
                    docker.withRegistry('https://index.docker.io/v1', 'docker-hub-credentials'){
                        dockerImage.push("${env.IMAGE_PATH}")
                    }
                    sh "echo Image pushed successfully to repository"
                }
            }
        }
    }
}