# Script Jenkins pour Exécuter Docker

## Script Complet avec Docker

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
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} .
                        docker tag ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Run Docker Container') {
            steps {
                script {
                    // Arrêter et supprimer le conteneur existant s'il existe
                    sh """
                        docker stop ${env.DOCKER_IMAGE_NAME}-container || true
                        docker rm ${env.DOCKER_IMAGE_NAME}-container || true
                    """
                    
                    // Démarrer MySQL si pas déjà démarré
                    sh """
                        docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=rootpassword \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || true
                    """
                    
                    // Attendre que MySQL soit prêt
                    sh 'sleep 10'
                    
                    // Démarrer l'application
                    sh """
                        docker run -d --name ${env.DOCKER_IMAGE_NAME}-container \\
                            --link student-mysql:mysql \\
                            -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/studentdb?createDatabaseIfNotExist=true \\
                            -e SPRING_DATASOURCE_USERNAME=root \\
                            -e SPRING_DATASOURCE_PASSWORD=rootpassword \\
                            -p 8089:8089 \\
                            ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                    """
                }
            }
        }
        
        stage('Verify Container') {
            steps {
                script {
                    sh 'sleep 15' // Attendre que l'application démarre
                    sh """
                        docker ps | grep ${env.DOCKER_IMAGE_NAME}-container
                        docker logs --tail 50 ${env.DOCKER_IMAGE_NAME}-container
                    """
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            cleanWs()
        }
        success {
            echo 'Pipeline réussi avec succès!'
            echo "Image Docker créée: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
            echo "Application accessible sur: http://localhost:8089/student"
        }
        failure {
            echo 'Pipeline a échoué!'
            script {
                sh 'docker logs ${env.DOCKER_IMAGE_NAME}-container || true'
            }
        }
    }
}
```

## Script avec Docker Compose (Recommandé)

Si vous préférez utiliser Docker Compose :

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven3'
    }
    
    environment {
        MAVEN_HOME = "${tool 'Maven3'}"
        PATH = "${env.MAVEN_HOME}/bin:${env.PATH}"
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
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker-compose build'
            }
        }
        
        stage('Start Services') {
            steps {
                sh 'docker-compose up -d'
            }
        }
        
        stage('Verify Services') {
            steps {
                script {
                    sh 'sleep 20' // Attendre que les services démarrent
                    sh 'docker-compose ps'
                    sh 'docker-compose logs --tail 50 student-management'
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            cleanWs()
        }
        success {
            echo 'Pipeline réussi avec succès!'
            echo 'Application accessible sur: http://localhost:8089/student'
        }
        failure {
            echo 'Pipeline a échoué!'
            sh 'docker-compose logs'
        }
        cleanup {
            // Optionnel: arrêter les services après le build
            // sh 'docker-compose down'
        }
    }
}
```

## Script Minimal (Build Docker seulement)

Si vous voulez juste construire l'image Docker sans l'exécuter :

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven3'
    }
    
    environment {
        MAVEN_HOME = "${tool 'Maven3'}"
        PATH = "${env.MAVEN_HOME}/bin:${env.PATH}"
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
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ."
                    sh "docker tag ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ${env.DOCKER_IMAGE_NAME}:latest"
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            cleanWs()
        }
        success {
            echo 'Pipeline réussi avec succès!'
            echo "Image Docker créée: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Prérequis dans Jenkins

Pour que Docker fonctionne dans Jenkins :

1. **Docker installé sur le serveur Jenkins**
   ```bash
   docker --version
   ```

2. **Jenkins a les permissions Docker**
   - L'utilisateur Jenkins doit être dans le groupe `docker`
   - Ou utiliser `sudo docker` (moins sécurisé)

3. **Plugins Jenkins (optionnel)**
   - Docker Pipeline plugin
   - Docker plugin

## Vérification

Après l'exécution du pipeline, vous pouvez :

```bash
# Voir les images créées
docker images | grep student-management

# Voir les conteneurs en cours d'exécution
docker ps

# Voir les logs
docker logs student-management-container
```

## Notes importantes

- Le script avec Docker Compose est **recommandé** car il gère automatiquement MySQL
- Assurez-vous que Docker est accessible depuis Jenkins
- Les ports 8089 et 3306 doivent être disponibles
- Le script attend que MySQL soit prêt avant de démarrer l'application

