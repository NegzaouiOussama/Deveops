# 🚀 Guide : Démarrer SonarQube

## 📋 État Actuel

SonarQube n'est **pas démarré** actuellement (ni dans Docker, ni dans Kubernetes).

## ✅ Option 1 : Démarrer SonarQube dans Docker (Recommandé - Plus Simple)

### Méthode Rapide

```bash
# Dans WSL, démarrer SonarQube avec Docker
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest
```

### Méthode avec Persistence (Recommandée)

```bash
# Créer un volume pour persister les données
docker volume create sonarqube_data
docker volume create sonarqube_extensions
docker volume create sonarqube_logs

# Démarrer SonarQube avec volumes
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest
```

### Vérifier que SonarQube démarre

```bash
# Vérifier les logs
docker logs -f sonarqube

# Attendre le message : "SonarQube is operational"
# Cela peut prendre 2-3 minutes au premier démarrage

# Vérifier que SonarQube est accessible
curl http://localhost:9000/api/system/status
```

### Accéder à SonarQube

- **URL** : http://localhost:9000 (ou http://172.29.114.102:9000 depuis Jenkins)
- **Login par défaut** : `admin` / `admin`
- **Vous devrez changer le mot de passe au premier login**

## ✅ Option 2 : Démarrer SonarQube dans Kubernetes

### Déployer SonarQube dans Kubernetes

```bash
# Aller dans le répertoire du projet
cd /mnt/c/Users/Negza/Documents/GitHub/Deveops

# Créer le PVC (PersistentVolumeClaim)
kubectl apply -f k8s/sonarqube-pvc.yaml

# Déployer SonarQube
kubectl apply -f k8s/sonarqube-deployment.yaml

# Exposer le service
kubectl apply -f k8s/sonarqube-service.yaml
```

### Vérifier le déploiement

```bash
# Vérifier les pods
kubectl get pods -n devops -l app=sonarqube

# Vérifier le service
kubectl get svc sonarqube-service -n devops

# Voir les logs (attendre que le pod soit Running)
kubectl logs -n devops -l app=sonarqube --tail=50 -f
```

### Accéder à SonarQube dans Kubernetes

```bash
# Obtenir l'URL du service
minikube service sonarqube-service -n devops --url

# Ou manuellement
export MINIKUBE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "SonarQube URL: http://${MINIKUBE_IP}:32000"
```

- **URL** : http://<MINIKUBE_IP>:32000
- **Login par défaut** : `admin` / `admin`

## 🔧 Configuration du Token SonarQube

Après avoir démarré SonarQube, créez un token pour Jenkins :

1. **Se connecter à SonarQube** : http://localhost:9000 (ou l'URL Kubernetes)
2. **Login** : `admin` / `admin` (puis changez le mot de passe)
3. **Aller dans** : My Account (icône utilisateur en haut à droite) → Security
4. **Generate Tokens** :
   - **Name** : `jenkins-global`
   - **Type** : **Global Analysis Token** (ou User Token)
   - **Generate**
5. **Copier le token** et mettre à jour le pipeline si nécessaire

## ⚡ Commandes Rapides

### Démarrer SonarQube Docker (Simple)

```bash
docker run -d --name sonarqube -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest
```

### Arrêter SonarQube Docker

```bash
docker stop sonarqube
docker rm sonarqube
```

### Redémarrer SonarQube Docker

```bash
docker restart sonarqube
```

### Vérifier les logs Docker

```bash
docker logs -f sonarqube
```

## 📊 Après le Démarrage

Une fois SonarQube démarré :

1. **Vérifier l'accessibilité** :
   ```bash
   curl http://localhost:9000/api/system/status
   # Devrait retourner : {"status":"UP",...}
   ```

2. **Relancer le pipeline Jenkins** - Il devrait maintenant détecter SonarQube automatiquement

3. **Le pipeline utilisera** :
   - Docker : `http://172.29.114.102:9000`
   - Kubernetes : `http://<MINIKUBE_IP>:32000`

## ⚠️ Notes Importantes

1. **Premier démarrage** : SonarQube peut prendre 2-3 minutes pour démarrer complètement
2. **Mémoire** : SonarQube nécessite au moins 2GB de RAM disponible
3. **Persistance** : Si vous utilisez Docker, utilisez des volumes pour persister les données
4. **URL** : Si SonarQube est dans Docker, l'URL `172.29.114.102:9000` doit être accessible depuis Jenkins

## 🔍 Dépannage

### SonarQube ne démarre pas

```bash
# Vérifier les logs
docker logs sonarqube

# Vérifier les ressources
docker stats sonarqube

# Vérifier que le port 9000 n'est pas utilisé
netstat -tuln | grep 9000
```

### SonarQube dans Kubernetes ne démarre pas

```bash
# Vérifier les pods
kubectl get pods -n devops -l app=sonarqube

# Voir les événements
kubectl describe pod -n devops -l app=sonarqube

# Voir les logs
kubectl logs -n devops -l app=sonarqube
```

### Le pipeline ne trouve toujours pas SonarQube

1. Vérifiez que SonarQube répond :
   ```bash
   curl http://localhost:9000/api/system/status
   ```

2. Vérifiez que l'IP est correcte (pour Docker) :
   ```bash
   # Depuis Jenkins, tester :
   curl http://172.29.114.102:9000/api/system/status
   ```

3. Vérifiez les logs du pipeline pour voir quelle URL est testée

## ✅ Recommandation

**Pour un démarrage rapide**, utilisez **Option 1 (Docker)** car c'est plus simple et plus rapide :

```bash
docker run -d --name sonarqube -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest
```

Puis attendez 2-3 minutes et vérifiez :
```bash
curl http://localhost:9000/api/system/status
```

Une fois que SonarQube répond, relancez votre pipeline Jenkins !

