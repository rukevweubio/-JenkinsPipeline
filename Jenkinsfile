pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "rukevweubio/my-grandel-app"
        DOCKER_TAG   = "latest"
        SONAR_HOST   = "https://potential-space-couscous-7v4rprpggq5c4-9000.app.github.dev"  // REPLACE WITH STABLE URL!
        GIT_REPO     = "https://github.com/rukevweubio/JenkinsPipeline.git"  // Unused; consider removing
    }

    stages {

        stage('Checkout') {
            steps {
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
                        sh """docker run --rm -v \$(pwd):/repo zricethezav/gitleaks:latest detect \
                            --source=/repo \
                            --report-format=json \
                            --report-path=/repo/gitleaks-report.json"""
                    }
                }
            }
        }

        stage('Test Sonar Connectivity') {  // New diagnostic stage
            steps {
                echo "Testing connection to SonarQube"
                sh "curl -v ${SONAR_HOST}/api/server/version || echo 'Connection failed!'"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis"
                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                    sh """./gradlew sonar \
                        -Dsonar.host.url=${SONAR_HOST} \
                        -Dsonar.token=\$SONAR_TOKEN \
                        -Dsonar.projectKey=JenkinsPipeline \  // Change to your actual key
                        -Dsonar.gradle.skipCompile=true \
                        --stacktrace --debug"""  // Remove --stacktrace --debug after debugging
                }
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