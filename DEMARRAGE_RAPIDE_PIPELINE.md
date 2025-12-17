# 🚀 Démarrage Rapide - Pipeline Jenkins après Redémarrage PC

## ⚠️ Problème

Après avoir arrêté et redémarré votre PC, le pipeline Jenkins échoue avec l'erreur :
```
error: error validating "STDIN": error validating data: failed to download openapi: 
Get "https://127.0.0.1:32771/openapi/v2?timeout=32s": dial tcp 127.0.0.1:32771: 
connect: connection refused
```

**Cause** : Minikube n'est pas démarré. Minikube ne démarre pas automatiquement après un redémarrage du PC.

## ✅ Solution : Checklist de Démarrage

### Étape 1 : Démarrer Minikube (Obligatoire)

Ouvrez **WSL** et exécutez :

```bash
# Vérifier l'état de Minikube
minikube status

# Si Minikube n'est pas démarré, le démarrer
minikube start

# Attendre que Minikube soit complètement démarré (peut prendre 1-2 minutes)
minikube status
```

**Résultat attendu** :
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Étape 2 : Vérifier que kubectl fonctionne

```bash
# Vérifier que kubectl peut se connecter au cluster
kubectl get nodes

# Résultat attendu :
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   XXm   v1.34.0
```

### Étape 3 : Vérifier que Jenkins peut utiliser kubectl

```bash
# Tester en tant qu'utilisateur Jenkins
sudo -u jenkins kubectl get nodes

# Si cette commande échoue, voir "Problème d'Accès Jenkins" ci-dessous
```

### Étape 4 : Vérifier le namespace devops existe

```bash
# Vérifier que le namespace devops existe
kubectl get namespace devops

# Si le namespace n'existe pas, il sera créé automatiquement par le pipeline
```

### Étape 5 : Relancer le Pipeline Jenkins

Une fois les étapes 1-3 réussies, vous pouvez relancer votre pipeline Jenkins.

## 🔧 Script Automatique de Démarrage

Créez un fichier `start-minikube-for-jenkins.sh` dans WSL :

```bash
#!/bin/bash

echo "========================================="
echo "Démarrage de Minikube pour Jenkins"
echo "========================================="
echo ""

# Vérifier l'état de Minikube
echo "1. Vérification de l'état de Minikube..."
if minikube status >/dev/null 2>&1; then
    echo "✅ Minikube est déjà démarré"
    minikube status
else
    echo "⚠️  Minikube n'est pas démarré. Démarrage en cours..."
    minikube start
    echo "✅ Minikube démarré avec succès"
fi

echo ""
echo "2. Vérification de kubectl..."
if kubectl get nodes >/dev/null 2>&1; then
    echo "✅ kubectl peut se connecter au cluster"
    kubectl get nodes
else
    echo "❌ Erreur: kubectl ne peut pas se connecter au cluster"
    exit 1
fi

echo ""
echo "3. Vérification de l'accès Jenkins à kubectl..."
if sudo -u jenkins kubectl get nodes >/dev/null 2>&1; then
    echo "✅ Jenkins peut utiliser kubectl"
else
    echo "⚠️  Avertissement: Jenkins ne peut pas utiliser kubectl"
    echo "   Ceci peut être normal si kubectl est configuré différemment"
fi

echo ""
echo "4. Vérification du namespace devops..."
if kubectl get namespace devops >/dev/null 2>&1; then
    echo "✅ Le namespace devops existe"
else
    echo "ℹ️  Le namespace devops n'existe pas encore (sera créé par le pipeline)"
fi

echo ""
echo "========================================="
echo "✅ Minikube est prêt pour Jenkins !"
echo "========================================="
echo ""
echo "Vous pouvez maintenant relancer votre pipeline Jenkins."
```

**Utilisation** :

```bash
# Rendre le script exécutable
chmod +x start-minikube-for-jenkins.sh

# Exécuter le script
./start-minikube-for-jenkins.sh
```

## 🐛 Dépannage

### Problème 1 : Minikube ne démarre pas

```bash
# Voir les logs détaillés
minikube start --v=7

# Ou si vous avez des problèmes, supprimer et recréer (ATTENTION: supprime tout)
minikube delete
minikube start
```

### Problème 2 : Jenkins ne peut pas utiliser kubectl

Si `sudo -u jenkins kubectl get nodes` échoue, vérifiez :

```bash
# Vérifier que le fichier kubeconfig existe pour Jenkins
sudo ls -la /var/lib/jenkins/.kube/config

# Si le fichier n'existe pas, voir CONFIGURER_JENKINS_KUBECTL.md
# pour configurer kubectl pour Jenkins
```

### Problème 3 : kubectl ne peut pas se connecter

```bash
# Réinitialiser le contexte kubectl
minikube update-context

# Vérifier le contexte actuel
kubectl config current-context

# Devrait afficher : minikube
```

## 📋 Checklist Rapide (Avant de Lancer le Pipeline)

- [ ] ✅ Minikube est démarré (`minikube status` affiche "Running")
- [ ] ✅ kubectl fonctionne (`kubectl get nodes` fonctionne)
- [ ] ✅ Jenkins peut utiliser kubectl (optionnel, dépend de la configuration)
- [ ] ✅ Docker est démarré (si nécessaire pour Minikube)

## ⚡ Commandes Ultra-Rapides

Pour une vérification rapide, exécutez simplement :

```bash
# Dans WSL
minikube status || minikube start
kubectl get nodes
```

Si ces deux commandes fonctionnent, vous pouvez relancer votre pipeline Jenkins !

## 🔄 Amélioration du Pipeline (Optionnel)

Pour rendre le pipeline plus robuste, vous pouvez ajouter un stage au début qui vérifie/démarre Minikube automatiquement :

```groovy
stage('Verify Kubernetes Cluster') {
    steps {
        script {
            sh """
                # Vérifier si Minikube est démarré
                if ! minikube status >/dev/null 2>&1; then
                    echo "Minikube n'est pas démarré. Démarrage en cours..."
                    minikube start || {
                        echo "Erreur: Impossible de démarrer Minikube"
                        exit 1
                    }
                fi
                
                # Vérifier que kubectl peut se connecter
                kubectl cluster-info || {
                    echo "Erreur: Impossible de se connecter au cluster Kubernetes"
                    exit 1
                }
            """
        }
    }
}
```

**Note** : Cette solution nécessite que l'utilisateur qui exécute Jenkins ait les permissions pour démarrer Minikube (généralement, il faut être dans le groupe docker).

## 📝 Résumé

**En résumé, après chaque redémarrage du PC, il faut :**

1. **Ouvrir WSL**
2. **Exécuter** : `minikube start`
3. **Vérifier** : `kubectl get nodes`
4. **Relancer le pipeline Jenkins**

C'est tout ! 🎉

