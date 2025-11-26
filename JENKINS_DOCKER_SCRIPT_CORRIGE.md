# Script Jenkins Docker - Version Corrigée

## Erreur : Permission denied sur Docker socket

L'erreur `permission denied while trying to connect to the Docker daemon socket` signifie que Jenkins n'a pas les permissions pour utiliser Docker.

## Solution 1 : Utiliser sudo (Solution Rapide)

Script corrigé avec sudo :

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
                        sudo docker build -t ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} .
                        sudo docker tag ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Run Docker Container') {
            steps {
                script {
                    // Arrêter le conteneur existant s'il existe
                    sh 'sudo docker stop ${env.DOCKER_IMAGE_NAME}-container || true'
                    sh 'sudo docker rm ${env.DOCKER_IMAGE_NAME}-container || true'
                    
                    // Démarrer MySQL si nécessaire
                    sh '''
                        sudo docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=rootpassword \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || true
                    '''
                    
                    sh 'sleep 10' // Attendre MySQL
                    
                    // Démarrer l'application
                    sh """
                        sudo docker run -d --name ${env.DOCKER_IMAGE_NAME}-container \\
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
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            cleanWs()
        }
        success {
            echo 'Pipeline réussi avec succès!'
            echo "Image Docker: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
            echo "Application: http://localhost:8089/student"
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Solution 2 : Ajouter Jenkins au groupe docker (Solution Permanente - Recommandée)

### Sur Linux :

1. **Vérifier l'utilisateur Jenkins** :
```bash
ps aux | grep jenkins
```

2. **Ajouter l'utilisateur au groupe docker** :
```bash
sudo usermod -aG docker jenkins
# ou si l'utilisateur est différent :
sudo usermod -aG docker $USER_JENKINS
```

3. **Redémarrer Jenkins** :
```bash
sudo systemctl restart jenkins
# ou
sudo service jenkins restart
```

4. **Vérifier** :
```bash
groups jenkins
# doit afficher "docker" dans la liste
```

### Script Jenkins SANS sudo (après configuration) :

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
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            cleanWs()
        }
        success {
            echo 'Pipeline réussi avec succès!'
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Solution 3 : Utiliser Docker Compose avec sudo

Si vous utilisez Docker Compose :

```groovy
stage('Build Docker Image') {
    steps {
        sh 'sudo docker-compose build'
    }
}

stage('Start Services') {
    steps {
        sh 'sudo docker-compose up -d'
    }
}
```

## Vérification des permissions

Pour tester si Jenkins peut utiliser Docker :

```bash
# Se connecter en tant qu'utilisateur Jenkins
sudo su - jenkins

# Tester Docker
docker ps
# ou
sudo docker ps
```

## Notes importantes

- **Solution avec sudo** : Fonctionne immédiatement mais nécessite que Jenkins ait les permissions sudo
- **Solution avec groupe docker** : Plus sécurisée, nécessite un redémarrage de Jenkins
- **Sécurité** : Ajouter au groupe docker donne des privilèges élevés, utilisez avec précaution

## Configuration sudo sans mot de passe (Optionnel)

Si vous voulez que Jenkins utilise sudo sans mot de passe :

1. Éditer `/etc/sudoers` :
```bash
sudo visudo
```

2. Ajouter cette ligne :
```
jenkins ALL=(ALL) NOPASSWD: /usr/bin/docker
```

3. Sauvegarder et tester

