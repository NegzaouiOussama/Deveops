# Solution aux Problèmes de Déploiement MySQL

## Problème 1 : ImagePullBackOff

Minikube ne peut pas télécharger l'image MySQL depuis Docker Hub.

### Solution : Charger l'image dans Minikube

```bash
# Méthode 1 : Utiliser l'environnement Docker de Minikube
eval $(minikube docker-env)
docker pull mysql:8.0
eval $(minikube docker-env -u)

# OU Méthode 2 : Charger depuis Docker local
docker pull mysql:8.0
minikube image load mysql:8.0

# OU Méthode 3 : Forcer Minikube à utiliser Docker Hub
minikube ssh
docker pull mysql:8.0
exit
```

## Problème 2 : Deux Services MySQL

Il y a deux services créés (`mysql` et `mysql-service`).

### Solution : Supprimer l'ancien service

```bash
kubectl delete service mysql -n devops
```

Le bon service est `mysql-service` (utilisé par l'application Spring Boot).

## Problème 3 : Nettoyer et Redéployer

Si vous voulez tout nettoyer et recommencer :

```bash
# Supprimer tout
kubectl delete deployment mysql -n devops
kubectl delete service mysql mysql-service -n devops
kubectl delete pvc mysql-pvc -n devops

# Redéployer
kubectl apply -f k8s/mysql-secret.yaml
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml
```

