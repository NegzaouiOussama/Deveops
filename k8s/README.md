# Manifests Kubernetes pour Student Management

Ce dossier contient tous les manifests Kubernetes nécessaires pour déployer l'application Student Management sur un cluster Kubernetes.

## Structure des fichiers

### MySQL
- `mysql-secret.yaml` - Secret contenant les credentials MySQL
- `mysql-pv.yaml` - PersistentVolume pour le stockage MySQL (optionnel pour Minikube)
- `mysql-pvc.yaml` - PersistentVolumeClaim pour demander du stockage
- `mysql-deployment.yaml` - Deployment MySQL avec le volume persistant
- `mysql-service.yaml` - Service ClusterIP pour exposer MySQL

### Application Spring Boot
- `app-configmap.yaml` - ConfigMap avec la configuration Spring Boot (URL DB, non sensible)
- `app-secret.yaml` - Secret avec les credentials MySQL (sécurisé)
- `app-deployment.yaml` - Deployment Spring Boot avec 2 replicas
- `app-service.yaml` - Service NodePort pour exposer l'application

### SonarQube (Optionnel)
- `sonarqube-pvc.yaml` - PersistentVolumeClaim pour SonarQube
- `sonarqube-deployment.yaml` - Deployment SonarQube
- `sonarqube-service.yaml` - Service NodePort pour SonarQube (port 32000)

## Déploiement

### Déploiement Automatique via Jenkins

Le pipeline Jenkins (`Jenkinsfile`) déploie automatiquement tout. Consultez `DEPLOYMENT_GUIDE.md` pour plus de détails.

### Déploiement Manuel

#### 1. Déployer MySQL

```bash
# Appliquer le Secret
kubectl apply -f k8s/mysql-secret.yaml

# Appliquer le PersistentVolume (optionnel pour Minikube)
kubectl apply -f k8s/mysql-pv.yaml

# Appliquer le PersistentVolumeClaim
kubectl apply -f k8s/mysql-pvc.yaml

# Appliquer le Deployment MySQL
kubectl apply -f k8s/mysql-deployment.yaml

# Appliquer le Service MySQL
kubectl apply -f k8s/mysql-service.yaml
```

#### 2. Vérifier le déploiement MySQL

```bash
# Voir les pods MySQL
kubectl get pods -n devops -l app=mysql

# Voir les services
kubectl get services -n devops

# Voir les PVC
kubectl get pvc -n devops

# Voir les PV
kubectl get pv

# Voir les logs MySQL
kubectl logs -n devops -l app=mysql
```

#### 3. Attendre que MySQL soit prêt

```bash
kubectl wait --for=condition=ready pod -l app=mysql -n devops --timeout=300s
```

#### 4. Déployer l'Application Spring Boot

```bash
# Appliquer le ConfigMap (configuration non sensible)
kubectl apply -f k8s/app-configmap.yaml

# Appliquer le Secret (credentials sécurisés)
kubectl apply -f k8s/app-secret.yaml

# Appliquer le Deployment
kubectl apply -f k8s/app-deployment.yaml

# Appliquer le Service
kubectl apply -f k8s/app-service.yaml
```

#### 5. Vérifier le déploiement de l'Application

```bash
# Voir les pods de l'application
kubectl get pods -n devops -l app=student-management

# Voir les services
kubectl get services -n devops

# Voir les logs
kubectl logs -n devops -l app=student-management
```

#### 6. Attendre que l'Application soit prête

```bash
kubectl wait --for=condition=ready pod -l app=student-management -n devops --timeout=300s
```

#### 7. Accéder à l'Application

```bash
# Avec Minikube
minikube service student-management -n devops --url

# Ou manuellement
export NODEPORT=$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}')
export CLUSTER_IP=$(minikube ip)
echo "Application URL: http://${CLUSTER_IP}:${NODEPORT}/student"
```

## Notes importantes

### Pour Minikube

Minikube a un **storage-provisioner** automatique qui gère les PVs. Deux options :

1. **Option 1 (Recommandée pour Minikube)** : Ne pas créer le PV manuellement
   - Supprimez l'étape `kubectl apply -f k8s/mysql-pv.yaml`
   - Minikube créera automatiquement un PV quand le PVC sera créé

2. **Option 2 (Pour l'apprentissage)** : Utiliser le PV manuel avec hostPath
   - Créez le répertoire sur le node Minikube : `minikube ssh` puis `sudo mkdir -p /data/mysql && sudo chmod 777 /data/mysql`
   - Appliquez le PV manuellement

### Credentials MySQL

Les credentials sont stockés dans le Secret `mysql-secret` :
- **Root password** : `rootpassword`
- **Database** : `studentdb`
- **User** : `studentuser`
- **Password** : `studentpass`

## Commandes utiles

```bash
# Supprimer tous les resources MySQL
kubectl delete -f k8s/mysql-deployment.yaml
kubectl delete -f k8s/mysql-service.yaml
kubectl delete -f k8s/mysql-pvc.yaml
kubectl delete -f k8s/mysql-pv.yaml
kubectl delete -f k8s/mysql-secret.yaml

# Redémarrer le pod MySQL
kubectl rollout restart deployment/mysql -n devops

# Accéder au shell MySQL
kubectl exec -it -n devops $(kubectl get pod -l app=mysql -n devops -o jsonpath='{.items[0].metadata.name}') -- mysql -uroot -prootpassword

# Connecter à MySQL depuis un autre pod
kubectl exec -it -n devops <pod-name> -- mysql -h mysql-service -uroot -prootpassword
```

