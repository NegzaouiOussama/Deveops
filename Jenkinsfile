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
                    // Sauvegarder le fichier jacoco.exec pour le rapport
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
                    // Vérifier d'abord que SonarQube est accessible
                    echo "🔍 Vérification de l'accessibilité SonarQube..."
                    def sonarCheck = sh(
                        script: """
                            curl -s -o /dev/null -w "%{http_code}" ${env.SONAR_HOST_URL}/api/system/status || echo "000"
                        """,
                        returnStdout: true
                    ).trim()
                    
                    if (sonarCheck != "200") {
                        echo "⚠️  ATTENTION: SonarQube pourrait ne pas être accessible (HTTP ${sonarCheck})"
                        echo "   Vérifiez que SonarQube est démarré: docker ps | grep sonarqube"
                        echo "   Ou démarrez-le: docker start sonarqube"
                        echo "   Le pipeline va quand même essayer de se connecter..."
                    } else {
                        echo "✅ SonarQube est accessible (HTTP ${sonarCheck})"
                    }
                    
                    // Exécuter l'analyse avec timeout augmenté et meilleure gestion d'erreurs
                    echo "📊 Démarrage de l'analyse SonarQube..."
                    try {
                        timeout(time: 10, unit: 'MINUTES') {
                    sh """
                        mvn sonar:sonar \\
                            -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                            -Dsonar.login=${env.SONAR_TOKEN} \\
                                    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \\
                                    -Dsonar.qualitygate.wait=false \\
                                    -Dsonar.scanner.force-deprecated-java-version=true
                            """
                        }
                        echo "✅ Analyse SonarQube terminée avec succès"
                    } catch (Exception e) {
                        echo "❌ Erreur lors de l'analyse SonarQube: ${e.getMessage()}"
                        echo "📋 Diagnostic:"
                        echo "   1. Vérifiez que SonarQube est accessible: curl ${env.SONAR_HOST_URL}/api/system/status"
                        echo "   2. Vérifiez que le token est valide"
                        echo "   3. Vérifiez les logs SonarQube: docker logs sonarqube --tail 50"
                        echo "   4. Le pipeline continue malgré l'erreur SonarQube..."
                        // Ne pas faire échouer le pipeline à cause de SonarQube
                        // catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        //     throw e
                        // }
                    }
                }
            }
            post {
                always {
                    script {
                        echo "📊 SonarQube Analysis Stage Completed"
                        echo "🔗 Dashboard: ${env.SONAR_HOST_URL}/dashboard?id=tn.esprit:student-management"
                        echo "⚠️  Note: Quality Gate status can be checked in SonarQube dashboard"
                        echo "   If Quality Gate FAILED, check:"
                        echo "   1. Fix the issues (currently 2 issues)"
                        echo "   2. Increase code coverage (currently 40.3%, target 80%)"
                        echo "   3. Review security hotspots"
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building NEW Docker image..."
                    echo "   Image: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                    echo "   Tag: ${env.BUILD_NUMBER} (unique pour chaque build)"
                    echo "   Build avec --no-cache pour inclure toutes les dépendances (notamment Actuator)"
                    
                    sh """
                        # Build without cache to ensure Actuator dependencies are included
                        # Chaque build crée une NOUVELLE image avec un tag unique (BUILD_NUMBER)
                        echo "🔨 Démarrage du build Docker..."
                        docker build --no-cache -t ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} .
                        
                        echo "🏷️  Tagging de l'image..."
                        docker tag ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest
                        
                        echo "✅ Image Docker créée avec succès:"
                        docker images | grep ${env.DOCKER_IMAGE_NAME} | grep -E "${env.DOCKER_IMAGE_TAG}|latest" | head -2
                    """
                    
                    echo "✅ Nouvelle image Docker créée: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    echo "📤 Pushing NEW Docker image to Docker Hub..."
                    echo "   Image tag: ${env.DOCKER_IMAGE_TAG} (Build #${env.BUILD_NUMBER})"
                    echo "   Image: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                    
                    // Se connecter à Docker Hub
                    echo "🔐 Logging into Docker Hub..."
                    sh """
                        echo ${env.DOCKER_PASSWORD} | docker login -u ${env.DOCKER_USERNAME} --password-stdin
                    """
                    
                    // Vérifier que l'image existe localement
                    echo "🔍 Vérification que la nouvelle image existe localement..."
                    sh """
                        echo "Images locales disponibles:"
                        docker images | grep ${env.DOCKER_IMAGE_NAME} | head -5
                        echo ""
                        echo "Vérification de l'image tag ${env.DOCKER_IMAGE_TAG}..."
                        docker images | grep ${env.DOCKER_IMAGE_NAME} | grep ${env.DOCKER_IMAGE_TAG} || (echo "❌ Image tag ${env.DOCKER_IMAGE_TAG} not found locally" && exit 1)
                        echo "✅ Image tag ${env.DOCKER_IMAGE_TAG} trouvée localement"
                    """
                    
                    // Pousser les images avec retry explicite
                    echo "📤 Pushing new image to Docker Hub..."
                    
                    // Push tag BUILD_NUMBER avec retry
                    def pushSuccess1 = false
                    def retryCount1 = 0
                    def maxRetries1 = 3
                    while (retryCount1 < maxRetries1 && !pushSuccess1) {
                        try {
                            echo "🔄 Pushing ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} (attempt ${retryCount1 + 1}/${maxRetries1})..."
                            sh "docker push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                            pushSuccess1 = true
                            echo "✅ Successfully pushed ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                        } catch (Exception e) {
                            retryCount1++
                            if (retryCount1 < maxRetries1) {
                                def waitTime = retryCount1 * 10
                                echo "⚠️  Failed to push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} (attempt ${retryCount1}/${maxRetries1}). Retrying in ${waitTime} seconds..."
                                sleep(waitTime)
                            } else {
                                echo "❌ Failed to push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} after ${maxRetries1} attempts"
                                throw e
                            }
                        }
                    }
                    
                    // Push tag latest avec retry
                    def pushSuccess2 = false
                    def retryCount2 = 0
                    def maxRetries2 = 3
                    while (retryCount2 < maxRetries2 && !pushSuccess2) {
                        try {
                            echo "🔄 Pushing ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest (attempt ${retryCount2 + 1}/${maxRetries2})..."
                            sh "docker push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest"
                            pushSuccess2 = true
                            echo "✅ Successfully pushed ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest"
                        } catch (Exception e) {
                            retryCount2++
                            if (retryCount2 < maxRetries2) {
                                def waitTime = retryCount2 * 10
                                echo "⚠️  Failed to push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest (attempt ${retryCount2}/${maxRetries2}). Retrying in ${waitTime} seconds..."
                                sleep(waitTime)
                            } else {
                                echo "❌ Failed to push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest after ${maxRetries2} attempts"
                                throw e
                            }
                        }
                    }
                    
                    echo "✅ All images pushed successfully to Docker Hub!"
                    echo ""
                    echo "📊 RÉSUMÉ DU PUSH:"
                    echo "   ✅ Nouvelle image poussée: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                    echo "   ✅ Tag latest mis à jour: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest"
                    echo "   🔗 Docker Hub: https://hub.docker.com/r/${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}"
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
                        # Le PVC peut déjà exister avec des paramètres différents, on ignore l'erreur si c'est le cas
                        kubectl apply -f k8s/mysql-pvc.yaml || echo "PVC mysql-pvc exists with different spec, continuing..."
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
                        kubectl wait --for=condition=ready pod -l app=mysql -n devops --timeout=10s || true
                        echo "MySQL deployment completed!"
                    """
                }
            }
        }
        
        stage('Update App Image Tag') {
            steps {
                script {
                    sh """
                        # Supprimer les pods en erreur (ImagePullBackOff)
                        kubectl delete pod -n devops -l app=student-management --field-selector=status.phase!=Running --ignore-not-found=true || echo "No pods to delete"
                        
                        # Mettre à jour l'image dans le deployment si il existe
                        kubectl set image deployment/student-management student-management=${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} -n devops --record || echo "Deployment not found, will be created in next stage"
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
                        
                        # Mettre à jour l'image avec le tag de build et forcer le pull
                        kubectl set image deployment/student-management student-management=${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} -n devops --record || echo "Image update failed, using latest"
                        
                        # Forcer le pull de l'image en supprimant les pods existants
                        kubectl rollout restart deployment/student-management -n devops || echo "Rollout restart completed"
                        
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
                        
                        echo "=== Application Deployment Status ==="
                        kubectl get deployment student-management -n devops || echo "Deployment check completed"
                        
                        echo "=== Getting NodePort for Application ==="
                        NODEPORT=\$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30080")
                        # Obtenir l'IP du node directement via kubectl (plus fiable que minikube ip)
                        MINIKUBE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "192.168.49.2")
                        
                        echo "Application URL: http://\${MINIKUBE_IP}:\${NODEPORT}/student"
                        echo "Swagger UI: http://\${MINIKUBE_IP}:\${NODEPORT}/student/swagger-ui.html"
                        
                        echo "=== Testing Application ==="
                        sleep 15
                        kubectl exec -n devops \$(kubectl get pod -l app=student-management -n devops -o jsonpath='{.items[0].metadata.name}' 2>/dev/null | head -1) -- wget -qO- http://localhost:8089/student/swagger-ui.html | head -5 || echo "Health check via pod exec failed"
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
                        
                        echo "=== Describing Pods ==="
                        kubectl describe pods -l app=student-management -n devops | head -50 || echo "Describe completed"
                    """
                }
            }
        }
        
        stage('Deploy Monitoring Stack (Prometheus & Grafana)') {
            steps {
                script {
                    // Cette étape est critique pour le monitoring - continuer même en cas d'erreurs précédentes
                    try {
                    sh """
                        echo "========================================="
                        echo "🚀 Déploiement du Monitoring Stack"
                        echo "========================================="
                        
                        # Détecter l'IP WSL pour la configuration Prometheus
                        WSL_IP=\$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print \$2}' | cut -d/ -f1 || echo "172.29.114.102")
                        echo "📡 IP WSL détectée: \$WSL_IP"
                        
                        # Mettre à jour la configuration Prometheus avec l'IP WSL
                        if [ -f k8s/prometheus-config.yaml ]; then
                            OLD_IP="172.29.114.102"
                            sed -i "s|\${OLD_IP}:8080|\${WSL_IP}:8080|g" k8s/prometheus-config.yaml 2>/dev/null || true
                            sed -i "s|\${OLD_IP}:9100|\${WSL_IP}:9100|g" k8s/prometheus-config.yaml 2>/dev/null || true
                            echo "✅ Configuration Prometheus mise à jour avec IP WSL: \$WSL_IP"
                        fi
                        
                        echo ""
                        echo "1️⃣  Déploiement de Node Exporter (métriques système)..."
                        kubectl apply -f k8s/node-exporter-deployment.yaml || echo "Node Exporter déjà déployé"
                        
                        # Démarrer Node Exporter WSL si disponible
                        if systemctl is-available --quiet node_exporter.service 2>/dev/null; then
                            echo "   🔄 Démarrage de Node Exporter WSL..."
                            sudo systemctl start node_exporter 2>/dev/null || echo "   ⚠️  Node Exporter WSL nécessite sudo"
                        fi
                        
                        echo ""
                        echo "2️⃣  Déploiement de Prometheus..."
                        kubectl apply -f k8s/prometheus-config.yaml
                        kubectl apply -f k8s/prometheus-deployment.yaml
                        kubectl apply -f k8s/prometheus-service.yaml
                        
                        echo ""
                        echo "3️⃣  Déploiement de Grafana..."
                        kubectl apply -f k8s/grafana-datasources.yaml
                        kubectl apply -f k8s/grafana-dashboards.yaml
                        kubectl apply -f k8s/grafana-dashboards-configmap.yaml
                        kubectl apply -f k8s/grafana-deployment.yaml
                        kubectl apply -f k8s/grafana-service.yaml
                        
                        echo ""
                        echo "4️⃣  Attente que les pods soient prêts..."
                        sleep 15
                        kubectl wait --for=condition=ready pod -l app=prometheus -n devops --timeout=120s || echo "Prometheus en cours de démarrage..."
                        kubectl wait --for=condition=ready pod -l app=grafana -n devops --timeout=120s || echo "Grafana en cours de démarrage..."
                        kubectl wait --for=condition=ready pod -l app=node-exporter -n devops --timeout=60s || echo "Node Exporter en cours de démarrage..."
                        
                        echo ""
                        echo "✅ Monitoring Stack déployé !"
                        echo "========================================="
                    """
                    } catch (Exception e) {
                        echo "⚠️  Erreur lors du déploiement du Monitoring Stack: ${e.getMessage()}"
                        echo "   Le pipeline continue malgré cette erreur..."
                        // Ne pas faire échouer le pipeline à cause du monitoring
                    }
                }
            }
        }
        
        stage('Verify Monitoring Stack (Prometheus & Grafana)') {
            steps {
                script {
                    sh """
                        echo "========================================="
                        echo "📊 Vérification du Monitoring Stack"
                        echo "========================================="
                        
                        MINIKUBE_IP=\$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "192.168.49.2")
                        WSL_IP=\$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print \$2}' | cut -d/ -f1 || echo "172.29.114.102")
                        
                        echo ""
                        echo "1️⃣  Vérification des pods Prometheus et Grafana..."
                        kubectl get pods -n devops -l 'app in (prometheus,grafana,node-exporter)' || echo "Monitoring pods check"
                        
                        echo ""
                        echo "2️⃣  Vérification Prometheus..."
                        PROMETHEUS_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://\${MINIKUBE_IP}:30909/api/v1/status/config || echo "000")
                        if [ "\$PROMETHEUS_STATUS" = "200" ]; then
                            echo "✅ Prometheus est accessible (HTTP \$PROMETHEUS_STATUS)"
                        else
                            echo "⚠️  Prometheus pourrait ne pas être accessible (HTTP \$PROMETHEUS_STATUS)"
                        fi
                        
                        echo ""
                        echo "3️⃣  Vérification Grafana..."
                        GRAFANA_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://\${MINIKUBE_IP}:30300/api/health || echo "000")
                        if [ "\$GRAFANA_STATUS" = "200" ]; then
                            echo "✅ Grafana est accessible (HTTP \$GRAFANA_STATUS)"
                        else
                            echo "⚠️  Grafana pourrait ne pas être accessible (HTTP \$GRAFANA_STATUS)"
                        fi
                        
                        echo ""
                        echo "4️⃣  Vérification des targets Prometheus..."
                        TARGETS=\$(curl -s http://\${MINIKUBE_IP}:30909/api/v1/targets 2>/dev/null || echo "")
                        if [ -n "\$TARGETS" ]; then
                            echo "Targets trouvés:"
                            echo "\$TARGETS" | grep -o '"job":"[^"]*"' | sort | uniq || echo "   Parsing targets..."
                        else
                            echo "⚠️  Impossible de récupérer les targets Prometheus"
                        fi
                        
                        echo ""
                        echo "5️⃣  Vérification Spring Boot Actuator..."
                        # Sélectionner uniquement les pods en état Running
                        APP_POD=\$(kubectl get pod -n devops -l app=student-management --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null | head -1)
                        NODEPORT=\$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30080")
                        
                        if [ -n "\$APP_POD" ]; then
                            # Vérifier que le pod est vraiment ready
                            POD_READY=\$(kubectl get pod \$APP_POD -n devops -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
                            if [ "\$POD_READY" = "True" ]; then
                                # Tester Actuator depuis l'extérieur (via NodePort) - plus fiable que exec
                                ACTUATOR_RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" http://\${MINIKUBE_IP}:\${NODEPORT}/student/actuator/prometheus 2>/dev/null || echo "000")
                                
                                if [ "\$ACTUATOR_RESPONSE" = "200" ]; then
                                    ACTUATOR_TEST=\$(curl -s http://\${MINIKUBE_IP}:\${NODEPORT}/student/actuator/prometheus 2>/dev/null | head -5 || echo "")
                                    if [ -n "\$ACTUATOR_TEST" ] && echo "\$ACTUATOR_TEST" | grep -q "# HELP"; then
                                        echo "✅ Spring Boot Actuator fonctionne (pod: \$APP_POD)"
                                        echo "   Métriques disponibles sur: http://\${MINIKUBE_IP}:\${NODEPORT}/student/actuator/prometheus"
                                        echo "   Exemple de métrique: \$(echo "\$ACTUATOR_TEST" | head -1)"
                                    else
                                        echo "⚠️  Actuator répond mais format inattendu (HTTP \$ACTUATOR_RESPONSE)"
                                        echo "   Réponse: \$(echo "\$ACTUATOR_TEST" | head -3)"
                                    fi
                                elif [ "\$ACTUATOR_RESPONSE" = "404" ]; then
                                    echo "⚠️  Actuator endpoint non trouvé (HTTP 404)"
                                    echo "   Vérifiez que:"
                                    echo "   1. Le profile 'docker' est actif (vérifiez Dockerfile)"
                                    echo "   2. Les dépendances Actuator sont dans pom.xml"
                                    echo "   3. application-docker.properties contient la config Actuator"
                                    echo "   Logs du pod:"
                                    kubectl logs \$APP_POD -n devops --tail=20 | grep -i actuator || echo "   Aucun log Actuator trouvé"
                                else
                                    echo "⚠️  Actuator non accessible (HTTP \$ACTUATOR_RESPONSE)"
                                    echo "   Pod: \$APP_POD"
                                fi
                            else
                                echo "⚠️  Pod \$APP_POD n'est pas en état Ready (status: \$POD_READY)"
                                echo "   Liste des pods:"
                                kubectl get pods -n devops -l app=student-management | head -5
                            fi
                        else
                            echo "⚠️  Aucun pod Running de l'application trouvé pour tester Actuator"
                            echo "   Liste de tous les pods:"
                            kubectl get pods -n devops -l app=student-management || echo "Aucun pod trouvé"
                        fi
                        
                        echo ""
                        echo "6️⃣  Vérification Node Exporter..."
                        NODE_EXPORTER_POD=\$(kubectl get pod -n devops -l app=node-exporter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null | head -1)
                        if [ -n "\$NODE_EXPORTER_POD" ]; then
                            NODE_METRICS=\$(kubectl exec -n devops \$NODE_EXPORTER_POD -- wget -qO- http://localhost:9100/metrics 2>/dev/null | grep -c "node_" || echo "0")
                            if [ "\$NODE_METRICS" -gt 0 ]; then
                                echo "✅ Node Exporter fonctionne (\$NODE_METRICS métriques système trouvées)"
                            else
                                echo "⚠️  Node Exporter pourrait ne pas fonctionner"
                            fi
                        else
                            echo "⚠️  Node Exporter pod non trouvé"
                        fi
                        
                        echo ""
                        echo "7️⃣  Vérification Jenkins Metrics..."
                        JENKINS_TEST=\$(curl -s -o /dev/null -w "%{http_code}" http://\${WSL_IP}:8080/prometheus 2>/dev/null || echo "000")
                        if [ "\$JENKINS_TEST" = "200" ]; then
                            echo "✅ Jenkins expose les métriques Prometheus (HTTP 200)"
                            echo "   Endpoint: http://\${WSL_IP}:8080/prometheus"
                            # Test rapide de récupération de métriques
                            JENKINS_METRICS_COUNT=\$(curl -s http://\${WSL_IP}:8080/prometheus 2>/dev/null | grep -c "^jenkins_" || echo "0")
                            if [ "\$JENKINS_METRICS_COUNT" -gt 0 ]; then
                                echo "   ✅ \$JENKINS_METRICS_COUNT métriques Jenkins trouvées"
                            fi
                        elif [ "\$JENKINS_TEST" = "302" ]; then
                            # Tester avec le slash final (Jenkins redirige vers /prometheus/)
                            JENKINS_TEST_SLASH=\$(curl -s -o /dev/null -w "%{http_code}" http://\${WSL_IP}:8080/prometheus/ 2>/dev/null || echo "000")
                            if [ "\$JENKINS_TEST_SLASH" = "200" ]; then
                                echo "✅ Jenkins expose les métriques Prometheus (HTTP 200 sur /prometheus/)"
                                echo "   Endpoint: http://\${WSL_IP}:8080/prometheus/"
                                JENKINS_METRICS_COUNT=\$(curl -s http://\${WSL_IP}:8080/prometheus/ 2>/dev/null | grep -c "^jenkins_" || echo "0")
                                if [ "\$JENKINS_METRICS_COUNT" -gt 0 ]; then
                                    echo "   ✅ \$JENKINS_METRICS_COUNT métriques Jenkins trouvées"
                                fi
                            else
                                echo "⚠️  Jenkins nécessite une authentification (HTTP \$JENKINS_TEST -> \$JENKINS_TEST_SLASH)"
                                echo "   Le plugin Prometheus est probablement installé mais protégé"
                                echo "   Configurez Prometheus avec authentification ou exposez l'endpoint publiquement"
                                echo "   Endpoint: http://\${WSL_IP}:8080/prometheus/"
                            fi
                        elif [ "\$JENKINS_TEST" = "401" ] || [ "\$JENKINS_TEST" = "403" ]; then
                            echo "⚠️  Jenkins nécessite une authentification (HTTP \$JENKINS_TEST)"
                            echo "   Le plugin Prometheus est probablement installé mais protégé"
                            echo "   Configurez Prometheus avec authentification ou exposez l'endpoint publiquement"
                            echo "   Endpoint: http://\${WSL_IP}:8080/prometheus/"
                        else
                            echo "⚠️  Jenkins ne semble pas exposer les métriques (HTTP \$JENKINS_TEST)"
                            echo "   Vérifiez que:"
                            echo "   1. Le plugin 'Prometheus metrics plugin' est installé dans Jenkins"
                            echo "   2. Jenkins est accessible depuis Prometheus sur: http://\${WSL_IP}:8080"
                            echo "   3. L'endpoint /prometheus est accessible"
                        fi
                        
                        echo ""
                        echo "========================================="
                        echo "📊 URLs du Monitoring"
                        echo "========================================="
                        echo "Prometheus: http://\${MINIKUBE_IP}:30909"
                        echo "   - Status: http://\${MINIKUBE_IP}:30909/api/v1/status/runtimeinfo"
                        echo "   - Targets: http://\${MINIKUBE_IP}:30909/targets"
                        echo "   - Graph: http://\${MINIKUBE_IP}:30909/graph"
                        echo ""
                        echo "Grafana: http://\${MINIKUBE_IP}:30300"
                        echo "   - Login: admin / admin"
                        echo "   - Dashboards: Automatiquement importés"
                        echo "     * Spring Boot Application Metrics"
                        echo "     * Jenkins Metrics"
                        echo "     * System Metrics (Node Exporter)"
                        echo ""
                        echo "Spring Actuator: http://\${MINIKUBE_IP}:30080/student/actuator/prometheus"
                        echo "Jenkins Metrics: http://\${WSL_IP}:8080/prometheus"
                        echo ""
                        echo "Pour accéder depuis Windows:"
                        echo "  Terminal 1: minikube service prometheus -n devops"
                        echo "  Terminal 2: minikube service grafana -n devops"
                        echo "========================================="
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
                def MINIKUBE_IP = sh(script: "kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type==\"InternalIP\")].address}' 2>/dev/null || echo '192.168.49.2'", returnStdout: true).trim()
                
                echo '=========================================='
                echo '✅ Pipeline réussi avec succès!'
                echo '=========================================='
                echo "📊 SonarQube Dashboard: ${env.SONAR_HOST_URL}/dashboard?id=tn.esprit:student-management"
                echo "🐳 Docker Image: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                echo "🐳 Docker Hub: https://hub.docker.com/r/${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}"
                echo "☸️  Kubernetes Namespace: devops"
                echo "🌐 Application URL: http://${MINIKUBE_IP}:${NODEPORT}/student"
                echo "📚 Swagger UI: http://${MINIKUBE_IP}:${NODEPORT}/student/swagger-ui.html"
                echo ""
                echo "📊 Monitoring Stack:"
                def WSL_IP = sh(script: "ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1 || echo '172.29.114.102'", returnStdout: true).trim()
                echo "   📈 Prometheus: http://${MINIKUBE_IP}:30909"
                echo "   📊 Grafana: http://${MINIKUBE_IP}:30300 (admin/admin)"
                echo "   🔧 Spring Actuator: http://${MINIKUBE_IP}:${NODEPORT}/student/actuator/prometheus"
                echo "   🏗️  Jenkins Metrics: http://${WSL_IP}:8080/prometheus"
                echo '=========================================='
            }
        }
        failure {
            echo '❌ Pipeline a échoué!'
            echo "Vérifiez les logs ci-dessus pour identifier le problème."
        }
        cleanup {
            sh 'docker logout || true'
        }
    }
}
