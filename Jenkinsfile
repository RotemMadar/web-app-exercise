pipeline {
    agent any

    parameters {
        string(name: 'IMAGE_NAME', defaultValue: 'nodejs-app')
        string(name: 'IMAGE_TAG', defaultValue: "${BUILD_NUMBER}")

        string(name: 'ARTIFACTORY_URL')
        string(name: 'ARTIFACTORY_REPO')

        string(name: 'ENVIRONMENT', defaultValue: 'dev')
    }

    environment {
        IMAGE_FULL = "${params.ARTIFACTORY_URL}/${params.ARTIFACTORY_REPO}/${params.IMAGE_NAME}:${params.IMAGE_TAG}"
        ARTIFACTORY_CRED_ID = "artifactory-creds"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_FULL} .
                """
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                sh """
                    trivy image \
                      --exit-code 1 \
                      --severity HIGH,CRITICAL \
                      ${IMAGE_FULL}
                """
            }
        }

        stage('Upload Image to Artifactory') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${ARTIFACTORY_CRED_ID}",
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD'
                )]) {
                    sh """
                        echo $PASS | docker login ${ARTIFACTORY_URL} -u $USER --password-stdin
                        docker push ${IMAGE_FULL}
                        docker logout ${ARTIFACTORY_URL}
                    """
                }
            }
        }
    }

    post {
        always {
            sh "docker image prune -f || true"
        }

        success {
            echo "Build successful for environment: ${params.ENVIRONMENT}"
        }

        failure {
            echo "Build failed for environment: ${params.ENVIRONMENT}"
        }
    }
}