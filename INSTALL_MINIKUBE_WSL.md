# Installation de Minikube dans WSL

## 📋 Prérequis

Ces commandes sont conçues pour WSL (Windows Subsystem for Linux).

## 🔧 Étape 1 : Mettre à jour le système

```bash
sudo apt update && sudo apt upgrade -y
```

## 🐳 Étape 2 : Installer Docker

### 2.1. Installer les dépendances

```bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
```

### 2.2. Ajouter la clé GPG officielle de Docker

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### 2.3. Ajouter le dépôt Docker

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 2.4. Installer Docker

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### 2.5. Démarrer Docker et l'ajouter au démarrage

```bash
sudo service docker start
```

### 2.6. Ajouter votre utilisateur au groupe docker (pour éviter d'utiliser sudo)

```bash
sudo usermod -aG docker $USER
```

### 2.7. Vérifier l'installation de Docker

```bash
docker --version
```

**⚠️ Important :** Après cette commande, vous devrez **fermer et rouvrir votre terminal WSL** pour que les changements de groupe prennent effet.

## 📦 Étape 3 : Installer kubectl

### 3.1. Télécharger kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

### 3.2. Installer kubectl

```bash
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 3.3. Vérifier l'installation

```bash
kubectl version --client
```

### 3.4. Nettoyer le fichier téléchargé

```bash
rm kubectl
```

## 🚀 Étape 4 : Installer Minikube

### 4.1. Télécharger Minikube

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
```

### 4.2. Installer Minikube

```bash
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### 4.3. Vérifier l'installation

```bash
minikube version
```

### 4.4. Nettoyer le fichier téléchargé

```bash
rm minikube-linux-amd64
```

## ▶️ Étape 5 : Démarrer Minikube

### 5.1. Démarrer Minikube avec Docker (recommandé pour WSL)

```bash
minikube start --driver=docker
```

### 5.2. Ou avec plus de ressources (optionnel)

```bash
minikube start --driver=docker --cpus=4 --memory=4096 --disk-size=20g
```

### 5.3. Vérifier que Minikube est démarré

```bash
kubectl get nodes
```

Vous devriez voir quelque chose comme :
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   XXm   v1.XX.X
```

## ✅ Vérifications Finales

### Vérifier le statut de Minikube

```bash
minikube status
```

### Vérifier que kubectl fonctionne

```bash
kubectl get pods --all-namespaces
```

### Obtenir l'IP de Minikube

```bash
minikube ip
```

## 🔍 Commandes Utiles

### Arrêter Minikube

```bash
minikube stop
```

### Démarrer Minikube (après l'avoir arrêté)

```bash
minikube start
```

### Supprimer complètement Minikube

```bash
minikube delete
```

### Voir le dashboard Minikube

```bash
minikube dashboard
```

### Voir les logs de Minikube

```bash
minikube logs
```

## 🎯 Créer le Namespace "devops"

Une fois Minikube démarré, créez le namespace pour votre projet :

```bash
kubectl create namespace devops
```

### Vérifier que le namespace est créé

```bash
kubectl get namespaces
```

## ⚠️ Notes Importantes pour WSL

1. **Docker Desktop** : Si vous avez Docker Desktop installé sur Windows, vous pouvez aussi l'utiliser. Assurez-vous que le service Docker fonctionne.

2. **Après avoir ajouté l'utilisateur au groupe docker** : Vous devez **fermer et rouvrir votre terminal WSL** pour que les changements prennent effet.

3. **Permissions** : Si vous avez des erreurs de permission avec Docker, utilisez `sudo` ou vérifiez que vous avez bien redémarré le terminal.

4. **Ressources** : Ajustez `--cpus`, `--memory` et `--disk-size` selon les ressources disponibles sur votre machine.

## 🐛 Dépannage

### Si Minikube ne démarre pas :

```bash
minikube delete
minikube start --driver=docker --force
```

### Si Docker n'est pas accessible :

```bash
sudo service docker status
sudo service docker restart
```

### Vérifier les logs d'erreur :

```bash
minikube logs
```

