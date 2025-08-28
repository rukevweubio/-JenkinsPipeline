
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "rukevweubio/my-grandel-app"
        DOCKER_TAG   = "latest"
        SONAR_HOST   = "https://potential-space-couscous-7v4rprpggq5c4-9000.app.github.dev"
        SONAR_TOKEN  = credentials('sonar-token') 
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    echo "Build the app with Gradle"
                    sh "./gradlew clean build"
                }
            }
        }

        stage('Docker Build Image') {
            steps {
                script {
                    echo "Building Docker image"
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                }
            }
        }

        stage('Docker Tag Image') {
            steps {
                script {
                    echo "Tagging Docker image"
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        stage('Trivy Scan Docker Image') {
            steps {
                script {
                    echo "Scanning Docker image for vulnerabilities using Trivy"
                    sh """
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }

        stage('GitLeaks Scan') {
            steps {
                script {
                    echo "Scanning repository for secrets using GitLeaks"
                    sh """
                    docker run --rm -v \$(pwd):/repo zricethezav/gitleaks:latest gitleaks detect --source=/repo --report-format=json --report-path=/repo/gitleaks-report.json
                    """
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    echo "Running SonarQube analysis"
                    sh """
                    ./gradlew sonarqube \
                        -Dsonar.host.url=${SONAR_HOST} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Logging in to Docker Hub..."
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    }
                }
            }
        }

        stage('Run Docker Image') {
            steps {
                script {
                    echo "Running Docker image"
                    sh "docker run -d -p 8082:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
    }
}
