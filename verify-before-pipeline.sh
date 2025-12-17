#!/bin/bash

echo "========================================="
echo "🔍 Vérification avant exécution du Pipeline"
echo "========================================="
echo ""

# 1. Vérifier Minikube
echo "1️⃣  Vérification de Minikube..."
if minikube status >/dev/null 2>&1; then
    echo "✅ Minikube est démarré"
    minikube status | grep -E "host|kubelet|apiserver"
else
    echo "❌ Minikube n'est PAS démarré"
    echo "   Commande: minikube start"
    exit 1
fi

# 2. Vérifier kubectl
echo ""
echo "2️⃣  Vérification de kubectl..."
if kubectl get nodes >/dev/null 2>&1; then
    echo "✅ kubectl fonctionne"
    kubectl get nodes
else
    echo "❌ kubectl ne fonctionne pas"
    exit 1
fi

# 3. Vérifier SonarQube
echo ""
echo "3️⃣  Vérification de SonarQube..."
if docker ps | grep -q sonarqube; then
    echo "✅ SonarQube est démarré"
    SONAR_STATUS=$(curl -s http://localhost:9000/api/system/status 2>/dev/null | grep -o '"status":"[^"]*"' || echo "")
    if [ -n "$SONAR_STATUS" ]; then
        echo "   Status: $SONAR_STATUS"
    fi
else
    echo "❌ SonarQube n'est PAS démarré"
    echo "   Commande: docker start sonarqube"
    exit 1
fi

# 4. Vérifier Docker
echo ""
echo "4️⃣  Vérification de Docker..."
if docker ps >/dev/null 2>&1; then
    echo "✅ Docker fonctionne"
else
    echo "❌ Docker ne fonctionne pas"
    exit 1
fi

# 5. Vérifier la connexion Docker Hub
echo ""
echo "5️⃣  Vérification de la connexion Docker Hub..."
DOCKER_HUB_TEST=$(curl -s -o /dev/null -w "%{http_code}" https://registry-1.docker.io/v2/ 2>/dev/null || echo "000")
if [ "$DOCKER_HUB_TEST" = "401" ] || [ "$DOCKER_HUB_TEST" = "200" ]; then
    echo "✅ Docker Hub est accessible (HTTP $DOCKER_HUB_TEST)"
else
    echo "⚠️  Docker Hub pourrait ne pas être accessible (HTTP $DOCKER_HUB_TEST)"
fi

# 6. Vérifier les pods de monitoring
echo ""
echo "6️⃣  Vérification des pods de monitoring..."
MONITORING_PODS=$(kubectl get pods -n devops -l 'app in (prometheus,grafana,node-exporter)' --no-headers 2>/dev/null | wc -l)
if [ "$MONITORING_PODS" -ge 3 ]; then
    echo "✅ Monitoring stack déployé ($MONITORING_PODS pods trouvés)"
    kubectl get pods -n devops -l 'app in (prometheus,grafana,node-exporter)' | grep -E "prometheus|grafana|node-exporter"
else
    echo "⚠️  Monitoring stack pourrait ne pas être complètement déployé"
    echo "   Pods trouvés: $MONITORING_PODS/3"
    echo "   Commande: ./deploy-monitoring.sh"
fi

# 7. Vérifier l'IP WSL pour Jenkins
echo ""
echo "7️⃣  Vérification de l'IP WSL pour Jenkins..."
WSL_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "")
if [ -n "$WSL_IP" ]; then
    echo "✅ IP WSL détectée: $WSL_IP"
    echo "   Assurez-vous que Prometheus peut accéder à: http://$WSL_IP:8080/prometheus"
else
    echo "⚠️  IP WSL non détectée"
fi

# 8. Vérifier que Jenkins expose les métriques
echo ""
echo "8️⃣  Vérification Jenkins Prometheus plugin..."
if [ -n "$WSL_IP" ]; then
    JENKINS_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://$WSL_IP:8080/prometheus 2>/dev/null || echo "000")
    if [ "$JENKINS_TEST" = "200" ]; then
        echo "✅ Jenkins expose les métriques Prometheus (HTTP $JENKINS_TEST)"
    else
        echo "⚠️  Jenkins ne semble pas exposer les métriques (HTTP $JENKINS_TEST)"
        echo "   Installez le plugin 'Prometheus metrics plugin' dans Jenkins"
    fi
else
    echo "⚠️  Impossible de vérifier (IP WSL non trouvée)"
fi

echo ""
echo "========================================="
echo "✅ Vérification terminée !"
echo "========================================="
echo ""
echo "📝 Commandes utiles:"
echo "   - Démarrer Minikube: minikube start"
echo "   - Démarrer SonarQube: docker start sonarqube"
echo "   - Déployer monitoring: ./deploy-monitoring.sh"
echo "   - Vérifier les pods: kubectl get pods -n devops"
echo ""
echo "🚀 Vous pouvez maintenant lancer le pipeline Jenkins !"
echo "========================================="

