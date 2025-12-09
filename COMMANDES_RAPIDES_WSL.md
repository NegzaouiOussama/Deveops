# Commandes Rapides pour WSL

## 🔧 Problèmes Courants

### 1. Erreur : "k8s/... does not exist"

**Cause** : Vous n'êtes pas dans le répertoire du projet

**Solution** :
```bash
cd /mnt/c/Users/Negza/Documents/GitHub/Deveops
```

Puis réessayez :
```bash
kubectl apply -f k8s/mysql-secret.yaml
```

### 2. Corriger le kubeconfig pour Jenkins

**Méthode rapide avec sed** :
```bash
# Modifier tous les chemins en une commande
sudo sed -i 's|/home/negzaoui/.minikube|/var/lib/jenkins/.minikube|g' /var/lib/jenkins/.kube/config

# Corriger les permissions
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
sudo chmod 600 /var/lib/jenkins/.kube/config

# Tester
sudo -u jenkins kubectl get nodes
```

### 3. Problème Docker Hub (DNS/Network)

**Si vous ne pouvez pas pull depuis Docker Hub**, Minikube utilisera son propre Docker. Vous n'avez pas besoin de pull manuellement, Kubernetes le fera automatiquement.

**Option** : Utiliser l'image déjà disponible localement
```bash
# Vérifier les images disponibles
docker images | grep mysql

# Si l'image existe déjà, Minikube l'utilisera
```

## 📋 Checklist Complète

### Avant de déployer :

1. **Aller dans le répertoire du projet** :
```bash
cd /mnt/c/Users/Negza/Documents/GitHub/Deveops
```

2. **Vérifier que Minikube est démarré** :
```bash
minikube status
```

3. **Vérifier kubectl fonctionne** :
```bash
kubectl get nodes
```

4. **Vérifier que Jenkins peut utiliser kubectl** :
```bash
sudo -u jenkins kubectl get nodes
```

5. **Déployer MySQL** :
```bash
kubectl apply -f k8s/mysql-secret.yaml
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml
```

## 🚀 Commandes de Déploiement Complet

```bash
# 1. Aller dans le projet
cd /mnt/c/Users/Negza/Documents/GitHub/Deveops

# 2. Déployer MySQL
kubectl apply -f k8s/mysql-secret.yaml
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml

# 3. Attendre MySQL
kubectl wait --for=condition=ready pod -l app=mysql -n devops --timeout=300s

# 4. Déployer l'application
kubectl apply -f k8s/app-configmap.yaml
kubectl apply -f k8s/app-secret.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml

# 5. Vérifier
kubectl get pods -n devops
kubectl get services -n devops
```

