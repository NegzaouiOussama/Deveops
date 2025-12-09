# Guide de Déploiement Kubernetes avec Jenkins

Ce guide explique comment déployer automatiquement l'application Spring Boot sur Kubernetes via Jenkins.

## 📋 Prérequis

1. **Jenkins** configuré et fonctionnel
2. **Docker** installé sur le serveur Jenkins
3. **kubectl** installé et configuré sur le serveur Jenkins
4. **Kubernetes Cluster** accessible depuis Jenkins (Minikube ou autre)
5. **Minikube** démarré si vous utilisez Minikube

## 🔧 Configuration de Jenkins

### 1. Vérifier que kubectl est accessible depuis Jenkins

Sur le serveur Jenkins, vérifiez :

```bash
kubectl version --client
kubectl get nodes
```

### 2. Configurer kubectl pour Jenkins

Consultez `CONFIGURER_JENKINS_KUBECTL.md` pour un guide détaillé sur la configuration de kubectl pour Jenkins.

#### Résumé rapide :

Si Jenkins est sur la même machine que Minikube :

```bash
# Créer le répertoire .kube pour Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo chown jenkins:jenkins /var/lib/jenkins/.kube

# Copier le kubeconfig
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config

# Copier les certificats Minikube
sudo mkdir -p /var/lib/jenkins/.minikube/profiles/minikube
sudo cp ~/.minikube/ca.crt /var/lib/jenkins/.minikube/ca.crt
sudo cp ~/.minikube/profiles/minikube/client.crt /var/lib/jenkins/.minikube/profiles/minikube/client.crt
sudo cp ~/.minikube/profiles/minikube/client.key /var/lib/jenkins/.minikube/profiles/minikube/client.key
sudo chown -R jenkins:jenkins /var/lib/jenkins/.minikube

# Modifier le kubeconfig pour pointer vers les certificats de Jenkins
sudo nano /var/lib/jenkins/.kube/config
# Changer les chemins de /home/user/.minikube/ vers /var/lib/jenkins/.minikube/
```

### 3. Configurer kubectl pour se connecter à Minikube (si nécessaire)

Si Jenkins est sur une machine différente de Minikube :

```bash
# Copier le kubeconfig de Minikube vers Jenkins
scp ~/.kube/config jenkins@jenkins-server:~/.kube/config
```

Ou si Jenkins est sur la même machine que Minikube :

```bash
# Assurez-vous que le user Jenkins peut accéder au kubeconfig
sudo chown -R jenkins:jenkins ~/.kube
```

### 4. Vérifier les permissions Docker

```bash
# Sur le serveur Jenkins
sudo usermod -aG docker jenkins
# Redémarrer Jenkins après cette commande
```

## 📁 Structure des Manifests Kubernetes

```
k8s/
├── mysql-secret.yaml          # Secret avec credentials MySQL
├── mysql-pvc.yaml             # PersistentVolumeClaim pour MySQL
├── mysql-deployment.yaml      # Deployment MySQL
├── mysql-service.yaml         # Service MySQL (ClusterIP)
├── app-configmap.yaml         # ConfigMap pour configuration Spring Boot (non sensible)
├── app-secret.yaml            # Secret avec credentials MySQL pour Spring Boot
├── app-deployment.yaml        # Deployment Spring Boot
└── app-service.yaml           # Service Spring Boot (NodePort)
```

## 🚀 Pipeline Jenkins

Le pipeline Jenkins (`Jenkinsfile`) effectue automatiquement :

1. **Checkout** - Récupère le code depuis GitHub
2. **Test** - Exécute les tests unitaires avec JaCoCo
3. **Generate JaCoCo Report** - Génère le rapport de couverture
4. **Package** - Package l'application en JAR
5. **MVN SONARQUBE** - Analyse la qualité du code
6. **Build Docker Image** - Construit l'image Docker
7. **Push Docker Image** - Push l'image vers Docker Hub
8. **Create Kubernetes Namespace** - Crée le namespace `devops`
9. **Deploy MySQL to Kubernetes** - Déploie MySQL
10. **Wait for MySQL to be Ready** - Attend que MySQL soit prêt
11. **Update App Image Tag** - Met à jour le tag de l'image
12. **Deploy Application to Kubernetes** - Déploie l'application
13. **Wait for Application to be Ready** - Attend que l'app soit prête
14. **Expose Services and Test Application** - Teste l'application
15. **Verify Code Quality on Pod** - Vérifie la qualité sur le pod

## 🔍 Commandes Manuelles de Déploiement

### Déployer MySQL

