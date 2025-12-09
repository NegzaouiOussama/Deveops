# Instructions pour Créer le Pipeline dans Jenkins

## 📋 Étapes pour Créer le Pipeline

### Étape 1 : Accéder à Jenkins

1. Ouvrez votre navigateur et allez à l'URL de Jenkins (ex: `http://localhost:8080` ou l'IP de votre serveur Jenkins)
2. Connectez-vous avec vos identifiants

### Étape 2 : Créer un Nouveau Job

1. Cliquez sur **"New Item"** (ou "Nouvel élément")
2. Entrez un nom pour votre pipeline (ex: `student-management-pipeline`)
3. Sélectionnez **"Pipeline"**
4. Cliquez sur **"OK"**

### Étape 3 : Configurer le Pipeline

#### Option A : Pipeline Script (Direct dans Jenkins)

1. Dans la configuration du job, descendez jusqu'à la section **"Pipeline"**
2. Dans **"Definition"**, sélectionnez **"Pipeline script"**
3. **Copiez-collez** le contenu du fichier `JENKINS_PIPELINE_SCRIPT_COMPLET.groovy` dans le champ **"Script"**

#### Option B : Pipeline Script from SCM (Recommandé)

1. Dans la configuration du job, section **"Pipeline"**
2. Dans **"Definition"**, sélectionnez **"Pipeline script from SCM"**
3. **SCM** : Sélectionnez **"Git"**
4. **Repository URL** : `https://github.com/NegzaouiOussama/Deveops.git`
5. **Branch** : `*/main` (ou `main`)
6. **Script Path** : `Jenkinsfile`
7. Cliquez sur **"Save"**

### Étape 4 : Prérequis à Vérifier

Avant de lancer le pipeline, assurez-vous que :

✅ **Jenkins a accès à kubectl** (voir `k8s/CONFIGURER_JENKINS_KUBECTL.md`)
✅ **Docker est installé** et Jenkins peut l'utiliser
✅ **Maven est configuré** dans Jenkins (Tools → Maven → Maven3)
✅ **Minikube est démarré** (si vous utilisez Minikube)
✅ **Les manifests Kubernetes sont dans le repo** (dossier `k8s/`)

### Étape 5 : Lancer le Pipeline

1. Retournez à la page principale du job
2. Cliquez sur **"Build Now"**
3. Surveillez les logs dans **"Build History"** → Cliquez sur le build → **"Console Output"**

## 🔍 Vérification du Pipeline

### Stages du Pipeline

Le pipeline exécute les étapes suivantes :

1. ✅ **Checkout** - Récupère le code depuis GitHub
2. ✅ **Test** - Exécute les tests unitaires avec JaCoCo
3. ✅ **Generate JaCoCo Report** - Génère le rapport de couverture
4. ✅ **Package** - Package l'application en JAR
5. ✅ **MVN SONARQUBE** - Analyse la qualité du code
6. ✅ **Build Docker Image** - Construit l'image Docker
7. ✅ **Push Docker Image** - Push l'image vers Docker Hub
8. ✅ **Create Kubernetes Namespace** - Crée le namespace `devops`
9. ✅ **Deploy MySQL to Kubernetes** - Déploie MySQL
10. ✅ **Wait for MySQL to be Ready** - Attend que MySQL soit prêt
11. ✅ **Deploy Application to Kubernetes** - Déploie l'application
12. ✅ **Wait for Application to be Ready** - Attend que l'app soit prête
13. ✅ **Expose Services and Test Application** - Teste l'application
14. ✅ **Verify Code Quality on Pod** - Vérifie la qualité sur le pod

### Résultats Attendus

À la fin d'un pipeline réussi, vous verrez :

```
==========================================
Pipeline réussi avec succès!
==========================================
SonarQube Dashboard: http://172.29.114.102:9000/dashboard?id=tn.esprit:student-management
Docker Image: negzaoui/student-management:BUILD_NUMBER
Docker Hub: https://hub.docker.com/r/negzaoui/student-management
Kubernetes Namespace: devops
Application URL: http://<IP>:30080/student
Health Check URL: http://<IP>:30080/student/actuator/health
Swagger UI: http://<IP>:30080/student/swagger-ui.html
==========================================
```

## 🐛 Dépannage

### Le pipeline échoue au stage "Deploy MySQL"

**Cause** : kubectl n'est pas accessible ou Minikube n'est pas démarré

**Solution** :
```bash
# Vérifier que Minikube est démarré
minikube status

# Vérifier que Jenkins peut utiliser kubectl
sudo -u jenkins kubectl get nodes
```

### Le pipeline échoue au stage "Push Docker Image"

**Cause** : Docker Hub credentials incorrects ou Docker non accessible

**Solution** :
- Vérifiez que `DOCKER_USERNAME` et `DOCKER_PASSWORD` sont corrects
- Vérifiez que Docker est accessible depuis Jenkins

### Le pipeline échoue au stage "Deploy Application"

**Cause** : Les manifests Kubernetes ne sont pas présents ou MySQL n'est pas prêt

**Solution** :
```bash
# Vérifier que les manifests existent
ls k8s/

# Vérifier que MySQL est prêt
kubectl get pods -n devops -l app=mysql
```

## 📝 Notes Importantes

1. **Premier Build** : Le premier build peut prendre plus de temps car il doit déployer MySQL et l'application
2. **Builds Suivants** : Les builds suivants seront plus rapides car MySQL est déjà déployé
3. **Rolling Update** : L'application effectue un rolling update à chaque nouveau build
4. **Tags Docker** : Chaque build utilise le numéro de build comme tag pour l'image Docker

## 🔐 Sécurité

⚠️ **Important** : Pour la production, stockez les secrets (DOCKER_PASSWORD, SONAR_TOKEN) dans Jenkins Credentials Store plutôt que directement dans le pipeline.

### Comment Utiliser Jenkins Credentials

1. **Jenkins** → **Manage Jenkins** → **Credentials**
2. Créez des credentials de type **"Secret text"** pour :
   - `DOCKER_PASSWORD`
   - `SONAR_TOKEN`
3. Dans le pipeline, utilisez :
   ```groovy
   environment {
       DOCKER_PASSWORD = credentials('docker-hub-password')
       SONAR_TOKEN = credentials('sonar-token')
   }
   ```

