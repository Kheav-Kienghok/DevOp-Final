pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    environment {
        // Source
        GIT_REPO_URL = 'https://github.com/Kheav-Kienghok/aupp-lms-devops-cicd.git'
        GIT_BRANCH   = 'main'

        // Sonar
        SONAR_SCANNER_HOME = tool 'Sonar-Scan'
        SONAR_SERVER = 'sonar-scanner'

        // Docker
        DOCKERHUB_USER = 'kienghok'
        DOCKERHUB_PASSWORD = credentials('dockerhub-password')

        IMAGE_NAME = 'kienghok/aupp-lms'
        IMAGE_TAG  = "${BUILD_NUMBER}"

        // AWS / Infra
        AWS_CREDENTIALS = 'aws-credentials'
        AWS_DEFAULT_REGION = 'us-east-1'

        // Runtime
        INSTANCE_IP = ''
    }

    stages {

        /* ---------------------------
         * 1. SOURCE
         * --------------------------- */
        stage('Checkout') {
            steps {
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO_URL}"
            }
        }

        /* ---------------------------
         * 2. BUILD
         * --------------------------- */
        stage('Build Application') {
            steps {
                echo "Building application artifacts..."
                sh 'echo "Build step placeholder (add Maven/Go/Node build here)"'
            }
        }

        /* ---------------------------
         * 3. TEST
         * --------------------------- */
        stage('Unit Tests') {
            steps {
                echo "Running unit tests..."
                sh 'echo "Add real test command here (pytest, mvn test, go test, etc.)"'
            }
        }

        /* ---------------------------
         * 4. STATIC ANALYSIS (SONAR)
         * --------------------------- */
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh """
                        ${SONAR_SCANNER_HOME}/bin/sonar-scanner
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        /* ---------------------------
         * 5. SECURITY SCANNING
         * --------------------------- */
        stage('Filesystem Security Scan (Trivy)') {
            steps {
                sh """
                    trivy fs \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --no-progress .
                """
            }
        }

        /* ---------------------------
         * 6. DOCKER BUILD & SCAN
         * --------------------------- */
        stage('Docker Build') {
            steps {
                script {
                    env.IMAGE_FULL = "${IMAGE_NAME}:${IMAGE_TAG}"

                    docker.build(env.IMAGE_FULL, "-f app/Dockerfile ./app")
                }
            }
        }

        stage('Container Security Scan (Trivy)') {
            steps {
                sh """
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --exit-code 1 \
                        --no-progress ${IMAGE_FULL}
                """
            }
        }

        /* ---------------------------
         * 7. PUSH IMAGE
         * --------------------------- */
        stage('Push Docker Image') {
            steps {
                sh """
                    echo "${DOCKERHUB_PASSWORD}" | docker login -u "${DOCKERHUB_USER}" --password-stdin

                    docker push ${IMAGE_FULL}

                    docker tag ${IMAGE_FULL} ${IMAGE_NAME}:latest
                    docker push ${IMAGE_NAME}:latest

                    docker logout
                """
            }
        }

        /* ---------------------------
         * 8. INFRA (TERRAFORM)
         * --------------------------- */
        stage('Provision Infrastructure & Deploy') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}"
                ]]) {

                    dir('infra/terraform') {
                        script {
                            // Run Terraform apply first.
                            sh """
                                terraform init
                                terraform apply -auto-approve --replace="module.compute.aws_instance.this"
                            """

                            // Capture output directly to avoid workspace path issues.
                            env.INSTANCE_IP = sh(
                                script: '''
                                    set -e

                                    IP="$(terraform output -raw ec2_public_ip 2>/dev/null || true)"

                                    if [ -z "$IP" ] || [ "$IP" = "null" ]; then
                                        INSTANCE_ID="$(terraform output -raw ec2_instance_id 2>/dev/null || true)"

                                        if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "null" ]; then
                                            IP="$(aws ec2 describe-instances \
                                                --instance-ids "$INSTANCE_ID" \
                                                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                                                --output text)"
                                        fi
                                    fi

                                    if [ "$IP" = "None" ] || [ "$IP" = "null" ]; then
                                        IP=""
                                    fi

                                    echo "$IP"
                                ''',
                                returnStdout: true
                            ).trim()

                            if (!env.INSTANCE_IP) {
                                error('Could not determine EC2 public IP from Terraform output or AWS API')
                            }

                            env.EC2_HOST = env.INSTANCE_IP

                            echo "✅ Captured IP from shell: ${env.INSTANCE_IP}"

                            sh """
                                ansible-playbook \
                                    -i ../ansible/inventory.ini \
                                    ../ansible/playbooks/server.yml

                                ansible-playbook \
                                    -i ../ansible/inventory.ini \
                                    ../ansible/playbooks/deploy.yml \
                                    --extra-vars \"image_full=${IMAGE_FULL} image_name=${IMAGE_NAME}\"
                            """
                        }
                    }
                }
            }
        }

        /* ---------------------------
         * 9. SMOKE TEST
         * --------------------------- */
        stage('Smoke Test') {
            steps {
                sh """
                    echo "Testing deployment..."

                    curl -f http://${EC2_HOST}:8000 || exit 1
                """
            }
        }
    }

    /* ---------------------------
     * POST ACTIONS
     * --------------------------- */
    post {
        success {
            echo "✅ Pipeline SUCCESS — build ${BUILD_NUMBER}"
        }

        failure {
            echo "❌ Pipeline FAILED — check logs"
        }

        always {
            echo "Pipeline completed"
            cleanWs()
        }
    }
}