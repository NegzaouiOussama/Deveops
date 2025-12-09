# Déployer SonarQube sur Kubernetes

Ce guide explique comment déployer SonarQube dans le namespace `devops` pour l'intégrer dans le pipeline CI/CD.

## 📋 Prérequis

- Kubernetes cluster opérationnel (Minikube)
- Namespace `devops` créé
- kubectl configuré et fonctionnel

## 🚀 Déploiement de SonarQube

### Option 1 : Déploiement Simple (sans base de données externe)

SonarQube peut fonctionner avec une base de données embarquée pour des tests/développement :

```bash
# Créer le PVC pour SonarQube
kubectl apply -f k8s/sonarqube-pvc.yaml

# Déployer SonarQube
kubectl apply -f k8s/sonarqube-deployment.yaml

# Exposer le service
kubectl apply -f k8s/sonarqube-service.yaml
```

### Option 2 : Utiliser SonarQube Existant (Docker)

Si vous avez déjà SonarQube qui tourne dans Docker (comme dans votre cas), vous pouvez :

1. **Garder SonarQube dans Docker** (recommandé pour simplicité)
2. **Utiliser l'URL existante** : `http://172.29.114.102:9000`

## 🔍 Vérification du Déploiement

### Vérifier les Pods

```bash
kubectl get pods -n devops -l app=sonarqube
```

### Vérifier les Services

```bash
kubectl get svc -n devops | grep sonarqube
```

### Consulter les Logs

```bash
kubectl logs -n devops -l app=sonarqube --tail=100
```

## 🌐 Accéder à SonarQube

### Avec Minikube

```bash
# Obtenir l'URL du service
minikube service sonarqube-service -n devops --url
```

Ou manuellement :

```bash
export NODEPORT=$(kubectl get service sonarqube-service -n devops -o jsonpath='{.spec.ports[0].nodePort}')
export CLUSTER_IP=$(minikube ip)
echo "SonarQube URL: http://${CLUSTER_IP}:${NODEPORT}"
```

### URL par défaut

- **SonarQube** : `http://<MINIKUBE_IP>:32000`
- **Credentials par défaut** : `admin` / `admin`

## 🔄 Intégration dans le Pipeline Jenkins

Le pipeline Jenkins utilise déjà SonarQube via l'URL configurée dans les variables d'environnement :

```groovy
environment {
    SONAR_HOST_URL = "http://172.29.114.102:9000"
    SONAR_TOKEN = "sqa_53a643aea3ccdbcedef2c73df0428a1d8397d01e"
}
```

### Vérifier que l'analyse a été effectuée

Après un build Jenkins, vous pouvez vérifier dans SonarQube :

1. **Accéder à SonarQube** : `http://172.29.114.102:9000` (ou l'URL du pod Kubernetes)
2. **Se connecter** avec vos credentials
3. **Vérifier le projet** : `tn.esprit:student-management`
4. **Voir les résultats** de l'analyse de qualité du code

## 📝 Commandes Utiles

### Redémarrer SonarQube

```bash
kubectl rollout restart deployment/sonarqube -n devops
```

### Voir les ressources utilisées

```bash
kubectl top pods -n devops -l app=sonarqube
```

### Décrire le pod

```bash
kubectl describe pod -n devops -l app=sonarqube
```

## 🗑️ Nettoyage

### Supprimer SonarQube

```bash
kubectl delete -f k8s/sonarqube-service.yaml
kubectl delete -f k8s/sonarqube-deployment.yaml
kubectl delete -f k8s/sonarqube-pvc.yaml
```

## ⚠️ Notes Importantes

1. **SonarQube nécessite beaucoup de mémoire** : Au moins 2GB de RAM
2. **Persistance** : Les données sont stockées dans un PVC
3. **Base de données** : Pour la production, utilisez une base de données externe (PostgreSQL)
4. **Performance** : SonarQube peut prendre plusieurs minutes au démarrage

## 🔐 Sécurité

Pour la production :
- Changez les credentials par défaut
- Utilisez un Ingress avec TLS au lieu de NodePort
- Configurez des quotas de ressources
- Utilisez des Secrets pour les credentials de base de données

