pipeline {
    agent any

    parameters {
        string(name: 'IMAGE_TAG', defaultValue: "${BUILD_NUMBER}")
        string(name: 'APP_NAME', defaultValue: "nodejs-web-app")
        string(name: 'GIT_MAIL', defaultValue: "rotemmadar9@gmail.com")
        string(name: 'GITOPS_REPO_NAME', defaultValue: "https://github.com/RotemMadar/web-app-GitOps.git")
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials') //Taken from credentials configured in Jenkins
        GITOPSREPO_CREDENTIALS = credentials('gitops-repo-credentials')
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
                bat """
                    trivy fs ^
                      --scanners vuln,secret,misconfig ^
                      --exit-code 1 ^
                      --severity CRITICAL ^
                      .
                """
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

        stage('Vulnerability Image Scanning (Trivy)') {
            steps {
                echo 'Scanning compiled Docker image...'
                bat """
                    trivy image ^
                      --exit-code 1 ^
                      --severity HIGH,CRITICAL ^
                      ${env.IMAGE_PATH}
                """
            }
        }

        stage('Upload Image to Artifactory') {
            steps {
                script{
                    retry(3) {
                        docker.withRegistry('', 'docker-hub-credentials') {
                            docker.image("${env.IMAGE_PATH}").push()
                        }
                    }
                    bat "echo Image pushed successfully to Dockerhub"
                }
            }
        }

        stage('Update Helm Values in Git') {
            steps {
                script {
                    bat 'if exist web-app-GitOps rmdir /s /q web-app-GitOps'
                    powershell """
                        git clone "${params.GITOPS_REPO_NAME}"
                    """
                    dir('web-app-GitOps') {
                        bat "git config user.email ${params.GIT_MAIL}"
                        bat "git config user.name ${env.GITOPSREPO_CREDENTIALS_USR}"
                        powershell """
                            (Get-Content ./web-app/values.yaml) -replace 'tag:.*', 'tag: "${params.IMAGE_TAG}"' | Set-Content ./web-app/values.yaml
                        """  
                        powershell """
                            (Get-Content ./web-app/Chart.yaml) -replace 'appVersion:.*', 'appVersion: "${params.IMAGE_TAG}"' | Set-Content ./web-app/Chart.yaml
                        """                  
                        bat "git add ."
                        bat "git commit -m \"ci: update image tag in helm chart to ${params.IMAGE_TAG}\""
                        bat 'git push https://%GITOPSREPO_CREDENTIALS_USR%:%GITOPSREPO_CREDENTIALS_PSW%@github.com/RotemMadar/web-app-GitOps.git main'
                        bat "git push origin main"
                    }
                }
            }
        }
    }
}