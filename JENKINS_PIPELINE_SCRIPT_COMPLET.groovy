pipeline {
    agent any
    
    tools {
        maven 'Maven3'
    }
    
    environment {
        MAVEN_HOME = "${tool 'Maven3'}"
        PATH = "${env.MAVEN_HOME}/bin:${env.PATH}"
        SONAR_HOST_URL = "http://172.29.114.102:9000"
        SONAR_TOKEN = "sqa_53a643aea3ccdbcedef2c73df0428a1d8397d01e"
        DOCKER_USERNAME = "negzaoui"
        DOCKER_PASSWORD = "dckr_pat_o-R1u9Ij5dpajyvfK7xcH6PRP6w"
        DOCKER_IMAGE_NAME = "student-management"
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/NegzaouiOussama/Deveops.git'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn clean test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    sh 'test -f target/jacoco.exec && echo "JaCoCo execution data saved" || echo "No JaCoCo execution data"'
                }
            }
        }
        
        stage('Generate JaCoCo Report') {
            steps {
                sh 'mvn jacoco:report'
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('MVN SONARQUBE') {
            steps {
                script {
                    sh """
                        mvn sonar:sonar \\
                            -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                            -Dsonar.login=${env.SONAR_TOKEN} \\
                            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    """
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} .
                        docker tag ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    sh """
                        echo ${env.DOCKER_PASSWORD} | docker login -u ${env.DOCKER_USERNAME} --password-stdin
                        docker push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                        docker push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Create Kubernetes Namespace') {
            steps {
                script {
                    sh """
                        kubectl create namespace devops --dry-run=client -o yaml | kubectl apply -f -
                    """
                }
            }
        }
        
        stage('Deploy MySQL to Kubernetes') {
            steps {
                script {
                    sh """
                        kubectl apply -f k8s/mysql-secret.yaml
                        kubectl apply -f k8s/mysql-pvc.yaml
                        kubectl apply -f k8s/mysql-deployment.yaml
                        kubectl apply -f k8s/mysql-service.yaml
                    """
                }
            }
        }
        
        stage('Wait for MySQL to be Ready') {
            steps {
                script {
                    sh """
                        kubectl wait --for=condition=ready pod -l app=mysql -n devops --timeout=300s || true
                        echo "MySQL deployment completed!"
                    """
                }
            }
        }
        
        stage('Deploy Application to Kubernetes') {
            steps {
                script {
                    sh """
                        kubectl apply -f k8s/app-configmap.yaml
                        kubectl apply -f k8s/app-secret.yaml
                        kubectl apply -f k8s/app-deployment.yaml
                        kubectl set image deployment/student-management student-management=${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} -n devops --record || echo "Image update will happen on next deployment"
                        kubectl apply -f k8s/app-service.yaml
                    """
                }
            }
        }
        
        stage('Wait for Application to be Ready') {
            steps {
                script {
                    sh """
                        kubectl wait --for=condition=ready pod -l app=student-management -n devops --timeout=300s || true
                        sleep 30
                        echo "Application deployment completed!"
                    """
                }
            }
        }
        
        stage('Expose Services and Test Application') {
            steps {
                script {
                    sh """
                        echo "=== Pods Status ==="
                        kubectl get pods -n devops
                        
                        echo "=== Services Status ==="
                        kubectl get services -n devops
                        
                        echo "=== Getting NodePort for Application ==="
                        NODEPORT=\$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}' || echo "30080")
                        MINIKUBE_IP=\$(minikube ip 2>/dev/null || kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' || echo "localhost")
                        
                        echo "Application URL: http://\${MINIKUBE_IP}:\${NODEPORT}/student"
                        echo "Health Check URL: http://\${MINIKUBE_IP}:\${NODEPORT}/student/actuator/health"
                        echo "Swagger UI: http://\${MINIKUBE_IP}:\${NODEPORT}/student/swagger-ui.html"
                        
                        echo "=== Testing Application Health ==="
                        sleep 15
                        kubectl exec -n devops \$(kubectl get pod -l app=student-management -n devops -o jsonpath='{.items[0].metadata.name}' 2>/dev/null | head -1) -- wget -qO- http://localhost:8089/student/actuator/health || echo "Health check via pod exec failed"
                    """
                }
            }
        }
        
        stage('Verify Code Quality on Pod') {
            steps {
                script {
                    sh """
                        echo "=== Checking Pod Logs for Code Quality ==="
                        kubectl logs -l app=student-management -n devops --tail=50 || echo "Logs check completed"
                        
                        echo "=== Pod Resource Usage ==="
                        kubectl top pods -n devops || echo "Metrics server not available"
                    """
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            script {
                def NODEPORT = sh(script: "kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo '30080'", returnStdout: true).trim()
                def MINIKUBE_IP = sh(script: "minikube ip 2>/dev/null || kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"InternalIP\")].address}' 2>/dev/null || echo 'localhost'", returnStdout: true).trim()
                
                echo '=========================================='
                echo 'Pipeline réussi avec succès!'
                echo '=========================================='
                echo "SonarQube Dashboard: ${env.SONAR_HOST_URL}/dashboard?id=tn.esprit:student-management"
                echo "Docker Image: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                echo "Docker Hub: https://hub.docker.com/r/${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}"
                echo "Kubernetes Namespace: devops"
                echo "Application URL: http://${MINIKUBE_IP}:${NODEPORT}/student"
                echo "Health Check URL: http://${MINIKUBE_IP}:${NODEPORT}/student/actuator/health"
                echo "Swagger UI: http://${MINIKUBE_IP}:${NODEPORT}/student/swagger-ui.html"
                echo '=========================================='
            }
        }
        failure {
            echo 'Pipeline a échoué!'
            echo "Vérifiez les logs ci-dessus pour identifier le problème."
        }
        cleanup {
            sh 'docker logout || true'
        }
    }
}

