# Solution : Sudo demande un mot de passe dans Jenkins

## Problème

L'erreur `sudo: a password is required` signifie que Jenkins ne peut pas utiliser sudo car il demande un mot de passe interactif.

## Solution 1 : Configurer sudo sans mot de passe (Recommandé)

### Sur le serveur Jenkins, exécutez ces commandes :

```bash
# 1. Éditer le fichier sudoers
sudo visudo

# 2. Ajouter cette ligne à la fin du fichier (remplacez 'jenkins' par l'utilisateur Jenkins si différent)
jenkins ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose

# 3. Sauvegarder et quitter (Ctrl+X, puis Y, puis Enter)
```

**OU** créez un fichier spécifique :

```bash
# Créer un fichier pour Jenkins
sudo visudo -f /etc/sudoers.d/jenkins

# Ajouter cette ligne :
jenkins ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose

# Sauvegarder
```

### Vérifier l'utilisateur Jenkins :

```bash
# Vérifier quel utilisateur exécute Jenkins
ps aux | grep jenkins
# ou
cat /etc/passwd | grep jenkins
```

## Solution 2 : Ajouter Jenkins au groupe docker (Meilleure solution)

Cette solution est plus sécurisée et ne nécessite pas sudo :

```bash
# 1. Ajouter Jenkins au groupe docker
sudo usermod -aG docker jenkins

# 2. Vérifier que le groupe docker existe
getent group docker

# 3. Redémarrer Jenkins pour appliquer les changements
sudo systemctl restart jenkins
# ou
sudo service jenkins restart

# 4. Vérifier
groups jenkins
# doit afficher "docker" dans la liste
```

**Après cette configuration, utilisez le script SANS sudo** (voir ci-dessous).

## Script Jenkins SANS sudo (après Solution 2)

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
                    sh 'docker stop ${env.DOCKER_IMAGE_NAME}-container || true'
                    sh 'docker rm ${env.DOCKER_IMAGE_NAME}-container || true'
                    
                    sh '''
                        docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=rootpassword \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || true
                    '''
                    
                    sh 'sleep 10'
                    
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
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            cleanWs()
        }
        success {
            echo 'Pipeline réussi avec succès!'
            echo "Image Docker: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Script Jenkins AVEC sudo (après Solution 1)

Si vous avez configuré sudo sans mot de passe :

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
                    sh 'sudo docker stop ${env.DOCKER_IMAGE_NAME}-container || true'
                    sh 'sudo docker rm ${env.DOCKER_IMAGE_NAME}-container || true'
                    
                    sh '''
                        sudo docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=rootpassword \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || true
                    '''
                    
                    sh 'sleep 10'
                    
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
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Vérification

Après avoir appliqué une des solutions, testez :

```bash
# Se connecter en tant qu'utilisateur Jenkins
sudo su - jenkins

# Tester Docker (sans sudo si Solution 2)
docker ps

# OU avec sudo (si Solution 1)
sudo docker ps
```

## Recommandation

**Utilisez la Solution 2** (ajouter au groupe docker) car :
- ✅ Plus sécurisée
- ✅ Pas besoin de sudo
- ✅ Configuration plus simple
- ✅ Meilleure pratique Docker

## Dépannage

### Si le groupe docker n'existe pas :

```bash
# Créer le groupe docker
sudo groupadd docker

# Ajouter Jenkins
sudo usermod -aG docker jenkins

# Redémarrer Jenkins
sudo systemctl restart jenkins
```

### Si les permissions ne fonctionnent toujours pas :

```bash
# Vérifier les permissions du socket Docker
ls -l /var/run/docker.sock

# Si nécessaire, changer les permissions (temporaire)
sudo chmod 666 /var/run/docker.sock
```


