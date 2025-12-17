#!/bin/bash

echo "========================================="
echo "Démarrage de SonarQube dans Docker"
echo "========================================="
echo ""

# Vérifier si SonarQube existe déjà (arrêté)
if docker ps -a | grep -q sonarqube; then
    echo "✅ SonarQube existe déjà - Démarrage..."
    docker start sonarqube
else
    echo "📦 Création et démarrage de SonarQube..."
    docker run -d \
      --name sonarqube \
      -p 9000:9000 \
      -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
      sonarqube:latest
fi

echo ""
echo "⏳ Attente du démarrage de SonarQube (cela peut prendre 2-3 minutes)..."
echo ""

# Attendre que SonarQube soit prêt
for i in {1..30}; do
    STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:9000/api/system/status 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
        echo ""
        echo "✅ SonarQube est opérationnel!"
        echo ""
        echo "🌐 URL: http://localhost:9000"
        echo "🌐 URL depuis Jenkins: http://172.29.114.102:9000"
        echo "👤 Login: admin / admin"
        echo ""
        exit 0
    fi
    echo -n "."
    sleep 10
done

echo ""
echo "⚠️  SonarQube démarre toujours... Vérifiez les logs:"
echo "   docker logs -f sonarqube"
echo ""
echo "Une fois prêt, accédez à: http://localhost:9000"

