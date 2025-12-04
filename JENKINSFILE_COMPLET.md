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
        DOCKER_USERNAME = "negzaoui"
        DOCKER_PASSWORD = "dckr_pat_o-R1u9Ij5dpajyvfK7xcH6PRP6w"
        DOCKER_IMAGE_NAME = "student-management"
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
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
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} .
                        docker tag ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    sh """
                        echo ${env.DOCKER_PASSWORD} | docker login -u ${env.DOCKER_USERNAME} --password-stdin
                        docker push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                        docker push ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline réussi avec succès!'
            echo "SonarQube Dashboard: ${env.SONAR_HOST_URL}/dashboard?id=tn.esprit:student-management"
            echo "Docker Image: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
            echo "Docker Hub: https://hub.docker.com/r/${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE_NAME}"
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
- **Build Docker Image** : Construction de l'image Docker avec tag de build
- **Push Docker Image** : Push de l'image vers Docker Hub

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

## Prérequis pour Docker

Avant d'utiliser ce pipeline avec Docker, assurez-vous que :

1. **Docker est installé sur le serveur Jenkins** :
   ```bash
   docker --version
   ```

2. **L'agent Jenkins a accès à Docker** :
   - L'utilisateur Jenkins doit être dans le groupe `docker`
   - Ou utiliser un agent Docker avec Docker-in-Docker

3. **Les credentials Docker Hub sont valides** :
   - `DOCKER_USERNAME` : Votre nom d'utilisateur Docker Hub
   - `DOCKER_PASSWORD` : Votre token d'accès Docker Hub (PAT - Personal Access Token)

## Étapes Docker Ajoutées

Le pipeline inclut maintenant deux nouvelles étapes Docker :

### 1. Build Docker Image

Cette étape :
- Construit l'image Docker à partir du Dockerfile présent dans le projet
- Tag l'image avec le numéro de build : `negzaoui/student-management:BUILD_NUMBER`
- Tag également l'image avec `latest` : `negzaoui/student-management:latest`

### 2. Push Docker Image

Cette étape :
- Se connecte à Docker Hub avec les credentials configurés
- Push l'image taggée avec le numéro de build
- Push l'image taggée avec `latest`

Les images seront disponibles sur Docker Hub à :
- `https://hub.docker.com/r/negzaoui/student-management`

## Vérification

Après avoir configuré le pipeline :

1. **Lancer le Build** : Cliquez sur "Build Now"
2. **Vérifier les Logs** : 
   - Stage "Test" : 6 tests doivent passer
   - Stage "Generate JaCoCo Report" : Rapport généré
   - Stage "MVN SONARQUBE" : Analyse réussie avec couverture
   - Stage "Build Docker Image" : Image Docker construite avec succès
   - Stage "Push Docker Image" : Image pushée vers Docker Hub

3. **Vérifier dans SonarQube** :
   - URL : http://172.29.114.102:9000/dashboard?id=tn.esprit:student-management
   - **Coverage** : Doit être > 0%

## Résultats Attendus

✅ **Tests** : 6 tests (1 existant + 5 nouveaux)
✅ **Coverage** : > 0% dans SonarQube
✅ **Rapport JaCoCo** : Généré dans `target/site/jacoco/jacoco.xml`
✅ **Analyse SonarQube** : Réussie avec couverture de code
✅ **Image Docker** : Construite et pushée vers Docker Hub
✅ **Docker Hub** : Image disponible à `negzaoui/student-management:BUILD_NUMBER` et `negzaoui/student-management:latest`