```bash
kubectl apply -f k8s/mysql-secret.yaml
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml

# Vérifier
kubectl get pods -n devops -l app=mysql
kubectl wait --for=condition=ready pod -l app=mysql -n devops --timeout=300s
```

### Déployer l'Application Spring Boot

```bash
# ConfigMap (configuration non sensible)
kubectl apply -f k8s/app-configmap.yaml

# Secret (credentials sécurisés)
kubectl apply -f k8s/app-secret.yaml

# Deployment
kubectl apply -f k8s/app-deployment.yaml

# Service
kubectl apply -f k8s/app-service.yaml

# Vérifier
kubectl get pods -n devops -l app=student-management
kubectl wait --for=condition=ready pod -l app=student-management -n devops --timeout=300s
```

## 🌐 Accéder à l'Application

### Avec Minikube

```bash
# Obtenir l'URL du service
minikube service student-management -n devops --url

# Ou manuellement
export NODEPORT=$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}')
export CLUSTER_IP=$(minikube ip)
echo "Application URL: http://${CLUSTER_IP}:${NODEPORT}/student"
```

### URLs Disponibles

- **Application** : `http://<CLUSTER_IP>:<NODEPORT>/student`
- **Health Check** : `http://<CLUSTER_IP>:<NODEPORT>/student/actuator/health`
- **Swagger UI** : `http://<CLUSTER_IP>:<NODEPORT>/student/swagger-ui.html`

## 🔄 Mise à Jour de l'Application

Le pipeline Jenkins met automatiquement à jour l'application avec chaque build :

```bash
# Dans le pipeline, l'image est mise à jour avec :
kubectl set image deployment/student-management student-management=negzaoui/student-management:BUILD_NUMBER -n devops
```

Pour mettre à jour manuellement :

```bash
# Mettre à jour l'image
kubectl set image deployment/student-management student-management=negzaoui/student-management:latest -n devops

# Vérifier le rollout
kubectl rollout status deployment/student-management -n devops

# Voir l'historique
kubectl rollout history deployment/student-management -n devops
```

## 🐛 Dépannage

### Vérifier les Pods

```bash
# Tous les pods
kubectl get pods -n devops

# Logs d'un pod
kubectl logs -n devops -l app=student-management --tail=100

# Décrire un pod
kubectl describe pod -n devops <pod-name>
```

### Vérifier les Services

```bash
# Tous les services
kubectl get services -n devops

# Détails d'un service
kubectl describe service student-management -n devops
```

### Vérifier la Connectivité MySQL

```bash
# Depuis un pod de l'application
kubectl exec -it -n devops $(kubectl get pod -l app=student-management -n devops -o jsonpath='{.items[0].metadata.name}') -- sh

# Dans le pod, tester MySQL
wget -qO- http://mysql:3306 || echo "MySQL not reachable"
```

### Redémarrer un Deployment

```bash
kubectl rollout restart deployment/student-management -n devops
```

## 🗑️ Nettoyage

### Supprimer l'Application

```bash
kubectl delete -f k8s/app-service.yaml
kubectl delete -f k8s/app-deployment.yaml
kubectl delete -f k8s/app-secret.yaml
kubectl delete -f k8s/app-configmap.yaml
```

### Supprimer MySQL

```bash
kubectl delete -f k8s/mysql-service.yaml
kubectl delete -f k8s/mysql-deployment.yaml
kubectl delete -f k8s/mysql-pvc.yaml
kubectl delete -f k8s/mysql-secret.yaml
```

### Supprimer Tout le Namespace

```bash
kubectl delete namespace devops
```

## 📝 Notes Importantes

1. **Image Pull Policy** : Le deployment utilise `imagePullPolicy: Always` pour toujours récupérer la dernière version
2. **Replicas** : L'application est déployée avec 2 replicas pour la haute disponibilité
3. **Health Checks** : L'application a des probes de liveness et readiness sur `/student/actuator/health`
4. **NodePort** : Le service utilise NodePort 30080 pour exposer l'application
5. **ConfigMap et Secret** : La configuration non sensible est dans le ConfigMap, les credentials sont dans un Secret séparé
6. **envFrom** : Le Deployment utilise `envFrom` avec `configMapRef` et `secretRef` pour charger toutes les variables d'environnement automatiquement

## 🔐 Sécurité

⚠️ **Important** : Pour la production, ne stockez PAS les mots de passe en clair dans les ConfigMaps. Utilisez des Secrets :

```bash
kubectl create secret generic app-secret --from-literal=db-password=rootpassword -n devops
```

Puis référencer dans le deployment avec `secretKeyRef`.

