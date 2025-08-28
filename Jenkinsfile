pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "rukevweubio/my-grandel-app"
        DOCKER_TAG   = "latest"
        SONAR_HOST   = "https://potential-space-couscous-7v4rprpggq5c4-9000.app.github.dev"
        SONAR_TOKEN  = credentials('sonarqube-token')
        GIT_REPO     = "https://github.com/rukevweubio/JenkinsPipeline.git"
    }

    stages {

        stage('Checkout') {
            steps {
                // echo "Cloning repository ${GIT_REPO}"
                // git url: "${GIT_REPO}", branch: 'main'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "Building the app with Gradle"
                sh "./gradlew clean build"
            }
        }

        stage('Docker Build & Tag') {
            steps {
                echo "Building and tagging Docker image"
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Security Scans') {
            parallel {
                stage('Trivy Scan') {
                    steps {
                        echo "Scanning Docker image for vulnerabilities with Trivy"
                        sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    }
                }

                stage('GitLeaks Scan') {
                    steps {
                        echo "Scanning repository for secrets using GitLeaks"
                        sh "docker run --rm -v \$(pwd):/repo zricethezav/gitleaks:latest gitleaks detect --source=/repo --report-format=json --report-path=/repo/gitleaks-report.json"
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis"
                sh "./gradlew sonarqube -Dsonar.host.url=${SONAR_HOST} -Dsonar.login=${SONAR_TOKEN}"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "Logging in to Docker Hub and pushing image"
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        stage('Run Docker Image') {
            steps {
                echo "Running Docker image"
                sh "docker run -d -p 8082:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }

    }
}
