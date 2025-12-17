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
    if [ $? -eq 0 ]; then
        echo "✅ Minikube démarré avec succès"
    else
        echo "❌ Erreur lors du démarrage de Minikube"
        exit 1
    fi
fi

echo ""
echo "2. Vérification de kubectl..."
if kubectl get nodes >/dev/null 2>&1; then
    echo "✅ kubectl peut se connecter au cluster"
    kubectl get nodes
else
    echo "❌ Erreur: kubectl ne peut pas se connecter au cluster"
    echo "   Tentative de réinitialisation du contexte..."
    minikube update-context
    if kubectl get nodes >/dev/null 2>&1; then
        echo "✅ kubectl fonctionne maintenant"
        kubectl get nodes
    else
        echo "❌ kubectl ne fonctionne toujours pas"
        exit 1
    fi
fi

echo ""
echo "3. Vérification de l'accès Jenkins à kubectl..."
if sudo -u jenkins kubectl get nodes >/dev/null 2>&1; then
    echo "✅ Jenkins peut utiliser kubectl"
else
    echo "⚠️  Avertissement: Jenkins ne peut pas utiliser kubectl directement"
    echo "   Cela peut être normal selon votre configuration"
fi

echo ""
echo "4. Vérification du namespace devops..."
if kubectl get namespace devops >/dev/null 2>&1; then
    echo "✅ Le namespace devops existe"
    kubectl get pods -n devops 2>/dev/null | head -5
else
    echo "ℹ️  Le namespace devops n'existe pas encore (sera créé par le pipeline)"
fi

echo ""
echo "========================================="
echo "✅ Minikube est prêt pour Jenkins !"
echo "========================================="
echo ""
echo "Vous pouvez maintenant relancer votre pipeline Jenkins."

