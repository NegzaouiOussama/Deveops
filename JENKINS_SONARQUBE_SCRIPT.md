# Script Jenkins avec SonarQube

## Script Complet à Copier dans Jenkins

Copiez ce script dans le champ "Script" de votre job Jenkins :

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
        SONAR_TOKEN = "sqp_8dc68dea51a4ba5983fee4be1be10c4266e6ef4d"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/NegzaouiOussama/Deveops.git'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn clean package -DskipTests'
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
                            -Dsonar.login=${env.SONAR_TOKEN}
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline réussi avec succès!'
            echo "SonarQube Dashboard: ${env.SONAR_HOST_URL}/dashboard?id=student-management"
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Configuration SonarQube

### 1. Accéder à SonarQube

Sur votre machine Windows, ouvrez :
- **URL** : http://172.29.114.102:9000 (ou http://localhost:9000)
- **Login** : `admin`
- **Password** : `admin` (première fois), puis changez à `sonar`

### 2. Token Créé ✅

Votre token SonarQube a été créé avec succès :
- **Nom** : Negzaoui
- **Type** : Project
- **Projet** : Deveops
- **Token** : `sqp_8dc68dea51a4ba5983fee4be1be10c4266e6ef4d`
- **Expiration** : 3 janvier 2026

Le token est déjà configuré dans le script Jenkins ci-dessus.

### 3. Créer le Projet dans SonarQube

1. **Projects** → **Create Project** → **Manually**
2. **Project key** : `student-management`
3. **Display name** : `Student Management`
4. **Set Up**

## Voir les Résultats

### Dans SonarQube :

1. Allez sur : http://172.29.114.102:9000
2. Cliquez sur **Projects**
3. Cliquez sur **Student Management**
4. Voir :
   - **Bugs** détectés
   - **Vulnerabilities** de sécurité
   - **Code Smells**
   - **Coverage** (couverture de code)
   - **Duplications**

### Dans Jenkins :

1. **Console Output** : Voir les logs de l'analyse SonarQube
2. Le stage "MVN SONARQUBE" affichera les résultats

## Commandes Utiles WSL

```bash
# Vérifier que SonarQube est actif
docker ps | grep sonarqube

# Démarrer SonarQube (si arrêté)
docker start sonarqube

# Voir les logs
docker logs sonarqube

# Vérifier l'IP
hostname -I
```

## Fichiers Configurés

✅ **pom.xml** : Plugin SonarQube Maven ajouté
✅ **sonar-project.properties** : Configuration SonarQube créée
✅ **Jenkinsfile** : Stage SonarQube ajouté

## Notes Importantes

- L'IP `172.29.114.102` est l'IP de votre WSL
- Si l'IP change, mettez à jour `SONAR_HOST_URL` dans le script
- Le token par défaut est `sonar` (mot de passe admin)
- Pour plus de sécurité, utilisez un token généré dans SonarQube

