# Comment Créer le Pipeline dans Jenkins

## 📋 Étapes pour Créer le Pipeline

### Étape 1 : Accéder à Jenkins

1. Ouvrez votre navigateur
2. Allez à l'URL de Jenkins (ex: `http://localhost:8080` ou l'IP de votre serveur)
3. Connectez-vous

### Étape 2 : Créer un Nouveau Job

1. Cliquez sur **"New Item"** (ou "Nouvel élément")
2. Entrez un nom : `student-management-pipeline`
3. Sélectionnez **"Pipeline"**
4. Cliquez sur **"OK"**

### Étape 3 : Configurer le Pipeline

#### Option A : Pipeline Script (Copier-Coller Direct)

1. Dans la configuration du job, descendez à la section **"Pipeline"**
2. Dans **"Definition"**, sélectionnez **"Pipeline script"**
3. **Copiez TOUT le contenu** du fichier `PIPELINE_JENKINS_SCRIPT_FINAL.txt`
4. **Collez-le** dans le champ **"Script"**
5. Cliquez sur **"Save"**

#### Option B : Pipeline Script from SCM (Recommandé - depuis GitHub)

1. Dans la configuration du job, section **"Pipeline"**
2. Dans **"Definition"**, sélectionnez **"Pipeline script from SCM"**
3. **SCM** : Sélectionnez **"Git"**
4. **Repository URL** : `https://github.com/NegzaouiOussama/Deveops.git`
5. **Branch** : `*/main` (ou `main`)
6. **Script Path** : `Jenkinsfile`
7. Cliquez sur **"Save"**

### Étape 4 : Lancer le Pipeline

1. Retournez à la page principale du job
2. Cliquez sur **"Build Now"**
3. Surveillez les logs dans **"Build History"** → Cliquez sur le build → **"Console Output"**

## ✅ Checklist Avant de Lancer

- [ ] Jenkins a accès à kubectl (voir `k8s/CONFIGURER_JENKINS_KUBECTL.md`)
- [ ] Docker est installé et accessible depuis Jenkins
- [ ] Maven est configuré dans Jenkins (Tools → Maven → Maven3)
- [ ] Minikube est démarré : `minikube status`
- [ ] Les manifests Kubernetes sont dans le repo (dossier `k8s/`)

## 🔍 Vérification du Pipeline

### Stages du Pipeline

Le pipeline exécute automatiquement :

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
14. ✅ **Verify Code Quality on Pod** - Vérifie les logs

### Résultats Attendus

À la fin d'un pipeline réussi, vous verrez :

```
==========================================
✅ Pipeline réussi avec succès!
==========================================
📊 SonarQube Dashboard: http://172.29.114.102:9000/dashboard?id=tn.esprit:student-management
🐳 Docker Image: negzaoui/student-management:BUILD_NUMBER
🐳 Docker Hub: https://hub.docker.com/r/negzaoui/student-management
☸️  Kubernetes Namespace: devops
🌐 Application URL: http://<IP>:30080/student
📚 Swagger UI: http://<IP>:30080/student/swagger-ui.html
==========================================
```

## 🐛 Dépannage

### Le pipeline échoue au stage "Deploy MySQL"

**Solution** : Vérifiez que kubectl fonctionne
```bash
sudo -u jenkins kubectl get nodes
```

### Le pipeline échoue au stage "Push Docker Image"

**Solution** : Vérifiez les credentials Docker Hub

### Le pipeline échoue au stage "Deploy Application"

**Solution** : Vérifiez que les manifests existent
```bash
ls k8s/
```

## 📝 Notes Importantes

1. **Premier Build** : Peut prendre 5-10 minutes (déploiement MySQL + Application)
2. **Builds Suivants** : Plus rapides (3-5 minutes)
3. **Rolling Update** : L'application effectue un rolling update à chaque build
4. **Tags Docker** : Chaque build utilise le numéro de build comme tag

