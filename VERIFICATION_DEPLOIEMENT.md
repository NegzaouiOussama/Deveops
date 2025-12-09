# Vérification du Déploiement

## ✅ État Actuel

- ✅ Jenkins peut utiliser kubectl
- ✅ MySQL est déployé et Running
- ✅ Application Spring Boot en cours de déploiement

## 🔧 Nettoyage : Supprimer le Service MySQL en Double

Vous avez deux services MySQL. Gardons seulement `mysql` :

```bash
kubectl delete service mysql-service -n devops
```

## 🔍 Vérifications

### 1. Vérifier l'état des Pods

```bash
kubectl get pods -n devops
```

Attendez que les pods `student-management` soient en statut `Running` (peut prendre 1-2 minutes).

### 2. Vérifier les Logs de l'Application

```bash
# Voir les logs d'un pod
kubectl logs -n devops -l app=student-management --tail=50

# Si les pods ne démarrent pas, voir les détails
kubectl describe pod -n devops -l app=student-management
```

### 3. Vérifier les Services

```bash
kubectl get services -n devops
```

Vous devriez voir :
- `mysql` - ClusterIP (port 3306)
- `student-management` - NodePort (port 30080)

### 4. Attendre que l'Application soit Prête

```bash
kubectl wait --for=condition=ready pod -l app=student-management -n devops --timeout=300s
```

### 5. Obtenir l'URL de l'Application

```bash
export NODEPORT=$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}')
export CLUSTER_IP=$(minikube ip)
echo "Application URL: http://${CLUSTER_IP}:${NODEPORT}/student"
echo "Health Check: http://${CLUSTER_IP}:${NODEPORT}/student/actuator/health"
echo "Swagger UI: http://${CLUSTER_IP}:${NODEPORT}/student/swagger-ui.html"
```

### 6. Tester l'Application

```bash
# Health check
curl http://$(minikube ip):30080/student/actuator/health

# Ou avec l'URL complète
minikube service student-management -n devops --url
```

## 🐛 Si les Pods ne Démarrant Pas

### Vérifier les Erreurs

```bash
# Voir les détails d'un pod
kubectl describe pod -n devops -l app=student-management

# Voir les events
kubectl get events -n devops --sort-by='.lastTimestamp'
```

### Problèmes Courants

1. **ImagePullBackOff** : L'image Docker n'est pas disponible
   - Solution : Vérifier que l'image est pushée sur Docker Hub
   - Ou : Charger l'image dans Minikube

2. **CrashLoopBackOff** : L'application crash au démarrage
   - Solution : Vérifier les logs pour voir l'erreur

3. **Pending** : Pas assez de ressources
   - Solution : Vérifier `kubectl describe pod` pour voir pourquoi

## 📊 Commandes de Monitoring

```bash
# Voir tous les resources
kubectl get all -n devops

# Voir l'utilisation des ressources
kubectl top pods -n devops

# Voir les logs en temps réel
kubectl logs -f -n devops -l app=student-management
```

