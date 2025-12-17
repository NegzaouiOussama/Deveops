# 🚀 Démarrage Rapide - Pipeline Jenkins

## ⚡ Après Redémarrage du PC : 2 Commandes Seulement !

Ouvrez **WSL** et exécutez :

```bash
minikube start
kubectl get nodes
```

Si ces deux commandes fonctionnent ✅, **vous pouvez relancer votre pipeline Jenkins** !

---

## 📋 Résumé Complet

### Le Problème
Après un redémarrage, Minikube n'est plus démarré, donc Jenkins ne peut pas se connecter à Kubernetes.

### La Solution
1. Démarrer Minikube : `minikube start`
2. Vérifier : `kubectl get nodes`
3. Relancer le pipeline Jenkins

---

## 🔄 Script Automatique (Optionnel)

Pour une vérification complète, utilisez le script :

```bash
# Dans WSL
./start-minikube-for-jenkins.sh
```

Ce script vérifie tout automatiquement et vous indique si Minikube est prêt.

---

## 📚 Documentation Complète

- **DEMARRAGE_RAPIDE_PIPELINE.md** - Guide détaillé complet
- **COMMANDES_RAPIDES_DEMARRAGE.md** - Commandes de référence rapide

---

## ❓ Problèmes ?

Si `kubectl get nodes` échoue :

```bash
# Réinitialiser le contexte
minikube update-context

# Réessayer
kubectl get nodes
```

---

**C'est tout !** 🎉

