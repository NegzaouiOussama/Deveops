#!/bin/bash

# Script d'installation du démarrage automatique de Prometheus et Grafana
# Ce script configure systemd pour démarrer automatiquement Prometheus/Grafana au démarrage de WSL

set -e

echo "========================================="
echo "🔧 Installation du démarrage automatique"
echo "========================================="
echo ""

SUDO_PASSWORD="00000000"

# Détecter automatiquement le répertoire du projet (où le script est exécuté)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="prometheus-grafana.service"
SCRIPT_FILE="start-prometheus-grafana.sh"

echo "📁 Répertoire du projet détecté: $PROJECT_DIR"

# Vérifier que les fichiers existent
if [ ! -f "$PROJECT_DIR/$SCRIPT_FILE" ]; then
    echo "❌ Erreur: $SCRIPT_FILE non trouvé dans $PROJECT_DIR"
    echo "   Fichiers présents dans le répertoire:"
    ls -la "$PROJECT_DIR" | grep -E "\.sh$|prometheus|grafana" || echo "   (aucun fichier correspondant trouvé)"
    exit 1
fi

# Rendre le script exécutable
chmod +x "$PROJECT_DIR/$SCRIPT_FILE"
echo "✅ Script $SCRIPT_FILE rendu exécutable"

# Créer le fichier de service systemd avec les bonnes variables
echo ""
echo "📝 Création du service systemd..."
SERVICE_CONTENT="[Unit]
Description=Prometheus and Grafana Auto Start Service
After=network.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=$USER
WorkingDirectory=$PROJECT_DIR
ExecStart=/bin/bash $PROJECT_DIR/$SCRIPT_FILE
StandardOutput=journal
StandardError=journal
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target"

echo "$SERVICE_CONTENT" | sudo tee /etc/systemd/system/prometheus-grafana.service > /dev/null
echo "✅ Service systemd créé"

# Recharger systemd
echo ""
echo "🔄 Rechargement de systemd..."
echo "$SUDO_PASSWORD" | sudo -S systemctl daemon-reload 2>/dev/null || sudo systemctl daemon-reload
echo "✅ systemd rechargé"

# Activer le service
echo ""
echo "⚙️  Activation du service..."
echo "$SUDO_PASSWORD" | sudo -S systemctl enable prometheus-grafana.service 2>/dev/null || sudo systemctl enable prometheus-grafana.service
echo "✅ Service activé (démarrage automatique au boot)"

# Démarrer le service maintenant
echo ""
echo "🚀 Démarrage du service..."
echo "$SUDO_PASSWORD" | sudo -S systemctl start prometheus-grafana.service 2>/dev/null || sudo systemctl start prometheus-grafana.service
echo "✅ Service démarré"

# Vérifier le statut
echo ""
echo "📊 Statut du service:"
sudo systemctl status prometheus-grafana.service --no-pager -l | head -15 || true

echo ""
echo "========================================="
echo "✅ Installation terminée !"
echo "========================================="
echo ""
echo "📋 Commandes utiles:"
echo "   Vérifier le statut: sudo systemctl status prometheus-grafana"
echo "   Voir les logs: sudo journalctl -u prometheus-grafana -f"
echo "   Redémarrer: sudo systemctl restart prometheus-grafana"
echo "   Désactiver: sudo systemctl disable prometheus-grafana"
echo ""
echo "✅ Prometheus et Grafana démarreront automatiquement au démarrage de WSL !"

