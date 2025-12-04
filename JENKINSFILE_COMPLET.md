# Jenkinsfile Complet avec JaCoCo et SonarQube

## Script Complet pour Jenkins

Voici le script Jenkinsfile complet qui fonctionne avec JaCoCo et SonarQube :

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven3'
    }
    
    environment {
        MAVEN_HOME = "${tool 'Maven3'}"
        PATH = "${env.MAVEN_HOME}/bin:${env.PATH}"
        SONAR_HOST_URL = "http://172.29.114.102:9000"
        SONAR_TOKEN = "sqa_53a643aea3ccdbcedef2c73df0428a1d8397d01e"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/NegzaouiOussama/Deveops.git'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn clean test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Generate JaCoCo Report') {
            steps {
                sh 'mvn jacoco:report'
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
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
    }
    
    post {
        success {
            echo 'Pipeline réussi avec succès!'
            echo "SonarQube Dashboard: ${env.SONAR_HOST_URL}/dashboard?id=tn.esprit:student-management"
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Différences avec votre Script

### ❌ Votre Script (Incomplet)
- Stage "Test" : `mvn test` (sans `clean`)
- Stage "Package" : `mvn clean package -DskipTests` (supprime le rapport JaCoCo)
- **Manque** : Stage "Generate JaCoCo Report"
- SonarQube : Pas de configuration JaCoCo

### ✅ Script Complet (Recommandé)
- Stage "Test" : `mvn clean test` (génère `jacoco.exec`)
- Stage "Generate JaCoCo Report" : `mvn jacoco:report` (génère le rapport XML)
- Stage "Package" : `mvn package -DskipTests` (sans `clean` pour préserver le rapport)
- SonarQube : Configuration JaCoCo pour afficher la couverture

## Comment Utiliser dans Jenkins

### Option 1 : Pipeline Script (Direct dans Jenkins)

1. Allez dans Jenkins → Votre Job → **Configure**
2. Section **Pipeline**
3. **Definition** : Sélectionnez "Pipeline script"
4. **Script** : Copiez-collez le script complet ci-dessus
5. Cliquez sur **Save**

### Option 2 : Pipeline Script from SCM (Recommandé)

1. Commitez le Jenkinsfile dans votre repo Git :
   ```bash
   git add Jenkinsfile
   git commit -m "Add Jenkinsfile with JaCoCo and SonarQube"
   git push
   ```

2. Dans Jenkins → Votre Job → **Configure**
3. Section **Pipeline**
4. **Definition** : Sélectionnez "Pipeline script from SCM"
5. **SCM** : Git
6. **Repository URL** : `https://github.com/NegzaouiOussama/Deveops.git`
7. **Branch** : `main`
8. **Script Path** : `Jenkinsfile`
9. Cliquez sur **Save**

## Vérification

Après avoir configuré le pipeline :

1. **Lancer le Build** : Cliquez sur "Build Now"
2. **Vérifier les Logs** : 
   - Stage "Test" : 6 tests doivent passer
   - Stage "Generate JaCoCo Report" : Rapport généré
   - Stage "MVN SONARQUBE" : Analyse réussie avec couverture

3. **Vérifier dans SonarQube** :
   - URL : http://172.29.114.102:9000/dashboard?id=tn.esprit:student-management
   - **Coverage** : Doit être > 0%

## Résultats Attendus

✅ **Tests** : 6 tests (1 existant + 5 nouveaux)
✅ **Coverage** : > 0% dans SonarQube
✅ **Rapport JaCoCo** : Généré dans `target/site/jacoco/jacoco.xml`
✅ **Analyse SonarQube** : Réussie avec couverture de code

