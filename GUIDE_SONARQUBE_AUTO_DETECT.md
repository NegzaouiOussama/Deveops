# Guide : Détection Automatique de SonarQube dans le Pipeline

## 🎯 Fonctionnalité

Le pipeline Jenkins détecte automatiquement où SonarQube est déployé (Docker ou Kubernetes) et utilise l'URL appropriée.

## 🔍 Comment ça fonctionne

### 1. Détection Automatique

Le pipeline vérifie dans cet ordre :

1. **Kubernetes** : Vérifie si un service `sonarqube-service` existe dans le namespace `devops`
   - Si trouvé : Utilise `http://<MINIKUBE_IP>:<NODEPORT>` (généralement port 32000)
   
2. **Docker** : Si SonarQube n'est pas dans Kubernetes, utilise l'URL configurée
   - URL par défaut : `http://172.29.114.102:9000`

### 2. Vérification de Disponibilité

Avant d'exécuter l'analyse, le pipeline :
- Teste la connectivité à l'URL SonarQube détectée
- Vérifie que le serveur répond avec un code HTTP 200

### 3. Comportement en Cas d'Erreur

- Si SonarQube est **accessible** : L'analyse s'exécute normalement ✅
- Si SonarQube n'est **pas accessible** : Un avertissement est affiché, mais le pipeline continue ⚠️

## 📋 Configuration Requise

### SonarQube dans Kubernetes

Si SonarQube est déployé dans Kubernetes :

```bash
# Vérifier que SonarQube est déployé
kubectl get pods -n devops -l app=sonarqube

# Vérifier le service
kubectl get svc sonarqube-service -n devops

# Le service doit exposer le port 32000 (NodePort)
```

### SonarQube dans Docker

Si SonarQube est dans Docker, assurez-vous que :
- SonarQube est accessible à l'URL configurée : `http://172.29.114.102:9000`
- Le firewall permet les connexions depuis Jenkins

## 🔧 Configuration du Pipeline

Le pipeline utilise ces variables d'environnement :

```groovy
environment {
    SONAR_HOST_URL = "http://172.29.114.102:9000"  // URL Docker par défaut
    SONAR_TOKEN = "sqa_53a643aea3ccdbcedef2c73df0428a1d8397d01e"
}
```

**Note** : L'URL peut être surchargée automatiquement si SonarQube est détecté dans Kubernetes.

## 📊 Exemple de Logs

### SonarQube dans Kubernetes

```
✅ SonarQube détecté dans Kubernetes : http://192.168.49.2:32000
🔍 Vérification de l'accessibilité de SonarQube...
✅ SonarQube est accessible à http://192.168.49.2:32000 - Exécution de l'analyse...
✅ Analyse SonarQube réussie
```

### SonarQube dans Docker

```
ℹ️  Utilisation de l'URL SonarQube Docker : http://172.29.114.102:9000
🔍 Vérification de l'accessibilité de SonarQube...
✅ SonarQube est accessible à http://172.29.114.102:9000 - Exécution de l'analyse...
✅ Analyse SonarQube réussie
```

### SonarQube Non Accessible

```
ℹ️  Utilisation de l'URL SonarQube Docker : http://172.29.114.102:9000
🔍 Vérification de l'accessibilité de SonarQube...
⚠️  SonarQube non disponible - le pipeline continue
```

## 🚀 Déploiement de SonarQube dans Kubernetes

Si vous voulez déployer SonarQube dans Kubernetes :

```bash
# Créer le PVC
kubectl apply -f k8s/sonarqube-pvc.yaml

# Déployer SonarQube
kubectl apply -f k8s/sonarqube-deployment.yaml

# Exposer le service
kubectl apply -f k8s/sonarqube-service.yaml

# Vérifier le déploiement
kubectl get pods -n devops -l app=sonarqube
kubectl get svc sonarqube-service -n devops

# Accéder à SonarQube
minikube service sonarqube-service -n devops --url
```

## 🔍 Dépannage

### SonarQube n'est pas détecté dans Kubernetes

Vérifiez :
```bash
# Le service existe-t-il ?
kubectl get svc sonarqube-service -n devops

# Le pod est-il Running ?
kubectl get pods -n devops -l app=sonarqube
```

### SonarQube dans Kubernetes n'est pas accessible

Vérifiez :
```bash
# Le NodePort est-il correct ?
kubectl get svc sonarqube-service -n devops -o jsonpath='{.spec.ports[0].nodePort}'

# L'IP de Minikube
minikube ip

# Test de connectivité
curl http://<MINIKUBE_IP>:32000/api/system/status
```

### SonarQube dans Docker n'est pas accessible

Vérifiez :
```bash
# SonarQube est-il démarré ?
docker ps | grep sonarqube

# Le port 9000 est-il ouvert ?
curl http://172.29.114.102:9000/api/system/status
```

## ✅ Avantages

1. **Flexible** : Fonctionne avec SonarQube dans Docker ou Kubernetes
2. **Automatique** : Détection automatique de l'emplacement
3. **Robuste** : Continue même si SonarQube n'est pas disponible
4. **Informatif** : Logs clairs sur ce qui est détecté et utilisé

