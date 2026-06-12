pipeline {
    agent any

    parameters {
        string(name: 'IMAGE_TAG', defaultValue: "${BUILD_NUMBER}")
        string(name: 'APP_NAME', defaultValue: "nodejs-web-app")
        string(name: 'GITOPS_REPO_NAME', defaultValue: "https://github.com/RotemMadar/web-app-GitOps.git")
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials') //Taken from credentials configured in Jenkins
        IMAGE_PATH = "${env.DOCKERHUB_CREDENTIALS_USR}/${params.APP_NAME}:${params.IMAGE_TAG}"
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
                    bat "echo Building the image: ${env.IMAGE_PATH}"
                    dockerImage = docker.build("${env.IMAGE_PATH}")
                }
            }
        }

        // stage('Security Scan (Trivy)') {
        //     steps {
        //         bat """
        //             trivy image \
        //               --exit-code 1 \
        //               --severity HIGH,CRITICAL \
        //               ${env.IMAGE_PATH}
        //         """
        //     }
        // }

        stage('Upload Image to Artifactory') {
            steps {
                script{
                    docker.withRegistry('https://index.docker.io/v1', 'docker-hub-credentials'){
                        docker.image("${env.IMAGE_PATH}").push()
                    }
                    bat "echo Successfully logged to dockerhub repository"
                    bat "echo Image pushed successfully to repository"
                }
            }
        }

        stage('Update Helm Values in Git') {
            steps {
                script {
                    powershell """
                        git clone "${params.GITOPS_REPO_NAME}"
                        cd web-app-GitOps
                    """
                    powershell """
                        (Get-Content ./web-app/values.yaml) -replace 'tag: ".*"', 'tag: "${params.IMAGE_TAG}"' | Set-Content ./my-webapp/values.yaml
                    """  
                    powershell """
                        (Get-Content ./web-app/Chart.yaml) -replace 'appVersion: ".*"', 'appVersion: "${params.IMAGE_TAG}"' | Set-Content ./my-webapp/Chart.yaml
                    """                  
                    bat "git add ."
                    bat "git commit -m 'ci: update image tag in helm chart to ${params.IMAGE_TAG}'"                    
                    bat "git push origin main"
                }
            }
        }
    }
}