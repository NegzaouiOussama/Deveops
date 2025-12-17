#!/bin/bash

echo "========================================="
echo "🚀 Déploiement de Prometheus et Grafana"
echo "========================================="
echo ""

# Vérifier que Minikube est démarré
echo "1️⃣  Vérification de Minikube..."
if ! minikube status >/dev/null 2>&1; then
    echo "⚠️  Minikube n'est pas démarré. Démarrage en cours..."
    minikube start
else
    echo "✅ Minikube est démarré"
fi

# Vérifier que kubectl fonctionne
echo ""
echo "2️⃣  Vérification de kubectl..."
if ! kubectl get nodes >/dev/null 2>&1; then
    echo "❌ Erreur: kubectl ne peut pas se connecter au cluster"
    exit 1
fi
echo "✅ kubectl fonctionne"

# Créer le namespace si nécessaire
echo ""
echo "3️⃣  Création du namespace devops..."
kubectl create namespace devops --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace devops prêt"

# Trouver l'IP WSL pour Jenkins (optionnel)
echo ""
echo "4️⃣  Configuration de Prometheus pour Jenkins..."
WSL_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "")
if [ -n "$WSL_IP" ]; then
    echo "   IP WSL détectée: $WSL_IP"
    echo "   Mettez à jour prometheus-config.yaml si nécessaire"
else
    echo "   Utilisation de host.docker.internal pour Jenkins"
fi

# Déployer Node Exporter
echo ""
echo "5️⃣  Déploiement de Node Exporter..."
kubectl apply -f k8s/node-exporter-deployment.yaml
echo "✅ Node Exporter déployé"

# Déployer Prometheus
echo ""
echo "6️⃣  Déploiement de Prometheus..."
kubectl apply -f k8s/prometheus-config.yaml
kubectl apply -f k8s/prometheus-deployment.yaml
kubectl apply -f k8s/prometheus-service.yaml
echo "✅ Prometheus déployé"

# Déployer Grafana
echo ""
echo "7️⃣  Déploiement de Grafana..."
kubectl apply -f k8s/grafana-dashboards.yaml
kubectl apply -f k8s/grafana-dashboards-configmap.yaml
kubectl apply -f k8s/grafana-datasources.yaml
kubectl apply -f k8s/grafana-deployment.yaml
kubectl apply -f k8s/grafana-service.yaml
echo "✅ Grafana déployé"

# Attendre que les pods soient prêts
echo ""
echo "8️⃣  Attente que les pods soient prêts..."
sleep 10
kubectl wait --for=condition=ready pod -l app=prometheus -n devops --timeout=120s || echo "Prometheus en cours de démarrage..."
kubectl wait --for=condition=ready pod -l app=grafana -n devops --timeout=120s || echo "Grafana en cours de démarrage..."
kubectl wait --for=condition=ready pod -l app=node-exporter -n devops --timeout=60s || echo "Node Exporter en cours de démarrage..."

# Afficher les URLs
echo ""
echo "========================================="
echo "✅ Déploiement terminé !"
echo "========================================="
echo ""

MINIKUBE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "192.168.49.2")

echo "📊 Prometheus:"
echo "   URL: http://${MINIKUBE_IP}:30909"
echo "   Ou via tunnel: minikube service prometheus -n devops"
echo ""
echo "📈 Grafana:"
echo "   URL: http://${MINIKUBE_IP}:30300"
echo "   Ou via tunnel: minikube service grafana -n devops"
echo "   Login: admin / admin"
echo "   ⚠️  Changez le mot de passe au premier login !"
echo ""
echo "🔍 Vérification des pods:"
kubectl get pods -n devops | grep -E "prometheus|grafana|node-exporter"
echo ""
echo "✅ Pour accéder depuis Windows, utilisez:"
echo "   minikube service prometheus -n devops"
echo "   minikube service grafana -n devops"
