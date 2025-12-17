# ⚡ Commandes Rapides - Démarrage Pipeline Jenkins

## 🎯 Après Redémarrage du PC

### Commandes Essentielles (à exécuter dans WSL)

```bash
# 1. Démarrer Minikube
minikube start

# 2. Vérifier que tout fonctionne
kubectl get nodes
```

**C'est tout !** Si ces deux commandes fonctionnent, vous pouvez relancer votre pipeline Jenkins.

---

## 📋 Checklist Complète (si vous avez des problèmes)

```bash
# 1. Vérifier/Démarrer Minikube
minikube status || minikube start

# 2. Vérifier kubectl
kubectl get nodes

# 3. Vérifier Jenkins (optionnel)
sudo -u jenkins kubectl get nodes

# 4. Vérifier le namespace
kubectl get namespace devops
```

---

## 🔄 Script Automatique

Utilisez le script `start-minikube-for-jenkins.sh` :

```bash
# Rendre exécutable (une seule fois)
chmod +x start-minikube-for-jenkins.sh

# Exécuter
./start-minikube-for-jenkins.sh
```

---

## ❌ Erreurs Courantes et Solutions

### Erreur : "connection refused"
**Solution** : `minikube start`

### Erreur : "kubectl: command not found"
**Solution** : Minikube n'est pas démarré ou kubectl n'est pas installé

### Erreur : "cannot connect to the Docker daemon"
**Solution** : Démarrer Docker ou utiliser `minikube start --driver=docker`

---

## ⏱️ Temps de Démarrage

- **Minikube** : ~1-2 minutes au premier démarrage
- **Vérifications** : ~5 secondes

---

## 💡 Astuce

Ajoutez cette ligne à votre `.bashrc` ou `.zshrc` pour un alias rapide :

```bash
alias jenkins-start="minikube start && kubectl get nodes"
```

Ensuite, vous pouvez simplement taper : `jenkins-start`

