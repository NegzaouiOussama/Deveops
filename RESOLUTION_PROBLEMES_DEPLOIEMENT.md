# Résolution des Problèmes de Déploiement

## 🔍 Problèmes Identifiés

1. ✅ **Pods en Running mais pas Ready** - Les health checks échouent
2. ❌ **Erreur DB** : "Duplicate foreign key constraint name" - La base de données a déjà des tables
3. ⚠️ **Service MySQL en double** - `mysql-service` doit être supprimé

## 🔧 Solutions

### 1. Nettoyer le Service MySQL en Double

```bash
kubectl delete service mysql-service -n devops
```

### 2. Résoudre le Problème de Base de Données

L'erreur "Duplicate foreign key constraint" indique que la base de données a déjà des tables. Deux options :

#### Option A : Nettoyer la Base de Données (Recommandé)

```bash
# Se connecter au pod MySQL
kubectl exec -it -n devops $(kubectl get pod -l app=mysql -n devops -o jsonpath='{.items[0].metadata.name}') -- mysql -uroot -prootpassword

# Dans MySQL, supprimer la base et la recréer
DROP DATABASE studentdb;
CREATE DATABASE studentdb;
exit
```

#### Option B : Changer la Stratégie Hibernate (Temporaire)

Modifier le ConfigMap pour utiliser `create-drop` au lieu de `update` :

```bash
kubectl edit configmap app-config -n devops
```

Changez :
```yaml
SPRING_JPA_HIBERNATE_DDL_AUTO: "update"
```

En :
```yaml
SPRING_JPA_HIBERNATE_DDL_AUTO: "create-drop"
```

Puis redémarrez les pods :
```bash
kubectl rollout restart deployment/student-management -n devops
```

### 3. Vérifier que les Pods Deviennent Ready

```bash
# Attendre que les pods soient Ready
kubectl wait --for=condition=ready pod -l app=student-management -n devops --timeout=300s

# Vérifier le statut
kubectl get pods -n devops
```

### 4. Tester l'Application

Une fois les pods Ready :

```bash
# Obtenir l'URL
minikube service student-management -n devops --url

# Tester le health check
curl http://127.0.0.1:$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}')/student/actuator/health
```

## 📋 Commandes Complètes de Résolution

```bash
# 1. Nettoyer le service MySQL en double
kubectl delete service mysql-service -n devops

# 2. Nettoyer la base de données
kubectl exec -it -n devops $(kubectl get pod -l app=mysql -n devops -o jsonpath='{.items[0].metadata.name}') -- mysql -uroot -prootpassword -e "DROP DATABASE IF EXISTS studentdb; CREATE DATABASE studentdb;"

# 3. Redémarrer l'application pour recréer les tables
kubectl rollout restart deployment/student-management -n devops

# 4. Attendre que les pods soient Ready
kubectl wait --for=condition=ready pod -l app=student-management -n devops --timeout=300s

# 5. Vérifier le statut
kubectl get pods -n devops

# 6. Tester l'application
export APP_URL=$(minikube service student-management -n devops --url)/student
curl ${APP_URL}/actuator/health
```

## ✅ Vérification Finale

Après ces étapes, vous devriez voir :

```bash
kubectl get pods -n devops
```

```
NAME                                  READY   STATUS    RESTARTS   AGE
mysql-85f6dc6984-fdbdn                1/1     Running   0          XXm
student-management-5dfcfb95b6-7jrwj   1/1     Running   0          XXm
student-management-5dfcfb95b6-rdhlq   1/1     Running   0          XXm
```

Notez que `READY` doit être `1/1` pour tous les pods.

## 🌐 Accéder à l'Application

Une fois les pods Ready :

```bash
# Méthode 1 : Avec minikube service
minikube service student-management -n devops --url

# Méthode 2 : Manuellement
export NODEPORT=$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}')
export CLUSTER_IP=$(minikube ip)
echo "Application: http://${CLUSTER_IP}:${NODEPORT}/student"
echo "Swagger: http://${CLUSTER_IP}:${NODEPORT}/student/swagger-ui.html"
```

## 🐛 Si les Pods Restent Non Ready

Vérifiez les health checks :

```bash
# Voir les détails des probes
kubectl describe pod -n devops -l app=student-management | grep -A 10 "Liveness\|Readiness"

# Tester manuellement le health check depuis un pod
kubectl exec -n devops $(kubectl get pod -l app=student-management -n devops -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:8089/student/actuator/health
```

Si le health check échoue, vérifiez que l'application démarre correctement dans les logs.

