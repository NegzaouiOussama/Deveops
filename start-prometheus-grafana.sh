#!/bin/bash

# Script de démarrage automatique pour Prometheus et Grafana
# Ce script démarre Minikube et déploie Prometheus/Grafana automatiquement

set -e

# Détecter automatiquement le répertoire du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "========================================="
echo "🚀 Démarrage automatique de Prometheus et Grafana"
echo "========================================="
echo ""
echo "📁 Répertoire du projet: $PROJECT_DIR"
echo ""

# Variables
WSL_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "172.29.114.102")
SUDO_PASSWORD="00000000"

# Fonction pour exécuter des commandes avec sudo
run_sudo() {
    echo "$SUDO_PASSWORD" | sudo -S "$@" 2>/dev/null || sudo "$@"
}

# 1. Vérifier et démarrer Minikube
echo "1️⃣  Vérification de Minikube..."
if ! minikube status >/dev/null 2>&1; then
    echo "   ⚠️  Minikube n'est pas démarré. Démarrage en cours..."
    minikube start --driver=docker
    echo "   ✅ Minikube démarré"
else
    echo "   ✅ Minikube est déjà démarré"
fi

# 2. Attendre que Minikube soit prêt
echo ""
echo "2️⃣  Attente que Minikube soit prêt..."
sleep 5
kubectl get nodes >/dev/null 2>&1 || (echo "   ⚠️  Attente supplémentaire..." && sleep 10)

# 3. Créer le namespace si nécessaire
echo ""
echo "3️⃣  Création du namespace devops..."
kubectl create namespace devops --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
echo "   ✅ Namespace devops prêt"

# 4. Installer node-exporter sur WSL si pas déjà installé
echo ""
echo "4️⃣  Vérification de Node Exporter sur WSL..."
if ! systemctl is-active --quiet node_exporter 2>/dev/null; then
    echo "   📦 Installation de Node Exporter sur WSL..."
    
    # Télécharger node-exporter
    NODE_EXPORTER_VERSION="1.7.0"
    NODE_EXPORTER_DIR="/opt/node_exporter"
    
    if [ ! -d "$NODE_EXPORTER_DIR" ]; then
        run_sudo mkdir -p "$NODE_EXPORTER_DIR"
        run_sudo wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" -O /tmp/node_exporter.tar.gz
        run_sudo tar -xzf /tmp/node_exporter.tar.gz -C /tmp
        run_sudo mv /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter "$NODE_EXPORTER_DIR/"
        run_sudo chmod +x "$NODE_EXPORTER_DIR/node_exporter"
        rm -f /tmp/node_exporter.tar.gz
        rm -rf /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64
    fi
    
    # Créer le service systemd pour node-exporter
    if [ ! -f /etc/systemd/system/node_exporter.service ]; then
        run_sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=$NODE_EXPORTER_DIR/node_exporter
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        run_sudo systemctl daemon-reload
        run_sudo systemctl enable node_exporter
        run_sudo systemctl start node_exporter
        echo "   ✅ Node Exporter installé et démarré sur WSL (port 9100)"
    else
        run_sudo systemctl start node_exporter 2>/dev/null || true
        echo "   ✅ Node Exporter déjà installé, démarrage..."
    fi
else
    echo "   ✅ Node Exporter est déjà actif sur WSL"
fi

# 5. Mettre à jour la configuration Prometheus avec l'IP WSL
echo ""
echo "5️⃣  Mise à jour de la configuration Prometheus..."
# Mettre à jour prometheus-config.yaml avec l'IP WSL actuelle
sed -i "s|172\.29\.114\.102:8080|${WSL_IP}:8080|g" k8s/prometheus-config.yaml 2>/dev/null || true
sed -i "s|172\.29\.114\.102:9100|${WSL_IP}:9100|g" k8s/prometheus-config.yaml 2>/dev/null || true
echo "   ✅ Configuration Prometheus mise à jour avec IP WSL: $WSL_IP"

# 6. Déployer Node Exporter dans Kubernetes
echo ""
echo "6️⃣  Déploiement de Node Exporter dans Kubernetes..."
kubectl apply -f k8s/node-exporter-deployment.yaml >/dev/null 2>&1 || echo "   ⚠️  Node Exporter déjà déployé"

# 7. Déployer Prometheus
echo ""
echo "7️⃣  Déploiement de Prometheus..."
kubectl apply -f k8s/prometheus-config.yaml >/dev/null 2>&1
kubectl apply -f k8s/prometheus-deployment.yaml >/dev/null 2>&1
kubectl apply -f k8s/prometheus-service.yaml >/dev/null 2>&1
echo "   ✅ Prometheus déployé"

# 8. Déployer Grafana
echo ""
echo "8️⃣  Déploiement de Grafana..."
kubectl apply -f k8s/grafana-dashboards.yaml >/dev/null 2>&1
kubectl apply -f k8s/grafana-dashboards-configmap.yaml >/dev/null 2>&1
kubectl apply -f k8s/grafana-datasources.yaml >/dev/null 2>&1
kubectl apply -f k8s/grafana-deployment.yaml >/dev/null 2>&1
kubectl apply -f k8s/grafana-service.yaml >/dev/null 2>&1
echo "   ✅ Grafana déployé"

# 9. Attendre que les pods soient prêts
echo ""
echo "9️⃣  Attente que les pods soient prêts..."
sleep 15
kubectl wait --for=condition=ready pod -l app=prometheus -n devops --timeout=120s >/dev/null 2>&1 || echo "   ⚠️  Prometheus en cours de démarrage..."
kubectl wait --for=condition=ready pod -l app=grafana -n devops --timeout=120s >/dev/null 2>&1 || echo "   ⚠️  Grafana en cours de démarrage..."

# 10. Afficher les URLs
echo ""
echo "========================================="
echo "✅ Prometheus et Grafana sont prêts !"
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
echo ""
echo "🔍 Node Exporter WSL:"
echo "   URL: http://${WSL_IP}:9100/metrics"
echo ""
echo "🏗️  Jenkins Metrics:"
echo "   URL: http://${WSL_IP}:8080/prometheus"
echo ""
echo "📊 Spring Boot Actuator:"
echo "   URL: http://${MINIKUBE_IP}:30080/student/actuator/prometheus"
echo ""
echo "========================================="
echo "✅ Démarrage automatique terminé !"
echo "========================================="

