# Solution : SonarQube Optionnel dans le Pipeline

## 🎯 Problème

Le pipeline Jenkins échoue quand SonarQube n'est pas accessible :
```
ERROR SonarQube server [http://172.29.114.102:9000] can not be reached
Connection refused
```

Cela empêche le pipeline de continuer avec Docker et Kubernetes.

## ✅ Solution

Rendre le stage SonarQube **non-bloquant** en utilisant `catchError` dans Jenkins. Le pipeline continuera même si SonarQube n'est pas disponible.

## 📝 Modification du Pipeline

### Avant (SonarQube bloque le pipeline) :
```groovy
stage('MVN SONARQUBE') {
    steps {
        script {
            sh """
                mvn sonar:sonar \\
                    -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                    -Dsonar.login=${env.SONAR_TOKEN} \\
                    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
            """
        }
    }
}
```

### Après (SonarQube ne bloque plus) :
```groovy
stage('MVN SONARQUBE') {
    steps {
        script {
            // SonarQube est optionnel - le pipeline continue même en cas d'échec
            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                echo "Tentative de connexion à SonarQube..."
                sh """
                    mvn sonar:sonar \\
                        -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                        -Dsonar.login=${env.SONAR_TOKEN} \\
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                """
                echo "✅ Analyse SonarQube réussie"
            }
            echo "⚠️  SonarQube non disponible - le pipeline continue"
        }
    }
}
```

## 🔍 Explication

- **`catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE')`** :
  - Capture les erreurs dans le bloc
  - `buildResult: 'SUCCESS'` : Le pipeline continue avec un statut SUCCESS
  - `stageResult: 'UNSTABLE'` : Le stage SonarQube est marqué comme UNSTABLE (jaune) au lieu de FAILURE (rouge)

## 📊 Résultat

- ✅ Si SonarQube est accessible : L'analyse s'exécute normalement
- ⚠️ Si SonarQube n'est pas accessible : Un avertissement est affiché, mais le pipeline continue avec Docker et Kubernetes

## 🚀 Alternative : Vérifier SonarQube avant d'analyser

Si vous voulez vérifier la disponibilité de SonarQube avant d'essayer l'analyse :

```groovy
stage('MVN SONARQUBE') {
    steps {
        script {
            // Vérifier si SonarQube est accessible
            def sonarAvailable = sh(
                script: "curl -s -o /dev/null -w '%{http_code}' ${env.SONAR_HOST_URL}/api/system/status || echo '000'",
                returnStdout: true
            ).trim()
            
            if (sonarAvailable == '200') {
                echo "✅ SonarQube est accessible - Exécution de l'analyse..."
                sh """
                    mvn sonar:sonar \\
                        -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                        -Dsonar.login=${env.SONAR_TOKEN} \\
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                """
            } else {
                echo "⚠️  SonarQube n'est pas accessible (code: ${sonarAvailable}) - Stage ignoré"
                echo "Le pipeline continue sans analyse SonarQube"
            }
        }
    }
}
```

## 📝 Notes

- Le pipeline fonctionnera même si SonarQube est arrêté
- Les rapports JaCoCo seront toujours générés (même si non envoyés à SonarQube)
- Vous pouvez démarrer SonarQube plus tard et relancer l'analyse manuellement si nécessaire

## 🔧 Démarrer SonarQube (si nécessaire)

Si vous voulez utiliser SonarQube, démarrez-le avant de lancer le pipeline :

```bash
# Si SonarQube est dans Docker
docker start sonarqube

# Si SonarQube est dans Kubernetes
kubectl get pods -n devops -l app=sonarqube
# Vérifier qu'il est Running

# Vérifier l'accès
curl http://172.29.114.102:9000/api/system/status
```

