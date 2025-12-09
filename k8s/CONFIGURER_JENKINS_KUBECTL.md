# Configurer kubectl pour Jenkins

Ce guide explique comment donner accès à kubectl à Jenkins pour qu'il puisse déployer automatiquement sur Kubernetes.

## 📋 Problème

Par défaut, l'utilisateur Jenkins n'a pas le droit d'exécuter `kubectl`. Sans cette configuration, Jenkins ne peut pas déployer automatiquement l'application dans Kubernetes.

## 🔧 Solution : Donner accès à Jenkins à la configuration Kubernetes

### Étape 1 : Créer le répertoire .kube pour Jenkins

```bash
sudo mkdir -p /var/lib/jenkins/.kube
sudo chown jenkins:jenkins /var/lib/jenkins/.kube
```

### Étape 2 : Copier le fichier kubeconfig

#### Option A : Si Jenkins est sur la même machine que Minikube

```bash
# Copier le kubeconfig vers Jenkins
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
```

#### Option B : Si Jenkins est sur une autre machine

```bash
# Sur la machine avec Minikube
scp ~/.kube/config jenkins@jenkins-server:/tmp/kubeconfig

# Sur la machine Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp /tmp/kubeconfig /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
```

### Étape 3 : Copier les certificats Minikube

Les chemins dans le kubeconfig pointent vers l'utilisateur qui a créé Minikube. Il faut les adapter pour Jenkins.

#### 3.1. Créer le répertoire .minikube pour Jenkins

```bash
sudo mkdir -p /var/lib/jenkins/.minikube/profiles/minikube
sudo chown -R jenkins:jenkins /var/lib/jenkins/.minikube
```

#### 3.2. Copier les certificats

```bash
# Si Jenkins est sur la même machine
sudo cp ~/.minikube/ca.crt /var/lib/jenkins/.minikube/ca.crt
sudo cp ~/.minikube/profiles/minikube/client.crt /var/lib/jenkins/.minikube/profiles/minikube/client.crt
sudo cp ~/.minikube/profiles/minikube/client.key /var/lib/jenkins/.minikube/profiles/minikube/client.key
sudo chown -R jenkins:jenkins /var/lib/jenkins/.minikube
```

### Étape 4 : Modifier le kubeconfig pour Jenkins

Éditer le fichier kubeconfig de Jenkins :

```bash
sudo nano /var/lib/jenkins/.kube/config
```

Modifier les chemins pour qu'ils pointent vers `/var/lib/jenkins/.minikube/...` :

**Avant :**
```yaml
clusters:
- cluster:
    certificate-authority: /home/vagrant/.minikube/ca.crt
    ...
users:
- user:
    client-certificate: /home/vagrant/.minikube/profiles/minikube/client.crt
    client-key: /home/vagrant/.minikube/profiles/minikube/client.key
```

**Après :**
```yaml
clusters:
- cluster:
    certificate-authority: /var/lib/jenkins/.minikube/ca.crt
    ...
users:
- user:
    client-certificate: /var/lib/jenkins/.minikube/profiles/minikube/client.crt
    client-key: /var/lib/jenkins/.minikube/profiles/minikube/client.key
```

### Étape 5 : Donner les droits à Jenkins sur les fichiers

```bash
********
# Donner la propriété complète du répertoire .kube à Jenkins
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

# Corriger les droits pour la sécurité (optionnel, pour l'utilisateur original)
# sudo chown vagrant:vagrant /home/vagrant/.kube/config
# chmod 600 /home/vagrant/.kube/config
```

### Étape 6 : Vérifier l'accès

Tester que Jenkins peut utiliser kubectl :

```bash
# Tester en tant qu'utilisateur Jenkins
sudo -u jenkins kubectl version --client
sudo -u jenkins kubectl get nodes

# Vérifier les pods dans le namespace devops
sudo -u jenkins kubectl get pods -n devops

# Vérifier les services
sudo -u jenkins kubectl get svc -n devops

# Si toutes les commandes fonctionnent, Jenkins est correctement configuré
```

Vous devriez voir quelque chose comme :

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   4d    v1.34.0
```

### Étape 7 : Redémarrer Jenkins (si nécessaire)

```bash
sudo systemctl restart jenkins
# Ou selon votre installation
sudo service jenkins restart
```

## ✅ Vérification Finale

Dans Jenkins, créez un job de test qui exécute :

```groovy
pipeline {
    agent any
    stages {
        stage('Test kubectl') {
            steps {
                sh 'kubectl version --client'
                sh 'kubectl get nodes'
                sh 'kubectl get namespaces'
            }
        }
    }
}
```

Si toutes les commandes fonctionnent, Jenkins est correctement configuré pour utiliser kubectl.

## 🔍 Alternative : Utiliser un Service Account Kubernetes

Pour plus de sécurité, vous pouvez créer un Service Account Kubernetes avec des permissions limitées :

### 1. Créer un Service Account

```bash
kubectl create serviceaccount jenkins -n devops
```

### 2. Créer un ClusterRoleBinding (pour accès au cluster)

```bash
kubectl create clusterrolebinding jenkins-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=devops:jenkins
```

### 3. Récupérer le token

```bash
SECRET=$(kubectl get serviceaccount jenkins -n devops -o jsonpath='{.secrets[0].name}')
kubectl get secret $SECRET -n devops -o jsonpath='{.data.token}' | base64 -d
```

### 4. Utiliser le token dans Jenkins

Dans le kubeconfig de Jenkins, remplacer les certificats par le token.

## 📝 Notes Importantes

1. **Sécurité** : Ne partagez jamais les certificats ou tokens en dehors de votre infrastructure
2. **Permissions** : Assurez-vous que seul Jenkins a accès au kubeconfig
3. **Backup** : Sauvegardez les fichiers de configuration avant de les modifier
4. **WSL** : Si vous utilisez WSL, les chemins seront différents (par exemple `/home/user/.kube/`)

## 🐛 Dépannage

### Erreur : "permission denied"

```bash
# Donner les droits complets sur le répertoire .kube
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

# Corriger les droits pour la sécurité
sudo chmod 600 /var/lib/jenkins/.kube/config
```

### Vérifier les Commandes (comme dans la présentation)

```bash
# Étape 2 – Vérification : Tester si Jenkins peut exécuter kubectl
sudo -u jenkins kubectl get nodes

# Vérifier les Pods dans le namespace devops
sudo -u jenkins kubectl get pods -n devops

# Vérifier les Services
sudo -u jenkins kubectl get svc -n devops

# Consulter les logs de l'application Spring Boot
sudo -u jenkins kubectl logs -n devops -l app=student-management --tail=50
```

### Erreur : "cannot connect to the server"

Vérifiez que :
- Minikube est démarré : `minikube status`
- Le serveur dans le kubeconfig est correct
- Les certificats sont bien copiés

### Erreur : "x509: certificate signed by unknown authority"

Les certificats ne sont pas correctement copiés ou les chemins dans le kubeconfig sont incorrects.

