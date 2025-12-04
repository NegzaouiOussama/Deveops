# Guide Configuration SonarQube avec Jenkins

## Étape 1 : Vérifier que SonarQube est en cours d'exécution

### Dans WSL :

```bash
# Vérifier que le conteneur SonarQube est actif
docker ps | grep sonarqube

# Si le conteneur n'est pas actif, le démarrer
docker start sonarqube

# Voir les logs
docker logs sonarqube
```

## Étape 2 : Accéder à SonarQube

### Sur votre machine Windows :

1. Ouvrez votre navigateur
2. Allez sur : **http://172.29.114.102:9000** (ou l'IP de votre WSL)
3. Connectez-vous avec :
   - **Login** : `admin`
   - **Password** : `admin` (première connexion)
4. Changez le mot de passe à : `sonar`

## Étape 3 : Token SonarQube ✅ (Déjà Créé)

Votre token SonarQube a été créé avec succès :
- **Nom** : Negzaoui
- **Type** : Project
- **Projet** : Deveops
- **Token** : `sqp_8dc68dea51a4ba5983fee4be1be10c4266e6ef4d`
- **Expiration** : 3 janvier 2026

Le token est déjà configuré dans le Jenkinsfile.

## Étape 4 : Créer un Projet dans SonarQube

1. Dans SonarQube, allez dans **Projects** → **Create Project**
2. Choisissez **Manually**
3. **Project key** : `student-management`
4. **Display name** : `Student Management`
5. Cliquez sur **Set Up**

## Étape 5 : Configurer le Pipeline Jenkins

### Script Jenkins avec SonarQube :

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
            echo "SonarQube: ${env.SONAR_HOST_URL}/dashboard?id=student-management"
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Étape 6 : Trouver l'IP de votre WSL

### Dans WSL :

```bash
# Voir l'IP de WSL
hostname -I

# Ou
ip addr show eth0 | grep inet
```

**Important** : Remplacez `172.29.114.102` dans le script par votre IP WSL.

## Étape 7 : Vérifier la Configuration

### Fichiers créés :

1. **pom.xml** : Plugin SonarQube Maven ajouté
2. **sonar-project.properties** : Configuration SonarQube
3. **Jenkinsfile** : Stage SonarQube ajouté

## Étape 8 : Exécuter le Pipeline

1. Dans Jenkins, lancez le pipeline
2. Attendez que le stage "MVN SONARQUBE" se termine
3. Allez sur SonarQube : http://172.29.114.102:9000
4. Cliquez sur votre projet **Student Management**
5. Voir les résultats de l'analyse

## Résultats dans SonarQube

Après l'exécution, vous verrez :
- **Bugs** : Nombre de bugs détectés
- **Vulnerabilities** : Vulnérabilités de sécurité
- **Code Smells** : Problèmes de qualité de code
- **Coverage** : Couverture de code par les tests
- **Duplications** : Code dupliqué

## Commandes Utiles

### Démarrer SonarQube :

```bash
docker start sonarqube
```

### Arrêter SonarQube :

```bash
docker stop sonarqube
```

### Voir les logs SonarQube :

```bash
docker logs sonarqube
docker logs -f sonarqube
```

### Vérifier que SonarQube est accessible :

```bash
curl http://172.29.114.102:9000
```

## Dépannage

### Erreur : "Unable to connect to SonarQube server"

1. Vérifier que SonarQube est démarré : `docker ps | grep sonarqube`
2. Vérifier l'IP dans le script Jenkins
3. Tester la connexion : `curl http://VOTRE_IP:9000`

### Erreur : "Authentication failed"

1. Vérifier le token dans SonarQube
2. Régénérer un nouveau token si nécessaire
3. Mettre à jour le token dans le script Jenkins

### Erreur : "Project does not exist"

1. Créer le projet dans SonarQube avec la clé `student-management`
2. Ou utiliser `sonar.projectKey` dans `sonar-project.properties`

## URLs Importantes

- **SonarQube** : http://172.29.114.102:9000
- **Dashboard Projet** : http://172.29.114.102:9000/dashboard?id=student-management
- **Login** : admin / sonar

