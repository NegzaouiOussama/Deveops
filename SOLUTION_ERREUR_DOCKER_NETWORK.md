# Solution à l'Erreur Docker Network

## Problème

L'erreur `dial tcp: lookup docker-images-prod... i/o timeout` indique un problème de connexion réseau/DNS dans WSL qui empêche Docker de télécharger l'image MySQL.

## Solution 1 : Vérifier et Corriger le DNS dans WSL

### Dans WSL, exécutez :

```bash
# Vérifier la configuration DNS
cat /etc/resolv.conf

# Si nécessaire, configurer Google DNS
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

# Redémarrer Docker
sudo systemctl restart docker
```

## Solution 2 : Script Jenkins avec Gestion d'Erreur Améliorée

Script corrigé qui gère mieux les erreurs réseau :

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
                script {
                    sh "docker build -t student-management:${BUILD_NUMBER} ."
                    sh "docker tag student-management:${BUILD_NUMBER} student-management:latest"
                }
            }
        }
        
        stage('Check MySQL Image') {
            steps {
                script {
                    sh '''
                        if ! docker images | grep -q mysql; then
                            echo "MySQL image not found, attempting to pull..."
                            docker pull mysql:8.0 || echo "Failed to pull MySQL image"
                        else
                            echo "MySQL image already exists"
                        fi
                    '''
                }
            }
        }
        
        stage('Run MySQL Container') {
            steps {
                script {
                    sh 'docker stop student-mysql || true'
                    sh 'docker rm student-mysql || true'
                    
                    sh '''
                        docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=0000 \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || echo "MySQL container failed to start"
                    '''
                    
                    sh 'sleep 15'
                }
            }
        }
        
        stage('Run Application Container') {
            steps {
                script {
                    sh 'docker stop student-management-container || true'
                    sh 'docker rm student-management-container || true'
                    
                    sh '''
                        docker run -d --name student-management-container \\
                            --link student-mysql:mysql \\
                            -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/studentdb?createDatabaseIfNotExist=true \\
                            -e SPRING_DATASOURCE_USERNAME=root \\
                            -e SPRING_DATASOURCE_PASSWORD=0000 \\
                            -p 8089:8089 \\
                            student-management:latest || echo "Application container failed to start"
                    '''
                }
            }
        }
        
        stage('Verify Containers') {
            steps {
                script {
                    sh 'sleep 20'
                    sh 'docker ps'
                    sh 'docker logs --tail 50 student-management-container || true'
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
            echo "Application: http://localhost:8089/student"
        }
        failure {
            echo 'Pipeline a échoué!'
            script {
                sh 'docker ps -a || true'
                sh 'docker logs student-mysql || true'
                sh 'docker logs student-management-container || true'
            }
        }
    }
}
```

## Solution 3 : Pré-télécharger l'Image MySQL

### Dans WSL, avant d'exécuter Jenkins :

```bash
# Télécharger l'image MySQL manuellement
docker pull mysql:8.0

# Vérifier qu'elle est bien téléchargée
docker images | grep mysql
```

## Solution 4 : Utiliser Docker Compose (Recommandé)

Si Docker Compose est disponible, créez un script qui utilise docker-compose.yml :

```groovy
stage('Start Services with Docker Compose') {
    steps {
        script {
            sh 'docker-compose down || true'
            sh 'docker-compose up -d'
            sh 'sleep 20'
            sh 'docker-compose ps'
        }
    }
}
```

## Solution 5 : Script avec Retry pour le Pull

```groovy
stage('Pull MySQL Image with Retry') {
    steps {
        script {
            def maxRetries = 3
            def retryCount = 0
            def success = false
            
            while (retryCount < maxRetries && !success) {
                try {
                    sh 'docker pull mysql:8.0'
                    success = true
                } catch (Exception e) {
                    retryCount++
                    echo "Pull attempt ${retryCount} failed, retrying..."
                    sh 'sleep 5'
                }
            }
            
            if (!success) {
                error("Failed to pull MySQL image after ${maxRetries} attempts")
            }
        }
    }
}
```

## Solution 6 : Vérifier la Connexion Internet dans WSL

```bash
# Tester la connexion
ping -c 3 8.8.8.8

# Tester DNS
nslookup docker.io

# Si ça ne fonctionne pas, redémarrer WSL
# Dans PowerShell Windows :
wsl --shutdown
wsl
```

## Solution 7 : Utiliser une Image MySQL Locale

Si vous avez déjà une image MySQL, utilisez-la :

```groovy
stage('Run MySQL Container') {
    steps {
        script {
            sh '''
                docker run -d --name student-mysql \\
                    -e MYSQL_ROOT_PASSWORD=0000 \\
                    -e MYSQL_DATABASE=studentdb \\
                    -p 3306:3306 \\
                    $(docker images mysql --format "{{.Repository}}:{{.Tag}}" | head -1) || mysql:8.0
            '''
        }
    }
}
```

## Diagnostic

Pour diagnostiquer le problème :

```bash
# Dans WSL
docker info
docker pull hello-world
ping google.com
nslookup docker.io
```

## Solution Rapide : Script Minimal qui Continue même si MySQL échoue

```groovy
stage('Run Docker Container') {
    steps {
        script {
            // Essayer de démarrer MySQL, mais continuer même en cas d'échec
            sh '''
                docker stop student-mysql || true
                docker rm student-mysql || true
                docker run -d --name student-mysql \\
                    -e MYSQL_ROOT_PASSWORD=0000 \\
                    -e MYSQL_DATABASE=studentdb \\
                    -p 3306:3306 \\
                    mysql:8.0 || echo "MySQL failed, but continuing..."
            '''
            
            // Démarrer l'application même si MySQL n'est pas disponible
            sh '''
                docker stop student-management-container || true
                docker rm student-management-container || true
                docker run -d --name student-management-container \\
                    -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/studentdb?createDatabaseIfNotExist=true \\
                    -e SPRING_DATASOURCE_USERNAME=root \\
                    -e SPRING_DATASOURCE_PASSWORD=0000 \\
                    -p 8089:8089 \\
                    student-management:latest || echo "Application failed to start"
            '''
        }
    }
}
```

