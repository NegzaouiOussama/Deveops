# Script Jenkins Docker avec Mot de Passe

## Script Corrigé avec Mot de Passe

Copiez ce script dans Jenkins (remplacez `00000000` par votre mot de passe si différent) :

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
        SUDO_PASSWORD = credentials('sudo-password') // Optionnel: utiliser credentials Jenkins
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
                        echo '00000000' | sudo -S docker build -t ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} .
                        echo '00000000' | sudo -S docker tag ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Run Docker Container') {
            steps {
                script {
                    sh 'echo "00000000" | sudo -S docker stop ${env.DOCKER_IMAGE_NAME}-container || true'
                    sh 'echo "00000000" | sudo -S docker rm ${env.DOCKER_IMAGE_NAME}-container || true'
                    
                    sh '''
                        echo "00000000" | sudo -S docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=rootpassword \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || true
                    '''
                    
                    sh 'sleep 10'
                    
                    sh """
                        echo "00000000" | sudo -S docker run -d --name ${env.DOCKER_IMAGE_NAME}-container \\
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

## Solution Recommandée : Configurer sudo sans mot de passe

### Étape 1 : Configurer sudoers

Sur le serveur Jenkins, exécutez :

```bash
sudo visudo
```

### Étape 2 : Ajouter cette ligne

Ajoutez à la fin du fichier (remplacez `jenkins` par l'utilisateur Jenkins si différent) :

```
jenkins ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose
```

### Étape 3 : Sauvegarder et tester

Après cette configuration, vous pouvez utiliser le script SANS mot de passe :

```groovy
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
```

## Solution Alternative : Ajouter Jenkins au groupe docker (Meilleure)

### Sur le serveur Jenkins :

```bash
# Ajouter Jenkins au groupe docker
sudo usermod -aG docker jenkins

# Vérifier l'utilisateur Jenkins
ps aux | grep jenkins

# Si l'utilisateur est différent, utilisez :
sudo usermod -aG docker $USER_JENKINS

# Redémarrer Jenkins
sudo systemctl restart jenkins
```

### Script SANS sudo (après configuration) :

```groovy
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
```

## Utiliser Jenkins Credentials (Plus Sécurisé)

### 1. Créer une credential dans Jenkins

1. Aller dans **Manage Jenkins** → **Credentials**
2. Cliquer sur **Add Credentials**
3. Type : **Secret text**
4. Secret : `00000000`
5. ID : `sudo-password`
6. Cliquer sur **OK**

### 2. Script avec credentials :

```groovy
environment {
    SUDO_PASSWORD = credentials('sudo-password')
}

stage('Build Docker Image') {
    steps {
        script {
            sh """
                echo '${env.SUDO_PASSWORD}' | sudo -S docker build -t ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} .
            """
        }
    }
}
```

## Résumé des Solutions

1. **Solution Rapide** : Utiliser `echo "00000000" | sudo -S` (script ci-dessus)
2. **Solution Recommandée** : Configurer sudo sans mot de passe pour docker
3. **Solution Meilleure** : Ajouter Jenkins au groupe docker (pas besoin de sudo)
4. **Solution Sécurisée** : Utiliser Jenkins Credentials pour stocker le mot de passe

