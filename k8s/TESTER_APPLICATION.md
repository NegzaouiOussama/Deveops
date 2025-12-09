# Tester l'Application Déployée

Ce guide explique comment tester l'application Spring Boot déployée sur Kubernetes.

## 🌐 Accéder à l'Application

### Obtenir l'URL de l'Application

```bash
# Avec Minikube (méthode recommandée)
minikube service student-management -n devops --url

# Ou manuellement
export NODEPORT=$(kubectl get service student-management -n devops -o jsonpath='{.spec.ports[0].nodePort}')
export CLUSTER_IP=$(minikube ip)
echo "Application URL: http://${CLUSTER_IP}:${NODEPORT}/student"
```

L'URL sera quelque chose comme : `http://192.168.49.2:30080/student`

## 🔍 Vérifications

### 1. Vérifier les Pods

```bash
kubectl get pods -n devops
```

Vous devriez voir :
- `mysql-xxx` - Pod MySQL
- `student-management-xxx` - Pod(s) de l'application (2 replicas)

### 2. Vérifier les Services

```bash
kubectl get svc -n devops
```

Vous devriez voir :
- `mysql` - Service ClusterIP (port 3306)
- `student-management` - Service NodePort (port 30080)

### 3. Consulter les Logs

```bash
# Logs de l'application
kubectl logs -n devops -l app=student-management --tail=100

# Logs d'un pod spécifique
kubectl logs -n devops <pod-name> --tail=100

# Logs MySQL
kubectl logs -n devops -l app=mysql --tail=50
```

## 🧪 Tests de l'Application

### Test 1 : Health Check

```bash
export APP_URL=$(minikube service student-management -n devops --url)/student

# Test health check
curl ${APP_URL}/actuator/health
```

Vous devriez voir :
```json
{"status":"UP"}
```

### Test 2 : API REST - Lister les Départements

```bash
# Lister tous les départements (vide au départ)
curl ${APP_URL}/department/getAllDepartment
```

Réponse attendue : `[]` (tableau vide)

### Test 3 : Créer un Département

```bash
# Créer un département
curl -X POST ${APP_URL}/department/createDepartment \
  -H "Content-Type: application/json" \
  -d '{"name": "IT", "location": "Tunis"}'
```

### Test 4 : Vérifier la Création

```bash
# Relister les départements
curl ${APP_URL}/department/getAllDepartment
```

Vous devriez voir le département créé :
```json
[{
  "idDepartment":1,
  "name":"IT",
  "location":"Tunis",
  "phone":null,
  "head":null,
  "students":[]
}]
```

### Test 5 : Tester d'Autres Endpoints

```bash
# Lister les étudiants
curl ${APP_URL}/student/getAllStudents

# Lister les cours
curl ${APP_URL}/course/getAllCourses
```

## 🌐 Accéder à Swagger UI

Swagger UI est accessible à :

```bash
export APP_URL=$(minikube service student-management -n devops --url)/student
echo "Swagger UI: ${APP_URL}/swagger-ui.html"
```

Ouvrez cette URL dans votre navigateur pour voir la documentation interactive de l'API.

## 🔍 Commandes de Debug

### Vérifier la Connectivité MySQL depuis le Pod

```bash
# Se connecter au pod de l'application
kubectl exec -it -n devops $(kubectl get pod -l app=student-management -n devops -o jsonpath='{.items[0].metadata.name}') -- sh

# Dans le pod, tester la connexion MySQL
wget -qO- http://mysql:3306 || echo "MySQL non accessible"

# Sortir du pod
exit
```

### Vérifier les Variables d'Environnement

```bash
kubectl exec -n devops $(kubectl get pod -l app=student-management -n devops -o jsonpath='{.items[0].metadata.name}') -- env | grep SPRING
```

### Décrire un Pod pour Debugging

```bash
kubectl describe pod -n devops -l app=student-management
```

### Vérifier les Endpoints du Service

```bash
kubectl get endpoints student-management -n devops
```

## 📊 Monitoring

### Voir l'Utilisation des Ressources

```bash
kubectl top pods -n devops
```

### Voir les Événements

```bash
kubectl get events -n devops --sort-by='.lastTimestamp'
```

## 🐛 Dépannage

### L'Application ne démarre pas

1. **Vérifier les logs** :
   ```bash
   kubectl logs -n devops -l app=student-management --tail=100
   ```

2. **Vérifier les events** :
   ```bash
   kubectl describe pod -n devops -l app=student-management
   ```

3. **Vérifier que MySQL est prêt** :
   ```bash
   kubectl get pods -n devops -l app=mysql
   ```

### L'Application ne peut pas se connecter à MySQL

1. **Vérifier le service MySQL** :
   ```bash
   kubectl get svc mysql -n devops
   ```

2. **Tester la connexion** :
   ```bash
   kubectl exec -it -n devops $(kubectl get pod -l app=mysql -n devops -o jsonpath='{.items[0].metadata.name}') -- mysql -uroot -prootpassword -e "SHOW DATABASES;"
   ```

### L'Application n'est pas accessible

1. **Vérifier le service NodePort** :
   ```bash
   kubectl get svc student-management -n devops
   ```

2. **Vérifier que Minikube est démarré** :
   ```bash
   minikube status
   ```

3. **Vérifier l'IP de Minikube** :
   ```bash
   minikube ip
   ```

## ✅ Checklist de Vérification

- [ ] Tous les pods sont en statut `Running`
- [ ] Les services sont créés et accessibles
- [ ] Le health check répond `UP`
- [ ] L'application peut créer des ressources (departments, students, etc.)
- [ ] Les logs ne montrent pas d'erreurs
- [ ] Swagger UI est accessible

